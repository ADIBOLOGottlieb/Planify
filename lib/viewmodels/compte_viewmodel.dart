import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';

/// Comptes de paiement de l'utilisateur (espèces, TMoney / Mixx by Yas,
/// Flooz…) avec leur solde.
class CompteViewModel with ChangeNotifier {
  List<Compte> _items = [];
  bool _isLoading = false;
  final _db = DatabaseHelper();
  final _api = ApiService();
  final _sync = SyncService();

  List<Compte> get items => [..._items];
  bool get isLoading => _isLoading;
  double get soldeTotal => _items.fold(0, (s, c) => s + c.solde);

  Future<List<Map<String, dynamic>>> _lignes(String userId) =>
      _db.query('comptes', where: 'utilisateur_id = ?', whereArgs: [userId]);

  Future<void> charger(String userId) async {
    _isLoading = true;
    notifyListeners();
    await _sync.synchroniser<Compte>(
      table: 'comptes',
      lignesLocales: await _lignes(userId),
      lireDistant: _api.getComptes,
      creerDistant: _api.createCompte,
      modifierDistant: _api.updateCompte,
      supprimerDistant: _api.deleteCompte,
      fromMap: Compte.fromMap,
      toMap: (c) => c.toMap(),
      idDe: (c) => c.id,
      modifieLe: (c) => c.updatedAt,
    );
    _items = (await _lignes(userId)).map(Compte.fromMap).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> ajouter({
    required String nom,
    required double solde,
    required String icone,
    required String couleur,
    String? operateur,
    required String userId,
  }) async {
    final nouveau = Compte(
      id: const Uuid().v4(),
      nom: nom,
      solde: solde,
      icone: icone,
      couleur: couleur,
      operateur: operateur,
      utilisateurId: userId,
    );
    await _db.insert('comptes', nouveau.toMap());
    _items.add(nouveau);
    notifyListeners();
    await _sync.envoyer(() => _api.createCompte(nouveau));
  }

  Future<void> modifier(Compte compte) async {
    final maj = Compte(
      id: compte.id,
      nom: compte.nom,
      solde: compte.solde,
      icone: compte.icone,
      couleur: compte.couleur,
      operateur: compte.operateur,
      utilisateurId: compte.utilisateurId,
      updatedAt: DateTime.now(),
    );
    await _db.update('comptes', maj.toMap(), 'id = ?', [maj.id]);
    final i = _items.indexWhere((element) => element.id == maj.id);
    if (i >= 0) {
      _items[i] = maj;
      notifyListeners();
    }
    await _sync.envoyer(() => _api.updateCompte(maj));
  }

  Future<void> supprimer(String id) async {
    await _db.delete('comptes', 'id = ?', [id]);
    _items.removeWhere((element) => element.id == id);
    notifyListeners();
    await _sync.supprimer('comptes', id, _api.deleteCompte);
  }

  Future<void> ajusterSolde(String id, double delta) async {
    final i = _items.indexWhere((element) => element.id == id);
    if (i >= 0) {
      _items[i].solde += delta;
      await modifier(_items[i]);
    }
  }

  Compte? findById(String? id) {
    if (id == null) return null;
    for (final c in _items) {
      if (c.id == id) return c;
    }
    return null;
  }

  void reset() {
    _items = [];
    notifyListeners();
  }
}
