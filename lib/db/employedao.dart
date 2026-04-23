import 'package:sqflite/sqflite.dart';
import '../models/employe.dart';
import 'database_helper.dart';

class EmployeDao {
  final dbHelper = DatabaseHelper.instance;

  // ---------------- INSERT ----------------
  Future<void> insertEmploye(Employe employe) async {
    final db = await dbHelper.database;

    // Insérer employé
    await db.insert(
      'employes',
      {
        'id': employe.id,
        'nom': employe.nom,
        'prenom': employe.prenom,
        'dateNaissance': employe.dateNaissance.toIso8601String(),
        'dateEmbauche': employe.dateEmbauche.toIso8601String(),
        'poste': employe.poste,
        'salaire': employe.salaire,
        'telephone': employe.telephone,
        'adresse': employe.adresse,
        'estActif': employe.estActif ? 1 : 0,
        'photoUrl': employe.photoUrl,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insérer paiements si disponibles
    for (var p in employe.paiements) {
      await db.insert(
        'paiements_employe',
        {
          'employeId': employe.id,
          'datePaiement': p.datePaiement.toIso8601String(),
          'mois': p.mois,
          'salaireBase': p.salaireBase,
          'prime': p.prime,
          'montantPaye': p.montantPaye,
          'statut': p.statut.toString().split('.').last,
        },
      );
    }
  }

  // ---------------- UPDATE EMPLOYE ----------------
  Future<void> updateEmploye(Employe employe) async {
    final db = await dbHelper.database;

    await db.update(
      'employes',
      {
        'nom': employe.nom,
        'prenom': employe.prenom,
        'dateNaissance': employe.dateNaissance.toIso8601String(),
        'dateEmbauche': employe.dateEmbauche.toIso8601String(),
        'poste': employe.poste,
        'salaire': employe.salaire,
        'telephone': employe.telephone,
        'adresse': employe.adresse,
        'estActif': employe.estActif ? 1 : 0,
        'photoUrl': employe.photoUrl,
      },
      where: 'id = ?',
      whereArgs: [employe.id],
    );

    // First, delete all existing payments for this employee
    await db.delete(
      'paiements_employe',
      where: 'employeId = ?',
      whereArgs: [employe.id],
    );

    // Then, insert all current payments
    for (var p in employe.paiements) {
      await db.insert(
        'paiements_employe',
        {
          'employeId': employe.id,
          'datePaiement': p.datePaiement.toIso8601String(),
          'mois': p.mois,
          'salaireBase': p.salaireBase,
          'prime': p.prime,
          'montantPaye': p.montantPaye,
          'statut': p.statut.toString().split('.').last,
        },
      );
    }
  }

  // ---------------- UPDATE SINGLE PAYMENT ----------------
  Future<void> updatePaiement(String employeId, PaiementEmploye paiement) async {
    final db = await dbHelper.database;

    await db.update(
      'paiements_employe',
      {
        'montantPaye': paiement.montantPaye,
        'statut': paiement.statut.toString().split('.').last,
      },
      where: 'employeId = ? AND mois = ? AND datePaiement = ?',
      whereArgs: [
        employeId,
        paiement.mois,
        paiement.datePaiement.toIso8601String()
      ],
    );
  }

  // ---------------- ADD NEW PAYMENT ----------------
  Future<void> addPaiement(String employeId, PaiementEmploye paiement) async {
    final db = await dbHelper.database;

    await db.insert(
      'paiements_employe',
      {
        'employeId': employeId,
        'datePaiement': paiement.datePaiement.toIso8601String(),
        'mois': paiement.mois,
        'salaireBase': paiement.salaireBase,
        'prime': paiement.prime,
        'montantPaye': paiement.montantPaye,
        'statut': paiement.statut.toString().split('.').last,
      },
    );
  }

  // ---------------- DELETE PAYMENT ----------------
  Future<void> deletePaiement(String employeId, String mois, DateTime datePaiement) async {
    final db = await dbHelper.database;

    await db.delete(
      'paiements_employe',
      where: 'employeId = ? AND mois = ? AND datePaiement = ?',
      whereArgs: [employeId, mois, datePaiement.toIso8601String()],
    );
  }

  // ---------------- GET PAYMENTS BY EMPLOYEE ID ----------------
  Future<List<PaiementEmploye>> getPaiementsByEmployeId(String employeId) async {
    final db = await dbHelper.database;

    final paiementsMaps = await db.query(
      'paiements_employe',
      where: 'employeId = ?',
      whereArgs: [employeId],
      orderBy: 'datePaiement DESC',
    );

    return paiementsMaps.map((e) {
      return PaiementEmploye(
        datePaiement: DateTime.parse(e['datePaiement'] as String),
        mois: e['mois'] as String,
        salaireBase: (e['salaireBase'] as num).toDouble(),
        prime: (e['prime'] as num?)?.toDouble() ?? 0.0,
        montantPaye: (e['montantPaye'] as num).toDouble(),
        statut: (e['statut'] == 'paye')
            ? StatutPaiement.paye
            : StatutPaiement.impaye,
      );
    }).toList();
  }

  // ---------------- DELETE ----------------
  Future<void> deleteEmploye(String id) async {
    final db = await dbHelper.database;
    
    // First delete all payments for this employee
    await db.delete(
      'paiements_employe',
      where: 'employeId = ?',
      whereArgs: [id],
    );
    
    // Then delete the employee
    await db.delete(
      'employes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- GET BY ID ----------------
  Future<Employe?> getEmployeById(String id) async {
    final db = await dbHelper.database;

    final maps = await db.query(
      'employes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final employeMap = maps.first;

      // Récupérer paiements
      final paiements = await getPaiementsByEmployeId(id);

      return Employe(
        id: employeMap['id'] as String,
        nom: employeMap['nom'] as String,
        prenom: employeMap['prenom'] as String,
        dateNaissance: DateTime.parse(employeMap['dateNaissance'] as String),
        dateEmbauche: DateTime.parse(employeMap['dateEmbauche'] as String),
        poste: employeMap['poste'] as String,
        salaire: (employeMap['salaire'] as num).toDouble(),
        telephone: employeMap['telephone'] as String,
        adresse: employeMap['adresse'] as String,
        estActif: (employeMap['estActif'] as int) == 1,
        photoUrl: employeMap['photoUrl'] as String,
        paiements: paiements,
      );
    }
    return null;
  }

  // ---------------- GET ALL ----------------
  Future<List<Employe>> getAllEmployes() async {
    final db = await dbHelper.database;
    final employeMaps = await db.query('employes');

    List<Employe> employes = [];

    for (var eMap in employeMaps) {
      final id = eMap['id'] as String;

      // Récup paiements
      final paiements = await getPaiementsByEmployeId(id);

      employes.add(
        Employe(
          id: eMap['id'] as String,
          nom: eMap['nom'] as String,
          prenom: eMap['prenom'] as String,
          dateNaissance: DateTime.parse(eMap['dateNaissance'] as String),
          dateEmbauche: DateTime.parse(eMap['dateEmbauche'] as String),
          poste: eMap['poste'] as String,
          salaire: (eMap['salaire'] as num).toDouble(),
          telephone: eMap['telephone'] as String,
          adresse: eMap['adresse'] as String,
          estActif: (eMap['estActif'] as int) == 1,
          photoUrl: eMap['photoUrl'] as String,
          paiements: paiements,
        ),
      );
    }

    return employes;
  }
}