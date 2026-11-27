import 'package:flutter/material.dart';

import '../app_config.dart';

/// Shared Material 3 Light & Dark themes for the app and local screenshots.
class AppTheme {
  const AppTheme._();

  static Color get seedColor => AppConfig.seedColor;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seedColor,
      brightness: Brightness.light,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seedColor,
      brightness: Brightness.dark,
    );
  }
}
