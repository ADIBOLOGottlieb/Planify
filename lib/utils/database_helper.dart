import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'planify.db');
    return openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE utilisateurs (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        mot_de_passe TEXT NOT NULL,
        devise TEXT DEFAULT 'FCFA',
        photo_profil TEXT,
        statut TEXT DEFAULT 'actif',
        date_inscription TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        icone TEXT NOT NULL,
        couleur TEXT NOT NULL,
        type TEXT NOT NULL,
        est_systeme INTEGER DEFAULT 0,
        est_archivee INTEGER DEFAULT 0,
        utilisateur_id TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        montant REAL NOT NULL,
        type TEXT NOT NULL,
        date_transaction TEXT NOT NULL,
        description TEXT,
        mode_paiement TEXT DEFAULT 'especes',
        justificatif TEXT,
        categorie_id TEXT NOT NULL,
        compte_id TEXT,
        utilisateur_id TEXT NOT NULL,
        date_creation TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (categorie_id) REFERENCES categories(id),
        FOREIGN KEY (compte_id) REFERENCES comptes(id),
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        montant_alloue REAL NOT NULL,
        montant_depense REAL DEFAULT 0,
        montant_reporte REAL DEFAULT 0,
        periode TEXT DEFAULT 'mensuel',
        date_debut TEXT NOT NULL,
        date_fin TEXT NOT NULL,
        categorie_id TEXT,
        utilisateur_id TEXT NOT NULL,
        statut_alerte INTEGER DEFAULT 0,
        alerte_80_envoyee INTEGER DEFAULT 0,
        alerte_100_envoyee INTEGER DEFAULT 0,
        updated_at TEXT,
        FOREIGN KEY (categorie_id) REFERENCES categories(id),
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE alertes (
        id TEXT PRIMARY KEY,
        type_alerte TEXT NOT NULL,
        message TEXT NOT NULL,
        date_envoi TEXT NOT NULL,
        est_lue INTEGER DEFAULT 0,
        utilisateur_id TEXT NOT NULL,
        budget_id TEXT,
        updated_at TEXT,
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id),
        FOREIGN KEY (budget_id) REFERENCES budgets(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions_recurrentes (
        id TEXT PRIMARY KEY,
        montant REAL NOT NULL,
        type TEXT NOT NULL,
        date_debut TEXT NOT NULL,
        prochaine_date TEXT NOT NULL,
        periodicite TEXT NOT NULL,
        description TEXT,
        mode_paiement TEXT DEFAULT 'especes',
        categorie_id TEXT NOT NULL,
        compte_id TEXT,
        utilisateur_id TEXT NOT NULL,
        actif INTEGER DEFAULT 1,
        updated_at TEXT,
        FOREIGN KEY (categorie_id) REFERENCES categories(id),
        FOREIGN KEY (compte_id) REFERENCES comptes(id),
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE objectifs (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        montant_cible REAL NOT NULL,
        montant_actuel REAL DEFAULT 0,
        date_echeance TEXT NOT NULL,
        statut TEXT DEFAULT 'en_cours',
        utilisateur_id TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE comptes (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        solde REAL DEFAULT 0,
        icone TEXT NOT NULL,
        couleur TEXT NOT NULL,
        operateur TEXT,
        utilisateur_id TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE utilisateurs ADD COLUMN statut TEXT DEFAULT 'actif'");
      await db.execute("ALTER TABLE categories ADD COLUMN est_archivee INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE transactions ADD COLUMN justificatif TEXT");
      await db.execute("ALTER TABLE budgets ADD COLUMN montant_reporte REAL DEFAULT 0");
      await db.execute("ALTER TABLE budgets ADD COLUMN alerte_80_envoyee INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE budgets ADD COLUMN alerte_100_envoyee INTEGER DEFAULT 0");

      await db.execute('''
        CREATE TABLE IF NOT EXISTS alertes (
          id TEXT PRIMARY KEY,
          type_alerte TEXT NOT NULL,
          message TEXT NOT NULL,
          date_envoi TEXT NOT NULL,
          est_lue INTEGER DEFAULT 0,
          utilisateur_id TEXT NOT NULL,
          budget_id TEXT,
          FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id),
          FOREIGN KEY (budget_id) REFERENCES budgets(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS transactions_recurrentes (
          id TEXT PRIMARY KEY,
          montant REAL NOT NULL,
          type TEXT NOT NULL,
          date_debut TEXT NOT NULL,
          prochaine_date TEXT NOT NULL,
          periodicite TEXT NOT NULL,
          description TEXT,
          mode_paiement TEXT DEFAULT 'especes',
          categorie_id TEXT NOT NULL,
          utilisateur_id TEXT NOT NULL,
          actif INTEGER DEFAULT 1,
          FOREIGN KEY (categorie_id) REFERENCES categories(id),
          FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute("ALTER TABLE utilisateurs ADD COLUMN updated_at TEXT");
      await db.execute("ALTER TABLE categories ADD COLUMN updated_at TEXT");
      await db.execute("ALTER TABLE transactions ADD COLUMN updated_at TEXT");
      await db.execute("ALTER TABLE budgets ADD COLUMN updated_at TEXT");
      await db.execute("ALTER TABLE alertes ADD COLUMN updated_at TEXT");
      await db.execute("ALTER TABLE transactions_recurrentes ADD COLUMN updated_at TEXT");
      await db.execute("ALTER TABLE objectifs ADD COLUMN updated_at TEXT");
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS comptes (
          id TEXT PRIMARY KEY,
          nom TEXT NOT NULL,
          solde REAL DEFAULT 0,
          icone TEXT NOT NULL,
          couleur TEXT NOT NULL,
          utilisateur_id TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
        )
      ''');
      await db.execute("ALTER TABLE transactions ADD COLUMN compte_id TEXT");
      await db.execute("ALTER TABLE transactions_recurrentes ADD COLUMN compte_id TEXT");
    }

    if (oldVersion < 5) {
      await db.execute("ALTER TABLE comptes ADD COLUMN operateur TEXT");
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final depenseCategories = [
      {'id': 'cat_logement', 'nom': 'Logement', 'icone': 'home', 'couleur': '#E53935', 'type': 'depense', 'est_systeme': 1},
      {'id': 'cat_alimentation', 'nom': 'Alimentation', 'icone': 'restaurant', 'couleur': '#FB8C00', 'type': 'depense', 'est_systeme': 1},
      {'id': 'cat_transport', 'nom': 'Transport', 'icone': 'directions_car', 'couleur': '#1E88E5', 'type': 'depense', 'est_systeme': 1},
      {'id': 'cat_sante', 'nom': 'Santé', 'icone': 'local_hospital', 'couleur': '#00897B', 'type': 'depense', 'est_systeme': 1},
      {'id': 'cat_education', 'nom': 'Éducation', 'icone': 'school', 'couleur': '#8E24AA', 'type': 'depense', 'est_systeme': 1},
      {'id': 'cat_loisirs', 'nom': 'Loisirs', 'icone': 'sports_esports', 'couleur': '#F4511E', 'type': 'depense', 'est_systeme': 1},
      {'id': 'cat_habillement', 'nom': 'Habillement', 'icone': 'checkroom', 'couleur': '#D81B60', 'type': 'depense', 'est_systeme': 1},
      {'id': 'cat_telecom', 'nom': 'Télécom', 'icone': 'phone_android', 'couleur': '#039BE5', 'type': 'depense', 'est_systeme': 1},
      {'id': 'cat_autre_dep', 'nom': 'Autres', 'icone': 'more_horiz', 'couleur': '#546E7A', 'type': 'depense', 'est_systeme': 1},
    ];

    final revenuCategories = [
      {'id': 'cat_salaire', 'nom': 'Salaire', 'icone': 'work', 'couleur': '#43A047', 'type': 'revenu', 'est_systeme': 1},
      {'id': 'cat_commerce', 'nom': 'Commerce', 'icone': 'storefront', 'couleur': '#00ACC1', 'type': 'revenu', 'est_systeme': 1},
      {'id': 'cat_freelance', 'nom': 'Freelance', 'icone': 'laptop', 'couleur': '#7CB342', 'type': 'revenu', 'est_systeme': 1},
      {'id': 'cat_investissement', 'nom': 'Investissement', 'icone': 'trending_up', 'couleur': '#F9A825', 'type': 'revenu', 'est_systeme': 1},
      {'id': 'cat_autre_rev', 'nom': 'Autres', 'icone': 'attach_money', 'couleur': '#6D4C41', 'type': 'revenu', 'est_systeme': 1},
    ];

    for (final cat in [...depenseCategories, ...revenuCategories]) {
      await db.insert('categories', cat);
    }
  }

  // Generic CRUD
  Future<String> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    return data['id'] as String;
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<int> update(String table, Map<String, dynamic> data, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }
}
