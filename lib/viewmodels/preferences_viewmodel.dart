import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../utils/app_constants.dart';

/// Préférences de l'utilisateur (page Paramètres) : apparence et
/// notifications. Persistées localement avec SharedPreferences.
class PreferencesViewModel extends ChangeNotifier {
  static const couleursAccent = <Color>[
    Color(0xFF2ECC70), // émeraude (par défaut)
    Color(0xFF3B82F6), // bleu
    Color(0xFF8E24AA), // violet
    Color(0xFFFB8C00), // orange
    Color(0xFFE53935), // rouge
    Color(0xFF00897B), // sarcelle
  ];

  ThemeMode _themeMode = ThemeMode.dark;
  Color _accent = couleursAccent.first;
  bool _alertesBudget = true;
  bool _rappelActif = false;
  TimeOfDay _heureRappel = const TimeOfDay(hour: 20, minute: 0);
  int _seuilParDefaut = 80;
  bool _charge = false;

  ThemeMode get themeMode => _themeMode;
  Color get accent => _accent;
  bool get alertesBudget => _alertesBudget;
  bool get rappelActif => _rappelActif;
  TimeOfDay get heureRappel => _heureRappel;
  int get seuilParDefaut => _seuilParDefaut;
  bool get charge => _charge;

  /// Thème effectivement affiché (le mode « système » suit l'appareil).
  bool estSombre(Brightness plateforme) => switch (_themeMode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system => plateforme == Brightness.dark,
      };

  Future<void> charger() async {
    final p = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[p.getInt('pref_theme') ?? ThemeMode.dark.index];
    _accent = Color(p.getInt('pref_accent') ?? couleursAccent.first.toARGB32());
    _alertesBudget = p.getBool('pref_alertes_budget') ?? true;
    _rappelActif = p.getBool('pref_rappel_actif') ?? false;
    _heureRappel = TimeOfDay(
        hour: p.getInt('pref_rappel_heure') ?? 20, minute: p.getInt('pref_rappel_minute') ?? 0);
    _seuilParDefaut = p.getInt('pref_seuil') ?? 80;
    _charge = true;
    appliquerCouleurs(WidgetsBinding.instance.platformDispatcher.platformBrightness);
    notifyListeners();
  }

  /// Met à jour la palette globale utilisée par les vues.
  void appliquerCouleurs(Brightness plateforme) {
    AppConstants.appliquer(sombre: estSombre(plateforme), accent: _accent);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    (await SharedPreferences.getInstance()).setInt('pref_theme', mode.index);
    notifyListeners();
  }

  Future<void> setAccent(Color couleur) async {
    _accent = couleur;
    (await SharedPreferences.getInstance()).setInt('pref_accent', couleur.toARGB32());
    notifyListeners();
  }

  Future<void> setAlertesBudget(bool actif) async {
    _alertesBudget = actif;
    (await SharedPreferences.getInstance()).setBool('pref_alertes_budget', actif);
    notifyListeners();
  }

  Future<void> setSeuilParDefaut(int seuil) async {
    _seuilParDefaut = seuil;
    (await SharedPreferences.getInstance()).setInt('pref_seuil', seuil);
    notifyListeners();
  }

  Future<void> setRappel({required bool actif, TimeOfDay? heure}) async {
    _rappelActif = actif;
    if (heure != null) _heureRappel = heure;
    final p = await SharedPreferences.getInstance();
    await p.setBool('pref_rappel_actif', actif);
    await p.setInt('pref_rappel_heure', _heureRappel.hour);
    await p.setInt('pref_rappel_minute', _heureRappel.minute);
    await NotificationService().programmerRappelQuotidien(actif ? _heureRappel : null);
    notifyListeners();
  }
}
