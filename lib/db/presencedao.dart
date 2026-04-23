import 'package:sqflite/sqflite.dart';
import '../models/Presence.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart'; // ← AJOUTEZ CET IMPORT

class PresenceDao {
  final dbHelper = DatabaseHelper.instance;

  // 🔹 Insérer ou remplacer une présence
  Future<int> insertPresence(Presence p) async {
    final db = await dbHelper.database;
    return await db.insert(
      'presences',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 🔹 Récupérer l'historique des présences d'un enfant
  Future<List<Presence>> getPresencesByEnfant(String enfantId) async {
    final db = await dbHelper.database;
    
    final maps = await db.query(
      'presences',
      where: 'enfantId = ?',
      whereArgs: [enfantId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => Presence.fromMap(maps[i]));
  }

  // 🔹 Récupérer la présence d'un enfant pour une date donnée
  Future<Presence?> getPresenceForDate(String enfantId, DateTime date) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'presences',
      where: 'enfantId = ? AND date = ?',
      whereArgs: [enfantId, date.toIso8601String()],
    );

    if (maps.isNotEmpty) {
      return Presence.fromMap(maps.first);
    }
    return null;
  }

  // 🔹 Récupérer les présences pour une date spécifique
  // Dans presence_dao.dart

// 🔹 Récupérer les présences pour une date spécifique (version corrigée)
Future<List<Presence>> getPresencesByDate(DateTime date) async {
  final db = await dbHelper.database;
  
  // Convertir la date en format string sans l'heure
  final dateString = DateFormat('yyyy-MM-dd').format(date);
  
  final maps = await db.query(
    'presences',
    where: 'date LIKE ?',
    whereArgs: ['$dateString%'], // Recherche par préfixe
  );

  return List.generate(maps.length, (i) => Presence.fromMap(maps[i]));
}

  // 🔹 Mettre à jour le statut d'une présence
  Future<int> updatePresenceStatus(String enfantId, DateTime date, String newStatus) async {
    final db = await dbHelper.database;
    return await db.update(
      'presences',
      {'statut': newStatus},
      where: 'enfantId = ? AND date = ?',
      whereArgs: [enfantId, date.toIso8601String()],
    );
  }

  // 🔹 Supprimer une présence
  Future<int> deletePresence(String enfantId, DateTime date) async {
    final db = await dbHelper.database;
    return await db.delete(
      'presences',
      where: 'enfantId = ? AND date = ?',
      whereArgs: [enfantId, date.toIso8601String()],
    );
  }

  // 🔹 Supprimer les méthodes qui utilisent la colonne 'classe' (optionnel)
  // Ces méthodes ne fonctionneront pas car la colonne 'classe' n'existe pas
  /*
  Future<List<String>> getClassesByEnfant(String enfantId) async {
    // Cette méthode ne peut pas fonctionner sans colonne 'classe'
    return [];
  }

  Future<List<Presence>> getPresencesByClasse(String classe) async {
    // Cette méthode ne peut pas fonctionner sans colonne 'classe'
    return [];
  }
  */
}