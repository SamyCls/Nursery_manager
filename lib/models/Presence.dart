class Presence {
  final String enfantId;  // FK -> enfant.id
  final DateTime date;    // jour de la présence
  final String statut;    // "Présent" | "Absent"

  Presence({
    required this.enfantId,
    required this.date,
    required this.statut,
  });

  Map<String, dynamic> toMap() {
    return {
      'enfantId': enfantId,
      'date': date.toIso8601String(),
      'statut': statut,
    };
  }

  factory Presence.fromMap(Map<String, dynamic> map) {
    return Presence(
      enfantId: map['enfantId'],
      date: DateTime.parse(map['date']),
      statut: map['statut'],
    );
  }
}
