import 'package:flutter/material.dart';

/// Shared Material 3 Light & Dark themes for the app and local screenshots.
class AppTheme {
  const AppTheme._();

  static const Color seedColor = Color(0xFF3F51B5);

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
