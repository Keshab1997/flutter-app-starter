import 'package:flutter/material.dart';
import 'package:local_vault_backup/local_vault_backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';

/// Persists user UI preferences (ThemeMode & EN/বাংলা language) locally via
/// [SharedPreferences], with an in-memory constructor for fast offline tests
/// and a ready-made [VaultBackupEngine] adapter for encrypted backups.
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

  /// Exports local preferences (extend with app database tables in new apps).
  Future<Map<String, dynamic>> exportVaultData() async {
    return <String, dynamic>{_themeKey: _themeMode.name, _banglaKey: _isBangla};
  }

  /// Restores preferences from a verified [local_vault_backup] payload.
  Future<void> importVaultData(Map<String, dynamic> payload) async {
    if (payload.containsKey(_themeKey)) {
      await setThemeMode(_parseThemeMode(payload[_themeKey] as String?));
    }
    if (payload[_banglaKey] is bool) {
      await setBangla(payload[_banglaKey] as bool);
    }
  }

  /// Ready-to-use offline encrypted backup & restore engine.
  VaultBackupEngine createVaultEngine() {
    return VaultBackupEngine(
      appId: AppConfig.packageId,
      schemaVersion: 1,
      adapter: CallbackVaultAdapter(
        onExport: exportVaultData,
        onImport: importVaultData,
      ),
    );
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
