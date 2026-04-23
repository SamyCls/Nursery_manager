import 'package:uuid/uuid.dart';

class Depense {
  String id;
  String categorie;
  String description;
  double montant;
  DateTime date;
  String attestation;

  // Constructeur avec paramètres requis
  Depense({
    String? id,
    required this.categorie,
    required this.description,
    required this.montant,
    required this.date,
    required this.attestation,
  }) : id = id ?? const Uuid().v4(); // génère un id automatiquement si non fourni
}