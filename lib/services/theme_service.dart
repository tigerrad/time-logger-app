import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { dark, light }
enum AppColorScheme { blue, green, purple }

class ThemeService extends ChangeNotifier {
  static const _kThemeMode = 'theme_mode';
  static const _kColorScheme = 'color_scheme';

  AppThemeMode _mode = AppThemeMode.dark;
  AppColorScheme _color = AppColorScheme.green;

  AppThemeMode get mode => _mode;
  AppColorScheme get color => _color;

  ThemeService() {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final m = p.getString(_kThemeMode);
    final c = p.getString(_kColorScheme);
    if (m == 'light') _mode = AppThemeMode.light;
    if (m == 'dark') _mode = AppThemeMode.dark;
    if (c == 'blue') _color = AppColorScheme.blue;
    if (c == 'green') _color = AppColorScheme.green;
    if (c == 'purple') _color = AppColorScheme.purple;
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode m) async {
    _mode = m;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kThemeMode, m.name);
    notifyListeners();
  }

  Future<void> setColor(AppColorScheme c) async {
    _color = c;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kColorScheme, c.name);
    notifyListeners();
  }

  bool get isDark => _mode == AppThemeMode.dark;

  Color get primaryColor {
    switch (_color) {
      case AppColorScheme.blue:
        return const Color(0xFF2196F3);
      case AppColorScheme.green:
        return const Color(0xFF00DCA0);
      case AppColorScheme.purple:
        return const Color(0xFF9C27B0);
    }
  }

  Color get secondaryColor {
    switch (_color) {
      case AppColorScheme.blue:
        return const Color(0xFF00BCD4);
      case AppColorScheme.green:
        return const Color(0xFF00A878);
      case AppColorScheme.purple:
        return const Color(0xFF673AB7);
    }
  }

  ThemeData get theme {
    final isDark = _mode == AppThemeMode.dark;
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark ? const Color(0xFF1C1C20) : const Color(0xFFF5F5F5),
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        error: const Color(0xFFF44336),
        onError: Colors.white,
        surface: isDark ? const Color(0xFF2D2D34) : Colors.white,
        onSurface: isDark ? Colors.white : Colors.black87,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF26262E) : primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: isDark ? const Color(0xFF2D2D34) : Colors.white,
        elevation: 2,
      ),
      useMaterial3: true,
    );
  }
}