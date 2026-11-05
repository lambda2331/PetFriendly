# Getting started

## English Flutter portfolio

Install Python 3 and Flutter 3.47.6, matching CI. No API keys, accounts or paid map services are required.

```sh
python3 scripts/build-portfolio.py
python3 scripts/build-web-demo.py --base-href /app/
python3 -m http.server 4173 --directory portfolio
```

Visit http://localhost:4173. The case study embeds the same demo available from `prototype.html`. `portfolio/app/` is generated and ignored; do not edit compiled files. Set `PETFRIENDLY_FLUTTER_BIN` to an absolute Flutter executable when needed.

The generator reads current `lib/` source and `tooling/portfolio/en.json`. It creates `build/portfolio-source/`, translates literal text while preserving Dart interpolation and compiles the same Flutter widgets and repositories with `PORTFOLIO_DEMO=true`. Unknown Russian display text fails the build. Internal geographic aliases are explicitly reviewed exceptions.

The portfolio flag selects seeded demo repositories and the offline map adapter, forces the English Material locale and isolates live service configuration. Theme, city and favorite IDs persist in browser preferences. Messages, forms, profile/pet edits, meetups and walking state remain in memory. Restarting the demo reloads in-memory fixtures while keeping preferences.

## What to try

- Nearby: pan the mock map, open markers, switch to fullscreen, zoom, show the simulated position and return to the embedded map.
- Places: search, filter, open details, save a place and compose a review. The profile shows favorites.
- People: search by name, pet or interest; start a direct chat; switch to communities and open shared walks.
- Walking: offer help with Bruno’s request. Create your own request, use the native demo helper actions and follow assignment/completion/review states.
- Profile: edit details, add a pet and use the separate settings screen for themes.
- Add place: select a point by moving the mock map. This creates a demo contribution, not a published real venue.

The map is intentionally synthetic; it does not claim real routes, venue locations or current pet access. No device location permission is requested in portfolio mode.

## Native Flutter preview

```sh
flutter pub get
flutter run --dart-define=USE_DEMO_DATA=true
```

Choose an iOS simulator or Android emulator. Native source remains primarily Russian. Its default unseeded demo and the portfolio’s seeded repository exercise the same screen code with different fixtures. The native map needs a public Mapbox token; without one it shows a places-list fallback.

For backend mode, copy `config/app.example.json` to ignored `config/app.local.json`, configure services you control and run:

```sh
flutter run --dart-define-from-file=config/app.local.json
```

Review the historical [service notes](services-setup.md) (Russian) before provisioning. Never put server keys in a client build. Backend verification scripts need deliberate local/staging configuration and may create test fixtures; they are not part of the public demo build.

## Checks and publication

```sh
python3 scripts/build-portfolio.py --check
python3 tooling/portfolio/test_localization.py
python3 scripts/build-web-demo.py --check
python3 scripts/check-portfolio.py
flutter analyze
mkdir -p docs/screenshots tooling/.logs
flutter test
```

The Pages workflow builds for `/PetFriendly/app/` and publishes only `portfolio/`, including the generated Flutter application. Pull requests build and validate without deploying. Native integration flows still require an emulator/device; backend scripts require configured services.
