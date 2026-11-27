import 'package:app_pulse_kit/app_pulse_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_starter/app_config.dart';
import 'package:flutter_app_starter/main.dart';
import 'package:flutter_app_starter/services/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'StarterApp renders home, notice banner, settings, and 5-tap inspector',
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

    final prefs = AppPreferences.inMemory();

    await tester.pumpWidget(
      StarterApp(
        pulseController: controller,
        preferences: prefs,
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

    // Navigate to SettingsScreen
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    // Switch theme to Dark
    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();
    expect(prefs.themeMode, ThemeMode.dark);

    // 5-tap version tile opens PulseDebugSheet
    final versionTile = find.text(AppConfig.appName);
    for (var i = 0; i < 5; i++) {
      await tester.tap(versionTile);
    }
    await tester.pumpAndSettle();
    expect(find.text('AppPulse Inspector'), findsOneWidget);

    controller.dispose();
    prefs.dispose();
  });
}
