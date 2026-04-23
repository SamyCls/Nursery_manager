class Enfant {
  final String id;
  final String nom;
  final String prenom;
  final String classe;
  final String telephone;
  bool estActif;

  // Infos supplémentaires du profil
  final String? dateNaissance;
  final String? sexe;
  final String? adresse;
  String? photoPath; // Peut être un path local ou une URL

  // Date d’inscription
  DateTime? dateInscription;

  // Infos du père
  final String? nomPrenomPere;
  final String? telPere;
  final String? professionPere;
  final String? adressePere;

  // Infos de la mère
  final String? nomPrenomMere;
  final String? telMere;
  final String? professionMere;
  final String? statutFamilial;

  // Infos santé
  final String? allergies;
  final String? commentairesMedicaux;
  final String? dossierMedicalPath; // PDF ou image

  // Paiements
  final List<Paiement>? paiements;

  // Historique de présence
  final Map<DateTime, String>? historiquePresence;

  // ✅ Progression scolaire
  List<Evaluation>? evaluations;

  Enfant({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.classe,
    required this.telephone,
    required this.estActif,
    this.dateNaissance,
    this.sexe,
    this.adresse,
    this.photoPath,
    this.dateInscription,
    this.nomPrenomPere,
    this.telPere,
    this.professionPere,
    this.adressePere,
    this.nomPrenomMere,
    this.telMere,
    this.professionMere,
    this.statutFamilial,
    this.allergies,
    this.commentairesMedicaux,
    this.dossierMedicalPath,
    this.historiquePresence,
    this.paiements,
    this.evaluations, // 👈 ajouté
  });

  String get nomComplet => '$nom $prenom';
  String get statut => estActif ? 'ACTIF' : 'INACTIF';
}

enum StatutPaiements {
  paye,
  impaye,
  partiel,
}

class Paiement {
  final DateTime date;
  final String mois;
  int montantPaye;
  int reste;
  int montantdu;
  StatutPaiements statut;

  Paiement({
    required this.date,
    required this.mois,
    required this.montantdu,
    required this.montantPaye,
    required this.reste,
    required this.statut,
  });
}

// ✅ Modèle pour les évaluations
// In your models/enfant.dart file
class Evaluation {
  final String enfantId;
  final DateTime date;  // Add date field
  String competence;   
  bool valeur;         
  String? texte;       

  Evaluation({
    required this.enfantId,
    required this.date,  // Add date parameter
    required this.competence,
    this.valeur = false,
    this.texte,
  });

  Map<String, dynamic> toMap() {
    return {
      'enfantId': enfantId,
      'date': date.millisecondsSinceEpoch,  // Store as timestamp
      'competence': competence,
      'valeur': valeur ? 1 : 0,
      'texte': texte,
    };
  }

  factory Evaluation.fromMap(Map<String, dynamic> map) {
    return Evaluation(
      enfantId: map['enfantId'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),  // Convert from timestamp
      competence: map['competence'],
      valeur: map['valeur'] == 1,
      texte: map['texte'],
    );
  }
}
// Exemple d’enfant vide
final emptyEnfant = Enfant(
  id: '',
  nom: '',
  prenom: '',
  classe: '',
  telephone: '',
  estActif: true,
  dateNaissance: '',
  sexe: '',
  adresse: '',
  photoPath: '',
  dateInscription: null,
  nomPrenomPere: '',
  telPere: '',
  professionPere: '',
  adressePere: '',
  nomPrenomMere: '',
  telMere: '',
  professionMere: '',
  statutFamilial: '',
  allergies: '',
  commentairesMedicaux: '',
  evaluations: [], // 👈 initialisé vide
);
