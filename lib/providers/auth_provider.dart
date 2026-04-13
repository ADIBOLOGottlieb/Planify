import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  Utilisateur? _currentUser;
  bool _isLoading = false;

  Utilisateur? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  final _db = DatabaseHelper();
  final _uuid = const Uuid();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      final results = await _db.query('utilisateurs', where: 'id = ?', whereArgs: [userId]);
      if (results.isNotEmpty) {
        _currentUser = Utilisateur.fromMap(results.first);
        notifyListeners();
      }
    }
  }

  Future<String?> inscrire({required String nom, required String prenom, required String email, required String motDePasse}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final existing = await _db.query('utilisateurs', where: 'email = ?', whereArgs: [email]);
      if (existing.isNotEmpty) {
        return 'Cet email est déjà utilisé.';
      }

      final user = Utilisateur(
        id: _uuid.v4(),
        nom: nom,
        prenom: prenom,
        email: email,
        motDePasse: motDePasse, // In production, hash this
        dateInscription: DateTime.now(),
      );

      await _db.insert('utilisateurs', user.toMap());
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.id);
      return null;
    } catch (e) {
      return 'Erreur lors de l\'inscription: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> connecter({required String email, required String motDePasse}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await _db.query('utilisateurs', where: 'email = ? AND mot_de_passe = ?', whereArgs: [email, motDePasse]);
      if (results.isEmpty) {
        return 'Email ou mot de passe incorrect.';
      }

      _currentUser = Utilisateur.fromMap(results.first);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _currentUser!.id);
      return null;
    } catch (e) {
      return 'Erreur lors de la connexion: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deconnecter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> mettreAJourProfil({String? nom, String? prenom, String? devise}) async {
    if (_currentUser == null) return 'Non connecté';
    try {
      final updated = _currentUser!.copyWith(
          nom: nom, prenom: prenom, devise: devise, updatedAt: DateTime.now());
      await _db.update('utilisateurs', updated.toMap(), 'id = ?', [updated.id]);
      _currentUser = updated;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  Future<String?> changerMotDePasse({required String ancien, required String nouveau}) async {
    if (_currentUser == null) return 'Non connecté';
    if (_currentUser!.motDePasse != ancien) return 'Ancien mot de passe incorrect.';
    try {
      await _db.update('utilisateurs', {'mot_de_passe': nouveau}, 'id = ?', [_currentUser!.id]);
      _currentUser = Utilisateur(
        id: _currentUser!.id,
        nom: _currentUser!.nom,
        prenom: _currentUser!.prenom,
        email: _currentUser!.email,
        motDePasse: nouveau,
        devise: _currentUser!.devise,
        dateInscription: _currentUser!.dateInscription,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return null;
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  Future<String?> reinitialiserMotDePasse(
      {required String email, required String nouveau}) async {
    try {
      final results =
          await _db.query('utilisateurs', where: 'email = ?', whereArgs: [email]);
      if (results.isEmpty) return 'Aucun compte avec cet email.';
      final user = Utilisateur.fromMap(results.first);
      await _db.update('utilisateurs', {'mot_de_passe': nouveau}, 'id = ?', [user.id]);
      if (_currentUser != null && _currentUser!.id == user.id) {
        _currentUser = Utilisateur(
          id: user.id,
          nom: user.nom,
          prenom: user.prenom,
          email: user.email,
          motDePasse: nouveau,
          devise: user.devise,
          photoProfil: user.photoProfil,
          statut: user.statut,
          dateInscription: user.dateInscription,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return null;
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  Future<void> supprimerCompte() async {
    if (_currentUser == null) return;
    final userId = _currentUser!.id;
    await _db.delete('transactions', 'utilisateur_id = ?', [userId]);
    await _db.delete('budgets', 'utilisateur_id = ?', [userId]);
    await _db.delete('objectifs', 'utilisateur_id = ?', [userId]);
    await _db.delete('alertes', 'utilisateur_id = ?', [userId]);
    await _db.delete('transactions_recurrentes', 'utilisateur_id = ?', [userId]);
    await _db.delete('categories', 'utilisateur_id = ?', [userId]);
    await _db.delete('utilisateurs', 'id = ?', [userId]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    _currentUser = null;
    notifyListeners();
  }
}
