#!/usr/bin/env python3
"""1-click initializer for apps created from `Keshab1997/flutter-app-starter`.

Renames the Flutter package, Android applicationId/namespace/MainActivity,
Web manifest/title, `AppConfig` (brand color, pulse URL, privacy policy URL),
`pulse.json`, `PRIVACY_POLICY.md`, `AGENTS.md`, `README.md`, wires any selected
companion `Keshab1997` Flutter kits (dependencies, AndroidManifest permissions,
R8 keep rules, remote kill-switches), and generates brand-colored Android & Web
launcher icons using stdlib Python only.

Usage:
    python3 tool/setup_new_app.py \
      --name "Khoroch Pro" \
      --pkg com.keshab.khorochpro \
      --repo Keshab1997/khoroch-pro \
      --lang bn \
      --color teal \
      --preset finance_vault \
      --kits ads,share

Stdlib only, Python >= 3.8.
"""
from __future__ import annotations

import argparse
import datetime
import json
import os
import re
import shutil
import struct
import sys
import zlib
from pathlib import Path

OLD_DART_PKG = "flutter_app_starter"
OLD_ANDROID_PKG = "com.keshab.flutter_app_starter"
OLD_APP_NAME = "Flutter App Starter"
OLD_REPO = "Keshab1997/flutter-app-starter"

PKG_ID_RE = re.compile(r"^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$")
DART_PKG_RE = re.compile(r"^[a-z][a-z0-9_]*$")
HEX_COLOR_RE = re.compile(r"^#?([0-9A-Fa-f]{6})$")

COLOR_PRESETS: dict[str, str] = {
    "indigo": "#3F51B5",
    "teal": "#0F766E",
    "emerald": "#15803D",
    "amber": "#B45309",
    "rose": "#BE123C",
    "violet": "#7C3AED",
    "slate": "#334155",
}

# Pre-wired zero-native-plugin kits already inside flutter-app-starter:
DEFAULT_CORE_KITS: list[tuple[str, str]] = [
    ("app_pulse_kit", "Remote soft/force updates, maintenance, notices & flags"),
    ("smart_review_feedback", "4-5★ Play Store review gate & 1-3★ feedback sheet"),
    ("smart_crash_diagnostics_kit", "Offline PII-scrubbed crash & error ring-buffer"),
    ("smart_legal_consent_kit", "Play Store privacy/terms viewer, AI output flag & 2-step Delete All My Data"),
    ("smart_onboarding_kit", "1st-launch EN/বাংলা walkthrough & What's New sheet"),
    ("local_vault_backup", "Encrypted offline JSON backup & restore"),
    ("bangla_kit", "Bangla digits, Indian ₹/৳ Lakh/Crore & dates"),
    ("smart_share_card", "Branded WhatsApp / Status PNG share cards"),
]

# Optional 1-click kits selectable via --preset, --kits, or --with-<slug>:
OPTIONAL_KITS: dict[str, tuple[str, str]] = {
    "ads": (
        "smart_ad_kit",
        "AdMob banners, capped interstitials, rewarded prompts & remote kill-switch",
    ),
    "notify": (
        "smart_notify_kit",
        "Local reminders, daily streak nudges & Quiet Hours",
    ),
    "ocr": (
        "smart_ocr_ai_bridge",
        "5-script on-device ML Kit OCR + AI failover bridge",
    ),
    "ai": (
        "admin_api_key_manager",
        "Firestore-backed Gemini / OpenRouter API key rotation & health pool",
    ),
    "ai_chat": (
        "smart_ai_chat_kit",
        "Daily free AI quota limiter, rewarded-ad credit boost, SHA-256 prompt cache & chat UI",
    ),
    "lock": (
        "smart_app_lock_kit",
        "Salted SHA-256 PIN & biometric app lock with auto-lock on background",
    ),
    "pdf": (
        "smart_pdf_export_kit",
        "Bangla-safe PDF ledger reports, POS receipts & scanned documents",
    ),
    "upi": (
        "smart_upi_qr_kit",
        "NPCI upi://pay QR payment card & GST/discount/bill-split calculator",
    ),
    "charts": (
        "smart_charts_stats_kit",
        "Pure-Dart CustomPainter bar, donut, trend sparkline & progress ring charts",
    ),
    "quiz": (
        "smart_quiz_flashcard_kit",
        "MCQ exam engine with negative marking, mistake bank & SM-2 flashcards",
    ),
    "image_prep": (
        "smart_image_prep_kit",
        "Pure-Dart image resizer, high-contrast B&W scan filter & AI token-saver compressor",
    ),
    "csv_wa": (
        "smart_csv_whatsapp_kit",
        "Excel Bangla-safe UTF-8 BOM CSV export/import & WhatsApp reminder builder",
    ),
    "cloud_sync": (
        "smart_cloud_sync_kit",
        "Offline outbox compaction, HLC conflict resolver & delta pull sync engine",
    ),
    "supabase": (
        "smart_supabase_kit",
        "Zero-Gradle Supabase Auth (Email/OTP/Guest + account delete), PostgREST & RLS SQL",
    ),
    "firebase": (
        "smart_firebase_kit",
        "Safe-Boot Firebase Auth (guest-to-email link + account delete) & chunked Firestore sync",
    ),
    "game_hud": (
        "smart_game_hud_kit",
        "Casual game HUD, high-score & coin wallet, pause/game-over & rewarded revive",
    ),
    "streaks": (
        "smart_streaks_gamify_kit",
        "Daily streaks, freeze shields, XP leveling & 7-day strip",
    ),
    "paywall": (
        "smart_paywall_pro_kit",
        "Pro upgrade sheet, 24h rewarded ad-free pass & SHA-256 promo codes",
    ),
    "voice": (
        "smart_voice_speech_kit",
        "EN/বাংলা TTS & STT controller with danda chunking & speed presets",
    ),
    "state_views": (
        "smart_state_views_kit",
        "Skeleton shimmer loader, empty states, offline/server error retry & SmartAsyncStateView",
    ),
    "form_inputs": (
        "smart_form_inputs_kit",
        "Bangla-digit-safe (০-৯ & 0-9) currency/number formatters, India/BD phone & UPI validators",
    ),
    "search_filter": (
        "smart_search_filter_kit",
        "Bangla-safe debounced fuzzy search, persistent recent searches, date-range chips & sort sheet",
    ),
    "permissions": (
        "smart_permission_kit",
        "Play Store permission rationale sheet, permanent-denial App Settings recovery & gateway",
    ),
    "help_faq": (
        "smart_help_faq_kit",
        "Searchable offline EN/বাংলা FAQ center, dismissible quick-tip banners & 1-tap support card",
    ),
    "updater": (
        "smart_app_updater_kit",
        "Play Store Flexible In-App Update + GitHub Release/v* tag auto-updater & Update Center",
    ),
}

KIT_ALIASES: dict[str, str] = {
    "smart_ad_kit": "ads",
    "ad": "ads",
    "admob": "ads",
    "smart_notify_kit": "notify",
    "notifications": "notify",
    "smart_ocr_ai_bridge": "ocr",
    "admin_api_key_manager": "ai",
    "ai_pack": "ai",
    "smart_ai_chat_kit": "ai_chat",
    "chat": "ai_chat",
    "smart_app_lock_kit": "lock",
    "app_lock": "lock",
    "pin": "lock",
    "smart_pdf_export_kit": "pdf",
    "smart_upi_qr_kit": "upi",
    "qr": "upi",
    "smart_charts_stats_kit": "charts",
    "chart": "charts",
    "smart_quiz_flashcard_kit": "quiz",
    "flashcards": "quiz",
    "smart_image_prep_kit": "image_prep",
    "image": "image_prep",
    "smart_csv_whatsapp_kit": "csv_wa",
    "csv": "csv_wa",
    "whatsapp": "csv_wa",
    "smart_cloud_sync_kit": "cloud_sync",
    "sync": "cloud_sync",
    "smart_supabase_kit": "supabase",
    "supa": "supabase",
    "smart_firebase_kit": "firebase",
    "fb": "firebase",
    "smart_game_hud_kit": "game_hud",
    "game": "game_hud",
    "smart_streaks_gamify_kit": "streaks",
    "streak": "streaks",
    "smart_paywall_pro_kit": "paywall",
    "pro": "paywall",
    "smart_voice_speech_kit": "voice",
    "tts": "voice",
    "speech": "voice",
    "smart_state_views_kit": "state_views",
    "skeleton": "state_views",
    "smart_form_inputs_kit": "form_inputs",
    "forms": "form_inputs",
    "smart_search_filter_kit": "search_filter",
    "search": "search_filter",
    "smart_permission_kit": "permissions",
    "permission": "permissions",
    "smart_help_faq_kit": "help_faq",
    "faq": "help_faq",
    "help": "help_faq",
    "smart_app_updater_kit": "updater",
    "app_updater": "updater",
    "in_app_update": "updater",
    "github_updater": "updater",
}

APP_PRESETS: dict[str, list[str]] = {
    "standard": [],
    "universal_ux": [
        "updater",
        "state_views",
        "form_inputs",
        "search_filter",
        "permissions",
        "help_faq",
    ],
    "finance_vault": [
        "updater",
        "lock",
        "pdf",
        "upi",
        "charts",
        "csv_wa",
        "notify",
        "state_views",
        "form_inputs",
        "search_filter",
        "help_faq",
    ],
    "scanner_ai": [
        "updater",
        "ai",
        "ai_chat",
        "ocr",
        "image_prep",
        "pdf",
        "permissions",
        "state_views",
        "search_filter",
        "help_faq",
    ],
    "quiz_learning": [
        "quiz",
        "streaks",
        "voice",
        "charts",
        "notify",
        "ads",
        "state_views",
        "search_filter",
        "help_faq",
    ],
    "ai_assistant": [
        "ai",
        "ai_chat",
        "voice",
        "ads",
        "paywall",
        "permissions",
        "state_views",
        "help_faq",
    ],
    "arcade_game": ["game_hud", "streaks", "ads", "paywall"],
    "cloud_supabase": ["cloud_sync", "supabase", "lock", "notify", "state_views"],
    "cloud_firebase": ["cloud_sync", "firebase", "lock", "notify", "state_views"],
    "monetized_pro": ["ads", "paywall", "notify", "help_faq"],
    "all_kits": sorted(OPTIONAL_KITS.keys()),
}

SAMPLE_ADMOB_APP_ID = "ca-app-pub-3940256099942544~3347511713"


def resolve_selected_kits(
    preset: str,
    kits_csv: str,
    explicit_flags: set[str],
) -> list[str]:
    if preset not in APP_PRESETS:
        raise ValueError(
            f"Unknown --preset {preset!r} (expected one of {sorted(APP_PRESETS)})"
        )
    chosen: set[str] = set(APP_PRESETS[preset]) | set(explicit_flags)

    if kits_csv.strip():
        for raw_token in re.split(r"[,\s+]+", kits_csv.strip().lower()):
            if not raw_token or raw_token == "none":
                continue
            if raw_token in ("all", "all_kits", "*"):
                chosen.update(OPTIONAL_KITS.keys())
                continue
            canonical = KIT_ALIASES.get(raw_token, raw_token)
            if canonical not in OPTIONAL_KITS:
                raise ValueError(
                    f"Unknown kit {raw_token!r} in --kits "
                    f"(available: {', '.join(sorted(OPTIONAL_KITS))}, or 'all')"
                )
            chosen.add(canonical)

    return sorted(chosen)


def resolve_hex_color(raw: str) -> str:
    key = raw.strip().lower()
    if key in COLOR_PRESETS:
        return COLOR_PRESETS[key]
    m = HEX_COLOR_RE.match(raw.strip())
    if not m:
        raise ValueError(
            f"Invalid --color {raw!r} (expected preset {sorted(COLOR_PRESETS)} or #RRGGBB)"
        )
    return f"#{m.group(1).upper()}"


def slugify_dart_pkg(app_name: str, package_id: str) -> str:
    tail = package_id.rsplit(".", 1)[-1]
    candidate = re.sub(r"[^a-z0-9_]+", "_", tail.lower()).strip("_")
    if candidate and DART_PKG_RE.match(candidate):
        return candidate
    fallback = re.sub(r"[^a-z0-9_]+", "_", app_name.lower()).strip("_")
    if not fallback or not fallback[0].isalpha():
        fallback = f"app_{fallback or 'starter'}"
    return fallback


def replace_in_file(path: Path, replacements: list[tuple[str, str]]) -> bool:
    if not path.is_file():
        return False
    original = path.read_text(encoding="utf-8")
    updated = original
    for old, new in replacements:
        updated = updated.replace(old, new)
    if updated == original:
        return False
    path.write_text(updated, encoding="utf-8")
    return True


def _png_chunk(chunk_type: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(chunk_type + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + chunk_type + data + struct.pack(">I", crc)


def render_brand_icon_png(size: int, hex_color: str, *, maskable: bool = False) -> bytes:
    """Render a crisp rounded-square gradient app icon with a geometric inner
    badge using pure Python stdlib (no Pillow required)."""
    hex_digits = hex_color.lstrip("#")
    r0 = int(hex_digits[0:2], 16)
    g0 = int(hex_digits[2:4], 16)
    b0 = int(hex_digits[4:6], 16)

    r_hi = min(255, int(r0 * 1.18 + 20))
    g_hi = min(255, int(g0 * 1.18 + 20))
    b_hi = min(255, int(b0 * 1.18 + 20))
    r_lo = max(0, int(r0 * 0.72))
    g_lo = max(0, int(g0 * 0.72))
    b_lo = max(0, int(b0 * 0.72))

    margin = 0.0 if maskable else size * 0.05
    radius = 0.0 if maskable else size * 0.22
    cx = (size - 1) / 2.0
    cy = (size - 1) / 2.0
    outer_r = size * 0.26
    inner_r = size * 0.13
    ring_w = max(1.5, size * 0.055)

    rows = bytearray()
    for y in range(size):
        rows.append(0)
        yf = float(y)
        for x in range(size):
            xf = float(x)
            if not maskable:
                dx = max(margin + radius - xf, 0.0, xf - (size - 1 - margin - radius))
                dy = max(margin + radius - yf, 0.0, yf - (size - 1 - margin - radius))
                if dx > 0.0 or dy > 0.0:
                    dist = (dx * dx + dy * dy) ** 0.5
                    if dist > radius:
                        rows.extend((0, 0, 0, 0))
                        continue

            t = (xf + yf) / max(1.0, 2.0 * (size - 1))
            r = int(r_hi + (r_lo - r_hi) * t)
            g = int(g_hi + (g_lo - g_hi) * t)
            b = int(b_hi + (b_lo - b_hi) * t)

            dd = ((xf - cx) ** 2 + (yf - cy) ** 2) ** 0.5
            if abs(dd - outer_r) <= ring_w / 2.0 or dd <= inner_r:
                r = int(r * 0.08 + 255 * 0.92)
                g = int(g * 0.08 + 255 * 0.92)
                b = int(b * 0.08 + 255 * 0.92)

            rows.extend((r, g, b, 255))

    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    compressed = zlib.compress(bytes(rows), level=6)
    return (
        b"\x89PNG\r\n\x1a\n"
        + _png_chunk(b"IHDR", ihdr)
        + _png_chunk(b"IDAT", compressed)
        + _png_chunk(b"IEND", b"")
    )


def generate_icons(root: Path, hex_color: str) -> None:
    targets: list[tuple[Path, int, bool]] = [
        (root / "android/app/src/main/res/mipmap-mdpi/ic_launcher.png", 48, False),
        (root / "android/app/src/main/res/mipmap-hdpi/ic_launcher.png", 72, False),
        (root / "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", 96, False),
        (root / "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", 144, False),
        (root / "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", 192, False),
        (root / "web/favicon.png", 32, False),
        (root / "web/icons/Icon-192.png", 192, False),
        (root / "web/icons/Icon-512.png", 512, False),
        (root / "web/icons/Icon-maskable-192.png", 192, True),
        (root / "web/icons/Icon-maskable-512.png", 512, True),
    ]
    for path, size, maskable in targets:
        if path.parent.is_dir():
            path.write_bytes(render_brand_icon_png(size, hex_color, maskable=maskable))


def move_main_activity(root: Path, new_pkg: str) -> None:
    kotlin_root = root / "android" / "app" / "src" / "main" / "kotlin"
    old_file = kotlin_root / Path(*OLD_ANDROID_PKG.split(".")) / "MainActivity.kt"
    new_dir = kotlin_root / Path(*new_pkg.split("."))
    new_file = new_dir / "MainActivity.kt"

    if not old_file.is_file():
        return

    content = old_file.read_text(encoding="utf-8")
    content = content.replace(f"package {OLD_ANDROID_PKG}", f"package {new_pkg}")
    new_dir.mkdir(parents=True, exist_ok=True)
    new_file.write_text(content, encoding="utf-8")

    if old_file.resolve() != new_file.resolve():
        old_file.unlink()
        parent = old_file.parent
        while parent != kotlin_root and parent.exists():
            try:
                parent.rmdir()
            except OSError:
                break
            parent = parent.parent


def configure_android_for_kits(root: Path, selected_kits: list[str]) -> None:
    manifest_path = root / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    if manifest_path.is_file():
        manifest = manifest_path.read_text(encoding="utf-8")
        permissions_to_add: list[str] = []
        if "notify" in selected_kits:
            permissions_to_add.append("android.permission.POST_NOTIFICATIONS")
        if "paywall" in selected_kits:
            permissions_to_add.append("com.android.vending.BILLING")

        for perm in permissions_to_add:
            tag = f'<uses-permission android:name="{perm}" />'
            if perm not in manifest:
                manifest = manifest.replace(
                    '<uses-permission android:name="android.permission.INTERNET" />',
                    f'<uses-permission android:name="android.permission.INTERNET" />\n    {tag}',
                    1,
                )

        if "ads" in selected_kits and "com.google.android.gms.ads.APPLICATION_ID" not in manifest:
            admob_meta = (
                "        <!-- Sample AdMob App ID (replace before Play Store release) -->\n"
                "        <meta-data\n"
                '            android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
                f'            android:value="{SAMPLE_ADMOB_APP_ID}" />\n'
            )
            manifest = manifest.replace(
                "    </application>",
                f"{admob_meta}    </application>",
                1,
            )

        manifest_path.write_text(manifest, encoding="utf-8")

    if "ocr" in selected_kits:
        proguard_path = root / "android" / "app" / "proguard-rules.pro"
        if proguard_path.is_file():
            rules = proguard_path.read_text(encoding="utf-8")
            if "com.google.mlkit" not in rules:
                rules += (
                    "\n# ML Kit on-device OCR keep rules (smart_ocr_ai_bridge)\n"
                    "-keep class com.google.mlkit.** { *; }\n"
                    "-dontwarn com.google.mlkit.**\n"
                )
                proguard_path.write_text(rules, encoding="utf-8")


def write_privacy_policy(
    root: Path,
    app_name: str,
    package_id: str,
    repo: str,
    selected_kits: list[str],
) -> None:
    today = datetime.date.today().isoformat()
    third_party_lines = [
        "- By default, core preferences, encrypted backups, and error diagnostics stay offline on your device."
    ]
    if "ads" in selected_kits:
        third_party_lines.append(
            "- **Google AdMob (`smart_ad_kit`)**: Used to display banners/interstitial/rewarded ads with consent and remote kill-switch support."
        )
    if "ai" in selected_kits or "ai_chat" in selected_kits or "ocr" in selected_kits:
        third_party_lines.append(
            "- **AI / OCR Processing**: Text or images explicitly submitted by the user for AI analysis are sent over HTTPS solely to fulfill that request."
        )
    if "paywall" in selected_kits:
        third_party_lines.append(
            "- **Google Play Billing**: Purchases and subscriptions are processed securely by Google Play."
        )
    if "supabase" in selected_kits or "firebase" in selected_kits or "cloud_sync" in selected_kits:
        third_party_lines.append(
            "- **Optional Cloud Account & Sync**: If you sign in to sync data across devices, you can permanently delete your cloud account and synced data anytime from inside Settings."
        )
    third_party_block = "\n".join(third_party_lines)

    content = f"""# Privacy Policy — {app_name}

**Last updated:** {today}

**{app_name}** (`{package_id}`) respects your privacy.

## Data We Collect
- By default, this app operates offline-first and stores user preferences (such as theme and language selection) locally on your device.
- The app fetches a read-only remote configuration file (`pulse.json`) solely to check for app updates, maintenance notices, and feature availability. No personal data is transmitted during this check.

## Third-Party Services & Optional Modules
{third_party_block}

## Contact
If you have any questions about this Privacy Policy, please contact the developer via the project repository:
https://github.com/{repo}
"""
    (root / "PRIVACY_POLICY.md").write_text(content, encoding="utf-8")


def write_starter_readme(
    root: Path,
    app_name: str,
    description: str,
    package_id: str,
    repo: str,
    selected_kits: list[str],
) -> None:
    kit_bullets = [
        f"- **`{pkg}`** — {desc}" for pkg, desc in DEFAULT_CORE_KITS
    ]
    for slug in selected_kits:
        pkg, desc = OPTIONAL_KITS[slug]
        kit_bullets.append(f"- **`{pkg}`** — {desc}")
    kits_md = "\n".join(kit_bullets)

    content = f"""# {app_name}

{description}

## Quick commands

```bash
# Fast local preflight (~1s)
python3 tool/preflight.py

# Analyze & test
flutter analyze --fatal-infos
flutter test

# Local screenshots (offline, ~1s/screen)
python3 tool/local_screenshots.py --shot home,settings
```

## Included Flutter Kits

{kits_md}

## Remote config (`app_pulse_kit`)

Edit [`pulse.json`](pulse.json) at the repo root to manage:
- Soft & force updates (`update`)
- Emergency maintenance mode (`maintenance`)
- Scheduled in-app notices (`notices`)
- Remote feature flags (`flags`)

- **Android package:** `{package_id}`
- **Privacy Policy:** [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md)
- **Repository:** `https://github.com/{repo}`
"""
    (root / "README.md").write_text(content, encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Configure a new Flutter app from flutter-app-starter.")
    ap.add_argument("--root", default=".", help="Repository root (default: .)")
    ap.add_argument("--name", required=True, help='Display app name, e.g. "My New App"')
    ap.add_argument("--pkg", required=True, help="Android applicationId, e.g. com.keshab.mynewapp")
    ap.add_argument("--dart-name", default=None, help="Optional Dart package name (snake_case)")
    ap.add_argument("--description", default=None, help="Short app description")
    ap.add_argument(
        "--repo",
        default=os.environ.get("GITHUB_REPOSITORY", ""),
        help="GitHub repo slug (owner/repo) for pulse.json & Privacy Policy URLs",
    )
    ap.add_argument("--lang", choices=["en", "bn"], default="en", help="Default UI language")
    ap.add_argument(
        "--color",
        default="indigo",
        help=f"Brand seed color preset ({', '.join(sorted(COLOR_PRESETS))}) or #RRGGBB",
    )
    ap.add_argument(
        "--email",
        default="support@example.com",
        help="Support / feedback email for smart_review_feedback",
    )
    ap.add_argument(
        "--preset",
        choices=sorted(APP_PRESETS.keys()),
        default="standard",
        help="App starter kit bundle preset",
    )
    ap.add_argument(
        "--kits",
        default="",
        help=(
            "Comma-separated extra kits to add: "
            f"{','.join(sorted(OPTIONAL_KITS.keys()))} (or 'all')"
        ),
    )
    ap.add_argument("--with-ai-pack", action="store_true", help="Add admin_api_key_manager")
    ap.add_argument("--with-ai-chat", action="store_true", help="Add smart_ai_chat_kit")
    ap.add_argument("--with-ads", action="store_true", help="Add smart_ad_kit")
    ap.add_argument("--with-notify", action="store_true", help="Add smart_notify_kit")
    ap.add_argument("--with-ocr", action="store_true", help="Add smart_ocr_ai_bridge")
    ap.add_argument("--with-lock", action="store_true", help="Add smart_app_lock_kit")
    ap.add_argument("--with-pdf", action="store_true", help="Add smart_pdf_export_kit")
    ap.add_argument("--with-upi", action="store_true", help="Add smart_upi_qr_kit")
    ap.add_argument("--with-charts", action="store_true", help="Add smart_charts_stats_kit")
    ap.add_argument("--with-quiz", action="store_true", help="Add smart_quiz_flashcard_kit")
    ap.add_argument("--with-image-prep", action="store_true", help="Add smart_image_prep_kit")
    ap.add_argument("--with-csv-wa", action="store_true", help="Add smart_csv_whatsapp_kit")
    ap.add_argument("--with-cloud-sync", action="store_true", help="Add smart_cloud_sync_kit")
    ap.add_argument("--with-supabase", action="store_true", help="Add smart_supabase_kit")
    ap.add_argument("--with-firebase", action="store_true", help="Add smart_firebase_kit")
    ap.add_argument("--with-game-hud", action="store_true", help="Add smart_game_hud_kit")
    ap.add_argument("--with-streaks", action="store_true", help="Add smart_streaks_gamify_kit")
    ap.add_argument("--with-paywall", action="store_true", help="Add smart_paywall_pro_kit")
    ap.add_argument("--with-voice", action="store_true", help="Add smart_voice_speech_kit")
    ap.add_argument("--with-state-views", action="store_true", help="Add smart_state_views_kit")
    ap.add_argument("--with-form-inputs", action="store_true", help="Add smart_form_inputs_kit")
    ap.add_argument("--with-search-filter", action="store_true", help="Add smart_search_filter_kit")
    ap.add_argument("--with-permissions", action="store_true", help="Add smart_permission_kit")
    ap.add_argument("--with-help-faq", action="store_true", help="Add smart_help_faq_kit")
    ap.add_argument("--with-updater", action="store_true", help="Add smart_app_updater_kit")
    ap.add_argument("--with-all-kits", action="store_true", help="Add all optional Flutter kits")
    ap.add_argument("--cleanup", action="store_true", help="Remove setup script & workflow after running")
    ap.add_argument(
        "--allow-template-repo",
        action="store_true",
        help="Allow running even when --repo is the template repo itself (tests only)",
    )
    args = ap.parse_args(argv)

    root = Path(args.root).resolve()
    app_name = args.name.strip()
    package_id = args.pkg.strip().lower()
    repo = args.repo.strip() or f"Keshab1997/{re.sub(r'[^a-z0-9-]+', '-', app_name.lower()).strip('-')}"

    if not app_name:
        print("setup_new_app: ERROR: --name must not be empty", file=sys.stderr)
        return 2
    if not PKG_ID_RE.match(package_id):
        print(
            f"setup_new_app: ERROR: invalid --pkg {package_id!r} (expected e.g. com.keshab.myapp)",
            file=sys.stderr,
        )
        return 2
    if repo.lower() == OLD_REPO.lower() and not args.allow_template_repo:
        print(
            f"setup_new_app: REFUSED to mutate template repository {OLD_REPO}. "
            "Use 'Use this template' to create a new repository first.",
            file=sys.stderr,
        )
        return 2

    explicit_flags: set[str] = set()
    flag_map = {
        "ai": args.with_ai_pack,
        "ai_chat": args.with_ai_chat,
        "ads": args.with_ads,
        "notify": args.with_notify,
        "ocr": args.with_ocr,
        "lock": args.with_lock,
        "pdf": args.with_pdf,
        "upi": args.with_upi,
        "charts": args.with_charts,
        "quiz": args.with_quiz,
        "image_prep": args.with_image_prep,
        "csv_wa": args.with_csv_wa,
        "cloud_sync": args.with_cloud_sync,
        "supabase": args.with_supabase,
        "firebase": args.with_firebase,
        "game_hud": args.with_game_hud,
        "streaks": args.with_streaks,
        "paywall": args.with_paywall,
        "voice": args.with_voice,
        "state_views": args.with_state_views,
        "form_inputs": args.with_form_inputs,
        "search_filter": args.with_search_filter,
        "permissions": args.with_permissions,
        "help_faq": args.with_help_faq,
        "updater": args.with_updater,
    }
    for slug, active in flag_map.items():
        if active:
            explicit_flags.add(slug)
    if args.with_all_kits:
        explicit_flags.update(OPTIONAL_KITS.keys())

    try:
        hex_color = resolve_hex_color(args.color)
        selected_kits = resolve_selected_kits(args.preset, args.kits, explicit_flags)
    except ValueError as exc:
        print(f"setup_new_app: ERROR: {exc}", file=sys.stderr)
        return 2

    dart_pkg = args.dart_name.strip().lower() if args.dart_name else slugify_dart_pkg(app_name, package_id)
    if not DART_PKG_RE.match(dart_pkg):
        print(f"setup_new_app: ERROR: invalid --dart-name {dart_pkg!r}", file=sys.stderr)
        return 2

    description = (args.description or f"{app_name} — Flutter app.").strip()
    pulse_url = f"https://raw.githubusercontent.com/{repo}/main/pulse.json"
    privacy_url = f"https://github.com/{repo}/blob/main/PRIVACY_POLICY.md"
    play_url = f"https://play.google.com/store/apps/details?id={package_id}"
    dart_color = f"0xFF{hex_color.lstrip('#')}"

    # 1. pubspec.yaml + optional kits
    pubspec = root / "pubspec.yaml"
    if pubspec.is_file():
        txt = pubspec.read_text(encoding="utf-8")
        txt = re.sub(r"^name:\s*.*$", f"name: {dart_pkg}", txt, count=1, flags=re.M)
        txt = re.sub(r"^description:\s*.*$", f"description: {description}", txt, count=1, flags=re.M)
        extra_blocks: list[str] = []
        for slug in selected_kits:
            pkg_name, _ = OPTIONAL_KITS[slug]
            if f"  {pkg_name}:" not in txt:
                extra_blocks.append(
                    f"  {pkg_name}:\n"
                    "    git:\n"
                    f"      url: https://github.com/Keshab1997/{pkg_name}.git\n"
                )
        if extra_blocks:
            joined = "".join(extra_blocks)
            txt = txt.replace(
                "  shared_preferences: ^2.2.2\n",
                f"  shared_preferences: ^2.2.2\n{joined}",
                1,
            )
        pubspec.write_text(txt, encoding="utf-8")

    # 2. Dart package imports across lib/, test/, tool/screenshots/
    for folder in ("lib", "test", "tool/screenshots"):
        base = root / folder
        if not base.is_dir():
            continue
        for dart_file in base.rglob("*.dart"):
            replace_in_file(
                dart_file,
                [(f"package:{OLD_DART_PKG}/", f"package:{dart_pkg}/")],
            )

    # 3. lib/app_config.dart
    app_config = root / "lib" / "app_config.dart"
    if app_config.is_file():
        escaped_name = app_name.replace("\\", "\\\\").replace("'", "\\'")
        escaped_email = args.email.strip().replace("\\", "\\\\").replace("'", "\\'")
        app_config.write_text(
            f"""import 'package:flutter/material.dart';

/// Central app identity, branding, and remote config metadata.
class AppConfig {{
  const AppConfig._();

  static const String appName = '{escaped_name}';
  static const String packageId = '{package_id}';
  static const Color seedColor = Color({dart_color});
  static const String pulseConfigUrl =
      '{pulse_url}';
  static const String privacyPolicyUrl =
      '{privacy_url}';
  static const String supportEmail = '{escaped_email}';
  static const bool defaultBangla = {'true' if args.lang == 'bn' else 'false'};
}}
""",
            encoding="utf-8",
        )

    # 4. pulse.json (+ remote ads_enabled kill-switch when ads kit is selected)
    pulse_path = root / "pulse.json"
    if pulse_path.is_file():
        data = json.loads(pulse_path.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            update = data.setdefault("update", {})
            if isinstance(update, dict):
                update["androidUrl"] = play_url
            flags = data.setdefault("flags", {})
            if isinstance(flags, dict) and "ads" in selected_kits:
                flags.setdefault("ads_enabled", True)
            pulse_path.write_text(
                json.dumps(data, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )

    # 5. Android files + kit-specific permissions/proguard
    replace_in_file(
        root / "android" / "app" / "build.gradle.kts",
        [(OLD_ANDROID_PKG, package_id)],
    )
    replace_in_file(
        root / "android" / "app" / "src" / "main" / "AndroidManifest.xml",
        [(f'android:label="{OLD_DART_PKG}"', f'android:label="{app_name}"')],
    )
    move_main_activity(root, package_id)
    configure_android_for_kits(root, selected_kits)

    # 6. Web files
    replace_in_file(
        root / "web" / "index.html",
        [
            (f"<title>{OLD_DART_PKG}</title>", f"<title>{app_name}</title>"),
            (f'content="{OLD_DART_PKG}"', f'content="{app_name}"'),
            (
                "1-click Flutter starter template with app_pulse_kit, Material 3, EN/BN UI, and flutter-builder CI.",
                description,
            ),
        ],
    )
    manifest = root / "web" / "manifest.json"
    if manifest.is_file():
        mdata = json.loads(manifest.read_text(encoding="utf-8"))
        mdata["name"] = app_name
        mdata["short_name"] = app_name
        mdata["description"] = description
        mdata["theme_color"] = hex_color
        mdata["background_color"] = hex_color
        manifest.write_text(json.dumps(mdata, indent=4, ensure_ascii=False) + "\n", encoding="utf-8")

    # 7. Brand-colored Android + Web icons
    generate_icons(root, hex_color)

    # 8. Privacy Policy, AGENTS.md & README.md
    write_privacy_policy(root, app_name, package_id, repo, selected_kits)
    replace_in_file(root / "AGENTS.md", [(OLD_DART_PKG, app_name)])
    write_starter_readme(root, app_name, description, package_id, repo, selected_kits)

    # 9. Remove template .iml if present
    old_iml = root / f"{OLD_DART_PKG}.iml"
    if old_iml.is_file():
        old_iml.unlink()

    # 10. Optional cleanup of one-time setup files (or remove stale lockfile if extra deps were added)
    if selected_kits or args.cleanup:
        lock = root / "pubspec.lock"
        if lock.is_file():
            lock.unlink()
    if args.cleanup:
        for rel in (".github/workflows/setup-new-app.yml", "tool/setup_new_app.py"):
            target = root / rel
            if target.is_file():
                target.unlink()

    idea_dir = root / ".idea"
    if idea_dir.is_dir():
        shutil.rmtree(idea_dir, ignore_errors=True)

    print(
        f"setup_new_app: configured '{app_name}' "
        f"(dart={dart_pkg}, android={package_id}, lang={args.lang}, "
        f"color={hex_color}, preset={args.preset}, extra_kits={selected_kits})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
