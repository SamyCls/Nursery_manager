// Seeds the local SQLite database with realistic French/Algerian dummy data.
//
// Public entry point: `seedDatabase()`. Call it once after the database has
// been opened (e.g. after `DatabaseHelper.instance.database`). All inserts use
// `ConflictAlgorithm.ignore`, so calling this multiple times is safe.

import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Public entry point — seeds every table in the correct dependency order.
Future<void> seedDatabase() async {
  final db = await DatabaseHelper.instance.database;

  // Order matters: respect FK dependencies.
  await _seedUsers(db);
  await _seedEnfants(db);                // FK target for many tables
  await _seedAccompagnateurs(db);        // FK -> enfants
  await _seedPresences(db);              // FK-like -> enfants
  await _seedEmployes(db);               // FK target for paiements_employe
  await _seedPaiementsEmploye(db);       // FK -> employes
  await _seedActivities(db);             // independent
  await _seedDepenses(db);               // independent
  await _seedPaiementsEnfant(db);        // FK -> enfants
  await _seedEvaluations(db);            // FK -> enfants
}

// ---------------------------------------------------------------------------
// USERS — 3 (1 admin + 2 standard)
// ---------------------------------------------------------------------------
Future<void> _seedUsers(Database db) async {
  final users = [
    {
      'id': 'usr-admin-001',
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
    },
    {
      'id': 'usr-std-001',
      'username': 'fatima',
      'password': 'pass123',
      'role': 'standard',
    },
    {
      'id': 'usr-std-002',
      'username': 'karim',
      'password': 'pass123',
      'role': 'standard',
    },
  ];

  for (final u in users) {
    await db.insert('users', u, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}

// ---------------------------------------------------------------------------
// ENFANTS — 25 (24 actifs + 1 inactif), répartis sur les 3 sections
// ---------------------------------------------------------------------------
Future<void> _seedEnfants(Database db) async {
  // Algerian first/last names + addresses
  const classes = ['Petite Section', 'Moyenne Section', 'Grande Section'];
  const wilayas = ['Alger', 'Oran', 'Constantine', 'Annaba', 'Blida', 'Sétif', 'Tlemcen', 'Béjaïa'];

  final enfants = <Map<String, dynamic>>[
    _enfant('ENF-001', 'Benali',     'Yacine',   'M', '2020-03-12', 'Petite Section',  'Mariés',
        'Mohamed Benali',     'Médecin',     'Samira Haddad',     'Enseignante',
        'Cité des Pins, Bt A n°12, Alger', '0550123456', '0660123456', '0770123456',
        'Arachides',           'Asthme léger — inhalateur dans le sac'),
    _enfant('ENF-002', 'Kaci',       'Lina',     'F', '2020-07-22', 'Petite Section',  'Mariés',
        'Karim Kaci',         'Ingénieur',   'Nawel Belkacem',    'Pharmacienne',
        'Rue Larbi Ben M\'hidi n°45, Oran', '0551234567', '0661234567', null,
        null, null),
    _enfant('ENF-003', 'Mansouri',   'Amine',    'M', '2019-11-05', 'Moyenne Section', 'Mariés',
        'Sofiane Mansouri',   'Commerçant',  'Lila Bouzid',       'Femme au foyer',
        'Hai El Badr, Bt 7, Constantine', '0552345678', '0662345678', '0772345678',
        null, null),
    _enfant('ENF-004', 'Cherif',     'Inès',     'F', '2019-04-18', 'Moyenne Section', 'Mariés',
        'Abdelkader Cherif',  'Comptable',   'Hayat Saïdi',       'Infirmière',
        'Boulevard Zighoud Youcef n°23, Annaba', '0553456789', '0663456789', null,
        'Lait de vache',       'Intolérance au lactose'),
    _enfant('ENF-005', 'Boudiaf',    'Adam',     'M', '2018-09-30', 'Grande Section',  'Mariés',
        'Yacine Boudiaf',     'Architecte',  'Souad Bensalem',    'Avocate',
        'Cité 1000 Logements, Bt C, Blida', '0554567890', '0664567890', '0774567890',
        null, null),
    _enfant('ENF-006', 'Hamidi',     'Maya',     'F', '2018-12-14', 'Grande Section',  'Divorcés',
        'Reda Hamidi',        'Chauffeur',   'Amina Lounis',      'Coiffeuse',
        'Rue de la République n°8, Sétif', '0555678901', '0665678901', null,
        'Œufs',                'Eczéma — crème prescrite'),
    _enfant('ENF-007', 'Zouaoui',    'Rayan',    'M', '2020-01-25', 'Petite Section',  'Mariés',
        'Hocine Zouaoui',     'Électricien', 'Karima Mahieddine', 'Couturière',
        'Hai Es-Salam Bt B, Tlemcen', '0556789012', '0666789012', null,
        null, null),
    _enfant('ENF-008', 'Belkhir',    'Sarah',    'F', '2019-08-08', 'Moyenne Section', 'Mariés',
        'Nabil Belkhir',      'Pharmacien',  'Yasmine Toumi',     'Médecin',
        'Cité du 8 Mai, Béjaïa', '0557890123', '0667890123', '0777890123',
        null, null),
    _enfant('ENF-009', 'Saadi',      'Mehdi',    'M', '2018-05-19', 'Grande Section',  'Mariés',
        'Tarek Saadi',        'Enseignant',  'Djamila Mokhtari',  'Sage-femme',
        'Cité Diar El Mahçoul, Alger', '0558901234', '0668901234', null,
        null, 'Port de lunettes'),
    _enfant('ENF-010', 'Boukhalfa',  'Nour',     'F', '2020-06-02', 'Petite Section',  'Mariés',
        'Lyes Boukhalfa',     'Mécanicien',  'Souhila Rahmani',   'Vendeuse',
        'Rue Didouche Mourad n°67, Oran', '0559012345', '0669012345', null,
        null, null),
    _enfant('ENF-011', 'Tounsi',     'Anis',     'M', '2019-02-28', 'Moyenne Section', 'Mariés',
        'Kamel Tounsi',       'Fonctionnaire','Nadia Khaldi',     'Secrétaire',
        'Cité 5 Juillet, Constantine', '0550987654', '0660987654', '0770987654',
        'Fruits à coque',      null),
    _enfant('ENF-012', 'Larbi',      'Yasmine',  'F', '2019-10-11', 'Moyenne Section', 'Mariés',
        'Faouzi Larbi',       'Plombier',    'Wahiba Slimani',    'Femme au foyer',
        'Hai El Houria, Annaba', '0551098765', '0661098765', null,
        null, null),
    _enfant('ENF-013', 'Hadji',      'Iyad',     'M', '2018-07-07', 'Grande Section',  'Veufs',
        'Ahmed Hadji',        'Boulanger',   '—',                 '—',
        'Rue des Frères Bouadou, Blida', '0552109876', '0662109876', null,
        null, 'Suivi psychologique mensuel'),
    _enfant('ENF-014', 'Brahimi',    'Ranya',    'F', '2020-09-15', 'Petite Section',  'Mariés',
        'Mourad Brahimi',     'Ingénieur',   'Sabrina Adjeroud',  'Architecte',
        'Cité AADL, Sétif', '0553210987', '0663210987', '0773210987',
        null, null),
    _enfant('ENF-015', 'Slimani',    'Zakaria',  'M', '2019-12-21', 'Moyenne Section', 'Mariés',
        'Bilal Slimani',      'Vétérinaire', 'Imane Bouchareb',   'Dentiste',
        'Boulevard Krim Belkacem, Tlemcen', '0554321098', '0664321098', null,
        null, null),
    _enfant('ENF-016', 'Chaouche',   'Lyna',     'F', '2018-04-03', 'Grande Section',  'Mariés',
        'Salim Chaouche',     'Restaurateur','Meriem Hamadi',     'Coiffeuse',
        'Cité des Olympiades, Béjaïa', '0555432109', '0665432109', '0775432109',
        'Gluten',              'Régime sans gluten strict'),
    _enfant('ENF-017', 'Berkane',    'Wassim',   'M', '2020-02-17', 'Petite Section',  'Mariés',
        'Djamel Berkane',     'Banquier',    'Linda Aït-Ouali',   'Cadre commercial',
        'Hai El Mokrani, Alger', '0556543210', '0666543210', null,
        null, null),
    _enfant('ENF-018', 'Touati',     'Selma',    'F', '2019-06-29', 'Moyenne Section', 'Mariés',
        'Riad Touati',        'Photographe', 'Salima Berrahma',   'Journaliste',
        'Rue Larbi Tebessi, Oran', '0557654321', '0667654321', null,
        null, null),
    _enfant('ENF-019', 'Khaled',     'Ilyes',    'M', '2018-11-09', 'Grande Section',  'Mariés',
        'Omar Khaled',        'Ingénieur',   'Fadila Ouyahia',    'Pharmacienne',
        'Cité 1er Novembre, Constantine', '0558765432', '0668765432', '0778765432',
        null, 'Asthme — traitement quotidien'),
    _enfant('ENF-020', 'Madani',     'Hiba',     'F', '2020-08-13', 'Petite Section',  'Mariés',
        'Yacine Madani',      'Avocat',      'Khadidja Belaïd',   'Notaire',
        'Boulevard du 1er Mai, Annaba', '0559876543', '0669876543', null,
        null, null),
    _enfant('ENF-021', 'Aliouane',   'Sami',     'M', '2019-03-26', 'Moyenne Section', 'Mariés',
        'Réda Aliouane',      'Technicien',  'Aïcha Mahmoudi',    'Enseignante',
        'Cité Bouinan, Blida', '0550321987', '0660321987', null,
        null, null),
    _enfant('ENF-022', 'Bencheikh',  'Layla',    'F', '2018-10-04', 'Grande Section',  'Mariés',
        'Mehdi Bencheikh',    'Médecin',     'Soraya Akkouche',   'Médecin',
        'Hai Amir Abdelkader, Sétif', '0551432098', '0661432098', '0771432098',
        'Pollen',              'Allergie saisonnière'),
    _enfant('ENF-023', 'Ferhat',     'Adel',     'M', '2019-01-16', 'Moyenne Section', 'Mariés',
        'Smail Ferhat',       'Agriculteur', 'Houria Belarbi',    'Femme au foyer',
        'Village Beni Snous, Tlemcen', '0552543109', '0662543109', null,
        null, null),
    _enfant('ENF-024', 'Boudjellal', 'Norah',    'F', '2020-05-24', 'Petite Section',  'Mariés',
        'Walid Boudjellal',   'Informaticien','Naïma Berkani',    'Designer',
        'Cité Tichy Bt 12, Béjaïa', '0553654210', '0663654210', null,
        null, null),
    // Inactif
    _enfant('ENF-025', 'Rahmoune',   'Nassim',   'M', '2018-08-19', 'Grande Section',  'Divorcés',
        'Said Rahmoune',      'Chauffeur',   'Houda Tahir',       'Vendeuse',
        'Rue Hassiba Ben Bouali, Alger', '0554765321', '0664765321', null,
        null, 'Inscrit pour suivi externe',
        actif: false),
  ];

  // sanity-check helper
  int actifCount = enfants.where((e) => e['estActif'] == 1).length;
  assert(actifCount == 24, 'Expected 24 active children, got $actifCount');
  assert(enfants.length == 25);

  for (final e in enfants) {
    await db.insert('enfants', e, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // silence the unused warnings for the extra constants kept above for context
  classes.length;
  wilayas.length;
}

Map<String, dynamic> _enfant(
  String id,
  String nom,
  String prenom,
  String sexeShort, // 'M' or 'F'
  String dateNaissance,
  String classe,
  String statutFamilial,
  String pere,
  String professionPere,
  String mere,
  String professionMere,
  String adresse,
  String tel,
  String telPere,
  String? telMere,
  String? allergies,
  String? commentairesMedicaux, {
  bool actif = true,
}) {
  // dateInscription = roughly 1 year after birth (typical creche entry).
  final birth = DateTime.parse(dateNaissance);
  final inscription = DateTime(birth.year + 2, birth.month, birth.day);

  return {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'classe': classe,
    'telephone': tel,
    'estActif': actif ? 1 : 0,
    'dateNaissance': dateNaissance,
    'sexe': sexeShort == 'M' ? 'Masculin' : 'Féminin',
    'adresse': adresse,
    'photoPath': null,
    'dateInscription': inscription.toIso8601String(),
    'nomPrenomPere': pere,
    'telPere': telPere,
    'professionPere': professionPere,
    'adressePere': adresse,
    'nomPrenomMere': mere,
    'telMere': telMere,
    'professionMere': professionMere,
    'statutFamilial': statutFamilial,
    'allergies': allergies,
    'commentairesMedicaux': commentairesMedicauxSafe(commentairesMedicaux),
    'dossierMedicalPath': null,
  };
}

String? commentairesMedicauxSafe(String? s) => (s == null || s.isEmpty) ? null : s;

// ---------------------------------------------------------------------------
// ACCOMPAGNATEURS — 15
// ---------------------------------------------------------------------------
Future<void> _seedAccompagnateurs(Database db) async {
  final accompagnateurs = [
    {'enfantId': 'ENF-001', 'nomPrenom': 'Yamina Benali',     'telephone': '0550111001', 'cin': '198501234567'},
    {'enfantId': 'ENF-002', 'nomPrenom': 'Mustapha Kaci',     'telephone': '0660222002', 'cin': '198502234568'},
    {'enfantId': 'ENF-003', 'nomPrenom': 'Khalida Mansouri',  'telephone': '0770333003', 'cin': '198503234569'},
    {'enfantId': 'ENF-004', 'nomPrenom': 'Brahim Cherif',     'telephone': '0550444004', 'cin': '198504234570'},
    {'enfantId': 'ENF-005', 'nomPrenom': 'Zineb Boudiaf',     'telephone': '0660555005', 'cin': '198505234571'},
    {'enfantId': 'ENF-006', 'nomPrenom': 'Tahar Lounis',      'telephone': '0770666006', 'cin': '198506234572'},
    {'enfantId': 'ENF-007', 'nomPrenom': 'Naima Zouaoui',     'telephone': '0550777007', 'cin': '198507234573'},
    {'enfantId': 'ENF-008', 'nomPrenom': 'Rachid Belkhir',    'telephone': '0660888008', 'cin': '198508234574'},
    {'enfantId': 'ENF-009', 'nomPrenom': 'Latifa Saadi',      'telephone': '0770999009', 'cin': '198509234575'},
    {'enfantId': 'ENF-010', 'nomPrenom': 'Hakim Boukhalfa',   'telephone': '0551010101', 'cin': '198510234576'},
    {'enfantId': 'ENF-011', 'nomPrenom': 'Souad Tounsi',      'telephone': '0661111111', 'cin': '198511234577'},
    {'enfantId': 'ENF-013', 'nomPrenom': 'Mokhtar Hadji',     'telephone': '0771212121', 'cin': '198512234578'},
    {'enfantId': 'ENF-016', 'nomPrenom': 'Razika Chaouche',   'telephone': '0551313131', 'cin': '198601234579'},
    {'enfantId': 'ENF-019', 'nomPrenom': 'Toufik Khaled',     'telephone': '0661414141', 'cin': '198602234580'},
    {'enfantId': 'ENF-022', 'nomPrenom': 'Hanane Bencheikh',  'telephone': '0771515151', 'cin': '198603234581'},
  ];

  for (final a in accompagnateurs) {
    await db.insert('accompagnateurs', a,
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}

// ---------------------------------------------------------------------------
// PRESENCES — 50, étalées sur plusieurs enfants et plusieurs jours
// ---------------------------------------------------------------------------
Future<void> _seedPresences(Database db) async {
  // Use ISO strings (matches PresenceDao serialization).
  final ids = List.generate(20, (i) => 'ENF-${(i + 1).toString().padLeft(3, '0')}');
  final today = DateTime(2026, 5, 4); // recent weekday
  const statuts = ['Présent', 'Absent', 'Retard'];

  final rows = <Map<String, dynamic>>[];
  int count = 0;
  // 10 distinct days (weekdays), ~5 enfants par jour => 50
  for (int d = 0; d < 10 && count < 50; d++) {
    final date = today.subtract(Duration(days: d));
    for (int k = 0; k < 5 && count < 50; k++) {
      final enfantId = ids[(d * 5 + k) % ids.length];
      // mix: 70% présent, 20% absent, 10% retard
      final pick = (d + k) % 10;
      final statut = pick < 7 ? statuts[0] : (pick < 9 ? statuts[1] : statuts[2]);
      rows.add({
        'enfantId': enfantId,
        'date': date.toIso8601String(),
        'statut': statut,
      });
      count++;
    }
  }

  for (final r in rows) {
    await db.insert('presences', r, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}

// ---------------------------------------------------------------------------
// EMPLOYES — 4
// ---------------------------------------------------------------------------
Future<void> _seedEmployes(Database db) async {
  final employes = [
    {
      'id': 'EMP-001',
      'nom': 'Benhamou', 'prenom': 'Karima',
      'dateNaissance': DateTime(1980, 4, 15).toIso8601String(),
      'dateEmbauche':  DateTime(2018, 9, 1).toIso8601String(),
      'poste': 'Directeur',
      'salaire': 95000.0,
      'telephone': '0550100200',
      'adresse': 'Cité des Eucalyptus, Alger',
      'estActif': 1,
      'photoUrl': '',
    },
    {
      'id': 'EMP-002',
      'nom': 'Hamoudi', 'prenom': 'Sabrina',
      'dateNaissance': DateTime(1990, 6, 22).toIso8601String(),
      'dateEmbauche':  DateTime(2020, 2, 10).toIso8601String(),
      'poste': 'Éducatrice',
      'salaire': 55000.0,
      'telephone': '0660200300',
      'adresse': 'Rue Hassiba Ben Bouali, Alger',
      'estActif': 1,
      'photoUrl': '',
    },
    {
      'id': 'EMP-003',
      'nom': 'Lakhdari', 'prenom': 'Nassima',
      'dateNaissance': DateTime(1992, 11, 3).toIso8601String(),
      'dateEmbauche':  DateTime(2021, 9, 5).toIso8601String(),
      'poste': 'Aide-éducatrice',
      'salaire': 42000.0,
      'telephone': '0770300400',
      'adresse': 'Cité 5 Juillet, Bab Ezzouar',
      'estActif': 1,
      'photoUrl': '',
    },
    {
      'id': 'EMP-004',
      'nom': 'Bouhadda', 'prenom': 'Mohamed',
      'dateNaissance': DateTime(1975, 1, 30).toIso8601String(),
      'dateEmbauche':  DateTime(2019, 1, 15).toIso8601String(),
      'poste': 'Agent d\'entretien',
      'salaire': 35000.0,
      'telephone': '0550400500',
      'adresse': 'Hai El Badr, Alger',
      'estActif': 1,
      'photoUrl': '',
    },
  ];

  for (final e in employes) {
    await db.insert('employes', e, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}

// ---------------------------------------------------------------------------
// PAIEMENTS EMPLOYE — 5
// statut stored as 'paye' | 'impaye' (read by EmployeDao)
// ---------------------------------------------------------------------------
Future<void> _seedPaiementsEmploye(Database db) async {
  final paiements = [
    {
      'employeId': 'EMP-001',
      'datePaiement': DateTime(2026, 4, 30).toIso8601String(),
      'mois': '2026-04',
      'salaireBase': 95000.0,
      'prime': 10000.0,
      'montantPaye': 105000.0,
      'statut': 'paye',
    },
    {
      'employeId': 'EMP-002',
      'datePaiement': DateTime(2026, 4, 30).toIso8601String(),
      'mois': '2026-04',
      'salaireBase': 55000.0,
      'prime': null,
      'montantPaye': 55000.0,
      'statut': 'paye',
    },
    {
      'employeId': 'EMP-003',
      'datePaiement': DateTime(2026, 4, 30).toIso8601String(),
      'mois': '2026-04',
      'salaireBase': 42000.0,
      'prime': 3000.0,
      'montantPaye': 45000.0,
      'statut': 'paye',
    },
    {
      'employeId': 'EMP-004',
      'datePaiement': DateTime(2026, 5, 1).toIso8601String(),
      'mois': '2026-04',
      'salaireBase': 35000.0,
      'prime': null,
      'montantPaye': 0.0,
      'statut': 'impaye',
    },
    {
      'employeId': 'EMP-002',
      'datePaiement': DateTime(2026, 5, 1).toIso8601String(),
      'mois': '2026-05',
      'salaireBase': 55000.0,
      'prime': null,
      'montantPaye': 0.0,
      'statut': 'impaye',
    },
  ];

  for (final p in paiements) {
    await db.insert('paiements_employe', p,
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}

// ---------------------------------------------------------------------------
// ACTIVITES — 5
// ---------------------------------------------------------------------------
Future<void> _seedActivities(Database db) async {
  final activities = [
    {
      'id': 'ACT-001',
      'className': 'Petite Section',
      'title': 'Lecture',
      'date': DateTime(2026, 5, 4).toIso8601String(),
      'start': '9:0',
      'end': '10:0',
      'notes': 'Histoire du petit lapin',
    },
    {
      'id': 'ACT-002',
      'className': 'Moyenne Section',
      'title': 'Art',
      'date': DateTime(2026, 5, 4).toIso8601String(),
      'start': '10:30',
      'end': '11:30',
      'notes': 'Peinture libre',
    },
    {
      'id': 'ACT-003',
      'className': 'Grande Section',
      'title': 'Sport',
      'date': DateTime(2026, 5, 5).toIso8601String(),
      'start': '9:0',
      'end': '10:0',
      'notes': null,
    },
    {
      'id': 'ACT-004',
      'className': 'Petite Section',
      'title': 'Musique',
      'date': DateTime(2026, 5, 5).toIso8601String(),
      'start': '11:0',
      'end': '12:0',
      'notes': 'Chansons traditionnelles',
    },
    {
      'id': 'ACT-005',
      'className': 'Moyenne Section',
      'title': 'Jeux',
      'date': DateTime(2026, 5, 6).toIso8601String(),
      'start': '14:0',
      'end': '15:0',
      'notes': null,
    },
  ];

  for (final a in activities) {
    await db.insert('activities', a, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}

// ---------------------------------------------------------------------------
// DEPENSES — 5
// ---------------------------------------------------------------------------
Future<void> _seedDepenses(Database db) async {
  final depenses = [
    {
      'id': 'DEP-001',
      'categorie': 'Alimentation',
      'description': 'Achat de fruits et légumes pour la semaine',
      'montant': 8500.0,
      'date': DateTime(2026, 5, 2).toIso8601String(),
      'attestation': '',
    },
    {
      'id': 'DEP-002',
      'categorie': 'Fournitures',
      'description': 'Cahiers, crayons et feutres',
      'montant': 12000.0,
      'date': DateTime(2026, 4, 28).toIso8601String(),
      'attestation': '',
    },
    {
      'id': 'DEP-003',
      'categorie': 'Entretien',
      'description': 'Produits de nettoyage et désinfectants',
      'montant': 6500.0,
      'date': DateTime(2026, 4, 25).toIso8601String(),
      'attestation': '',
    },
    {
      'id': 'DEP-004',
      'categorie': 'Électricité',
      'description': 'Facture Sonelgaz — Avril 2026',
      'montant': 18500.0,
      'date': DateTime(2026, 5, 3).toIso8601String(),
      'attestation': '',
    },
    {
      'id': 'DEP-005',
      'categorie': 'Maintenance',
      'description': 'Réparation climatiseur salle Moyenne Section',
      'montant': 14000.0,
      'date': DateTime(2026, 4, 20).toIso8601String(),
      'attestation': '',
    },
  ];

  for (final d in depenses) {
    await db.insert('depenses', d, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}

// ---------------------------------------------------------------------------
// PAIEMENTS ENFANT — 20 (Avril 2026 + Mai 2026)
// statut INTEGER: 0 = paye, 1 = impaye, 2 = partiel  (matches StatutPaiements enum)
// ---------------------------------------------------------------------------
Future<void> _seedPaiementsEnfant(Database db) async {
  const fraisMensuel = 12000;

  final periods = [
    {'date': DateTime(2026, 4, 5), 'mois': '2026-04'},
    {'date': DateTime(2026, 5, 5), 'mois': '2026-05'},
  ];

  // 10 enfants × 2 mois = 20 paiements
  final enfantsPayants = List.generate(10, (i) => 'ENF-${(i + 1).toString().padLeft(3, '0')}');

  final rows = <Map<String, dynamic>>[];
  for (int p = 0; p < periods.length; p++) {
    final period = periods[p];
    final date = period['date'] as DateTime;
    final mois = period['mois'] as String;

    for (int i = 0; i < enfantsPayants.length; i++) {
      final enfantId = enfantsPayants[i];
      // Mix: 70% paye, 20% partiel, 10% impaye
      final pick = (i + p * 3) % 10;
      late int statut;
      late int montantPaye;
      late int reste;
      if (pick < 7) {
        statut = 0; // paye
        montantPaye = fraisMensuel;
        reste = 0;
      } else if (pick < 9) {
        statut = 2; // partiel
        montantPaye = fraisMensuel ~/ 2;
        reste = fraisMensuel - montantPaye;
      } else {
        statut = 1; // impaye
        montantPaye = 0;
        reste = fraisMensuel;
      }

      rows.add({
        'id': '${enfantId}_${mois}_${date.millisecondsSinceEpoch}',
        'enfant_id': enfantId,
        'date': date.toIso8601String(),
        'mois': mois,
        'montantdu': fraisMensuel,
        'montantPaye': montantPaye,
        'reste': reste,
        'statut': statut,
      });
    }
  }

  assert(rows.length == 20, 'Expected 20 payments, got ${rows.length}');

  for (final r in rows) {
    await db.insert('paiements', r, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}

// ---------------------------------------------------------------------------
// EVALUATIONS — 20 (2 par enfant × 10 enfants)
// ---------------------------------------------------------------------------
Future<void> _seedEvaluations(Database db) async {
  const competences = [
    'Autonomie',
    'Socialisation',
    'Langage',
    'Motricité fine',
    'Créativité',
    'Concentration',
  ];

  const textesPositifs = <String?>[
    'Excellents progrès ce mois-ci.',
    'Très bonne participation en classe.',
    'A su collaborer avec ses camarades.',
    null,
    'Maîtrise acquise.',
  ];
  const textesAImprover = <String?>[
    'À encourager — manque encore de confiance.',
    'Doit travailler la concentration en groupe.',
    null,
    'Besoin de soutien individualisé.',
  ];

  final enfants = List.generate(10, (i) => 'ENF-${(i + 1).toString().padLeft(3, '0')}');
  final dates = [
    DateTime(2026, 4, 15),
    DateTime(2026, 5, 1),
  ];

  final rows = <Map<String, dynamic>>[];
  for (int i = 0; i < enfants.length; i++) {
    for (int j = 0; j < dates.length; j++) {
      final positive = (i + j) % 3 != 0; // ~66% positifs
      rows.add({
        'enfantId': enfants[i],
        'date': dates[j].millisecondsSinceEpoch,
        'competence': competences[(i * 2 + j) % competences.length],
        'valeur': positive ? 1 : 0,
        'texte': positive
            ? textesPositifs[(i + j) % textesPositifs.length]
            : textesAImprover[(i + j) % textesAImprover.length],
      });
    }
  }

  assert(rows.length == 20);

  for (final r in rows) {
    await db.insert('evaluations', r,
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
