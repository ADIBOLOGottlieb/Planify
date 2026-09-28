import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class CategoryViewModel extends ChangeNotifier {
  List<Categorie> _categories = [];
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  final _api = ApiService();
  final _sync = SyncService();

  List<Categorie> get categories => _categories;
  List<Categorie> get depenseCategories =>
      _categories.where((c) => c.type == 'depense' && !c.estArchivee).toList();
  List<Categorie> get revenuCategories =>
      _categories.where((c) => c.type == 'revenu' && !c.estArchivee).toList();
  List<Categorie> get archivees =>
      _categories.where((c) => c.estArchivee).toList();

  Categorie? findById(String id) => _categories.firstWhere((c) => c.id == id,
      orElse: () => Categorie(
          id: id, nom: 'Autre', icone: 'more_horiz', couleur: '#546E7A', type: 'depense'));

  Future<List<Map<String, dynamic>>> _lignes(String userId) => _db.query(
        'categories',
        where: 'est_systeme = 1 OR utilisateur_id = ?',
        whereArgs: [userId],
        orderBy: 'nom ASC',
      );

  Future<void> charger(String userId) async {
    // Les catégories système (gérées depuis l'interface d'administration)
    // sont rapatriées ; une personnalisation locale plus récente est
    // conservée et n'est jamais envoyée au serveur.
    await _sync.synchroniser<Categorie>(
      table: 'categories',
      lignesLocales: await _lignes(userId),
      lireDistant: _api.getCategories,
      creerDistant: _api.createCategory,
      modifierDistant: _api.updateCategory,
      supprimerDistant: _api.deleteCategory,
      fromMap: Categorie.fromMap,
      toMap: (c) => c.toMap(),
      idDe: (c) => c.id,
      modifieLe: (c) => c.updatedAt,
      preparerEnvoi: (c) async => c.estSysteme ? null : c,
    );
    _categories = (await _lignes(userId)).map(Categorie.fromMap).toList();
    notifyListeners();
  }

  Future<void> ajouter({required String nom, required String icone, required String couleur, required String type, required String userId}) async {
    final cat = Categorie(
      id: _uuid.v4(),
      nom: nom,
      icone: icone,
      couleur: couleur,
      type: type,
      utilisateurId: userId,
      updatedAt: DateTime.now(),
    );
    await _db.insert('categories', cat.toMap());
    _categories.add(cat);
    notifyListeners();
    await _sync.envoyer(() => _api.createCategory(cat));
  }

  /// Modifie une catégorie. Les catégories système peuvent être
  /// personnalisées (nom, icône, couleur) mais restent locales.
  Future<void> modifier(Categorie cat) async {
    final updated = cat.copyWith(updatedAt: DateTime.now());
    await _db.update('categories', updated.toMap(), 'id = ?', [cat.id]);
    final idx = _categories.indexWhere((c) => c.id == cat.id);
    if (idx >= 0) _categories[idx] = updated;
    notifyListeners();
    if (!updated.estSysteme) await _sync.envoyer(() => _api.updateCategory(updated));
  }

  Future<void> archiver(String id, {required bool archive}) async {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    await modifier(_categories[idx].copyWith(estArchivee: archive));
  }

  /// Supprime une catégorie personnalisée (les catégories système ne peuvent
  /// pas être supprimées, seulement archivées).
  Future<void> supprimer(String id) async {
    final count = await _db.delete('categories', 'id = ? AND est_systeme = 0', [id]);
    if (count == 0) return;
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
    await _sync.supprimer('categories', id, _api.deleteCategory);
  }

  void reset() {
    _categories = [];
    notifyListeners();
  }
}
