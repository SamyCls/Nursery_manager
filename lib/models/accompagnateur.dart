class Accompagnateur {
  final int? id;            
  final String enfantId;    
  final String nomPrenom;
  final String telephone;
  final String cin;

  Accompagnateur({
    this.id,
    required this.enfantId,
    required this.nomPrenom,
    required this.telephone,
    required this.cin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enfantId': enfantId,
      'nomPrenom': nomPrenom,
      'telephone': telephone,
      'cin': cin,
    };
  }

  factory Accompagnateur.fromMap(Map<String, dynamic> map) {
    return Accompagnateur(
      id: map['id'],
      enfantId: map['enfantId'],
      nomPrenom: map['nomPrenom'],
      telephone: map['telephone'],
      cin: map['cin'],
    );
  }
}
