import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('creche_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // ------------------ Enfants ------------------
    await db.execute('''
      CREATE TABLE enfants (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        classe TEXT NOT NULL,
        telephone TEXT NOT NULL,
        estActif INTEGER NOT NULL,
        dateNaissance TEXT,
        sexe TEXT,
        adresse TEXT,
        photoPath TEXT,
        dateInscription TEXT,
        nomPrenomPere TEXT,
        telPere TEXT,
        professionPere TEXT,
        adressePere TEXT,
        nomPrenomMere TEXT,
        telMere TEXT,
        professionMere TEXT,
        statutFamilial TEXT,
        allergies TEXT,
        commentairesMedicaux TEXT,
        dossierMedicalPath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE accompagnateurs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        enfantId TEXT,
        nomPrenom TEXT,
        telephone TEXT,
        cin TEXT,
        FOREIGN KEY (enfantId) REFERENCES enfants(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE presences (
        enfantId TEXT NOT NULL,
        date TEXT NOT NULL,
        statut TEXT NOT NULL,
        PRIMARY KEY (enfantId, date)
      )
    ''');

    // ------------------ Employes ------------------
    await db.execute('''
      CREATE TABLE employes (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        dateNaissance TEXT NOT NULL,
        dateEmbauche TEXT NOT NULL,
        poste TEXT NOT NULL,
        salaire REAL NOT NULL,
        telephone TEXT,
        adresse TEXT,
        estActif INTEGER NOT NULL,
        photoUrl TEXT
      )
    ''');

    // ------------------ Paiements des employes ------------------
    await db.execute('''
      CREATE TABLE paiements_employe (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeId TEXT NOT NULL,
        datePaiement TEXT NOT NULL,
        mois TEXT NOT NULL,
        salaireBase REAL NOT NULL,
        prime REAL,
        montantPaye REAL NOT NULL,
        statut TEXT NOT NULL,
        FOREIGN KEY (employeId) REFERENCES employes(id) ON DELETE CASCADE
      )
    ''');

    // ------------------ Activities ------------------
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        className TEXT NOT NULL,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        start TEXT NOT NULL,
        end TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // ------------------ Dépenses ------------------
    await db.execute('''
      CREATE TABLE depenses (
        id TEXT PRIMARY KEY,
        categorie TEXT NOT NULL,
        description TEXT NOT NULL,
        montant REAL NOT NULL,
        date TEXT NOT NULL,
        attestation TEXT
      )
    ''');

    // ------------------ Paiements Enfant  ------------------
    await db.execute('''
      CREATE TABLE paiements (
        id TEXT PRIMARY KEY,
        enfant_id TEXT NOT NULL,
        date TEXT NOT NULL,
        mois TEXT NOT NULL,
        montantdu INTEGER NOT NULL,
        montantPaye INTEGER NOT NULL,
        reste INTEGER NOT NULL,
        statut INTEGER NOT NULL,
        FOREIGN KEY (enfant_id) REFERENCES enfants (id) ON DELETE CASCADE
      )
    ''');

    // ------------------ Users ------------------
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL CHECK (role IN ('admin', 'standard'))
      )
    ''');

    // ------------------ Evaluations ------------------ ✅
    await db.execute('''
  CREATE TABLE evaluations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    enfantId TEXT NOT NULL,
    date INTEGER NOT NULL, -- Store as timestamp (milliseconds since epoch)
    competence TEXT NOT NULL,
    valeur INTEGER NOT NULL, -- 1 = ✅, 0 = ❌
    texte TEXT,
    FOREIGN KEY (enfantId) REFERENCES enfants(id) ON DELETE CASCADE
  )
''');
  }

  // Close DB
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
