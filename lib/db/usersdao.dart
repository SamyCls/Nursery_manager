// user_dao.dart
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '/models/utilisateurs.dart'; // Assurez-vous d'avoir ce modèle

class UserDao {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  // Créer un utilisateur
  Future<int> insertUser(AppUser user) async {
    final db = await dbHelper.database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Récupérer un utilisateur par son username
  Future<AppUser?> getUserByUsername(String username) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return AppUser.fromMap(maps.first);
    }
    return null;
  }

  // Récupérer tous les utilisateurs
  Future<List<AppUser>> getAllUsers() async {
    final db = await dbHelper.database;
    final maps = await db.query('users');
    return maps.map((map) => AppUser.fromMap(map)).toList();
  }

  // Mettre à jour un utilisateur
  Future<int> updateUser(AppUser user) async {
    final db = await dbHelper.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Supprimer un utilisateur
  Future<int> deleteUser(String id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Vérifier les credentials de connexion
  Future<AppUser?> authenticate(String username, String password) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      return AppUser.fromMap(maps.first);
    }
    return null;
  }
}