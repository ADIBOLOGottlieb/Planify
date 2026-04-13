import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/database_helper.dart';
import '../services/api_service.dart';
import '../utils/settings_service.dart';

class AlertProvider extends ChangeNotifier {
  List<Alerte> _alertes = [];
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  final _api = ApiService();
  final _settings = SettingsService();

  List<Alerte> get alertes => _alertes;
  int get nonLues => _alertes.where((a) => !a.estLue).length;

  Future<void> charger(String userId) async {
    final syncEnabled = await _settings.isSyncEnabled();
    if (syncEnabled) {
      try {
        await _syncWithRemote(userId);
        final results = await _db.query(
          'alertes',
          where: 'utilisateur_id = ?',
          whereArgs: [userId],
          orderBy: 'date_envoi DESC',
        );
        _alertes = results.map(Alerte.fromMap).toList();
        notifyListeners();
        return;
      } catch (_) {}
    }
    final results = await _db.query(
      'alertes',
      where: 'utilisateur_id = ?',
      whereArgs: [userId],
      orderBy: 'date_envoi DESC',
    );
    _alertes = results.map(Alerte.fromMap).toList();
    notifyListeners();
  }

  Future<void> _syncWithRemote(String userId) async {
    final remote = await _api.getAlertes();
    final localRows = await _db.query('alertes', where: 'utilisateur_id = ?', whereArgs: [userId]);
    final local = {
      for (final m in localRows) m['id'] as String: Alerte.fromMap(m)
    };
    final remoteMap = {for (final a in remote) a.id: a};

    for (final entry in local.entries) {
      if (!remoteMap.containsKey(entry.key)) {
        try {
          await _api.createAlerte(entry.value);
        } catch (_) {}
      }
    }

    for (final r in remote) {
      final l = local[r.id];
      if (l == null) {
        await _db.insert('alertes', r.toMap());
      } else {
        if (l.updatedAt.isAfter(r.updatedAt)) {
          try {
            await _api.updateAlerte(l);
          } catch (_) {}
        } else if (r.updatedAt.isAfter(l.updatedAt)) {
          await _db.update('alertes', r.toMap(), 'id = ?', [r.id]);
        }
      }
    }
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

    if (await _settings.isSyncEnabled()) {
      try {
        await _api.createAlerte(alerte);
      } catch (_) {}
    }
  }

  Future<void> marquerLue(String id) async {
    await _db.update('alertes', {
      'est_lue': 1,
      'updated_at': DateTime.now().toIso8601String(),
    }, 'id = ?', [id]);
    final idx = _alertes.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      final updated = Alerte(
        id: _alertes[idx].id,
        typeAlerte: _alertes[idx].typeAlerte,
        message: _alertes[idx].message,
        dateEnvoi: _alertes[idx].dateEnvoi,
        estLue: true,
        utilisateurId: _alertes[idx].utilisateurId,
        budgetId: _alertes[idx].budgetId,
        updatedAt: DateTime.now(),
      );
      _alertes[idx] = updated;
      notifyListeners();
      if (await _settings.isSyncEnabled()) {
        try {
          await _api.updateAlerte(updated);
        } catch (_) {}
      }
    }
  }

  Future<void> marquerToutesLues() async {
    for (final a in _alertes.where((a) => !a.estLue)) {
      await _db.update('alertes', {
        'est_lue': 1,
        'updated_at': DateTime.now().toIso8601String(),
      }, 'id = ?', [a.id]);
    }
    _alertes = _alertes
        .map((a) => Alerte(
              id: a.id,
              typeAlerte: a.typeAlerte,
              message: a.message,
              dateEnvoi: a.dateEnvoi,
              estLue: true,
              utilisateurId: a.utilisateurId,
              budgetId: a.budgetId,
              updatedAt: DateTime.now(),
            ))
        .toList();
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      for (final a in _alertes) {
        try {
          await _api.updateAlerte(a);
        } catch (_) {}
      }
    }
  }

  Future<void> supprimer(String id) async {
    await _db.delete('alertes', 'id = ?', [id]);
    _alertes.removeWhere((a) => a.id == id);
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        await _api.deleteAlerte(id);
      } catch (_) {}
    }
  }

  void reset() {
    _alertes = [];
    notifyListeners();
  }
}
