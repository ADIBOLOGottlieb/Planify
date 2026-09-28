import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'services/notification_service.dart';
import 'services/push_service.dart';
import 'utils/app_theme.dart';
import 'viewmodels/alert_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/budget_viewmodel.dart';
import 'viewmodels/category_viewmodel.dart';
import 'viewmodels/compte_viewmodel.dart';
import 'viewmodels/objectif_viewmodel.dart';
import 'viewmodels/preferences_viewmodel.dart';
import 'viewmodels/recurrence_viewmodel.dart';
import 'viewmodels/transaction_viewmodel.dart';
import 'views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Navigateur : SQLite compilé en WebAssembly (web/sqlite3.wasm), stocké dans IndexedDB.
  if (kIsWeb) databaseFactory = databaseFactoryFfiWebNoWebWorker;
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('fr_FR');
  await NotificationService().init();
  await PushService().init();
  final preferences = PreferencesViewModel();
  await preferences.charger();
  runApp(PlanifyApp(preferences: preferences));
}

class PlanifyApp extends StatelessWidget {
  final PreferencesViewModel preferences;
  const PlanifyApp({super.key, required this.preferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: preferences),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider(create: (_) => TransactionViewModel()),
        ChangeNotifierProvider(create: (_) => BudgetViewModel()),
        ChangeNotifierProvider(create: (_) => ObjectifViewModel()),
        ChangeNotifierProvider(create: (_) => AlertViewModel()),
        ChangeNotifierProvider(create: (_) => RecurrenceViewModel()),
        ChangeNotifierProvider(create: (_) => CompteViewModel()),
      ],
      child: const _ThemedApp(),
    );
  }
}

/// Applique le thème choisi (clair / sombre / système, couleur d'accent) et
/// reconstruit toute l'interface lorsqu'il change.
class _ThemedApp extends StatefulWidget {
  const _ThemedApp();

  @override
  State<_ThemedApp> createState() => _ThemedAppState();
}

class _ThemedAppState extends State<_ThemedApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  void _reconstruireTout(BuildContext context) {
    void marquer(Element e) {
      e.markNeedsBuild();
      e.visitChildren(marquer);
    }
    (context as Element).visitChildren(marquer);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesViewModel>();
    prefs.appliquerCouleurs(MediaQuery.platformBrightnessOf(context));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reconstruireTout(context);
    });
    return MaterialApp(
      title: 'Planify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
