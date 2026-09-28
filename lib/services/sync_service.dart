import 'api_service.dart';
import 'database_helper.dart';
import 'settings_service.dart';

/// Synchronisation « offline-first » entre la base SQLite locale et l'API.
///
/// - Toute écriture est d'abord faite en local, puis envoyée au serveur si
///   possible. En cas d'échec réseau, elle sera rattrapée à la synchronisation
///   suivante (élément absent du serveur ou `updated_at` plus récent).
/// - Une suppression qui n'a pas pu être envoyée est mémorisée dans la table
///   `suppressions_en_attente`, rejouée avant chaque fusion.
/// - Les conflits sont résolus par la date de modification la plus récente
///   (« last write wins »).
class SyncService {
  SyncService({ApiService? api, DatabaseHelper? db, SettingsService? settings})
      : _api = api ?? ApiService(),
        _db = db ?? DatabaseHelper(),
        _settings = settings ?? SettingsService();

  final ApiService _api;
  final DatabaseHelper _db;
  final SettingsService _settings;

  static const _tableSuppressions = 'suppressions_en_attente';

  /// Vrai si la synchronisation est activée et qu'un jeton d'API existe.
  Future<bool> actif() async =>
      await _settings.isSyncEnabled() && await _api.estConnecte();

  /// Envoie une création ou une modification ; les erreurs sont ignorées car
  /// la synchronisation suivante renverra l'élément.
  Future<void> envoyer(Future<void> Function() action) async {
    if (!await actif()) return;
    try {
      await action();
    } catch (_) {}
  }

  /// Propage une suppression, ou la met en attente si le serveur est
  /// injoignable.
  Future<void> supprimer(
      String table, String id, Future<void> Function(String id) supprimerDistant) async {
    if (!await _settings.isSyncEnabled()) return;
    if (await actif()) {
      try {
        await supprimerDistant(id);
        return;
      } on ApiException catch (e) {
        if (e.statusCode == 404) return;
      } catch (_) {}
    }
    await _db.insert(_tableSuppressions, {'id': id, 'table_name': table});
  }

  /// Fusionne les données locales de [table] avec celles du serveur.
  /// Ne fait rien (et ne lève pas d'erreur) si la synchronisation est
  /// inactive ou si le serveur est injoignable.
  Future<void> synchroniser<T>({
    required String table,
    required List<Map<String, dynamic>> lignesLocales,
    required Future<List<T>> Function() lireDistant,
    required Future<void> Function(T) creerDistant,
    required Future<void> Function(T) modifierDistant,
    required Future<void> Function(String id) supprimerDistant,
    required T Function(Map<String, dynamic>) fromMap,
    required Map<String, dynamic> Function(T) toMap,
    required String Function(T) idDe,
    required DateTime Function(T) modifieLe,
    Future<T?> Function(T)? preparerEnvoi,
  }) async {
    if (!await actif()) return;
    try {
      final enAttente = await _rejouerSuppressions(table, supprimerDistant);
      final distants = await lireDistant();
      final locaux = {for (final m in lignesLocales) m['id'] as String: fromMap(m)};
      final idsDistants = {for (final d in distants) idDe(d)};

      Future<void> pousser(T element, Future<void> Function(T) action) async {
        final aEnvoyer = preparerEnvoi == null ? element : await preparerEnvoi(element);
        if (aEnvoyer == null) return;
        try {
          await action(aEnvoyer);
        } catch (_) {}
      }

      for (final local in locaux.values) {
        if (!idsDistants.contains(idDe(local))) await pousser(local, creerDistant);
      }

      for (final distant in distants) {
        final id = idDe(distant);
        if (enAttente.contains(id)) continue;
        final local = locaux[id];
        if (local == null) {
          await _db.insert(table, toMap(distant));
        } else if (modifieLe(local).isAfter(modifieLe(distant))) {
          await pousser(local, modifierDistant);
        } else if (modifieLe(distant).isAfter(modifieLe(local))) {
          await _db.update(table, toMap(distant), 'id = ?', [id]);
        }
      }
    } on ApiException catch (_) {
      // Hors ligne : les données locales restent la référence.
    }
  }

  /// Rejoue les suppressions en attente et renvoie les identifiants qui n'ont
  /// toujours pas pu être supprimés côté serveur.
  Future<Set<String>> _rejouerSuppressions(
      String table, Future<void> Function(String id) supprimerDistant) async {
    final lignes = await _db.query(_tableSuppressions,
        where: 'table_name = ?', whereArgs: [table]);
    final restants = <String>{};
    for (final l in lignes) {
      final id = l['id'] as String;
      try {
        await supprimerDistant(id);
      } on ApiException catch (e) {
        if (e.statusCode != 404) {
          restants.add(id);
          if (e.horsLigne) rethrow;
          continue;
        }
      }
      await _db.delete(_tableSuppressions, 'id = ? AND table_name = ?', [id, table]);
    }
    return restants;
  }
}
