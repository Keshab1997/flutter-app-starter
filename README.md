# Flutter App Starter (1-Click Template)

**Pre-built Flutter app template for `Keshab1997` — start any new Android + Web Flutter app in 2 clicks (even from your phone).**<br>
**নতুন Flutter app বানানোর ১-ক্লিক template — ফোন বা ব্রাউজার থেকেই ৩০ সেকেন্ডে নতুন app রেডি করুন।**

---

## How to create a new app (2 clicks) / নতুন app বানানোর নিয়ম

1. Click **"Use this template" → "Create a new repository"** at the top of this page (e.g. `my-new-app`).
2. Inside your new repo, open **Actions → `Setup New App (1-Click)` → Run workflow** and choose:
   - **App Name:** e.g. `My New App`
   - **Package ID:** e.g. `com.keshab.mynewapp`
   - **Default Language:** `en` or `bn`
   - **Brand Color:** `indigo` / `teal` / `emerald` / `amber` / `rose` / `violet` / `slate`
   - **Optional:** tick `include_ai_pack` to pre-wire `admin_api_key_manager`

In ~30 seconds, the workflow automatically:
- Renames `pubspec.yaml`, Dart imports, Android `applicationId` / `namespace` / `MainActivity.kt`, Web `index.html` & `manifest.json`, `pulse.json`, `AGENTS.md`, and `README.md`
- Generates matching **brand-colored Android launcher icons & Web favicons**
- Customizes **`PRIVACY_POLICY.md`** for Google Play Console
- Commits and cleans up the one-time setup files!

**Or run locally (CLI):**
```bash
python3 tool/setup_new_app.py \
  --name "My New App" \
  --pkg com.keshab.mynewapp \
  --repo Keshab1997/my-new-app \
  --lang bn \
  --color teal \
  --cleanup
```

---

## What's already wired out of the box / ভেতরে আগে থেকেই যা যা রেডি আছে

- **Flutter `3.50.1`** (`.fvmrc`) + matched **AGP `9.3.1` / Gradle `9.5.0` / Kotlin `2.4.20`** (`check_toolchain` green on Day 1) + `java-version: "21"`.
- **Auto Android Release Signing** (`android/app/build.gradle.kts`) — automatically uses `android/key.properties` when provided locally or by `flutter-builder` CI, with safe debug fallback locally.
- **[`app_pulse_kit`](https://github.com/Keshab1997/app_pulse_kit) + `pulse.json`** — remote soft/force updates, maintenance screen, scheduled notices, feature flags, and hidden 5-tap **`PulseDebugSheet`** in Settings.
- **Persistent Theme (System / Light / Dark) & EN / বাংলা** via `SharedPreferences` + ready-made **`SettingsScreen`** + **`PRIVACY_POLICY.md`**.
- **Global Error Guard** (`AppErrorView`) — clean fallback instead of red/grey screen on unexpected widget errors.
- **[`flutter-builder`](https://github.com/Keshab1997/flutter-builder) workflows (`@v1.18.9`)** + **Agent Pack** + pre-wired local screenshots (`home` & `settings`).
