import '../models/enfant.dart';
import 'database_helper.dart';

class EnfantDao {
  final dbHelper = DatabaseHelper.instance;

// Convert Enfant object to Map
Map<String, dynamic> _enfantToMap(Enfant e) {
  return {
    'id': e.id,
    'nom': e.nom,
    'prenom': e.prenom,
    'classe': e.classe,
    'telephone': e.telephone,
    'estActif': e.estActif ? 1 : 0,
    'dateNaissance': e.dateNaissance,
    'sexe': e.sexe,
    'adresse': e.adresse,
    'photoPath': e.photoPath,
    'nomPrenomPere': e.nomPrenomPere,
    'telPere': e.telPere,
    'professionPere': e.professionPere,
    'adressePere': e.adressePere,
    'nomPrenomMere': e.nomPrenomMere,
    'telMere': e.telMere,
    'professionMere': e.professionMere,
    'statutFamilial': e.statutFamilial,
    'allergies': e.allergies,
    'commentairesMedicaux': e.commentairesMedicaux,
    'dossierMedicalPath': e.dossierMedicalPath,

    // 🔹 On stocke en String (format ISO8601) si non null
    'dateInscription': e.dateInscription?.toIso8601String(),
  };
}

// Convert Map to Enfant object
Enfant _mapToEnfant(Map<String, dynamic> map) {
  return Enfant(
    id: map['id'],
    nom: map['nom'],
    prenom: map['prenom'],
    classe: map['classe'],
    telephone: map['telephone'],
    estActif: map['estActif'] == 1,
    dateNaissance: map['dateNaissance'],
    sexe: map['sexe'],
    adresse: map['adresse'],
    photoPath: map['photoPath'],
    nomPrenomPere: map['nomPrenomPere'],
    telPere: map['telPere'],
    professionPere: map['professionPere'],
    adressePere: map['adressePere'],
    nomPrenomMere: map['nomPrenomMere'],
    telMere: map['telMere'],
    professionMere: map['professionMere'],
    statutFamilial: map['statutFamilial'],
    allergies: map['allergies'],
    commentairesMedicaux: map['commentairesMedicaux'],
    dossierMedicalPath: map['dossierMedicalPath'],

    // 🔹 On reconvertit en DateTime si non null
    dateInscription: map['dateInscription'] != null
        ? DateTime.tryParse(map['dateInscription'])
        : null,
  );
}


  // Convert Paiement object to Map
  Map<String, dynamic> _paiementToMap(Paiement p, String enfantId) {
    return {
      'id': '${enfantId}_${p.mois}_${p.date.millisecondsSinceEpoch}',
      'enfant_id': enfantId,
      'date': p.date.toIso8601String(),
      'mois': p.mois,
      'montantdu': p.montantdu,
      'montantPaye': p.montantPaye,
      'reste': p.reste,
      'statut': p.statut.index,
    };
  }

  // Convert Map to Paiement object
  Paiement _mapToPaiement(Map<String, dynamic> map) {
    return Paiement(
      date: DateTime.parse(map['date']),
      mois: map['mois'],
      montantdu: map['montantdu'],
      montantPaye: map['montantPaye'],
      reste: map['reste'],
      statut: StatutPaiements.values[map['statut']],
    );
  }

  // ---------------- ENFANT CRUD Operations ----------------

  // Insert a new enfant
  Future<int> insertEnfant(Enfant enfant) async {
    final db = await dbHelper.database;
    return await db.insert('enfants', _enfantToMap(enfant));
  }

  // Update existing enfant
  Future<int> updateEnfant(Enfant enfant) async {
    final db = await dbHelper.database;
    return await db.update(
      'enfants',
      _enfantToMap(enfant),
      where: 'id = ?',
      whereArgs: [enfant.id],
    );
  }

  // Delete an enfant
  Future<int> deleteEnfant(String id) async {
  final db = await dbHelper.database;

  // First delete all payments for this child
  await db.delete('paiements', where: 'enfant_id = ?', whereArgs: [id]);
  
  // Delete all presence records for this child
  await db.delete('presences', where: 'enfantId = ?', whereArgs: [id]);

  // Then delete the child
  return await db.delete('enfants', where: 'id = ?', whereArgs: [id]);
}
  // Get all enfants
  Future<List<Enfant>> getAllEnfants() async {
    final db = await dbHelper.database;
    final result = await db.query('enfants', orderBy: 'nom ASC');
    return result.map((map) => _mapToEnfant(map)).toList();
  }

  // Get enfant by ID
  Future<Enfant?> getEnfantById(String id) async {
    final db = await dbHelper.database;
    final result = await db.query('enfants', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return _mapToEnfant(result.first);
    }
    return null;
  }

  // ---------------- PAIEMENT CRUD Operations ----------------

  // Add a new payment for a child
  Future<int> insertPaiement(String enfantId, Paiement paiement) async {
    final db = await dbHelper.database;
    return await db.insert('paiements', _paiementToMap(paiement, enfantId));
  }

  // Update an existing payment
  Future<int> updatePaiement(String enfantId, Paiement paiement) async {
    final db = await dbHelper.database;
    return await db.update(
      'paiements',
      _paiementToMap(paiement, enfantId),
      where: 'id = ? AND enfant_id = ?',
      whereArgs: [
        '${enfantId}_${paiement.mois}_${paiement.date.millisecondsSinceEpoch}',
        enfantId,
      ],
    );
  }

  // Delete a payment
  Future<int> deletePaiement(String paiementId, String enfantId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'paiements',
      where: 'id = ? AND enfant_id = ?',
      whereArgs: [paiementId, enfantId],
    );
  }

  // Get all payments for a specific child
  Future<List<Paiement>> getPaiementsByEnfantId(String enfantId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'paiements',
      where: 'enfant_id = ?',
      whereArgs: [enfantId],
      orderBy: 'date DESC',
    );
    return result.map((map) => _mapToPaiement(map)).toList();
  }

  // Get a specific payment by ID
  Future<Paiement?> getPaiementById(String paiementId, String enfantId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'paiements',
      where: 'id = ? AND enfant_id = ?',
      whereArgs: [paiementId, enfantId],
    );
    if (result.isNotEmpty) {
      return _mapToPaiement(result.first);
    }
    return null;
  }

  // Get payments by month and year
  Future<List<Paiement>> getPaiementsByMonth(String mois, int annee) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'paiements',
      where: 'mois = ? AND strftime("%Y", date) = ?',
      whereArgs: [mois, annee.toString()],
      orderBy: 'date DESC',
    );
    return result.map((map) => _mapToPaiement(map)).toList();
  }

  // Get payments by status
  Future<List<Paiement>> getPaiementsByStatus(StatutPaiements statut) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'paiements',
      where: 'statut = ?',
      whereArgs: [statut.index],
      orderBy: 'date DESC',
    );
    return result.map((map) => _mapToPaiement(map)).toList();
  }
  
  // Edit specific fields of an enfant
Future<int> editEnfant(String id, Map<String, dynamic> updates) async {
  final db = await dbHelper.database;
  
  // Handle boolean conversion if estActif is being updated
  if (updates.containsKey('estActif') && updates['estActif'] is bool) {
    updates['estActif'] = updates['estActif'] ? 1 : 0;
  }
  
  return await db.update(
    'enfants',
    updates,
    where: 'id = ?',
    whereArgs: [id],
  );
}

  // Get enfant with payments (eager loading)
  Future<Enfant?> getEnfantWithPaiements(String enfantId) async {
    final db = await dbHelper.database;

    // Get the enfant
    final enfantResult = await db.query(
      'enfants',
      where: 'id = ?',
      whereArgs: [enfantId],
    );

    if (enfantResult.isEmpty) return null;

    final enfant = _mapToEnfant(enfantResult.first);

    // Get payments for this enfant
    final paiementsResult = await db.query(
      'paiements',
      where: 'enfant_id = ?',
      whereArgs: [enfantId],
      orderBy: 'date DESC',
    );

    final paiements = paiementsResult
        .map((map) => _mapToPaiement(map))
        .toList();

    // Return a new Enfant object with payments
    return Enfant(
      id: enfant.id,
      nom: enfant.nom,
      prenom: enfant.prenom,
      classe: enfant.classe,
      telephone: enfant.telephone,
      estActif: enfant.estActif,
      dateNaissance: enfant.dateNaissance,
      sexe: enfant.sexe,
      adresse: enfant.adresse,
      photoPath: enfant.photoPath,
      nomPrenomPere: enfant.nomPrenomPere,
      telPere: enfant.telPere,
      professionPere: enfant.professionPere,
      adressePere: enfant.adressePere,
      nomPrenomMere: enfant.nomPrenomMere,
      telMere: enfant.telMere,
      professionMere: enfant.professionMere,
      statutFamilial: enfant.statutFamilial,
      allergies: enfant.allergies,
      commentairesMedicaux: enfant.commentairesMedicaux,
      dossierMedicalPath: enfant.dossierMedicalPath,
      paiements: paiements,
      historiquePresence: enfant.historiquePresence,
      dateInscription: enfant.dateInscription,
    );
    
  }
}
