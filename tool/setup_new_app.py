#!/usr/bin/env python3
"""1-click initializer for apps created from `Keshab1997/flutter-app-starter`.

Renames the Flutter package, Android applicationId/namespace/MainActivity,
Web manifest/title, `AppConfig`, `pulse.json`, `AGENTS.md`, and `README.md`
in one clean pass.

Usage:
    python3 tool/setup_new_app.py \
      --name "Khoroch Pro" \
      --pkg com.keshab.khorochpro \
      --repo Keshab1997/khoroch-pro \
      --lang bn

Stdlib only, Python >= 3.8.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
from pathlib import Path

OLD_DART_PKG = "flutter_app_starter"
OLD_ANDROID_PKG = "com.keshab.flutter_app_starter"
OLD_APP_NAME = "Flutter App Starter"
OLD_REPO = "Keshab1997/flutter-app-starter"

PKG_ID_RE = re.compile(r"^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$")
DART_PKG_RE = re.compile(r"^[a-z][a-z0-9_]*$")


def slugify_dart_pkg(app_name: str, package_id: str) -> str:
    """Derive a valid Dart package name from the package ID tail or app name."""
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
        # Prune now-empty old package directories cleanly.
        parent = old_file.parent
        while parent != kotlin_root and parent.exists():
            try:
                parent.rmdir()
            except OSError:
                break
            parent = parent.parent


def write_starter_readme(
    root: Path,
    app_name: str,
    description: str,
    package_id: str,
    repo: str,
) -> None:
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
python3 tool/local_screenshots.py --shot home
```

## Remote config (`app_pulse_kit`)

Edit [`pulse.json`](pulse.json) at the repo root to manage:
- Soft & force updates (`update`)
- Emergency maintenance mode (`maintenance`)
- Scheduled in-app notices (`notices`)
- Remote feature flags (`flags`)

- **Android package:** `{package_id}`
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
        help="GitHub repo slug (owner/repo) for pulse.json URL",
    )
    ap.add_argument("--lang", choices=["en", "bn"], default="en", help="Default UI language")
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

    dart_pkg = args.dart_name.strip().lower() if args.dart_name else slugify_dart_pkg(app_name, package_id)
    if not DART_PKG_RE.match(dart_pkg):
        print(f"setup_new_app: ERROR: invalid --dart-name {dart_pkg!r}", file=sys.stderr)
        return 2

    description = (args.description or f"{app_name} — Flutter app.").strip()
    pulse_url = f"https://raw.githubusercontent.com/{repo}/main/pulse.json"
    play_url = f"https://play.google.com/store/apps/details?id={package_id}"

    # 1. pubspec.yaml
    pubspec = root / "pubspec.yaml"
    if pubspec.is_file():
        txt = pubspec.read_text(encoding="utf-8")
        txt = re.sub(r"^name:\s*.*$", f"name: {dart_pkg}", txt, count=1, flags=re.M)
        txt = re.sub(r"^description:\s*.*$", f"description: {description}", txt, count=1, flags=re.M)
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
        app_config.write_text(
            f"""/// Central app identity & remote config metadata.
class AppConfig {{
  const AppConfig._();

  static const String appName = '{escaped_name}';
  static const String pulseConfigUrl =
      '{pulse_url}';
  static const bool defaultBangla = {'true' if args.lang == 'bn' else 'false'};
}}
""",
            encoding="utf-8",
        )

    # 4. pulse.json
    pulse_path = root / "pulse.json"
    if pulse_path.is_file():
        data = json.loads(pulse_path.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            update = data.setdefault("update", {})
            if isinstance(update, dict):
                update["androidUrl"] = play_url
            pulse_path.write_text(
                json.dumps(data, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )

    # 5. Android files
    replace_in_file(
        root / "android" / "app" / "build.gradle.kts",
        [(OLD_ANDROID_PKG, package_id)],
    )
    replace_in_file(
        root / "android" / "app" / "src" / "main" / "AndroidManifest.xml",
        [(f'android:label="{OLD_DART_PKG}"', f'android:label="{app_name}"')],
    )
    move_main_activity(root, package_id)

    # 6. Web files
    replace_in_file(
        root / "web" / "index.html",
        [
            (f"<title>{OLD_DART_PKG}</title>", f"<title>{app_name}</title>"),
            (
                f'content="{OLD_DART_PKG}"',
                f'content="{app_name}"',
            ),
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
        manifest.write_text(json.dumps(mdata, indent=4, ensure_ascii=False) + "\n", encoding="utf-8")

    # 7. AGENTS.md & README.md
    replace_in_file(
        root / "AGENTS.md",
        [(OLD_DART_PKG, app_name)],
    )
    write_starter_readme(root, app_name, description, package_id, repo)

    # 8. Remove template .iml if present
    old_iml = root / f"{OLD_DART_PKG}.iml"
    if old_iml.is_file():
        old_iml.unlink()

    # 9. Optional cleanup of one-time setup files
    if args.cleanup:
        for rel in (".github/workflows/setup-new-app.yml", "tool/setup_new_app.py"):
            target = root / rel
            if target.is_file():
                target.unlink()
        # Also remove pubspec.lock so next pub get resolves fresh under new package name
        lock = root / "pubspec.lock"
        if lock.is_file():
            lock.unlink()

    # Clean empty .idea if flutter create left one
    idea_dir = root / ".idea"
    if idea_dir.is_dir():
        shutil.rmtree(idea_dir, ignore_errors=True)

    print(f"setup_new_app: configured '{app_name}' (dart={dart_pkg}, android={package_id}, lang={args.lang})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
