import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';

/// Historique des notifications (table ALERTE du MCD).
class AlertViewModel extends ChangeNotifier {
  List<Alerte> _alertes = [];
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  final _api = ApiService();
  final _sync = SyncService();

  List<Alerte> get alertes => _alertes;
  int get nonLues => _alertes.where((a) => !a.estLue).length;

  Future<List<Map<String, dynamic>>> _lignes(String userId) => _db.query('alertes',
      where: 'utilisateur_id = ?', whereArgs: [userId], orderBy: 'date_envoi DESC');

  Future<void> charger(String userId) async {
    await _sync.synchroniser<Alerte>(
      table: 'alertes',
      lignesLocales: await _lignes(userId),
      lireDistant: _api.getAlertes,
      creerDistant: _api.createAlerte,
      modifierDistant: _api.updateAlerte,
      supprimerDistant: _api.deleteAlerte,
      fromMap: Alerte.fromMap,
      toMap: (a) => a.toMap(),
      idDe: (a) => a.id,
      modifieLe: (a) => a.updatedAt,
    );
    _alertes = (await _lignes(userId)).map(Alerte.fromMap).toList();
    notifyListeners();
  }

  Future<void> ajouter({
    required String type,
    required String message,
    required String userId,
    String? budgetId,
  }) async {
    final alerte = Alerte(
      id: _uuid.v4(),
      typeAlerte: type,
      message: message,
      dateEnvoi: DateTime.now(),
      estLue: false,
      utilisateurId: userId,
      budgetId: budgetId,
      updatedAt: DateTime.now(),
    );
    await _db.insert('alertes', alerte.toMap());
    _alertes.insert(0, alerte);
    notifyListeners();
    await _sync.envoyer(() => _api.createAlerte(alerte));
  }

  Alerte _lue(Alerte a) => Alerte(
        id: a.id,
        typeAlerte: a.typeAlerte,
        message: a.message,
        dateEnvoi: a.dateEnvoi,
        estLue: true,
        utilisateurId: a.utilisateurId,
        budgetId: a.budgetId,
        updatedAt: DateTime.now(),
      );

  Future<void> marquerLue(String id) async {
    final idx = _alertes.indexWhere((a) => a.id == id);
    if (idx < 0) return;
    final updated = _lue(_alertes[idx]);
    await _db.update('alertes', updated.toMap(), 'id = ?', [id]);
    _alertes[idx] = updated;
    notifyListeners();
    await _sync.envoyer(() => _api.updateAlerte(updated));
  }

  Future<void> marquerToutesLues() async {
    final aMarquer = _alertes.where((a) => !a.estLue).map(_lue).toList();
    for (final a in aMarquer) {
      await _db.update('alertes', a.toMap(), 'id = ?', [a.id]);
    }
    _alertes = _alertes.map((a) => a.estLue ? a : _lue(a)).toList();
    notifyListeners();
    await _sync.envoyer(() async {
      for (final a in aMarquer) {
        await _api.updateAlerte(a);
      }
    });
  }

  Future<void> supprimer(String id) async {
    await _db.delete('alertes', 'id = ?', [id]);
    _alertes.removeWhere((a) => a.id == id);
    notifyListeners();
    await _sync.supprimer('alertes', id, _api.deleteAlerte);
  }

  void reset() {
    _alertes = [];
    notifyListeners();
  }
}
