# Flutter App Starter (1-Click Template)

**Pre-built Flutter app template for `Keshab1997` — start any new Android + Web Flutter app in 2 clicks (even from your phone).**<br>
**নতুন Flutter app বানানোর ১-ক্লিক template — ফোন বা ব্রাউজার থেকেই ৩০ সেকেন্ডে নতুন app রেডি করুন।**

---

## How to create a new app (2 clicks) / নতুন app বানানোর নিয়ম

1. Click **"Use this template" → "Create a new repository"** at the top of this page (e.g. `my-new-app`).
2. Inside your new repo, open **Actions → `Setup New App (1-Click)` → Run workflow** and enter:
   - **App Name:** e.g. `My New App`
   - **Package ID:** e.g. `com.keshab.mynewapp`
   - **Default Language:** `en` or `bn`

In ~30 seconds, the workflow automatically renames `pubspec.yaml`, Android `applicationId` / `namespace` / `MainActivity.kt`, Web `index.html` & `manifest.json`, `pulse.json`, `AGENTS.md`, and `README.md` — then commits and cleans up the one-time setup files.

**Or run locally (CLI):**
```bash
python3 tool/setup_new_app.py \
  --name "My New App" \
  --pkg com.keshab.mynewapp \
  --repo Keshab1997/my-new-app \
  --lang bn \
  --cleanup
```

---

## What's already wired out of the box / ভেতরে আগে থেকেই যা যা রেডি আছে

- **Flutter `3.50.1` (`.fvmrc`)** with matched **AGP `9.3.1` / Gradle `9.5.0` / Kotlin `2.4.20`** (`check_toolchain` green on Day 1) + `java-version: "21"` in Android release workflows.
- **[`app_pulse_kit`](https://github.com/Keshab1997/app_pulse_kit) + `pulse.json`** — remote soft/force updates, maintenance screen, scheduled notices, feature flags, and in-app QA `PulseDebugSheet`.
- **Material 3 Light & Dark theme** + **EN / বাংলা** toggle (`PulseStrings.en()` / `PulseStrings.bn()`).
- **[`flutter-builder`](https://github.com/Keshab1997/flutter-builder) workflows (`@v1.18.9`)** — `ci.yml`, `web-preview.yml`, `manual-build.yml`, `publish-release.yml`, `ui-screenshots.yml`, `widget-tests.yml`, plus `distribution/whatsnew/` (`en-US` & `bn-BD`).
- **Agent Pack** — `AGENTS.md`, `tool/preflight.py`, `tool/agent_loop.py`, `tool/ci_watch.py`, `tool/local_screenshots.py`, and pre-wired `tool/screenshots/shot_registry.dart` (`home` shot ready!).
- **Passing starter widget test** + strict `analysis_options.yaml` + secret-safe `.gitignore`.
