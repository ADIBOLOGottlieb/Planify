import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:planify/viewmodels/auth_viewmodel.dart';
import 'package:planify/services/database_helper.dart';
import 'package:planify/utils/password_hasher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AuthViewModel auth;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.databaseName = 'test_auth.db';
    await databaseFactory.deleteDatabase(join(await getDatabasesPath(), DatabaseHelper.databaseName));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final db = await DatabaseHelper().database;
    await db.delete('utilisateurs');
    auth = AuthViewModel();
  });

  Future<void> inscrireAlice() async {
    final err = await auth.inscrire(
      nom: 'Doe',
      prenom: 'Alice',
      email: 'Alice@Example.com',
      motDePasse: 'MotDePasse1',
      questionSecrete: AuthViewModel.questionsSecretes.first,
      reponseSecrete: 'Médor',
    );
    expect(err, isNull);
    await auth.deconnecter();
  }

  test('le mot de passe est haché en base, jamais stocké en clair', () async {
    await inscrireAlice();
    final rows = await DatabaseHelper().query('utilisateurs');
    final stocke = rows.single['mot_de_passe'] as String;
    expect(stocke, isNot('MotDePasse1'));
    expect(PasswordHasher.isHashed(stocke), isTrue);
    expect(PasswordHasher.isHashed(rows.single['reponse_secrete'] as String), isTrue);
  });

  test('connexion : bon mot de passe accepté, email insensible à la casse', () async {
    await inscrireAlice();
    expect(await auth.connecter(email: 'alice@example.COM', motDePasse: 'MotDePasse1'), isNull);
    expect(auth.isLoggedIn, isTrue);
  });

  test('connexion : mauvais mot de passe refusé', () async {
    await inscrireAlice();
    final err = await auth.connecter(email: 'alice@example.com', motDePasse: 'Mauvais123');
    expect(err, contains('incorrect'));
    expect(auth.isLoggedIn, isFalse);
  });

  test("email déjà utilisé refusé à l'inscription", () async {
    await inscrireAlice();
    final err = await auth.inscrire(
        nom: 'X',
        prenom: 'Y',
        email: 'alice@example.com',
        motDePasse: 'MotDePasse1',
        questionSecrete: AuthViewModel.questionsSecretes.first,
        reponseSecrete: 'abc');
    expect(err, 'Cet email est déjà utilisé.');
  });

  test('blocage après 5 échecs, même avec le bon mot de passe ensuite', () async {
    await inscrireAlice();
    String? err;
    for (var i = 0; i < AuthViewModel.maxTentatives; i++) {
      err = await auth.connecter(email: 'alice@example.com', motDePasse: 'Mauvais123');
    }
    expect(err, contains('bloqué'));
    err = await auth.connecter(email: 'alice@example.com', motDePasse: 'MotDePasse1');
    expect(err, contains('bloqué'));
    expect(auth.isLoggedIn, isFalse);
  });

  test("un succès remet le compteur d'échecs à zéro", () async {
    await inscrireAlice();
    for (var i = 0; i < AuthViewModel.maxTentatives - 1; i++) {
      await auth.connecter(email: 'alice@example.com', motDePasse: 'Mauvais123');
    }
    expect(await auth.connecter(email: 'alice@example.com', motDePasse: 'MotDePasse1'), isNull);
    await auth.deconnecter();
    final err = await auth.connecter(email: 'alice@example.com', motDePasse: 'Mauvais123');
    expect(err, contains('4 tentatives restantes'));
  });

  test('réinitialisation : mauvaise réponse refusée', () async {
    await inscrireAlice();
    final err = await auth.reinitialiserMotDePasse(
        email: 'alice@example.com', reponse: 'Rex', nouveau: 'Nouveau123');
    expect(err, contains('Réponse incorrecte'));
    expect(await auth.connecter(email: 'alice@example.com', motDePasse: 'MotDePasse1'), isNull);
  });

  test('réinitialisation : bonne réponse (casse et accents ignorés)', () async {
    await inscrireAlice();
    expect(await auth.questionSecretePour('alice@example.com'),
        AuthViewModel.questionsSecretes.first);
    final err = await auth.reinitialiserMotDePasse(
        email: 'alice@example.com', reponse: '  MEDOR ', nouveau: 'Nouveau123');
    expect(err, isNull);
    expect(await auth.connecter(email: 'alice@example.com', motDePasse: 'MotDePasse1'), isNotNull);
    expect(await auth.connecter(email: 'alice@example.com', motDePasse: 'Nouveau123'), isNull);
  });

  test("changement de mot de passe exige l'ancien", () async {
    await inscrireAlice();
    await auth.connecter(email: 'alice@example.com', motDePasse: 'MotDePasse1');
    expect(await auth.changerMotDePasse(ancien: 'Faux1234', nouveau: 'Nouveau123'),
        'Ancien mot de passe incorrect.');
    expect(await auth.changerMotDePasse(ancien: 'MotDePasse1', nouveau: 'Nouveau123'), isNull);
    await auth.deconnecter();
    expect(await auth.connecter(email: 'alice@example.com', motDePasse: 'Nouveau123'), isNull);
  });

  test("« Rester connecté » décoché : la session n'est pas restaurée", () async {
    await inscrireAlice();
    await auth.connecter(
        email: 'alice@example.com', motDePasse: 'MotDePasse1', resterConnecte: false);
    final auth2 = AuthViewModel();
    await auth2.init();
    expect(auth2.isLoggedIn, isFalse);
  });

  test('« Rester connecté » coché : la session est restaurée', () async {
    await inscrireAlice();
    await auth.connecter(email: 'alice@example.com', motDePasse: 'MotDePasse1');
    final auth2 = AuthViewModel();
    await auth2.init();
    expect(auth2.currentUser?.prenom, 'Alice');
  });
}
