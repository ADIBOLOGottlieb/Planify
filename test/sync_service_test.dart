import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:planify/models/models.dart';
import 'package:planify/services/api_service.dart';
import 'package:planify/services/database_helper.dart';
import 'package:planify/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Serveur simulé : une liste d'objectifs en mémoire.
class _FauxServeur extends ApiService {
  bool enLigne = true;
  final Map<String, Objectif> donnees = {};
  final List<String> suppressions = [];

  void _verifier() {
    if (!enLigne) throw const ApiException('hors ligne', horsLigne: true);
  }

  @override
  Future<bool> estConnecte() async => true;

  @override
  Future<List<Objectif>> getObjectifs() async {
    _verifier();
    return donnees.values.toList();
  }

  @override
  Future<Objectif> createObjectif(Objectif o) async {
    _verifier();
    return donnees[o.id] = o;
  }

  @override
  Future<void> updateObjectif(Objectif o) async {
    _verifier();
    donnees[o.id] = o;
  }

  @override
  Future<void> deleteObjectif(String id) async {
    _verifier();
    suppressions.add(id);
    if (donnees.remove(id) == null) {
      throw const ApiException('introuvable', statusCode: 404);
    }
  }
}

Objectif _obj(String id, DateTime maj, {String nom = 'Moto'}) => Objectif(
      id: id,
      nom: nom,
      montantCible: 100000,
      dateEcheance: DateTime(2027, 1, 1),
      utilisateurId: 'u1',
      updatedAt: maj,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FauxServeur serveur;
  late SyncService sync;
  final db = DatabaseHelper();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.databaseName = 'test_sync.db';
    await databaseFactory.deleteDatabase(join(await getDatabasesPath(), DatabaseHelper.databaseName));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sync_enabled': true});
    FlutterSecureStorage.setMockInitialValues({});
    final base = await db.database;
    await base.delete('objectifs');
    await base.delete('suppressions_en_attente');
    serveur = _FauxServeur();
    sync = SyncService(api: serveur);
  });

  Future<void> synchroniser() async => sync.synchroniser<Objectif>(
        table: 'objectifs',
        lignesLocales: await db.query('objectifs'),
        lireDistant: serveur.getObjectifs,
        creerDistant: serveur.createObjectif,
        modifierDistant: serveur.updateObjectif,
        supprimerDistant: serveur.deleteObjectif,
        fromMap: Objectif.fromMap,
        toMap: (o) => o.toMap(),
        idDe: (o) => o.id,
        modifieLe: (o) => o.updatedAt,
      );

  Future<List<String>> idsLocaux() async =>
      (await db.query('objectifs')).map((m) => m['id'] as String).toList();

  test('élément local absent du serveur : envoyé', () async {
    await db.insert('objectifs', _obj('a', DateTime(2026, 1, 1)).toMap());
    await synchroniser();
    expect(serveur.donnees.keys, ['a']);
  });

  test('élément distant absent en local : téléchargé', () async {
    serveur.donnees['b'] = _obj('b', DateTime(2026, 1, 1));
    await synchroniser();
    expect(await idsLocaux(), ['b']);
  });

  test('conflit : la version la plus récente gagne', () async {
    await db.insert('objectifs', _obj('c', DateTime(2026, 1, 2), nom: 'local').toMap());
    serveur.donnees['c'] = _obj('c', DateTime(2026, 1, 1), nom: 'serveur');
    serveur.donnees['d'] = _obj('d', DateTime(2026, 3, 1), nom: 'serveur récent');
    await db.insert('objectifs', _obj('d', DateTime(2026, 2, 1), nom: 'local ancien').toMap());

    await synchroniser();

    expect(serveur.donnees['c']!.nom, 'local');
    final d = (await db.query('objectifs', where: 'id = ?', whereArgs: ['d'])).single;
    expect(d['nom'], 'serveur récent');
  });

  test('suppression hors ligne : mise en attente puis rejouée', () async {
    serveur.donnees['e'] = _obj('e', DateTime(2026, 1, 1));
    serveur.enLigne = false;
    await sync.supprimer('objectifs', 'e', serveur.deleteObjectif);
    expect(await db.query('suppressions_en_attente'), hasLength(1));

    serveur.enLigne = true;
    await synchroniser();

    expect(serveur.donnees, isEmpty, reason: 'supprimé sur le serveur');
    expect(await idsLocaux(), isEmpty, reason: "l'élément ne revient pas en local");
    expect(await db.query('suppressions_en_attente'), isEmpty);
  });

  test('suppression déjà faite côté serveur (404) : attente retirée', () async {
    await db.insert('suppressions_en_attente', {'id': 'z', 'table_name': 'objectifs'});
    await synchroniser();
    expect(serveur.suppressions, ['z']);
    expect(await db.query('suppressions_en_attente'), isEmpty);
  });

  test('serveur injoignable : aucune erreur, données locales intactes', () async {
    await db.insert('objectifs', _obj('f', DateTime(2026, 1, 1)).toMap());
    serveur.enLigne = false;
    await synchroniser();
    expect(await idsLocaux(), ['f']);
  });

  test('synchronisation désactivée : rien n\'est envoyé', () async {
    SharedPreferences.setMockInitialValues({'sync_enabled': false});
    await db.insert('objectifs', _obj('g', DateTime(2026, 1, 1)).toMap());
    await synchroniser();
    expect(serveur.donnees, isEmpty);
  });
}
