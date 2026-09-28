import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notifications locales : alertes budgétaires, rappel quotidien de saisie
/// des dépenses et affichage des notifications push reçues au premier plan.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const _idRappelQuotidien = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _canalAlertes = AndroidNotificationDetails(
    'budget_alerts',
    'Alertes budgétaires',
    channelDescription: 'Seuil de budget atteint ou dépassé',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _canalRappels = AndroidNotificationDetails(
    'rappels',
    'Rappels de saisie',
    channelDescription: 'Rappel quotidien pour enregistrer vos dépenses',
    importance: Importance.defaultImportance,
  );

  static const _canalPush = AndroidNotificationDetails(
    'planify_push',
    'Informations Planify',
    channelDescription: 'Rapports et messages envoyés par le serveur',
    importance: Importance.high,
  );

  /// Les notifications locales n'existent que sur Android et iOS : dans le
  /// navigateur, les méthodes de ce service ne font rien.
  bool get _disponible => !kIsWeb;

  Future<void> init() async {
    if (_initialized || !_disponible) return;
    tz_data.initializeTimeZones();
    // Application conçue pour le Togo (UTC+0, sans heure d'été).
    tz.setLocalLocation(tz.getLocation('Africa/Lome'));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  int _nouvelId() => DateTime.now().millisecondsSinceEpoch ~/ 1000 % 1000000;

  Future<void> showBudgetAlert({required String title, required String body}) async {
    if (!_disponible) return;
    await init();
    await _plugin.show(_nouvelId(), title, body,
        const NotificationDetails(android: _canalAlertes, iOS: DarwinNotificationDetails()));
  }

  Future<void> afficherPush({required String title, required String body}) async {
    if (!_disponible) return;
    await init();
    await _plugin.show(_nouvelId(), title, body,
        const NotificationDetails(android: _canalPush, iOS: DarwinNotificationDetails()));
  }

  /// Programme (ou annule si [heure] est null) le rappel quotidien
  /// « Pensez à enregistrer vos dépenses ».
  Future<void> programmerRappelQuotidien(TimeOfDay? heure) async {
    if (!_disponible) return;
    await init();
    await _plugin.cancel(_idRappelQuotidien);
    if (heure == null) return;
    final now = tz.TZDateTime.now(tz.local);
    var prochain = tz.TZDateTime(tz.local, now.year, now.month, now.day, heure.hour, heure.minute);
    if (!prochain.isAfter(now)) prochain = prochain.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      _idRappelQuotidien,
      'Planify',
      'Pensez à enregistrer vos dépenses de la journée.',
      prochain,
      const NotificationDetails(android: _canalRappels, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
