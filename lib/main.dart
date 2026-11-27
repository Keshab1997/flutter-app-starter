import 'package:app_pulse_kit/app_pulse_kit.dart';
import 'package:flutter/material.dart';

import 'app_config.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final pulse = await AppPulse.init(
    configUrl: AppConfig.pulseConfigUrl,
    fallbackConfig: const PulseConfig(
      flags: <String, dynamic>{'show_welcome_card': true},
    ),
  );

  runApp(StarterApp(pulseController: pulse));
}

class StarterApp extends StatefulWidget {
  const StarterApp({
    super.key,
    required this.pulseController,
  });

  final AppPulseController pulseController;

  @override
  State<StarterApp> createState() => _StarterAppState();
}

class _StarterAppState extends State<StarterApp> {
  bool _isDark = false;
  bool _isBangla = AppConfig.defaultBangla;

  @override
  Widget build(BuildContext context) {
    final strings =
        _isBangla ? const PulseStrings.bn() : const PulseStrings.en();

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: AppPulseGate(
        controller: widget.pulseController,
        strings: strings,
        child: HomeScreen(
          pulseController: widget.pulseController,
          isDark: _isDark,
          isBangla: _isBangla,
          onToggleTheme: () => setState(() => _isDark = !_isDark),
          onToggleLanguage: () => setState(() => _isBangla = !_isBangla),
        ),
      ),
    );
  }
}
