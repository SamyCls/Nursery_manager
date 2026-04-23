import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/depenses.dart';

class DepenseDao {
  final dbHelper = DatabaseHelper.instance;

  // Convertir un Depense en Map pour l'insertion en DB
  Map<String, dynamic> _depenseToMap(Depense d) {
    return {
      'id': d.id,
      'categorie': d.categorie,
      'description': d.description,
      'montant': d.montant,
      'date': d.date.toIso8601String(), // Stocker en ISO
      'attestation': d.attestation,
    };
  }

  // Convertir un Map de la DB en Depense
  Depense _mapToDepense(Map<String, dynamic> map) {
    return Depense(
      id: map['id'],
      categorie: map['categorie'],
      description: map['description'],
      montant: map['montant'],
      date: DateTime.parse(map['date']),
      attestation: map['attestation'] ?? '',
    );
  }

  /// Insérer une dépense
  Future<void> insertDepense(Depense depense) async {
    final db = await dbHelper.database;
    await db.insert(
      'depenses',
      _depenseToMap(depense),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupérer toutes les dépenses
  Future<List<Depense>> getAllDepenses() async {
    final db = await dbHelper.database;
    final maps = await db.query('depenses', orderBy: "date DESC");
    return maps.map((m) => _mapToDepense(m)).toList();
  }

  /// Récupérer une dépense par ID
  Future<Depense?> getDepenseById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'depenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return _mapToDepense(maps.first);
    }
    return null;
  }

  /// Mettre à jour une dépense
  Future<int> updateDepense(Depense depense) async {
    final db = await dbHelper.database;
    return await db.update(
      'depenses',
      _depenseToMap(depense),
      where: 'id = ?',
      whereArgs: [depense.id],
    );
  }

  /// Supprimer une dépense
  Future<int> deleteDepense(String id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'depenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Supprimer toutes les dépenses
  Future<int> deleteAllDepenses() async {
    final db = await dbHelper.database;
    return await db.delete('depenses');
  }
}
