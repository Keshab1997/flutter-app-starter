import 'dart:async';
import 'dart:convert';

import 'package:app_pulse_kit/app_pulse_kit.dart';
import 'package:bangla_kit/bangla_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_vault_backup/local_vault_backup.dart';
import 'package:smart_crash_diagnostics_kit/smart_crash_diagnostics_kit.dart';
import 'package:smart_legal_consent_kit/smart_legal_consent_kit.dart';
import 'package:smart_onboarding_kit/smart_onboarding_kit.dart';
import 'package:smart_review_feedback/smart_review_feedback.dart';
import 'package:smart_share_card/smart_share_card.dart';

import '../app_config.dart';
import '../main.dart';
import '../services/app_preferences.dart';

/// Ready-made Material 3 Settings screen with persistent ThemeMode,
/// EN / বাংলা toggle (`bangla_kit`), encrypted Backup & Restore
/// (`local_vault_backup`), Share Card preview (`smart_share_card`), App Tour
/// (`smart_onboarding_kit`), offline Crash Diagnostics
/// (`smart_crash_diagnostics_kit`), remote update check (`app_pulse_kit`),
/// Rate & Feedback (`smart_review_feedback`), Privacy Policy link, and a
/// hidden 5-tap version card opening `PulseDebugSheet` for QA.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.pulseController,
    required this.preferences,
    required this.reviewController,
    this.diagnosticsController,
    this.onboardingController,
    this.legalController,
  });

  final AppPulseController pulseController;
  final AppPreferences preferences;
  final SmartReviewController reviewController;
  final CrashDiagnosticsController? diagnosticsController;
  final OnboardingController? onboardingController;
  final LegalConsentController? legalController;

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

  Future<void> _openVaultSheet(BuildContext context, bool bn) {
    final engine = widget.preferences.createVaultEngine();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            4,
            16,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: VaultBackupCard(
            engine: engine,
            strings: bn ? const VaultStrings.bn() : const VaultStrings.en(),
            onSaveBackup: (Uint8List bytes, String fileName) async {
              await Clipboard.setData(ClipboardData(text: utf8.decode(bytes)));
              if (sheetContext.mounted) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      bn
                          ? '$fileName ক্লিপবোর্ডে কপি হয়েছে'
                          : 'Copied $fileName JSON to clipboard',
                    ),
                  ),
                );
              }
            },
            onPickBackup: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              final raw = data?.text?.trim();
              if (raw == null || raw.isEmpty) return null;
              return Uint8List.fromList(utf8.encode(raw));
            },
          ),
        );
      },
    );
  }

  Future<void> _openShareCardSheet(BuildContext context, bool bn) {
    final cardController = SmartShareCardController();
    const playUrl =
        'https://play.google.com/store/apps/details?id=${AppConfig.packageId}';
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SmartShareCardCanvas(
                controller: cardController,
                child: BrandedShareCardShell(
                  brand: ShareCardBrand(
                    appName: AppConfig.appName,
                    tagline: bn
                        ? 'দ্রুত, সুন্দর ও অফলাইন-ফার্স্ট'
                        : 'Fast, clean & offline-first',
                    playStoreUrl: playUrl,
                  ),
                  badgeText: bn ? 'রেডিমেড' : 'READY',
                  body: Text(
                    bn
                        ? '${AppConfig.appName} ব্যবহার করে দেখুন — বাংলা ও English সাপোর্টসহ!'
                        : 'Try ${AppConfig.appName} on Google Play — built with EN & বাংলা support!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await cardController.capturePng(pixelRatio: 2.0);
                  final caption = ShareCardCaption.score(
                    appName: AppConfig.appName,
                    scoreText: '5★',
                    playStoreUrl: playUrl,
                    bangla: bn,
                  );
                  await Clipboard.setData(ClipboardData(text: caption));
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          bn
                              ? 'শেয়ার ক্যাপশন কপি হয়েছে!'
                              : 'Share caption copied to clipboard!',
                        ),
                      ),
                    );
                    Navigator.of(sheetContext).pop();
                  }
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(bn ? 'ক্যাপশন কপি করুন' : 'Copy Share Caption'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        widget.preferences,
        widget.pulseController,
      ]),
      builder: (BuildContext context, Widget? _) {
        final bn = widget.preferences.isBangla;
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final rawVer =
            'v${widget.pulseController.currentVersion} (build ${widget.pulseController.currentBuildNumber ?? '-'})';
        final displayVer = bn ? BanglaDigits.toBangla(rawVer) : rawVer;

        return Scaffold(
          appBar: AppBar(title: Text(bn ? 'সেটিংস' : 'Settings')),
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
                bn ? 'ডেটা ও টুলস' : 'Data & Tools',
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
                      leading: const Icon(Icons.backup_outlined),
                      title: Text(
                        bn ? 'ব্যাকআপ ও রিস্টোর' : 'Backup & Restore',
                      ),
                      subtitle: Text(
                        bn
                            ? 'পাসওয়ার্ডসহ অফলাইন JSON ব্যাকআপ'
                            : 'Encrypted offline JSON backup & restore',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => unawaited(_openVaultSheet(context, bn)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.ios_share_rounded),
                      title: Text(bn ? 'অ্যাপ শেয়ার কার্ড' : 'Share App Card'),
                      subtitle: Text(
                        bn
                            ? 'বন্ধুদের সাথে ব্র্যান্ডেড কার্ড শেয়ার করুন'
                            : 'Preview branded status card & copy caption',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => unawaited(_openShareCardSheet(context, bn)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.auto_stories_outlined),
                      title: Text(bn ? 'অ্যাপ পরিচিতি' : 'App Tour'),
                      subtitle: Text(
                        bn
                            ? 'শুরুর গাইড আবার দেখুন'
                            : 'Replay the welcome walkthrough',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        unawaited(
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (BuildContext routeCtx) =>
                                  SmartOnboardingFlow(
                                controller: widget.onboardingController,
                                initialBangla: bn,
                                slides: kStarterOnboardingSlides,
                                onCompleted: (bool choseBangla) {
                                  unawaited(
                                    widget.preferences.setBangla(
                                      choseBangla,
                                    ),
                                  );
                                  Navigator.of(routeCtx).pop();
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (widget.diagnosticsController != null) ...<Widget>[
                      const Divider(height: 1),
                      DiagnosticsSettingsTile(
                        controller: widget.diagnosticsController!,
                        strings: bn
                            ? const DiagnosticsStrings.bn()
                            : const DiagnosticsStrings.en(),
                      ),
                    ],
                  ],
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
                            ? (bn
                                ? 'আপনি লেটেস্ট ভার্সনে আছেন'
                                : 'You are up to date')
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
                      leading: const Icon(Icons.star_rate_rounded),
                      title: Text(bn ? 'রেটিং ও মতামত' : 'Rate & Feedback'),
                      subtitle: Text(
                        bn
                            ? 'অ্যাপটি কেমন লাগছে জানান'
                            : 'Share a rating or report an issue',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        unawaited(
                          widget.reviewController.showNow(
                            context,
                            strings: bn
                                ? const ReviewStrings.bn(
                                    appName: AppConfig.appName,
                                  )
                                : const ReviewStrings.en(
                                    appName: AppConfig.appName,
                                  ),
                            screenName: 'SettingsScreen',
                          ),
                        );
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
                      subtitle: Text(displayVer),
                      onTap: _handleVersionTap,
                    ),
                  ],
                ),
              ),
              if (widget.legalController != null) ...<Widget>[
                const SizedBox(height: 20),
                Text(
                  bn ? 'প্রাইভেসি ও ডেটা নিয়ন্ত্রণ' : 'Privacy & Data Control',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                LegalSettingsSection(
                  controller: widget.legalController!,
                  strings: bn ? const LegalStrings.bn() : const LegalStrings(),
                  privacyPolicySummary: bn
                      ? '${AppConfig.appName} অফলাইন-ফার্স্ট হিসেবে কাজ করে। আপনার সেটিংস ও ব্যাকআপ আপনার ফোনেই সুরক্ষিত থাকে।'
                      : '${AppConfig.appName} operates offline-first. Your preferences and local backups remain stored on this device.',
                  onOpenExternalPrivacyUrl: () {
                    unawaited(launchPulseUrl(AppConfig.privacyPolicyUrl));
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
