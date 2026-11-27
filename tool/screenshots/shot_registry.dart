import 'package:app_pulse_kit/app_pulse_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_starter/screens/home_screen.dart';
import 'package:flutter_app_starter/screens/settings_screen.dart';
import 'package:flutter_app_starter/services/app_preferences.dart';
import 'package:flutter_app_starter/theme/app_theme.dart';
import 'package:smart_review_feedback/smart_review_feedback.dart';

import 'shot_framework.dart';

final AppPulseController _shotPulse = AppPulseController(
  source: MemoryPulseSource(
    const PulseConfig(flags: <String, dynamic>{'show_welcome_card': true}),
  ),
  storage: InMemoryPulseStorage(),
  appVersion: '1.0.0',
  buildNumber: 1,
);

final SmartReviewController _shotReview = SmartReviewController(
  feedbackSink: MemoryFeedbackSink(),
  storage: InMemoryReviewStorage(),
  storeAdapter: FakeStoreReviewAdapter(),
  appName: 'Flutter App Starter',
  appVersion: '1.0.0',
  buildNumber: '1',
);

final AppPreferences _shotPrefs = AppPreferences.inMemory(
  themeMode: ThemeMode.light,
  isBangla: false,
);

final ShotEnv env = ShotEnv(
  app: (Shot shot, Widget home) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: shot.dark ? AppTheme.dark() : AppTheme.light(),
    home: home,
  ),
  setUpAll: () async {
    await _shotPulse.init();
    await _shotReview.init();
  },
);

final List<Shot> shots = <Shot>[
  Shot(
    name: 'home',
    build: () => HomeScreen(
      pulseController: _shotPulse,
      preferences: _shotPrefs,
      reviewController: _shotReview,
    ),
  ),
  Shot(
    name: 'settings',
    build: () => SettingsScreen(
      pulseController: _shotPulse,
      preferences: _shotPrefs,
      reviewController: _shotReview,
    ),
  ),
];
