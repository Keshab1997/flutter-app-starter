import 'package:app_pulse_kit/app_pulse_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_starter/app_config.dart';
import 'package:flutter_app_starter/main.dart';
import 'package:flutter_app_starter/services/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_crash_diagnostics_kit/smart_crash_diagnostics_kit.dart';
import 'package:smart_legal_consent_kit/smart_legal_consent_kit.dart';
import 'package:smart_onboarding_kit/smart_onboarding_kit.dart';
import 'package:smart_review_feedback/smart_review_feedback.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'StarterApp renders home, notice banner, settings kits, rating sheet, and 5-tap inspector',
    (WidgetTester tester) async {
      final controller = AppPulseController(
        source: MemoryPulseSource(
          const PulseConfig(
            notices: <PulseNotice>[
              PulseNotice(
                id: 'welcome-test',
                title: 'Live Notice',
                message: 'Everything works offline and online.',
              ),
            ],
            flags: <String, dynamic>{'show_welcome_card': true},
          ),
        ),
        storage: InMemoryPulseStorage(),
        appVersion: '1.0.0',
        buildNumber: 1,
      );
      await controller.init();

      final reviewController = SmartReviewController(
        feedbackSink: MemoryFeedbackSink(),
        storage: InMemoryReviewStorage(),
        storeAdapter: FakeStoreReviewAdapter(),
        appName: AppConfig.appName,
        appVersion: '1.0.0',
        buildNumber: '1',
      );
      await reviewController.init();

      final diagnostics = await CrashDiagnosticsController.init(
        appName: AppConfig.appName,
        installErrorHooks: false,
      );
      final legal = await LegalConsentController.create();
      final onboarding = OnboardingController();
      final prefs = AppPreferences.inMemory();

      await tester.pumpWidget(
        StarterApp(
          pulseController: controller,
          preferences: prefs,
          reviewController: reviewController,
          diagnosticsController: diagnostics,
          onboardingController: onboarding,
          legalController: legal,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live Notice'), findsOneWidget);

      if (AppConfig.defaultBangla) {
        expect(find.text('আপনার নতুন অ্যাপ তৈরি!'), findsOneWidget);
        await tester.tap(find.text('EN'));
        await tester.pumpAndSettle();
        expect(find.text('Your new app is ready!'), findsOneWidget);
      } else {
        expect(find.text('Your new app is ready!'), findsOneWidget);
        await tester.tap(find.text('বাং'));
        await tester.pumpAndSettle();
        expect(find.text('আপনার নতুন অ্যাপ তৈরি!'), findsOneWidget);
      }

      // Navigate to SettingsScreen (currently in বাংলা if defaultBangla == false)
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      // Switch theme to Dark
      await tester.tap(find.byIcon(Icons.dark_mode_rounded));
      await tester.pumpAndSettle();
      expect(prefs.themeMode, ThemeMode.dark);

      // Pre-wired Data & Tools tiles are present
      expect(find.byIcon(Icons.backup_outlined), findsOneWidget);
      expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
      expect(find.byType(DiagnosticsSettingsTile), findsOneWidget);

      // Scroll down to Rate & Feedback tile and open SmartReviewSheet
      await tester.scrollUntilVisible(
        find.byIcon(Icons.star_rate_rounded),
        200,
      );
      await tester.tap(find.byIcon(Icons.star_rate_rounded));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('review_star_5')),
        findsOneWidget,
      );
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // 5-tap version tile opens PulseDebugSheet
      final versionTile = find.text(AppConfig.appName);
      await tester.scrollUntilVisible(versionTile, 200);
      for (var i = 0; i < 5; i++) {
        await tester.tap(versionTile);
      }
      await tester.pumpAndSettle();
      expect(find.text('AppPulse Inspector'), findsOneWidget);

      controller.dispose();
      reviewController.dispose();
      diagnostics.dispose();
      prefs.dispose();
    },
  );

  testWidgets(
    'StarterApp shows SmartOnboardingFlow when initialShowOnboarding is true',
    (WidgetTester tester) async {
      final controller = AppPulseController(
        source: MemoryPulseSource(const PulseConfig()),
        storage: InMemoryPulseStorage(),
        appVersion: '1.0.0',
        buildNumber: 1,
      );
      await controller.init();
      final reviewController = SmartReviewController(
        feedbackSink: MemoryFeedbackSink(),
        storage: InMemoryReviewStorage(),
        storeAdapter: FakeStoreReviewAdapter(),
        appName: AppConfig.appName,
        appVersion: '1.0.0',
        buildNumber: '1',
      );
      await reviewController.init();
      final prefs = AppPreferences.inMemory();

      await tester.pumpWidget(
        StarterApp(
          pulseController: controller,
          preferences: prefs,
          reviewController: reviewController,
          onboardingController: OnboardingController(),
          initialShowOnboarding: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SmartOnboardingFlow), findsOneWidget);

      controller.dispose();
      reviewController.dispose();
      prefs.dispose();
    },
  );
}
