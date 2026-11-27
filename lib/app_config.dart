import 'package:flutter/material.dart';

/// Central app identity, branding, and remote config metadata.
///
/// Automatically updated by `tool/setup_new_app.py` (or the 1-click
/// "Setup New App" GitHub Action) when creating a new app from this template.
class AppConfig {
  const AppConfig._();

  static const String appName = 'Flutter App Starter';
  static const String packageId = 'com.keshab.flutter_app_starter';
  static const Color seedColor = Color(0xFF3F51B5);
  static const String pulseConfigUrl =
      'https://raw.githubusercontent.com/Keshab1997/flutter-app-starter/main/pulse.json';
  static const String privacyPolicyUrl =
      'https://github.com/Keshab1997/flutter-app-starter/blob/main/PRIVACY_POLICY.md';
  static const String supportEmail = 'support@example.com';
  static const bool defaultBangla = false;
}
