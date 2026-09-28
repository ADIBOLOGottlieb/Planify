import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:planify/services/database_helper.dart';
import 'package:planify/utils/password_hasher.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('la migration v5 → v7 hache les mots de passe et ajoute les nouvelles colonnes', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.databaseName = 'test_migration.db';
    final path = join(await getDatabasesPath(), DatabaseHelper.databaseName);
    await databaseFactory.deleteDatabase(path);

    // Base telle que produite par la version 5 de l'application.
    final v5 = await openDatabase(path, version: 5, onCreate: (db, _) async {
      await db.execute('CREATE TABLE utilisateurs ('
          'id TEXT PRIMARY KEY, nom TEXT NOT NULL, prenom TEXT NOT NULL, '
          'email TEXT UNIQUE NOT NULL, mot_de_passe TEXT NOT NULL, '
          "devise TEXT DEFAULT 'FCFA', photo_profil TEXT, "
          "statut TEXT DEFAULT 'actif', date_inscription TEXT NOT NULL, "
          'updated_at TEXT)');
      await db.execute('CREATE TABLE budgets (id TEXT PRIMARY KEY, montant_alloue REAL NOT NULL)');
    });
    await v5.insert('utilisateurs', {
      'id': 'u1',
      'nom': 'Doe',
      'prenom': 'Bob',
      'email': 'bob@example.com',
      'mot_de_passe': 'Ancien123',
      'date_inscription': DateTime.now().toIso8601String(),
    });
    await v5.close();

    final rows = await DatabaseHelper().query('utilisateurs');
    final stocke = rows.single['mot_de_passe'] as String;
    expect(PasswordHasher.isHashed(stocke), isTrue);
    expect(await PasswordHasher.verify('Ancien123', stocke), isTrue);
    expect(rows.single['tentatives_echouees'], 0);
    expect(rows.single['email_verifie'], 0);

    final db = await DatabaseHelper().database;
    await db.insert('budgets', {'id': 'b1', 'montant_alloue': 1000});
    final budget = await db.query('budgets');
    expect(budget.single['seuil_alerte'], 80);
    expect(await db.query('suppressions_en_attente'), isEmpty);
  });
}
