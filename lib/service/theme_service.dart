import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'app_theme_mode';

  // Sauvegarder le thème
  Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  // Récupérer le thème
  Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false; // Par défaut: mode clair
  }

  // Basculer le thème
  Future<bool> toggleTheme() async {
    final current = await getTheme();
    await saveTheme(!current);
    return !current;
  }
}
