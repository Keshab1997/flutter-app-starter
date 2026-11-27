import 'package:app_pulse_kit/app_pulse_kit.dart';
import 'package:flutter/material.dart';

import 'app_config.dart';
import 'screens/home_screen.dart';
import 'services/app_preferences.dart';
import 'theme/app_theme.dart';
import 'widgets/app_error_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorWidget();

  final results = await Future.wait<Object>(<Future<Object>>[
    AppPreferences.load(),
    AppPulse.init(
      configUrl: AppConfig.pulseConfigUrl,
      fallbackConfig: const PulseConfig(
        flags: <String, dynamic>{'show_welcome_card': true},
      ),
    ),
  ]);

  runApp(
    StarterApp(
      preferences: results[0] as AppPreferences,
      pulseController: results[1] as AppPulseController,
    ),
  );
}

class StarterApp extends StatelessWidget {
  const StarterApp({
    super.key,
    required this.pulseController,
    required this.preferences,
  });

  final AppPulseController pulseController;
  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: preferences,
      builder: (BuildContext context, Widget? _) {
        final strings = preferences.isBangla
            ? const PulseStrings.bn()
            : const PulseStrings.en();

        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          themeMode: preferences.themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: AppPulseGate(
            controller: pulseController,
            strings: strings,
            child: HomeScreen(
              pulseController: pulseController,
              preferences: preferences,
            ),
          ),
        );
      },
    );
  }
}
