import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/models.dart';
import 'secure_store.dart';
import 'settings_service.dart';

/// Erreur renvoyée par l'API Laravel, avec un message lisible par
/// l'utilisateur. [horsLigne] indique que le serveur n'a pas pu être joint.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool horsLigne;
  const ApiException(this.message, {this.statusCode, this.horsLigne = false});

  @override
  String toString() => message;
}

/// Résultat d'une authentification réussie auprès de l'API.
class AuthResult {
  final String token;
  final Map<String, dynamic> user;
  const AuthResult(this.token, this.user);
}

/// Client de l'API REST Laravel (Sanctum). Les échanges se font en JSON sur
/// HTTPS ; le jeton est lu dans le stockage sécurisé et ajouté en en-tête
/// `Authorization: Bearer` par un intercepteur Dio.
class ApiService {
  ApiService({Dio? dio, SecureStore? secureStore, SettingsService? settings})
      : _secureStore = secureStore ?? SecureStore(),
        _settings = settings ?? SettingsService(),
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.baseUrl = '${await _settings.getApiBaseUrl()}/api';
        final token = await _secureStore.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        // Jeton expiré (24 h) ou révoqué : on l'oublie, une reconnexion
        // en ligne en délivrera un nouveau.
        if (e.response?.statusCode == 401) await _secureStore.clearToken();
        handler.next(e);
      },
    ));
  }

  final Dio _dio;
  final SecureStore _secureStore;
  final SettingsService _settings;

  Future<bool> estConfiguree() async => (await _settings.getApiBaseUrl()).isNotEmpty;

  Future<bool> estConnecte() async {
    final token = await _secureStore.getToken();
    return token != null && token.isNotEmpty && await estConfiguree();
  }

  Future<T> _call<T>(Future<Response<dynamic>> Function() request,
      T Function(dynamic data) parse) async {
    if (!await estConfiguree()) {
      throw const ApiException('API non configurée', horsLigne: true);
    }
    try {
      final res = await request();
      return parse(res.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final res = e.response;
    if (res == null) {
      return const ApiException('Serveur injoignable. Vérifiez votre connexion.',
          horsLigne: true);
    }
    final data = res.data;
    String message = 'Erreur serveur (${res.statusCode})';
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        message = first is List && first.isNotEmpty ? '${first.first}' : '$first';
      } else if (data['message'] is String) {
        message = data['message'] as String;
      }
    }
    if (res.statusCode == 429) {
      message = 'Trop de tentatives. Réessayez dans quelques minutes.';
    }
    return ApiException(message, statusCode: res.statusCode);
  }

  // ---------------------------------------------------------------- Auth

  AuthResult _authResult(dynamic data) =>
      AuthResult(data['token'] as String, Map<String, dynamic>.from(data['user']));

  Future<AuthResult> register({
    required String id,
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String devise,
  }) async {
    final result = await _call(
        () => _dio.post('/register', data: {
              'id': id,
              'nom': nom,
              'prenom': prenom,
              'email': email,
              'password': password,
              'password_confirmation': password,
              'devise': devise,
            }),
        _authResult);
    await _secureStore.setToken(result.token);
    return result;
  }

  Future<AuthResult> login(String email, String password) async {
    final result = await _call(
        () => _dio.post('/login', data: {
              'email': email,
              'password': password,
              'device_name': kIsWeb ? 'web' : Platform.operatingSystem,
            }),
        _authResult);
    await _secureStore.setToken(result.token);
    return result;
  }

  Future<void> logout() async {
    try {
      if (await estConnecte()) await _call(() => _dio.post('/logout'), (_) {});
    } on ApiException catch (_) {
      // Déconnexion locale même si le serveur est injoignable.
    } finally {
      await _secureStore.clearToken();
    }
  }

  Future<Map<String, dynamic>> me() =>
      _call(() => _dio.get('/user'), (d) => Map<String, dynamic>.from(d));

  Future<void> updateProfile(Map<String, dynamic> champs) =>
      _call(() => _dio.put('/user', data: champs), (_) {});

  Future<void> changePassword(String ancien, String nouveau) => _call(
      () => _dio.put('/user/password', data: {
            'ancien_mot_de_passe': ancien,
            'password': nouveau,
            'password_confirmation': nouveau,
          }),
      (_) {});

  Future<void> deleteAccount() => _call(() => _dio.delete('/user'), (_) {});

  Future<void> resendVerificationEmail() =>
      _call(() => _dio.post('/email/resend'), (_) {});

  /// Envoie un code de réinitialisation à 6 chiffres par email.
  Future<void> forgotPassword(String email) =>
      _call(() => _dio.post('/forgot-password', data: {'email': email}), (_) {});

  Future<void> resetPassword(
          {required String email, required String code, required String password}) =>
      _call(
          () => _dio.post('/reset-password', data: {
                'email': email,
                'code': code,
                'password': password,
                'password_confirmation': password,
              }),
          (_) {});

  /// Enregistre le jeton Firebase Cloud Messaging de l'appareil.
  Future<void> registerDeviceToken(String fcmToken) =>
      _call(() => _dio.post('/device-token', data: {'token_fcm': fcmToken}), (_) {});

  Future<void> envoyerSignalement(String sujet, String message) => _call(
      () => _dio.post('/signalements', data: {'sujet': sujet, 'message': message}),
      (_) {});

  // ----------------------------------------------------------- Ressources

  Future<List<T>> _list<T>(String path, T Function(Map<String, dynamic>) fromMap) =>
      _call(() => _dio.get(path), (d) {
        final list = d is Map ? d['data'] as List : d as List;
        return list.map((e) => fromMap(Map<String, dynamic>.from(e))).toList();
      });

  Future<T> _create<T>(String path, Map<String, dynamic> body,
          T Function(Map<String, dynamic>) fromMap) =>
      _call(() => _dio.post(path, data: body), (d) {
        final map = d is Map && d['data'] is Map ? d['data'] : d;
        return fromMap(Map<String, dynamic>.from(map));
      });

  Future<void> _update(String path, Map<String, dynamic> body) =>
      _call(() => _dio.put(path, data: body), (_) {});

  Future<void> _delete(String path) => _call(() => _dio.delete(path), (_) {});

  /// [chemin] : fichier local (Android / iOS) ou image en data URI (navigateur).
  Future<String> uploadReceipt(String chemin) => _call(
      () async => _dio.post('/receipts',
          data: FormData.fromMap({
            'file': chemin.startsWith('data:')
                ? MultipartFile.fromBytes(UriData.parse(chemin).contentAsBytes(),
                    filename: 'recu.jpg')
                : await MultipartFile.fromFile(chemin),
          })),
      (d) => d['url'] as String);

  Future<List<Transaction>> getTransactions() => _list('/transactions', Transaction.fromMap);
  Future<Transaction> createTransaction(Transaction t) =>
      _create('/transactions', t.toMap(), Transaction.fromMap);
  Future<void> updateTransaction(Transaction t) => _update('/transactions/${t.id}', t.toMap());
  Future<void> deleteTransaction(String id) => _delete('/transactions/$id');

  Future<List<Categorie>> getCategories() => _list('/categories', Categorie.fromMap);
  Future<Categorie> createCategory(Categorie c) =>
      _create('/categories', c.toMap(), Categorie.fromMap);
  Future<void> updateCategory(Categorie c) => _update('/categories/${c.id}', c.toMap());
  Future<void> deleteCategory(String id) => _delete('/categories/$id');

  Future<List<Budget>> getBudgets() => _list('/budgets', Budget.fromMap);
  Future<Budget> createBudget(Budget b) => _create('/budgets', b.toMap(), Budget.fromMap);
  Future<void> updateBudget(Budget b) => _update('/budgets/${b.id}', b.toMap());
  Future<void> deleteBudget(String id) => _delete('/budgets/$id');

  Future<List<Objectif>> getObjectifs() => _list('/objectifs', Objectif.fromMap);
  Future<Objectif> createObjectif(Objectif o) =>
      _create('/objectifs', o.toMap(), Objectif.fromMap);
  Future<void> updateObjectif(Objectif o) => _update('/objectifs/${o.id}', o.toMap());
  Future<void> deleteObjectif(String id) => _delete('/objectifs/$id');

  Future<List<Alerte>> getAlertes() => _list('/alertes', Alerte.fromMap);
  Future<Alerte> createAlerte(Alerte a) => _create('/alertes', a.toMap(), Alerte.fromMap);
  Future<void> updateAlerte(Alerte a) => _update('/alertes/${a.id}', a.toMap());
  Future<void> deleteAlerte(String id) => _delete('/alertes/$id');

  Future<List<TransactionRecurrente>> getRecurrences() =>
      _list('/recurrences', TransactionRecurrente.fromMap);
  Future<TransactionRecurrente> createRecurrence(TransactionRecurrente r) =>
      _create('/recurrences', r.toMap(), TransactionRecurrente.fromMap);
  Future<void> updateRecurrence(TransactionRecurrente r) =>
      _update('/recurrences/${r.id}', r.toMap());
  Future<void> deleteRecurrence(String id) => _delete('/recurrences/$id');

  Future<List<Compte>> getComptes() => _list('/comptes', Compte.fromMap);
  Future<Compte> createCompte(Compte c) => _create('/comptes', c.toMap(), Compte.fromMap);
  Future<void> updateCompte(Compte c) => _update('/comptes/${c.id}', c.toMap());
  Future<void> deleteCompte(String id) => _delete('/comptes/$id');
}
