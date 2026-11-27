import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';

/// Persists user UI preferences (ThemeMode & EN/বাংলা language) locally via
/// [SharedPreferences], with an in-memory constructor for fast offline tests.
class AppPreferences extends ChangeNotifier {
  AppPreferences._({
    required SharedPreferences? prefs,
    required ThemeMode themeMode,
    required bool isBangla,
  })  : _prefs = prefs,
        _themeMode = themeMode,
        _isBangla = isBangla;

  /// Ephemeral preferences for widget tests and local screenshot rendering.
  factory AppPreferences.inMemory({
    ThemeMode themeMode = ThemeMode.system,
    bool isBangla = AppConfig.defaultBangla,
  }) {
    return AppPreferences._(
      prefs: null,
      themeMode: themeMode,
      isBangla: isBangla,
    );
  }

  static const String _themeKey = 'app_theme_mode';
  static const String _banglaKey = 'app_is_bangla';

  final SharedPreferences? _prefs;
  ThemeMode _themeMode;
  bool _isBangla;

  ThemeMode get themeMode => _themeMode;
  bool get isBangla => _isBangla;

  /// Loads persisted preferences from [SharedPreferences].
  static Future<AppPreferences> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      final themeMode = _parseThemeMode(savedTheme);
      final isBangla = prefs.getBool(_banglaKey) ?? AppConfig.defaultBangla;
      return AppPreferences._(
        prefs: prefs,
        themeMode: themeMode,
        isBangla: isBangla,
      );
    } catch (_) {
      return AppPreferences.inMemory();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs?.setString(_themeKey, mode.name);
  }

  Future<void> setBangla(bool value) async {
    if (_isBangla == value) return;
    _isBangla = value;
    notifyListeners();
    await _prefs?.setBool(_banglaKey, value);
  }

  Future<void> toggleBangla() => setBangla(!_isBangla);

  Future<void> cycleTheme() {
    switch (_themeMode) {
      case ThemeMode.system:
        return setThemeMode(ThemeMode.dark);
      case ThemeMode.dark:
        return setThemeMode(ThemeMode.light);
      case ThemeMode.light:
        return setThemeMode(ThemeMode.system);
    }
  }

  static ThemeMode _parseThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
