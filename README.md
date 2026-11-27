# Flutter App Starter (1-Click Template)

**Pre-built Flutter app template for `Keshab1997` — start any new Android + Web Flutter app in 2 clicks (even from your phone).**<br>
**নতুন Flutter app বানানোর ১-ক্লিক template — ফোন বা ব্রাউজার থেকেই ৩০ সেকেন্ডে আপনার পছন্দের সব Flutter Kit সহ নতুন app রেডি করুন।**

---

## How to create a new app (2 clicks) / নতুন app বানানোর নিয়ম

1. Click **"Use this template" → "Create a new repository"** at the top of this page (e.g. `my-new-app`).
2. Inside your new repo, open **Actions → `Setup New App (1-Click)` → Run workflow** and choose:
   - **App Name:** e.g. `My New App`
   - **Package ID:** e.g. `com.keshab.mynewapp`
   - **Default Language:** `en` or `bn`
   - **Brand Color:** `indigo` / `teal` / `emerald` / `amber` / `rose` / `violet` / `slate`
   - **App Preset (`app_preset`):**
     - `standard` *(default — 8 zero-plugin core kits pre-wired)*
     - `finance_vault` *(+ `lock`, `pdf`, `upi`, `charts`, `csv_wa`, `notify`)*
     - `scanner_ai` *(+ `ai`, `ai_chat`, `ocr`, `image_prep`, `pdf`)*
     - `quiz_learning` *(+ `quiz`, `streaks`, `voice`, `charts`, `notify`, `ads`)*
     - `ai_assistant` *(+ `ai`, `ai_chat`, `voice`, `ads`, `paywall`)*
     - `arcade_game` *(+ `game_hud`, `streaks`, `ads`, `paywall`)*
     - `cloud_supabase` *(+ `cloud_sync`, `supabase`, `lock`, `notify`)*
     - `cloud_firebase` *(+ `cloud_sync`, `firebase`, `lock`, `notify`)*
     - `monetized_pro` *(+ `ads`, `paywall`, `notify`)*
     - `all_kits` *(adds all 27 kits in 1 click!)*
   - **Extra Kits (`extra_kits`):** comma-separated mix-and-match: `ads,notify,ocr,ai,ai_chat,lock,pdf,upi,charts,quiz,image_prep,csv_wa,cloud_sync,supabase,firebase,game_hud,streaks,paywall,voice` (or `all`)

**Or run locally (CLI):**
```bash
python3 tool/setup_new_app.py \
  --name "My New App" \
  --pkg com.keshab.mynewapp \
  --repo Keshab1997/my-new-app \
  --lang bn \
  --color teal \
  --preset finance_vault \
  --kits ads,paywall \
  --cleanup
```

---

## Pre-wired Zero-Plugin Core Kits (Always Included — 100% Web & Test Safe)

| Package | What's Ready Out of the Box |
|---|---|
| [`app_pulse_kit`](https://github.com/Keshab1997/app_pulse_kit) | Remote soft/force updates, maintenance screen, notice banner, flags & 5-tap `PulseDebugSheet` |
| [`smart_review_feedback`](https://github.com/Keshab1997/smart_review_feedback) | 4–5★ Store Review routing & 1–3★ feedback sheet (EN + বাংলা) |
| [`smart_crash_diagnostics_kit`](https://github.com/Keshab1997/smart_crash_diagnostics_kit) | Offline PII/API-key scrubbed error ring-buffer + `DiagnosticsSettingsTile` & Copy Debug Log |
| [`smart_legal_consent_kit`](https://github.com/Keshab1997/smart_legal_consent_kit) | Play Store offline Privacy/Terms reader, domain disclaimers, AI output report sheet & 2-step **Delete All My Data** |
| [`smart_onboarding_kit`](https://github.com/Keshab1997/smart_onboarding_kit) | 1st-launch EN/বাংলা onboarding walkthrough + Settings *App Tour* replay + `WhatsNewSheet` |
| [`local_vault_backup`](https://github.com/Keshab1997/local_vault_backup) | Password-encrypted offline JSON Backup & Restore sheet in Settings |
| [`bangla_kit`](https://github.com/Keshab1997/bangla_kit) | বাংলা digits (`BanglaDigits`), Indian `₹`/`৳` Lakh/Crore & Bangla date helpers |
| [`smart_share_card`](https://github.com/Keshab1997/smart_share_card) | Branded WhatsApp/Status PNG share card preview & EN/বাংলা caption copy in Settings |

---

## Optional 1-Click Kits (`app_preset` / `extra_kits` / `--with-*`)

| Key (`--kits`) | CLI Flag | Package | Auto-Configuration Applied by `setup_new_app.py` |
|---|---|---|---|
| `ads` | `--with-ads` | [`smart_ad_kit`](https://github.com/Keshab1997/smart_ad_kit) | Adds dep + sample AdMob `APPLICATION_ID` in `AndroidManifest.xml` + `ads_enabled` flag in `pulse.json` + Privacy Policy note |
| `notify` | `--with-notify` | [`smart_notify_kit`](https://github.com/Keshab1997/smart_notify_kit) | Adds dep + Android 13+ `POST_NOTIFICATIONS` permission in `AndroidManifest.xml` |
| `ocr` | `--with-ocr` | [`smart_ocr_ai_bridge`](https://github.com/Keshab1997/smart_ocr_ai_bridge) | Adds dep + ML Kit R8 `-keep` rules in `android/app/proguard-rules.pro` |
| `ai` | `--with-ai-pack` | [`admin_api_key_manager`](https://github.com/Keshab1997/admin_api_key_manager) | Adds Firestore-backed Gemini/OpenRouter key rotation pool + Privacy Policy note |
| `ai_chat` | `--with-ai-chat` | [`smart_ai_chat_kit`](https://github.com/Keshab1997/smart_ai_chat_kit) | Adds daily free AI quota limiter, rewarded-ad credit boost, SHA-256 prompt cache & EN/বাংলা chat UI |
| `lock` | `--with-lock` | [`smart_app_lock_kit`](https://github.com/Keshab1997/smart_app_lock_kit) | Adds salted SHA-256 PIN + biometric `AppLockGate` & `AppLockSettingsTile` |
| `pdf` | `--with-pdf` | [`smart_pdf_export_kit`](https://github.com/Keshab1997/smart_pdf_export_kit) | Adds Bangla-safe pure-Dart PDF ledger, receipt & scanned document exporter |
| `upi` | `--with-upi` | [`smart_upi_qr_kit`](https://github.com/Keshab1997/smart_upi_qr_kit) | Adds NPCI `upi://pay` vector QR payment card & GST/discount/bill-split calculator |
| `charts` | `--with-charts` | [`smart_charts_stats_kit`](https://github.com/Keshab1997/smart_charts_stats_kit) | Adds zero-dep `CustomPainter` bar, donut, trend sparkline & progress ring charts (EN + বাংলা) |
| `quiz` | `--with-quiz` | [`smart_quiz_flashcard_kit`](https://github.com/Keshab1997/smart_quiz_flashcard_kit) | Adds MCQ exam engine with negative marking, persistent `MistakeBank` & SM-2 flashcards |
| `image_prep` | `--with-image-prep` | [`smart_image_prep_kit`](https://github.com/Keshab1997/smart_image_prep_kit) | Adds pure-Dart image resizer, B&W high-contrast scan filter & AI token-saver Base64 compressor |
| `csv_wa` | `--with-csv-wa` | [`smart_csv_whatsapp_kit`](https://github.com/Keshab1997/smart_csv_whatsapp_kit) | Adds Excel Bangla-safe UTF-8 BOM CSV codec & WhatsApp due-reminder/khata builder |
| `cloud_sync` | `--with-cloud-sync` | [`smart_cloud_sync_kit`](https://github.com/Keshab1997/smart_cloud_sync_kit) | Adds offline outbox compaction, Last-Write-Wins HLC resolver & delta pull sync engine |
| `supabase` | `--with-supabase` | [`smart_supabase_kit`](https://github.com/Keshab1997/smart_supabase_kit) | Adds zero-Gradle Supabase Auth (Email/OTP/Guest + Play Store account deletion), PostgREST & RLS SQL |
| `firebase` | `--with-firebase` | [`smart_firebase_kit`](https://github.com/Keshab1997/smart_firebase_kit) | Adds Safe-Boot Firebase Auth (guest-to-email link + Play Store account deletion) & chunked Firestore sync |
| `game_hud` | `--with-game-hud` | [`smart_game_hud_kit`](https://github.com/Keshab1997/smart_game_hud_kit) | Adds casual game HUD, persistent high-score/coins, pause/game-over & rewarded-ad revive |
| `streaks` | `--with-streaks` | [`smart_streaks_gamify_kit`](https://github.com/Keshab1997/smart_streaks_gamify_kit) | Adds daily streaks, freeze shields, XP leveling & 7-day strip |
| `paywall` | `--with-paywall` | [`smart_paywall_pro_kit`](https://github.com/Keshab1997/smart_paywall_pro_kit) | Adds Pro paywall, 24h rewarded pass, SHA-256 promo codes + `BILLING` permission |
| `voice` | `--with-voice` | [`smart_voice_speech_kit`](https://github.com/Keshab1997/smart_voice_speech_kit) | Adds EN/বাংলা TTS & STT controller with danda chunking & learner speed presets |

---

## Toolchain & CI Ready on Day 1

- **Flutter `3.50.1`** (`.fvmrc`) + matched **AGP `9.3.1` / Gradle `9.5.0` / Kotlin `2.4.20`** + `java-version: "21"`.
- **Auto Android Release Signing** (`android/app/build.gradle.kts`) with debug fallback locally.
- **[`flutter-builder`](https://github.com/Keshab1997/flutter-builder) workflows (`@v1.18.9`)** + **Agent Pack** + offline local screenshots (`python3 tool/local_screenshots.py --shot home,settings`).
