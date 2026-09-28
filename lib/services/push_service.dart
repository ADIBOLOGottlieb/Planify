import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'notification_service.dart';

/// Notifications push via Firebase Cloud Messaging (FCM).
///
/// Le projet Firebase est fourni à la compilation, sans fichier
/// `google-services.json` :
/// ```
/// flutter run --dart-define=FIREBASE_API_KEY=... \
///   --dart-define=FIREBASE_APP_ID=... \
///   --dart-define=FIREBASE_SENDER_ID=... \
///   --dart-define=FIREBASE_PROJECT_ID=...
/// ```
/// Sans ces valeurs, les notifications push sont désactivées et
/// l'application continue de fonctionner (notifications locales seulement).
class PushService {
  static final PushService _instance = PushService._internal();
  factory PushService() => _instance;
  PushService._internal();

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

  static bool get estConfigure =>
      _apiKey.isNotEmpty && _appId.isNotEmpty && _senderId.isNotEmpty && _projectId.isNotEmpty;

  bool _pret = false;

  Future<void> init() async {
    if (_pret || !estConfigure || kIsWeb) return;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _senderId,
          projectId: _projectId,
        ),
      );
      await FirebaseMessaging.instance.requestPermission();
      // Au premier plan, Android n'affiche pas les push : on passe par une
      // notification locale.
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n != null) {
          NotificationService().afficherPush(title: n.title ?? 'Planify', body: n.body ?? '');
        }
      });
      FirebaseMessaging.instance.onTokenRefresh.listen(_envoyerJeton);
      _pret = true;
    } catch (e) {
      debugPrint('FCM indisponible : $e');
    }
  }

  /// Transmet le jeton FCM de l'appareil à l'API (colonne `token_fcm`).
  Future<void> enregistrerAppareil() async {
    await init();
    if (!_pret) return;
    try {
      final jeton = await FirebaseMessaging.instance.getToken();
      if (jeton != null) await _envoyerJeton(jeton);
    } catch (_) {}
  }

  Future<void> _envoyerJeton(String jeton) async {
    try {
      final api = ApiService();
      if (await api.estConnecte()) await api.registerDeviceToken(jeton);
    } catch (_) {}
  }
}
