import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark,
  sepia,
  system,
}

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  AppThemeMode _currentMode = AppThemeMode.system;

  AppThemeMode get currentMode => _currentMode;
  bool get isSepia => _currentMode == AppThemeMode.sepia;
  bool get isDark => _currentMode == AppThemeMode.dark;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode != null) {
        _currentMode = AppThemeMode.values.firstWhere(
          (e) => e.name == savedMode,
          orElse: () => AppThemeMode.system,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _currentMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode.name);
    } catch (_) {}
  }

  ThemeMode get themeMode {
    switch (_currentMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.sepia:
        return ThemeMode.light; // Sepia uses custom light theme
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  ThemeData get currentTheme {
    if (_currentMode == AppThemeMode.sepia) {
      return sepiaTheme;
    }
    if (_currentMode == AppThemeMode.dark) {
      return darkTheme;
    }
    return lightTheme;
  }

  // 1. LIGHT THEME (Mode Siang / Terang)
  ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.light,
        surface: const Color(0xFFF8FAFC),
        onSurface: const Color(0xFF0F172A),
        primary: Colors.teal.shade700,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE2E8F0),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }

  // 2. DARK THEME (Mode Malam / Gelap)
  ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF2DD4BF), // Vibrant Teal
        onPrimary: Color(0xFF042F2E),
        secondary: Color(0xFF5EEAD4),
        onSecondary: Color(0xFF042F2E),
        surface: Color(0xFF1E293B),
        onSurface: Color(0xFFF1F5F9),
        error: Color(0xFFF87171),
        onError: Color(0xFF450A0A),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Slate Navy
      cardColor: const Color(0xFF1E293B),
      dividerColor: const Color(0xFF334155),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Color(0xFFF1F5F9),
        iconTheme: IconThemeData(color: Color(0xFFF1F5F9)),
      ),
    );
  }

  // 3. SEPIA THEME (Mode Hangat / Eye-Care Mushaf)
  ThemeData get sepiaTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF00796B), // Deep Forest Teal
        onPrimary: Colors.white,
        secondary: Color(0xFFB45309), // Warm Amber
        onSecondary: Colors.white,
        surface: Color(0xFFFFFDF7), // Soft Paper
        onSurface: Color(0xFF3E2723), // Deep Warm Espresso
        error: Color(0xFFD32F2F),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4ECD8), // Warm Parchment
      cardColor: const Color(0xFFFFFDF7),
      dividerColor: const Color(0xFFE2D5C3),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF4E342E), // Warm deep brown
        foregroundColor: Color(0xFFFFF8E7),
        iconTheme: IconThemeData(color: Color(0xFFFFF8E7)),
      ),
    );
  }
}
