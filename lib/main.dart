import 'package:app_pulse_kit/app_pulse_kit.dart';
import 'package:flutter/material.dart';
import 'package:smart_review_feedback/smart_review_feedback.dart';

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
    SmartReview.init(
      feedbackSink: const EmailFeedbackSink(toEmail: AppConfig.supportEmail),
      appName: AppConfig.appName,
      androidPackageName: AppConfig.packageId,
    ),
  ]);

  runApp(
    StarterApp(
      preferences: results[0] as AppPreferences,
      pulseController: results[1] as AppPulseController,
      reviewController: results[2] as SmartReviewController,
    ),
  );
}

class StarterApp extends StatelessWidget {
  const StarterApp({
    super.key,
    required this.pulseController,
    required this.preferences,
    required this.reviewController,
  });

  final AppPulseController pulseController;
  final AppPreferences preferences;
  final SmartReviewController reviewController;

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
              reviewController: reviewController,
            ),
          ),
        );
      },
    );
  }
}
