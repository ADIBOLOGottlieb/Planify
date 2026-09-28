import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _syncEnabledKey = 'sync_enabled';
  static const _apiBaseUrlKey = 'api_base_url';

  /// URL de l'API Laravel fournie à la compilation :
  /// `flutter run --dart-define=API_URL=https://api.planify.tg`
  static const String apiUrlParDefaut = String.fromEnvironment('API_URL');

  Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncEnabledKey) ?? false;
  }

  Future<void> setSyncEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, value);
  }

  Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_apiBaseUrlKey) ?? apiUrlParDefaut;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Future<void> setApiBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiBaseUrlKey, value.trim());
  }
}
