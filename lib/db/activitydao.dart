import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/activity.dart';
import 'database_helper.dart';

class ActivityDao {
  final dbHelper = DatabaseHelper.instance;

  // ---------------- Convert Activity -> Map ----------------
  Map<String, dynamic> _activityToMap(Activity a) {
    return {
      'id': a.id,
      'className': a.className,
      'title': a.title,
      'date': a.date.toIso8601String(), // store as ISO 8601
      'start': '${a.start.hour}:${a.start.minute}', // HH:mm
      'end': '${a.end.hour}:${a.end.minute}',       // HH:mm
      'notes': a.notes,
    };
  }

  // ---------------- Convert Map -> Activity ----------------
  Activity _mapToActivity(Map<String, dynamic> map) {
    TimeOfDay _parseTime(String t) {
      final parts = t.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return Activity(
      id: map['id'],
      className: map['className'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      start: _parseTime(map['start']),
      end: _parseTime(map['end']),
      notes: map['notes'] ?? '',
    );
  }

  // ---------------- Insert ----------------
  Future<void> insertActivity(Activity activity) async {
    final db = await dbHelper.database;
    await db.insert(
      'activities',
      _activityToMap(activity),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------------- Update ----------------
  Future<int> updateActivity(Activity activity) async {
    final db = await dbHelper.database;
    return await db.update(
      'activities',
      _activityToMap(activity),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  // ---------------- Delete ----------------
  Future<int> deleteActivity(String id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- Fetch all ----------------
  Future<List<Activity>> getAllActivities() async {
    final db = await dbHelper.database;
    final maps = await db.query('activities');
    return maps.map(_mapToActivity).toList();
  }

  // ---------------- Fetch by class + date (like planner) ----------------
  Future<List<Activity>> getActivitiesByClassAndDate(
      String className, DateTime day) async {
    final db = await dbHelper.database;

    // normalize date to YYYY-MM-DD
    final dateString =
        DateTime(day.year, day.month, day.day).toIso8601String().split('T')[0];

    final maps = await db.query(
      'activities',
      where: 'className = ? AND date LIKE ?',
      whereArgs: [className, '$dateString%'],
    );

    final list = maps.map(_mapToActivity).toList();

    // sort by start time
    list.sort((a, b) =>
        (a.start.hour * 60 + a.start.minute) -
        (b.start.hour * 60 + b.start.minute));
    return list;
  }

  // ---------------- Fetch one ----------------
  Future<Activity?> getActivityById(String id) async {
    final db = await dbHelper.database;
    final maps =
        await db.query('activities', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return _mapToActivity(maps.first);
    }
    return null;
  }
}
