import '../../core/models/analytics_model.dart';
import '../../core/models/user_model.dart';
import '../../core/repositories/catalog_repository.dart';

abstract interface class AnalyticsStore {
  Future<AnalyticsDashboard> dashboard();

  Future<AnalyticsDashboard> refresh();
}

class AnalyticsService {
  const AnalyticsService(this._store);

  final AnalyticsStore _store;

  Future<AnalyticsDashboard> dashboard(UserModel actor) {
    _requireTeacher(actor);
    return _store.dashboard();
  }

  Future<AnalyticsDashboard> refresh(UserModel actor) {
    _requireTeacher(actor);
    return _store.refresh();
  }

  void _requireTeacher(UserModel actor) {
    if (actor.role != UserRole.teacher) {
      throw const CatalogException(
        'forbidden',
        'Solo un docente puede consultar métricas de aprendizaje.',
      );
    }
  }
}
