# Modelos de datos para metricas y analitica

Este documento resume el MER SQL operativo y el modelo documental MongoDB que
soporta el dashboard docente. Sirve como insumo directo para el RFC de
arquitectura.

## Decision de arquitectura

SQLite sigue siendo la fuente de verdad para autenticacion, sesiones,
entrenamiento, parciales, calificaciones, incidentes y progreso. MongoDB queda
como warehouse derivado: guarda documentos reconstruibles y snapshots del mismo
`AnalyticsDashboard` que ya consume la interfaz docente.

```mermaid
flowchart LR
  UI[Dashboard docente] --> API[Analytics API]
  API --> Service[AnalyticsService]
  Service --> Store{AnalyticsStore}
  Store --> SQLiteStore[SqliteAnalyticsStore]
  Store --> MongoStore[MongoAnalyticsStore]
  SQLiteStore --> SQLite[(SQLite operacional)]
  MongoStore --> SQLite
  MongoStore --> Mongo[(MongoDB analitico)]
  Mongo --> Snapshot[teacher_metric_snapshots.current]
```

## MER SQL operacional

```mermaid
erDiagram
  USERS ||--o{ SESSIONS : owns
  USERS ||--o{ TRAINING_ATTEMPTS : practices
  USERS ||--o{ MISSION_PROGRESS : completes
  USERS ||--o{ ASSESSMENT_ATTEMPTS : takes
  WORLDS ||--o{ TOPICS : contains
  WORLDS ||--o{ MISSIONS : contains
  TOPICS ||--o{ MISSIONS : groups
  MISSIONS ||--o{ MISSION_OPTIONS : offers
  MISSIONS ||--o{ TRAINING_ATTEMPTS : receives
  TRAINING_ATTEMPTS ||--o{ TRAINING_ATTEMPT_OPTIONS : selected
  WORLDS ||--o{ QUESTIONS : evaluates
  TOPICS ||--o{ QUESTIONS : classifies
  QUESTIONS ||--o{ QUESTION_OPTIONS : offers
  WORLDS ||--o{ ASSESSMENT_WORLD_SETTINGS : configures
  WORLDS ||--o{ ASSESSMENT_SESSIONS : opens
  ASSESSMENT_SESSIONS ||--o{ ASSESSMENT_ATTEMPTS : controls
  ASSESSMENT_ATTEMPTS ||--o{ ASSESSMENT_ATTEMPT_QUESTIONS : snapshots
  ASSESSMENT_ATTEMPT_QUESTIONS ||--o{ ASSESSMENT_ATTEMPT_OPTIONS : snapshots
  ASSESSMENT_ATTEMPT_OPTIONS ||--o{ ASSESSMENT_ANSWERS : answers
  ASSESSMENT_ATTEMPTS ||--o{ ASSESSMENT_DRAFT_ANSWERS : drafts
  ASSESSMENT_SESSIONS ||--o{ ASSESSMENT_ATTEMPT_EVENTS : audits
  ASSESSMENT_ATTEMPTS ||--o{ ASSESSMENT_ATTEMPT_EVENTS : emits

  USERS {
    string id PK
    string username
    string display_name
    string role
    bool is_active
  }
  WORLDS {
    string id PK
    string title
    int sort_order
    string status
  }
  TOPICS {
    string id PK
    string world_id FK
    string title
    int sort_order
    string status
  }
  MISSIONS {
    string id PK
    string world_id FK
    string topic_id FK
    string title
    string selection_type
    int content_version
    string status
  }
  TRAINING_ATTEMPTS {
    string id PK
    string user_id FK
    string mission_id FK
    bool is_correct
    bool hint_used
    datetime attempted_at
  }
  ASSESSMENT_SESSIONS {
    string id PK
    string world_id FK
    string opened_by FK
    string status
    datetime opened_at
    datetime closes_at
  }
  ASSESSMENT_ATTEMPTS {
    string id PK
    string user_id FK
    string world_id FK
    string session_id FK
    string status
    int score
    bool passed
  }
  ASSESSMENT_ATTEMPT_EVENTS {
    string id PK
    string session_id FK
    string attempt_id FK
    string user_id FK
    string type
    int score
    datetime occurred_at
  }
```

## MER SQL analitico local

```mermaid
erDiagram
  DW_DIM_STUDENT ||--o{ DW_FACT_TRAINING_ATTEMPT : student
  DW_DIM_STUDENT ||--o{ DW_FACT_ASSESSMENT_ATTEMPT : student
  DW_DIM_STUDENT ||--o{ DW_FACT_INTEGRITY_EVENT : student
  DW_DIM_WORLD ||--o{ DW_DIM_TOPIC : contains
  DW_DIM_WORLD ||--o{ DW_DIM_MISSION : contains
  DW_DIM_TOPIC ||--o{ DW_DIM_MISSION : groups
  DW_DIM_TOPIC ||--o{ DW_FACT_TRAINING_ATTEMPT : topic
  DW_DIM_TOPIC ||--o{ DW_FACT_ASSESSMENT_TOPIC_SCORE : topic
  DW_DIM_MISSION ||--o{ DW_FACT_TRAINING_ATTEMPT : mission
  DW_DIM_DATE ||--o{ DW_FACT_TRAINING_ATTEMPT : date
  DW_DIM_DATE ||--o{ DW_FACT_ASSESSMENT_ATTEMPT : date
  DW_DIM_DATE ||--o{ DW_FACT_INTEGRITY_EVENT : date

  DW_DIM_STUDENT {
    string student_id PK
    string username
    string display_name
    bool is_active
  }
  DW_DIM_WORLD {
    string world_id PK
    string title
    int sort_order
    string status
  }
  DW_DIM_TOPIC {
    string topic_id PK
    string world_id
    string title
    string status
  }
  DW_DIM_MISSION {
    string mission_id PK
    string world_id
    string topic_id
    string title
    string status
  }
  DW_FACT_TRAINING_ATTEMPT {
    string attempt_id PK
    string student_id
    string topic_id
    string mission_id
    bool is_correct
  }
  DW_FACT_ASSESSMENT_ATTEMPT {
    string attempt_id PK
    string student_id
    string world_id
    string status
    int score
    int incidents
  }
  DW_FACT_INTEGRITY_EVENT {
    string event_id PK
    string student_id
    string attempt_id
    string type
    datetime occurred_at
  }
```

## Modelo documental MongoDB

```mermaid
erDiagram
  STUDENTS ||--o{ TRAINING_ATTEMPTS : studentId
  STUDENTS ||--o{ ASSESSMENT_ATTEMPTS : studentId
  STUDENTS ||--o{ INTEGRITY_EVENTS : studentId
  LEARNING_CATALOG ||--o{ TRAINING_ATTEMPTS : missionId
  LEARNING_CATALOG ||--o{ ASSESSMENT_ATTEMPTS : worldId
  ASSESSMENT_ATTEMPTS ||--o{ INTEGRITY_EVENTS : attemptId
  ETL_RUNS ||--o{ TEACHER_METRIC_SNAPSHOTS : runId

  STUDENTS {
    string _id
    string runId
    string username
    string displayName
    bool isActive
  }
  LEARNING_CATALOG {
    string _id
    string runId
    string title
    array topics
    array missions
  }
  TRAINING_ATTEMPTS {
    string _id
    string runId
    string studentId
    string worldId
    string topicId
    string missionId
    array selectedOptionIds
    bool isCorrect
  }
  ASSESSMENT_ATTEMPTS {
    string _id
    string runId
    string studentId
    string worldId
    string sessionId
    string status
    int score
    array topicScores
    array questionReview
  }
  INTEGRITY_EVENTS {
    string _id
    string runId
    string studentId
    string attemptId
    string sessionId
    string type
  }
  TEACHER_METRIC_SNAPSHOTS {
    string _id
    string runId
    date refreshedAt
    object dashboard
  }
  ETL_RUNS {
    string _id
    string runId
    string status
    object counts
  }
```

## Colecciones MongoDB

| Coleccion | Uso | Fuente |
| --- | --- | --- |
| `students` | Dimension docente de estudiantes activos/inactivos | `users` |
| `learning_catalog` | Mundo con temas y misiones embebidas | `worlds`, `topics`, `missions` |
| `training_attempts` | Hechos de entrenamiento | `training_attempts` |
| `assessment_attempts` | Intentos cerrados de parcial con revision | `assessment_attempts` y snapshots |
| `integrity_events` | Incidentes y anulaciones auditables | `assessment_attempt_events` |
| `teacher_metric_snapshots` | JSON publicado del dashboard docente | `AnalyticsDashboard` |
| `etl_runs` | Bitacora de refresh exitoso/fallido | runtime analitico |

El documento `_id = "current"` en `teacher_metric_snapshots` es el snapshot
publicado que lee `GET /api/v1/analytics/dashboard` cuando
`ANALYTICS_STORE=mongo`.
