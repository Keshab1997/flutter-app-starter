import 'dart:async';

import 'package:app_pulse_kit/app_pulse_kit.dart';
import 'package:flutter/material.dart';

import '../app_config.dart';
import '../services/app_preferences.dart';

/// Ready-made Material 3 Settings screen with persistent ThemeMode,
/// EN / বাংলা toggle, remote update check, Privacy Policy link, and a hidden
/// 5-tap version card that opens `PulseDebugSheet` for QA.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.pulseController,
    required this.preferences,
  });

  final AppPulseController pulseController;
  final AppPreferences preferences;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _versionTapCount = 0;

  void _handleVersionTap() {
    _versionTapCount++;
    if (_versionTapCount >= 5) {
      _versionTapCount = 0;
      unawaited(
        PulseDebugSheet.show(context, controller: widget.pulseController),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
        <Listenable>[widget.preferences, widget.pulseController],
      ),
      builder: (BuildContext context, Widget? _) {
        final bn = widget.preferences.isBangla;
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(bn ? 'সেটিংস' : 'Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                bn ? 'দেখতে কেমন হবে' : 'Appearance',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                segments: <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_rounded, size: 18),
                    label: Text(bn ? 'সিস্টেম' : 'System'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_rounded, size: 18),
                    label: Text(bn ? 'লাইট' : 'Light'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_rounded, size: 18),
                    label: Text(bn ? 'ডার্ক' : 'Dark'),
                  ),
                ],
                selected: <ThemeMode>{widget.preferences.themeMode},
                onSelectionChanged: (Set<ThemeMode> next) {
                  if (next.isNotEmpty) {
                    unawaited(widget.preferences.setThemeMode(next.first));
                  }
                },
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: colors.surfaceContainerLow,
                child: SwitchListTile(
                  secondary: const Icon(Icons.translate_rounded),
                  title: Text(bn ? 'বাংলা ভাষা' : 'Bangla Language (বাংলা)'),
                  subtitle: Text(
                    bn
                        ? 'ইংরেজিতে ফিরে যেতে বন্ধ করুন'
                        : 'Switch UI & update dialogs to বাংলা',
                  ),
                  value: bn,
                  onChanged: (bool value) {
                    unawaited(widget.preferences.setBangla(value));
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                bn ? 'অ্যাপ ও আপডেট' : 'App & Updates',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: colors.surfaceContainerLow,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.system_update_rounded),
                      title: Text(bn ? 'আপডেট চেক করুন' : 'Check for updates'),
                      subtitle: Text(
                        widget.pulseController.updateStatus == UpdateStatus.none
                            ? (bn ? 'আপনি লেটেস্ট ভার্সনে আছেন' : 'You are up to date')
                            : widget.pulseController.updateStatus.name,
                      ),
                      trailing: widget.pulseController.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      onTap: () {
                        unawaited(widget.pulseController.refresh());
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(bn ? 'গোপনীয়তা নীতি' : 'Privacy Policy'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () {
                        unawaited(launchPulseUrl(AppConfig.privacyPolicyUrl));
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text(AppConfig.appName),
                      subtitle: Text(
                        'v${widget.pulseController.currentVersion} '
                        '(build ${widget.pulseController.currentBuildNumber ?? '-'})',
                      ),
                      onTap: _handleVersionTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
