# Getting started

This guide separates the English portfolio from the native application. Neither the static website nor its demo needs Supabase, Mapbox or sign-in.

## Portfolio and interactive prototype

Requirements: Python 3 and a modern browser with CSS `light-dark()` support.

```sh
python3 scripts/build-portfolio.py
python3 scripts/check-portfolio.py
python3 -m http.server 4173 --directory portfolio
```

Visit http://localhost:4173. `portfolio/index.html` is the case study. `portfolio/prototype.html` is generated from `design/prototype.fragment.html`; the same generator updates `design/prototype.html` for direct review from the repository.

Edit the fragment, `portfolio/assets/prototype.css` and `portfolio/assets/prototype.js` rather than either generated file. Case-study styles live in `portfolio/assets/site.css`. The website uses bundled fonts and a pinned Lucide distribution, with no CDN dependency.

Prototype links accept `?screen=nearby`, `people`, `walk`, `chats` or `profile`. `?embed=1` hides the surrounding demo guide for the embedded case-study view. The reset button clears only this prototype’s storage key. It does not affect native app preferences or other websites.

## Native Flutter demo

Use the SDK version pinned in `.github/workflows/checks.yml` (Flutter 3.47.6 when this guide was prepared). Install the platform prerequisites from Flutter’s documentation and run `flutter doctor`.

```sh
flutter pub get
flutter devices
flutter run --dart-define=USE_DEMO_DATA=true
```

Select an iOS simulator or Android emulator when prompted. iOS requires macOS and the Xcode/CocoaPods toolchain. Android requires its SDK and a compatible Java toolchain. The native interface is primarily Russian; the English portfolio does not imply full native localization.

The app defaults to demo mode. Without a configured public Mapbox token, it exposes a map-unavailable state and a places-list fallback. This is expected, not a setup failure. The helper script `scripts/run-ios.sh` also supports the project’s existing local setup; its machine-specific SDK defaults are documented in the historical development guide.

## Optional backend mode

Copy `config/app.example.json` to an ignored `config/app.local.json`. Configure an endpoint and a client publishable/anon key for a Supabase environment you control; set `USE_DEMO_DATA` to false. Configure Mapbox and optional providers only if needed.

```sh
flutter run --dart-define-from-file=config/app.local.json
```

Backend configuration is a separate task. The repository contains SQL migrations and functions; a clone does not provision or verify hosted services. Local Supabase tooling is pinned in `tooling/package-lock.json`:

```sh
npm ci --prefix tooling
./tooling/node_modules/.bin/supabase start
```

A running Docker-compatible runtime is required. Review `supabase/config.toml` and the existing [service setup notes](services-setup.md) (Russian) before provisioning providers or serving functions. Do not run database reset or staging verification against an environment containing valuable data. Backend verification creates synthetic fixtures and requires the intended configuration.

Keep credentials, signing material and provider configuration in ignored local files. Never place server keys in the Flutter client or the static site. `portfolio/` is the complete Pages deployment boundary.

## Checks

```sh
python3 scripts/build-portfolio.py --check
python3 scripts/check-portfolio.py
flutter analyze
mkdir -p docs/screenshots tooling/.logs
flutter test
```

The first two commands validate the static deliverable; the latter two validate native code. Native integration tests need an emulator/device. Backend scripts need a configured environment and are not part of the portfolio build.

## GitHub Pages

The workflow `.github/workflows/pages.yml` validates pull requests and deploys `portfolio/` from `master`. Repository Pages settings must use GitHub Actions as the source. `workflow_dispatch` can publish an unchanged version again. Source modifications go through the regular Git workflow; no hosted build service or paid dependency is required.
