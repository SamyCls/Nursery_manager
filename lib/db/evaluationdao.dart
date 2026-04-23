import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/enfant.dart';

 // Make sure this import exists

class EvaluationDao {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertEvaluation(Evaluation eval) async {
    final db = await dbHelper.database;
    return await db.insert('evaluations', eval.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Evaluation>> getEvaluationsByEnfant(String enfantId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'evaluations',
      where: 'enfantId = ?',
      whereArgs: [enfantId],
      orderBy: 'date DESC',  // Order by date
    );
    return result.map((map) => Evaluation.fromMap(map)).toList();
  }

  // New method: Get evaluations by child and month
  Future<List<Evaluation>> getEvaluationsByMonth(String enfantId, int year, int month) async {
    final db = await dbHelper.database;
    
    // Calculate start and end of month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);
    
    final result = await db.query(
      'evaluations',
      where: 'enfantId = ? AND date >= ? AND date < ?',
      whereArgs: [enfantId, startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
    );
    
    return result.map((map) => Evaluation.fromMap(map)).toList();
  }

  // New method: Get all evaluations for a specific month across all children
  Future<Map<String, List<Evaluation>>> getAllEvaluationsByMonth(int year, int month) async {
    final db = await dbHelper.database;
    
    // Calculate start and end of month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);
    
    final result = await db.query(
      'evaluations',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      orderBy: 'enfantId, date',
    );
    
    // Group evaluations by child ID
    Map<String, List<Evaluation>> evaluationsByChild = {};
    for (var map in result) {
      final evaluation = Evaluation.fromMap(map);
      if (!evaluationsByChild.containsKey(evaluation.enfantId)) {
        evaluationsByChild[evaluation.enfantId] = [];
      }
      evaluationsByChild[evaluation.enfantId]!.add(evaluation);
    }
    
    return evaluationsByChild;
  }

  Future<void> deleteEvaluation(int id) async {
    final db = await dbHelper.database;
    await db.delete('evaluations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearEvaluations(String enfantId) async {
    final db = await dbHelper.database;
    await db.delete('evaluations', where: 'enfantId = ?', whereArgs: [enfantId]);
  }

  // New method: Clear evaluations for a specific month and child
  Future<void> clearEvaluationsForMonth(String enfantId, int year, int month) async {
    final db = await dbHelper.database;
    
    // Calculate start and end of month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);
    
    await db.delete(
      'evaluations',
      where: 'enfantId = ? AND date >= ? AND date < ?',
      whereArgs: [enfantId, startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
    );
  }
}