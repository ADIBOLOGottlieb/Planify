import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/database_helper.dart';
import '../services/api_service.dart';
import '../utils/settings_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<Categorie> _categories = [];
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  final _api = ApiService();
  final _settings = SettingsService();

  List<Categorie> get categories => _categories;
  List<Categorie> get depenseCategories =>
      _categories.where((c) => c.type == 'depense' && !c.estArchivee).toList();
  List<Categorie> get revenuCategories =>
      _categories.where((c) => c.type == 'revenu' && !c.estArchivee).toList();
  List<Categorie> get archivees =>
      _categories.where((c) => c.estArchivee).toList();

  Categorie? findById(String id) => _categories.firstWhere((c) => c.id == id, orElse: () => Categorie(id: id, nom: 'Autre', icone: 'more_horiz', couleur: '#546E7A', type: 'depense'));

  Future<void> charger(String userId) async {
    final syncEnabled = await _settings.isSyncEnabled();
    if (syncEnabled) {
      try {
        await _syncWithRemote(userId);
        final results = await _db.query(
          'categories',
          where: 'est_systeme = 1 OR utilisateur_id = ?',
          whereArgs: [userId],
          orderBy: 'nom ASC',
        );
        _categories = results.map(Categorie.fromMap).toList();
        notifyListeners();
        return;
      } catch (_) {}
    }
    final results = await _db.query(
      'categories',
      where: 'est_systeme = 1 OR utilisateur_id = ?',
      whereArgs: [userId],
      orderBy: 'nom ASC',
    );
    _categories = results.map(Categorie.fromMap).toList();
    notifyListeners();
  }

  Future<void> _syncWithRemote(String userId) async {
    final remote = await _api.getCategories();
    final localRows = await _db.query(
      'categories',
      where: 'est_systeme = 0 AND utilisateur_id = ?',
      whereArgs: [userId],
    );
    final local = {
      for (final m in localRows) m['id'] as String: Categorie.fromMap(m)
    };
    final remoteMap = {for (final c in remote) c.id: c};

    for (final entry in local.entries) {
      if (!remoteMap.containsKey(entry.key)) {
        try {
          await _api.createCategory(entry.value);
        } catch (_) {}
      }
    }

    for (final r in remote) {
      final l = local[r.id];
      if (l == null) {
        await _db.insert('categories', r.toMap());
      } else {
        if (l.updatedAt.isAfter(r.updatedAt)) {
          try {
            await _api.updateCategory(l);
          } catch (_) {}
        } else if (r.updatedAt.isAfter(l.updatedAt)) {
          await _db.update('categories', r.toMap(), 'id = ?', [r.id]);
        }
      }
    }
  }

  Future<void> ajouter({required String nom, required String icone, required String couleur, required String type, required String userId}) async {
    final now = DateTime.now();
    final cat = Categorie(
      id: _uuid.v4(),
      nom: nom,
      icone: icone,
      couleur: couleur,
      type: type,
      utilisateurId: userId,
      updatedAt: now,
    );
    await _db.insert('categories', cat.toMap());
    _categories.add(cat);
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        await _api.createCategory(cat);
      } catch (_) {}
    }
  }

  Future<void> modifier(Categorie cat) async {
    final updated = cat.copyWith(updatedAt: DateTime.now());
    await _db.update('categories', updated.toMap(), 'id = ?', [cat.id]);
    final idx = _categories.indexWhere((c) => c.id == cat.id);
    if (idx >= 0) _categories[idx] = updated;
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        await _api.updateCategory(updated);
      } catch (_) {}
    }
  }

  Future<void> archiver(String id, {required bool archive}) async {
    await _db.update('categories', {
      'est_archivee': archive ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, 'id = ?', [id]);
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      _categories[idx] = _categories[idx]
          .copyWith(estArchivee: archive, updatedAt: DateTime.now());
    }
    notifyListeners();

    if (await _settings.isSyncEnabled() && idx >= 0) {
      try {
        await _api.updateCategory(_categories[idx]);
      } catch (_) {}
    }
  }

  Future<void> supprimer(String id) async {
    await _db.delete('categories', 'id = ? AND est_systeme = 0', [id]);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        await _api.deleteCategory(id);
      } catch (_) {}
    }
  }

  void reset() {
    _categories = [];
    notifyListeners();
  }
}
