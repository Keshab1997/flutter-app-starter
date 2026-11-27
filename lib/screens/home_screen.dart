import 'dart:async';

import 'package:app_pulse_kit/app_pulse_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_config.dart';
import '../services/app_preferences.dart';
import 'settings_screen.dart';

/// Clean starter home screen wired with `app_pulse_kit` notice banners,
/// feature flags, persistent Theme/EN-বাংলা switch, Settings navigation, and
/// debug QA inspector.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.pulseController,
    required this.preferences,
  });

  final AppPulseController pulseController;
  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isBangla = preferences.isBangla;
    final strings =
        isBangla ? const PulseStrings.bn() : const PulseStrings.en();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: <Widget>[
          IconButton(
            tooltip: isBangla ? 'Switch to English' : 'বাংলায় দেখুন',
            onPressed: () {
              unawaited(preferences.toggleBangla());
            },
            icon: Text(
              isBangla ? 'EN' : 'বাং',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (kDebugMode)
            IconButton(
              tooltip: 'AppPulse Inspector',
              onPressed: () {
                unawaited(
                  PulseDebugSheet.show(context, controller: pulseController),
                );
              },
              icon: const Icon(Icons.monitor_heart_rounded),
            ),
          IconButton(
            tooltip: isBangla ? 'সেটিংস' : 'Settings',
            onPressed: () {
              unawaited(
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => SettingsScreen(
                      pulseController: pulseController,
                      preferences: preferences,
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          PulseNoticeBanner(
            controller: pulseController,
            strings: strings,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PulseFeatureBuilder.toggle(
                  controller: pulseController,
                  flag: 'show_welcome_card',
                  defaultValue: true,
                  enabledChild: Card(
                    elevation: 0,
                    color: colors.primaryContainer.withValues(alpha: 0.45),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.rocket_launch_rounded,
                            size: 32,
                            color: colors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isBangla
                                ? 'আপনার নতুন অ্যাপ তৈরি!'
                                : 'Your new app is ready!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isBangla
                                ? 'Material 3, রিমোট আপডেট, নোটিশ ব্যানার, সেটিংস ও ফিচার ফ্ল্যাগ আগে থেকেই সেট করা আছে।'
                                : 'Material 3, remote updates, notice banners, persistent settings, and feature flags are pre-wired.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: colors.surfaceContainerLow,
                  child: ListTile(
                    leading: Icon(Icons.verified_rounded, color: colors.primary),
                    title: Text(
                      isBangla ? 'রিমোট কনফিগ স্ট্যাটাস' : 'Remote Config Status',
                    ),
                    subtitle: ListenableBuilder(
                      listenable: pulseController,
                      builder: (BuildContext _, Widget? __) => Text(
                        'v${pulseController.currentVersion} • '
                        '${pulseController.updateStatus.name}',
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Refresh config',
                      onPressed: () {
                        unawaited(pulseController.refresh());
                      },
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
