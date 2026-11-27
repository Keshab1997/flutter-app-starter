/// Central app identity & remote config metadata.
///
/// Automatically updated by `tool/setup_new_app.py` (or the 1-click
/// "Setup New App" GitHub Action) when creating a new app from this template.
class AppConfig {
  const AppConfig._();

  static const String appName = 'Flutter App Starter';
  static const String pulseConfigUrl =
      'https://raw.githubusercontent.com/Keshab1997/flutter-app-starter/main/pulse.json';
  static const bool defaultBangla = false;
}
