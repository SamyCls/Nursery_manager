import 'package:flutter/material.dart';

class Activity {
  final String id; // Unique ID for DB storage
  String className; // Class concerned
   String title; // Activity title
   DateTime date; // Full date (YYYY-MM-DD)
   TimeOfDay start; // Start time
   TimeOfDay end; // End time
   String notes; // Optional notes

  Activity({
    required this.id,
    required this.className,
    required this.title,
    required this.date,
    required this.start,
    required this.end,
    this.notes = '',
  });
}