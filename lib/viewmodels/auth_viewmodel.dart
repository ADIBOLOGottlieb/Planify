import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/push_service.dart';
import '../services/settings_service.dart';
import '../utils/password_hasher.dart';

/// Authentification et gestion du compte.
///
/// Fonctionnement « offline-first » :
/// - si l'API Laravel est configurée, l'inscription et la connexion passent
///   par le serveur, qui délivre un jeton Sanctum (24 h) conservé dans le
///   stockage sécurisé ; le mot de passe est aussi haché localement pour
///   permettre la connexion hors ligne ;
/// - sans réseau, la connexion est vérifiée sur la base locale, avec blocage
///   temporaire après [maxTentatives] échecs.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({ApiService? api, SettingsService? settings})
      : _api = api ?? ApiService(),
        _settings = settings ?? SettingsService();

  /// Nombre d'échecs tolérés avant blocage temporaire du compte.
  static const int maxTentatives = 5;
  static const Duration dureeBlocage = Duration(minutes: 15);

  static const List<String> questionsSecretes = [
    'Quel est le nom de votre premier animal de compagnie ?',
    'Quelle est la ville de naissance de votre mère ?',
    'Quel était le nom de votre école primaire ?',
    'Quel est le prénom de votre meilleur(e) ami(e) d\'enfance ?',
    'Quel est votre plat préféré ?',
  ];

  static const _tablesUtilisateur = [
    'transactions', 'budgets', 'objectifs', 'alertes',
    'transactions_recurrentes', 'comptes', 'categories',
  ];

  Utilisateur? _currentUser;
  bool _isLoading = false;

  Utilisateur? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  final ApiService _api;
  final SettingsService _settings;
  final _db = DatabaseHelper();
  final _uuid = const Uuid();

  Future<bool> modeEnLigne() => _api.estConfiguree();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('rester_connecte') ?? true)) {
      // Session limitée à la durée de vie de l'application.
      await prefs.remove('userId');
      return;
    }
    final userId = prefs.getString('userId');
    if (userId != null) {
      final results = await _db.query('utilisateurs', where: 'id = ?', whereArgs: [userId]);
      if (results.isNotEmpty) {
        _currentUser = Utilisateur.fromMap(results.first);
        notifyListeners();
        // Rafraîchit le profil (email vérifié…) sans bloquer le démarrage.
        rafraichirProfil();
      }
    }
  }

  static String _normaliserEmail(String email) => email.trim().toLowerCase();

  /// Rend la réponse secrète insensible à la casse, aux espaces et aux accents.
  static String _normaliserReponse(String reponse) {
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c',
    };
    final lower = reponse.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return lower.split('').map((c) => accents[c] ?? c).join();
  }

  Future<Map<String, dynamic>?> _trouverParEmail(String email) async {
    final rows = await _db.query('utilisateurs',
        where: 'LOWER(email) = ?', whereArgs: [_normaliserEmail(email)]);
    return rows.isEmpty ? null : rows.first;
  }

  /// Renvoie un message d'erreur si le compte est bloqué, sinon null.
  String? _messageSiBloque(Map<String, dynamic> row) {
    final bloque = row['bloque_jusqu_a'] as String?;
    if (bloque == null) return null;
    final jusqua = DateTime.parse(bloque);
    final restant = jusqua.difference(DateTime.now());
    if (restant.isNegative) return null;
    final minutes = restant.inMinutes + 1;
    return 'Trop de tentatives échouées. Compte bloqué pendant encore $minutes min.';
  }

  /// Enregistre un échec et bloque le compte au bout de [maxTentatives].
  Future<String> _enregistrerEchec(Map<String, dynamic> row, String messageBase) async {
    final tentatives = ((row['tentatives_echouees'] as int?) ?? 0) + 1;
    if (tentatives >= maxTentatives) {
      await _db.update('utilisateurs', {
        'tentatives_echouees': 0,
        'bloque_jusqu_a': DateTime.now().add(dureeBlocage).toIso8601String(),
      }, 'id = ?', [row['id']]);
      return 'Trop de tentatives échouées. Compte bloqué pendant ${dureeBlocage.inMinutes} min.';
    }
    await _db.update('utilisateurs', {'tentatives_echouees': tentatives}, 'id = ?', [row['id']]);
    final restantes = maxTentatives - tentatives;
    return '$messageBase ($restantes tentative${restantes > 1 ? 's' : ''} restante${restantes > 1 ? 's' : ''}).';
  }

  Future<void> _reinitialiserEchecs(String userId) =>
      _db.update('utilisateurs', {'tentatives_echouees': 0, 'bloque_jusqu_a': null}, 'id = ?', [userId]);

  Future<void> _ouvrirSession(Utilisateur user, {bool resterConnecte = true}) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.id);
    await prefs.setBool('rester_connecte', resterConnecte);
  }

  /// Crée ou met à jour l'utilisateur local à partir de la réponse de l'API.
  /// Si un compte local de même email existe avec un autre identifiant (créé
  /// hors ligne), ses données sont rattachées à l'identifiant du serveur.
  Future<Utilisateur> _enregistrerUtilisateurDistant(
      Map<String, dynamic> distant, String motDePasse) async {
    final id = distant['id'].toString();
    final existant = await _trouverParEmail(distant['email'] as String);
    if (existant != null && existant['id'] != id) {
      await _migrerIdentifiant(existant['id'] as String, id);
    }
    final champs = {
      'id': id,
      'nom': distant['nom'],
      'prenom': distant['prenom'],
      'email': _normaliserEmail(distant['email'] as String),
      'mot_de_passe': await PasswordHasher.hash(motDePasse),
      'devise': distant['devise'] ?? 'FCFA',
      'photo_profil': existant?['photo_profil'],
      'statut': distant['statut'] ?? 'actif',
      'email_verifie': distant['email_verifie'] == true ? 1 : 0,
      'date_inscription': distant['date_inscription'] ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'tentatives_echouees': 0,
      'bloque_jusqu_a': null,
    };
    final dejaLa = await _db.query('utilisateurs', where: 'id = ?', whereArgs: [id]);
    if (dejaLa.isEmpty) {
      await _db.insert('utilisateurs', champs);
    } else {
      await _db.update('utilisateurs', champs, 'id = ?', [id]);
    }
    final rows = await _db.query('utilisateurs', where: 'id = ?', whereArgs: [id]);
    return Utilisateur.fromMap(rows.first);
  }

  Future<void> _migrerIdentifiant(String ancien, String nouveau) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final table in _tablesUtilisateur) {
        await txn.update(table, {'utilisateur_id': nouveau},
            where: 'utilisateur_id = ?', whereArgs: [ancien]);
      }
      await txn.delete('utilisateurs', where: 'id = ?', whereArgs: [ancien]);
    });
  }

  Future<void> _apresConnexionEnLigne() async {
    await _settings.setSyncEnabled(true);
    PushService().enregistrerAppareil();
  }

  Future<String?> inscrire({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String questionSecrete,
    required String reponseSecrete,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (await _trouverParEmail(email) != null) {
        return 'Cet email est déjà utilisé.';
      }

      var user = Utilisateur(
        id: _uuid.v4(),
        nom: nom,
        prenom: prenom,
        email: _normaliserEmail(email),
        motDePasse: await PasswordHasher.hash(motDePasse),
        questionSecrete: questionSecrete,
        dateInscription: DateTime.now(),
      );

      final enLigne = await _api.estConfiguree();
      if (enLigne) {
        // Le serveur garantit l'unicité de l'email et envoie l'email de
        // vérification ; une connexion est donc nécessaire pour s'inscrire.
        try {
          final res = await _api.register(
            id: user.id,
            nom: nom,
            prenom: prenom,
            email: user.email,
            password: motDePasse,
            devise: user.devise,
          );
          user = user.copyWith(emailVerifie: res.user['email_verifie'] == true);
        } on ApiException catch (e) {
          return e.horsLigne
              ? 'Connexion Internet requise pour créer un compte.'
              : e.message;
        }
      }

      await _db.insert('utilisateurs', {
        ...user.toMap(),
        'reponse_secrete': await PasswordHasher.hash(_normaliserReponse(reponseSecrete)),
        'tentatives_echouees': 0,
      });
      await _ouvrirSession(user);
      if (enLigne) await _apresConnexionEnLigne();
      return null;
    } catch (e) {
      return 'Erreur lors de l\'inscription: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> connecter({
    required String email,
    required String motDePasse,
    bool resterConnecte = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (await _api.estConfiguree()) {
        try {
          final res = await _api.login(_normaliserEmail(email), motDePasse);
          final user = await _enregistrerUtilisateurDistant(res.user, motDePasse);
          await _ouvrirSession(user, resterConnecte: resterConnecte);
          await _apresConnexionEnLigne();
          return null;
        } on ApiException catch (e) {
          if (!e.horsLigne) {
            return e.statusCode == 401 || e.statusCode == 422
                ? 'Email ou mot de passe incorrect.'
                : e.message;
          }
          // Serveur injoignable : connexion hors ligne ci-dessous.
        }
      }

      final row = await _trouverParEmail(email);
      if (row == null) {
        return 'Email ou mot de passe incorrect.';
      }
      final bloque = _messageSiBloque(row);
      if (bloque != null) return bloque;

      if (!await PasswordHasher.verify(motDePasse, row['mot_de_passe'] as String)) {
        return await _enregistrerEchec(row, 'Email ou mot de passe incorrect');
      }

      await _reinitialiserEchecs(row['id'] as String);
      await _ouvrirSession(Utilisateur.fromMap(row), resterConnecte: resterConnecte);
      return null;
    } catch (e) {
      return 'Erreur lors de la connexion: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deconnecter() async {
    await _api.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    _currentUser = null;
    notifyListeners();
  }

  /// Met à jour le statut de vérification de l'email depuis le serveur.
  Future<void> rafraichirProfil() async {
    if (_currentUser == null || !await _api.estConnecte()) return;
    try {
      final distant = await _api.me();
      final verifie = distant['email_verifie'] == true;
      if (verifie != _currentUser!.emailVerifie) {
        await _db.update('utilisateurs', {'email_verifie': verifie ? 1 : 0},
            'id = ?', [_currentUser!.id]);
        _currentUser = _currentUser!.copyWith(emailVerifie: verifie);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<String?> renvoyerEmailVerification() async {
    try {
      await _api.resendVerificationEmail();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> mettreAJourProfil({String? nom, String? prenom, String? devise, String? photoProfil}) async {
    if (_currentUser == null) return 'Non connecté';
    try {
      final updated = _currentUser!.copyWith(
          nom: nom, prenom: prenom, devise: devise, photoProfil: photoProfil,
          updatedAt: DateTime.now());
      await _db.update('utilisateurs', updated.toMap(), 'id = ?', [updated.id]);
      _currentUser = updated;
      notifyListeners();
      if (await _api.estConnecte()) {
        try {
          await _api.updateProfile(
              {'nom': updated.nom, 'prenom': updated.prenom, 'devise': updated.devise});
        } catch (_) {}
      }
      return null;
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  Future<String?> changerMotDePasse({required String ancien, required String nouveau}) async {
    if (_currentUser == null) return 'Non connecté';
    if (!await PasswordHasher.verify(ancien, _currentUser!.motDePasse)) {
      return 'Ancien mot de passe incorrect.';
    }
    if (await _api.estConnecte()) {
      try {
        await _api.changePassword(ancien, nouveau);
      } on ApiException catch (e) {
        return e.horsLigne
            ? 'Connexion Internet requise pour changer le mot de passe.'
            : e.message;
      }
    }
    try {
      final hash = await PasswordHasher.hash(nouveau);
      await _db.update('utilisateurs', {'mot_de_passe': hash}, 'id = ?', [_currentUser!.id]);
      _currentUser = _currentUser!.copyWith(motDePasse: hash, updatedAt: DateTime.now());
      notifyListeners();
      return null;
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  /// Définit ou remplace la question secrète (utile pour les comptes créés
  /// avant son introduction). Le mot de passe actuel est exigé.
  Future<String?> definirQuestionSecrete({
    required String motDePasse,
    required String question,
    required String reponse,
  }) async {
    if (_currentUser == null) return 'Non connecté';
    if (!await PasswordHasher.verify(motDePasse, _currentUser!.motDePasse)) {
      return 'Mot de passe incorrect.';
    }
    await _db.update('utilisateurs', {
      'question_secrete': question,
      'reponse_secrete': await PasswordHasher.hash(_normaliserReponse(reponse)),
    }, 'id = ?', [_currentUser!.id]);
    _currentUser = _currentUser!.copyWith(questionSecrete: question);
    notifyListeners();
    return null;
  }

  // ------------------------------------------------ Mot de passe oublié

  /// Valeur renvoyée quand le serveur est injoignable.
  static const String horsLigne = '__hors_ligne__';

  /// Demande l'envoi d'un code de réinitialisation par email (en ligne).
  /// Renvoie null en cas de succès, [horsLigne] si le serveur est
  /// injoignable, sinon un message d'erreur.
  Future<String?> demanderCodeReinitialisation(String email) async {
    if (!await _api.estConfiguree()) return horsLigne;
    try {
      await _api.forgotPassword(_normaliserEmail(email));
      return null;
    } on ApiException catch (e) {
      return e.horsLigne ? horsLigne : e.message;
    }
  }

  Future<String?> reinitialiserAvecCode({
    required String email,
    required String code,
    required String nouveau,
  }) async {
    try {
      await _api.resetPassword(email: _normaliserEmail(email), code: code, password: nouveau);
    } on ApiException catch (e) {
      return e.message;
    }
    final row = await _trouverParEmail(email);
    if (row != null) {
      await _db.update('utilisateurs', {'mot_de_passe': await PasswordHasher.hash(nouveau)},
          'id = ?', [row['id']]);
      await _reinitialiserEchecs(row['id'] as String);
    }
    return null;
  }

  /// Question secrète associée à l'email, ou null si le compte n'existe pas
  /// ou n'a pas de question configurée.
  Future<String?> questionSecretePour(String email) async {
    final row = await _trouverParEmail(email);
    if (row == null || row['reponse_secrete'] == null) return null;
    return row['question_secrete'] as String?;
  }

  /// Réinitialisation hors ligne par la question secrète (compte local).
  Future<String?> reinitialiserMotDePasse({
    required String email,
    required String reponse,
    required String nouveau,
  }) async {
    try {
      final row = await _trouverParEmail(email);
      if (row == null || row['reponse_secrete'] == null) {
        return 'Réinitialisation impossible pour ce compte.';
      }
      final bloque = _messageSiBloque(row);
      if (bloque != null) return bloque;

      if (!await PasswordHasher.verify(
          _normaliserReponse(reponse), row['reponse_secrete'] as String)) {
        return await _enregistrerEchec(row, 'Réponse incorrecte');
      }

      final hash = await PasswordHasher.hash(nouveau);
      await _db.update('utilisateurs', {'mot_de_passe': hash}, 'id = ?', [row['id']]);
      await _reinitialiserEchecs(row['id'] as String);
      if (_currentUser != null && _currentUser!.id == row['id']) {
        _currentUser = _currentUser!.copyWith(motDePasse: hash, updatedAt: DateTime.now());
        notifyListeners();
      }
      return null;
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  Future<String?> supprimerCompte() async {
    if (_currentUser == null) return null;
    if (await _api.estConnecte()) {
      try {
        await _api.deleteAccount();
      } on ApiException catch (e) {
        return e.horsLigne
            ? 'Connexion Internet requise pour supprimer le compte du serveur.'
            : e.message;
      }
    }
    final userId = _currentUser!.id;
    for (final table in _tablesUtilisateur) {
      await _db.delete(table, 'utilisateur_id = ?', [userId]);
    }
    await _db.delete('utilisateurs', 'id = ?', [userId]);
    await _api.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    _currentUser = null;
    notifyListeners();
    return null;
  }
}
