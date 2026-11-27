import 'dart:async';

import 'package:app_pulse_kit/app_pulse_kit.dart';
import 'package:flutter/material.dart';
import 'package:smart_crash_diagnostics_kit/smart_crash_diagnostics_kit.dart';
import 'package:smart_legal_consent_kit/smart_legal_consent_kit.dart';
import 'package:smart_onboarding_kit/smart_onboarding_kit.dart';
import 'package:smart_review_feedback/smart_review_feedback.dart';

import 'app_config.dart';
import 'screens/home_screen.dart';
import 'services/app_preferences.dart';
import 'theme/app_theme.dart';
import 'widgets/app_error_view.dart';

const List<OnboardingSlide> kStarterOnboardingSlides = <OnboardingSlide>[
  OnboardingSlide(
    icon: Icons.rocket_launch_rounded,
    titleEn: 'Fast & Offline-First',
    bodyEn: 'Designed for smooth everyday use — even without internet.',
    titleBn: 'দ্রুত ও অফলাইন-ফার্স্ট',
    bodyBn: 'ইন্টারনেট ছাড়াই প্রতিদিন দ্রুত ও সহজে ব্যবহার করুন।',
  ),
  OnboardingSlide(
    icon: Icons.shield_outlined,
    titleEn: 'Encrypted Local Backups',
    bodyEn: 'Export & restore your data anytime with password protection.',
    titleBn: 'সুরক্ষিত লোকাল ব্যাকআপ',
    bodyBn: 'পাসওয়ার্ড দিয়ে যেকোনো সময় আপনার ডেটা ব্যাকআপ ও রিস্টোর করুন।',
  ),
  OnboardingSlide(
    icon: Icons.translate_rounded,
    titleEn: 'English & বাংলা Ready',
    bodyEn: 'Switch between English, বাংলা, Light, and Dark mode anytime.',
    titleBn: 'বাংলা ও English সাপোর্ট',
    bodyBn: 'যেকোনো সময় বাংলা, ইংরেজি, লাইট ও ডার্ক থিম বদলে নিন।',
  ),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorWidget();

  final onboardingController = OnboardingController();
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
    CrashDiagnosticsController.init(appName: AppConfig.appName),
    onboardingController.hasCompletedOnboarding(),
    LegalConsentController.create(),
  ]);

  final preferences = results[0] as AppPreferences;
  final pulseController = results[1] as AppPulseController;
  final reviewController = results[2] as SmartReviewController;
  final diagnosticsController = results[3] as CrashDiagnosticsController;
  final completedOnboarding = results[4] as bool;
  final legalController = results[5] as LegalConsentController;

  runApp(
    StarterApp(
      preferences: preferences,
      pulseController: pulseController,
      reviewController: reviewController,
      diagnosticsController: diagnosticsController,
      onboardingController: onboardingController,
      legalController: legalController,
      initialShowOnboarding: !completedOnboarding,
    ),
  );
}

class StarterApp extends StatefulWidget {
  const StarterApp({
    super.key,
    required this.pulseController,
    required this.preferences,
    required this.reviewController,
    this.diagnosticsController,
    this.onboardingController,
    this.legalController,
    this.initialShowOnboarding = false,
  });

  final AppPulseController pulseController;
  final AppPreferences preferences;
  final SmartReviewController reviewController;
  final CrashDiagnosticsController? diagnosticsController;
  final OnboardingController? onboardingController;
  final LegalConsentController? legalController;
  final bool initialShowOnboarding;

  @override
  State<StarterApp> createState() => _StarterAppState();
}

class _StarterAppState extends State<StarterApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.initialShowOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.preferences,
      builder: (BuildContext context, Widget? _) {
        final strings = widget.preferences.isBangla
            ? const PulseStrings.bn()
            : const PulseStrings.en();

        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          themeMode: widget.preferences.themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: AppPulseGate(
            controller: widget.pulseController,
            strings: strings,
            child: _showOnboarding
                ? SmartOnboardingFlow(
                    controller: widget.onboardingController,
                    initialBangla: widget.preferences.isBangla,
                    appVersion:
                        widget.pulseController.currentVersion.toString(),
                    slides: kStarterOnboardingSlides,
                    onCompleted: (bool choseBangla) {
                      unawaited(widget.preferences.setBangla(choseBangla));
                      setState(() => _showOnboarding = false);
                    },
                  )
                : HomeScreen(
                    pulseController: widget.pulseController,
                    preferences: widget.preferences,
                    reviewController: widget.reviewController,
                    diagnosticsController: widget.diagnosticsController,
                    onboardingController: widget.onboardingController,
                    legalController: widget.legalController,
                  ),
          ),
        );
      },
    );
  }
}
