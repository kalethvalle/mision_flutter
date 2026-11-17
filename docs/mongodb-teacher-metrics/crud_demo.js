// crud_demo.js
// Programa de conexion y CRUD sin credenciales en el codigo.
// Requisitos:
//   npm install mongodb
//   export MONGODB_URI="mongodb://quest_app@localhost:27017/flutter_quest_dw?authSource=flutter_quest_dw"
//   node crud_demo.js

const { MongoClient } = require("mongodb");

const uri = process.env.MONGODB_URI;

if (!uri) {
  console.error("Falta MONGODB_URI. Define la variable de entorno antes de ejecutar.");
  process.exit(1);
}

async function main() {
  const client = new MongoClient(uri);

  try {
    await client.connect();
    const db = client.db("flutter_quest_dw");
    const students = db.collection("students");

    const studentId = "student_crud_demo";
    const student = {
      username: "demo.crud",
      displayName: "Demo CRUD",
      role: "student",
      isActive: true,
      createdAt: new Date()
    };

    await students.updateOne(
      { _id: studentId },
      { $setOnInsert: { _id: studentId }, $set: student },
      { upsert: true }
    );
    console.log("CREATE/UPSERT OK:", studentId);

    const found = await students.findOne({ _id: studentId });
    console.log("READ OK:", found.displayName);

    await students.updateOne(
      { _id: studentId },
      { $set: { isActive: false, updatedAt: new Date() } }
    );
    console.log("UPDATE OK:", studentId);

    const activeStudents = await students
      .find({ isActive: true }, { projection: { username: 1, displayName: 1 } })
      .sort({ displayName: 1 })
      .limit(5)
      .toArray();
    console.log("LIST OK:", activeStudents);

    await students.deleteOne({ _id: studentId });
    console.log("DELETE OK:", studentId);
  } finally {
    await client.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
