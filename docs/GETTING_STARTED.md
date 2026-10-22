# Getting started with PetFriendly

Start in demo mode, then configure a local backend. Use synthetic data during evaluation. Ordinary demo community, chat and walking lists are empty; integration-test fixtures are not persistent customer accounts.

## Requirements

- Recorded development SDK: Flutter 3.47.6 / Dart 3.13.5.
- iOS: macOS, Xcode, an installed Simulator runtime and CocoaPods; deployment target iOS 15 or later.
- Android: Android SDK and Java 17. Gradle/AGP/Kotlin settings are in the platform project.
- Local backend: Node/npm, the pinned Supabase CLI in `tooling/` and a Docker-compatible runtime.

Check current SDK/store requirements before release; these versions describe the development environment, not store acceptance.

## UI preview

```sh
flutter pub get
flutter devices
flutter run -d <device-id>
```

On macOS, `scripts/run-ios.sh` can select and boot an iPhone Simulator. Set `PETFRIENDLY_SIMULATOR_ID` and `PETFRIENDLY_FLUTTER_BIN` explicitly when several devices or SDKs exist.

Choose English from the language control or Settings. Theme, language, manual city and favorite IDs are local preferences. User-authored names/messages and source place names retain their original language. Device location requires permission; a manual city is always available.

Without a public Mapbox token the map shows an unavailable state. The offline Minsk list remains reviewable. Check free-tier quotas and billing controls before live map use; paid usage is not authorized by this setup.

## Client configuration

```sh
cp config/app.example.json config/app.local.json
flutter run -d <device-id> --dart-define-from-file=config/app.local.json
```

Keep the example blank. Put your own parameters in the ignored local file:

| Parameter | Purpose |
| --- | --- |
| `USE_DEMO_DATA` | `true` for preview; `false` for a configured backend |
| `SUPABASE_URL` | Your local/staging project URL |
| `SUPABASE_PUBLISHABLE_KEY` | Public client key; never a server/service-role secret |
| `MAPBOX_ACCESS_TOKEN` | Public token with appropriate account controls |
| `AUTH_*_ENABLED` | Enable a provider after backend/callback setup |
| `FIREBASE_*` | Client app parameters; server/APNs setup is separate |

Database passwords, SMTP secrets, private signing files and Firebase service-account JSON must not enter the mobile configuration or Git. Use buyer-owned accounts for handover.

## Local Supabase

With a working container runtime:

```sh
npm ci --prefix tooling
./tooling/node_modules/.bin/supabase start --exclude studio,vector,logflare,imgproxy,supavisor
./tooling/node_modules/.bin/supabase functions serve --no-verify-jwt
```

Project functions perform their own authorization checks; the local development flag is not an instruction to bypass application authorization. Migrations are in `supabase/migrations/`; seed catalog data is in `supabase/seed.sql`. Confirm migration state before testing and do not reset data you need.

Configure a public client key and `USE_DEMO_DATA=false`. The standard local endpoint is `http://127.0.0.1:54321` on iOS Simulator or `http://10.0.2.2:54321` on Android Emulator. A physical phone needs its own reachable, appropriately secured endpoint.

## Checks and demonstration

```sh
mkdir -p docs/screenshots
flutter analyze
flutter test --concurrency=1
node --experimental-strip-types scripts/check-international-geocoding.mjs
```

Use a Node version supporting TypeScript type stripping for the last command. Local server scripts read ignored `config/backend-status.local.json` and require local administrative credentials; inspect their target, synthetic fixtures and cleanup before running them. Never substitute production accounts.

Some historical native targets reference superseded controls. See [Readiness](READINESS.md) before selecting a journey. For a buyer call, prepare an isolated environment with an owner, helper, pet, meetup and agreement conversation, then rehearse the exact build/device and keyboard/map behavior.
