import '../models/accompagnateur.dart';
import 'database_helper.dart';

class AccompagnateurDao {
  final dbHelper = DatabaseHelper.instance;

  // 🔹 Ajouter un accompagnateur
  Future<int> insertAccompagnateur(Accompagnateur acc) async {
    final db = await dbHelper.database;
    return await db.insert('accompagnateurs', acc.toMap());
  }

  // 🔹 Récupérer les accompagnateurs d’un enfant
  Future<List<Accompagnateur>> getAccompagnateursByEnfant(String enfantId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'accompagnateurs',
      where: 'enfantId = ?',
      whereArgs: [enfantId],
    );

    return List.generate(maps.length, (i) => Accompagnateur.fromMap(maps[i]));
  }

  // 🔹 Supprimer un accompagnateur
  Future<int> deleteAccompagnateur(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'accompagnateurs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🔹 Mettre à jour un accompagnateur
  Future<int> updateAccompagnateur(Accompagnateur acc) async {
    final db = await dbHelper.database;
    return await db.update(
      'accompagnateurs',
      acc.toMap(),
      where: 'id = ?',
      whereArgs: [acc.id],
    );
  }
}
