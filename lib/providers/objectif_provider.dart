import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/database_helper.dart';
import '../services/api_service.dart';
import '../utils/settings_service.dart';

class ObjectifProvider extends ChangeNotifier {
  List<Objectif> _objectifs = [];
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  final _api = ApiService();
  final _settings = SettingsService();

  List<Objectif> get objectifs => _objectifs;
  List<Objectif> get objectifsEnCours => _objectifs.where((o) => o.statut == 'en_cours').toList();

  Future<void> charger(String userId) async {
    final syncEnabled = await _settings.isSyncEnabled();
    if (syncEnabled) {
      try {
        await _syncWithRemote(userId);
        final results = await _db.query('objectifs',
            where: 'utilisateur_id = ?', whereArgs: [userId], orderBy: 'date_echeance ASC');
        _objectifs = results.map(Objectif.fromMap).toList();
        notifyListeners();
        return;
      } catch (_) {}
    }
    final results = await _db.query('objectifs', where: 'utilisateur_id = ?', whereArgs: [userId], orderBy: 'date_echeance ASC');
    _objectifs = results.map(Objectif.fromMap).toList();
    notifyListeners();
  }

  Future<void> _syncWithRemote(String userId) async {
    final remote = await _api.getObjectifs();
    final localRows = await _db.query('objectifs', where: 'utilisateur_id = ?', whereArgs: [userId]);
    final local = {
      for (final m in localRows) m['id'] as String: Objectif.fromMap(m)
    };
    final remoteMap = {for (final o in remote) o.id: o};

    for (final entry in local.entries) {
      if (!remoteMap.containsKey(entry.key)) {
        try {
          await _api.createObjectif(entry.value);
        } catch (_) {}
      }
    }

    for (final r in remote) {
      final l = local[r.id];
      if (l == null) {
        await _db.insert('objectifs', r.toMap());
      } else {
        if (l.updatedAt.isAfter(r.updatedAt)) {
          try {
            await _api.updateObjectif(l);
          } catch (_) {}
        } else if (r.updatedAt.isAfter(l.updatedAt)) {
          await _db.update('objectifs', r.toMap(), 'id = ?', [r.id]);
        }
      }
    }
  }

  Future<void> ajouter({required String nom, required double montantCible, required DateTime dateEcheance, required String userId}) async {
    final obj = Objectif(
      id: _uuid.v4(),
      nom: nom,
      montantCible: montantCible,
      dateEcheance: dateEcheance,
      utilisateurId: userId,
      updatedAt: DateTime.now(),
    );
    await _db.insert('objectifs', obj.toMap());
    _objectifs.add(obj);
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        await _api.createObjectif(obj);
      } catch (_) {}
    }
  }

  Future<void> alimenter(String id, double montant) async {
    final idx = _objectifs.indexWhere((o) => o.id == id);
    if (idx < 0) return;
    _objectifs[idx].montantActuel = (_objectifs[idx].montantActuel + montant).clamp(0, _objectifs[idx].montantCible);
    if (_objectifs[idx].montantActuel >= _objectifs[idx].montantCible) {
      _objectifs[idx].statut = 'atteint';
    }
    _objectifs[idx] = Objectif(
      id: _objectifs[idx].id,
      nom: _objectifs[idx].nom,
      montantCible: _objectifs[idx].montantCible,
      montantActuel: _objectifs[idx].montantActuel,
      dateEcheance: _objectifs[idx].dateEcheance,
      statut: _objectifs[idx].statut,
      utilisateurId: _objectifs[idx].utilisateurId,
      updatedAt: DateTime.now(),
    );
    await _db.update('objectifs', _objectifs[idx].toMap(), 'id = ?', [id]);
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        await _api.updateObjectif(_objectifs[idx]);
      } catch (_) {}
    }
  }

  Future<void> supprimer(String id) async {
    await _db.delete('objectifs', 'id = ?', [id]);
    _objectifs.removeWhere((o) => o.id == id);
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        await _api.deleteObjectif(id);
      } catch (_) {}
    }
  }

  void reset() {
    _objectifs = [];
    notifyListeners();
  }
}
