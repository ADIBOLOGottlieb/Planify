import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/services/api_service.dart';
import 'package:planify/services/secure_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adaptateur HTTP simulé : enregistre les requêtes et renvoie une réponse
/// fixée par le test.
class _FauxAdaptateur implements HttpClientAdapter {
  RequestOptions? derniere;
  int statut = 200;
  Object? corps;
  bool injoignable = false;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) async {
    derniere = options;
    if (injoignable) {
      throw DioException.connectionError(requestOptions: options, reason: 'hors ligne');
    }
    return ResponseBody.fromString(jsonEncode(corps), statut,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FauxAdaptateur http;
  late ApiService api;

  setUp(() {
    SharedPreferences.setMockInitialValues({'api_base_url': 'https://api.planify.test/'});
    FlutterSecureStorage.setMockInitialValues({});
    http = _FauxAdaptateur();
    api = ApiService(dio: Dio()..httpClientAdapter = http);
  });

  test('login : enregistre le jeton puis l\'envoie en Bearer', () async {
    http.corps = {
      'token': 'abc123',
      'user': {'id': 'u1', 'email': 'a@b.tg'}
    };
    final res = await api.login('a@b.tg', 'MotDePasse1');
    expect(res.user['id'], 'u1');
    expect(http.derniere!.uri.toString(), 'https://api.planify.test/api/login');
    expect(await SecureStore().getToken(), 'abc123');

    http.corps = [];
    await api.getTransactions();
    expect(http.derniere!.headers['Authorization'], 'Bearer abc123');
  });

  test('401 : message du serveur et jeton oublié', () async {
    await SecureStore().setToken('expire');
    http
      ..statut = 401
      ..corps = {'message': 'Unauthenticated.'};
    await expectLater(api.getBudgets(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)));
    expect(await SecureStore().getToken(), isNull);
  });

  test('422 : première erreur de validation renvoyée', () async {
    http
      ..statut = 422
      ..corps = {
        'message': 'The given data was invalid.',
        'errors': {
          'email': ['Cet email est déjà utilisé.']
        }
      };
    await expectLater(
        api.register(
            id: 'u1', nom: 'D', prenom: 'A', email: 'a@b.tg', password: 'x', devise: 'FCFA'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Cet email est déjà utilisé.')));
  });

  test('serveur injoignable : exception « hors ligne »', () async {
    http.injoignable = true;
    await expectLater(api.getCategories(),
        throwsA(isA<ApiException>().having((e) => e.horsLigne, 'horsLigne', true)));
  });

  test('API non configurée : aucune requête', () async {
    SharedPreferences.setMockInitialValues({});
    await expectLater(api.getObjectifs(),
        throwsA(isA<ApiException>().having((e) => e.horsLigne, 'horsLigne', true)));
    expect(http.derniere, isNull);
  });

  test('liste paginée Laravel ({"data": [...]}) acceptée', () async {
    http.corps = {
      'data': [
        {
          'id': 'c1', 'nom': 'Moto', 'solde': 1500, 'icone': 'two_wheeler',
          'couleur': '#1E88E5', 'operateur': null, 'utilisateur_id': 'u1',
          'updated_at': '2026-09-01T10:00:00.000'
        }
      ]
    };
    final comptes = await api.getComptes();
    expect(comptes.single.solde, 1500);
  });
}
