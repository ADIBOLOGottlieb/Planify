import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/database_helper.dart';
import 'package:uuid/uuid.dart';

class CompteProvider with ChangeNotifier {
  List<Compte> _items = [];
  bool _isLoading = false;

  List<Compte> get items => [..._items];
  bool get isLoading => _isLoading;

  Future<void> charger(String userId) async {
    _isLoading = true;
    notifyListeners();

    final data = await DatabaseHelper().query(
      'comptes',
      where: 'utilisateur_id = ?',
      whereArgs: [userId],
    );

    _items = data.map((e) => Compte.fromMap(e)).toList();
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

    await DatabaseHelper().insert('comptes', nouveau.toMap());
    _items.add(nouveau);
    notifyListeners();
  }

  Future<void> modifier(Compte compte) async {
    await DatabaseHelper().update(
      'comptes',
      compte.toMap(),
      'id = ?',
      [compte.id],
    );
    final i = _items.indexWhere((element) => element.id == compte.id);
    if (i >= 0) {
      _items[i] = compte;
      notifyListeners();
    }
  }

  Future<void> supprimer(String id) async {
    await DatabaseHelper().delete('comptes', 'id = ?', [id]);
    _items.removeWhere((element) => element.id == id);
    notifyListeners();
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
    return _items.firstWhere((element) => element.id == id,
        orElse: () => throw Exception('Compte introuvable'));
  }
}
