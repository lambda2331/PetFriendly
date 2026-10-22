# Repository packaging checks

Prepared on 22 October 2026, on `codex/repository-packaging`, with Flutter 3.47.6 / Dart 3.13.5. The application/design source snapshot is commit `f65f0ca`. This branch captures the owner's current development sources; the packaging work does not introduce a new approved product flow.

## Executed checks

| Check | Result |
| --- | --- |
| `flutter pub get` | Completed; lockfile retained |
| `flutter analyze` | Passed: no issues found |
| `flutter test test/chat_unicode_test.dart --reporter expanded --timeout 45s` | Passed: 1 test |
| `flutter test --no-pub --concurrency=4 --reporter expanded` | Completed with exit 1: 561 passed, 2 failed (details below) |
| `node --experimental-strip-types scripts/check-international-geocoding.mjs` | Passed: 34,156 city keys, country labels, bounds, aliases, zones and legacy/manual cases; 244 country/territory codes |

The first full-suite attempt stopped making progress while loading `chat_unicode_test.dart`, after 11 passing tests. It was terminated. That target passed independently. A sequential retry progressed without test failures but was stopped to restart the complete suite with four workers. Neither interrupted attempt is counted as a passing suite.

## Findings from the current snapshot

- `world_cities_test.dart`: the typeahead timing check measured 589 ms against a `<500 ms` bound during the four-worker run. All **5 tests in that file passed** in the sequential targeted retest. This shows a load-sensitive result; it does not establish a universal performance guarantee.
- `meetup_studio_test.dart`: “Dedicated details and chat Back retain originating search” failed with `Bad state: No element` in `ensureVisible` via `press`, at test line 37. It failed again in the sequential retest. Whether this is a stale finder or a product regression remains unresolved; do not present this journey as verified.
- Targeted sequential command: `flutter test --no-pub --concurrency=1 test/world_cities_test.dart test/meetup_studio_test.dart --reporter expanded`. Result: **7 passed, 1 failed**, exit 1.

No application code or assertion thresholds were changed to obtain a passing result. The full suite is **not green**.

## Package inspection

- The GitHub repository is private. No visibility or collaborator changes were made.
- New guide links and image references were checked locally. The SVG cover was rendered and visually inspected.
- The delivery tree was scanned for private-key blocks, common GitHub/AWS/Supabase secret formats, JWT literals, Mapbox tokens and Google API keys. No matches were found for those patterns. Credential-bearing URL matches occur in synthetic/negative-test fixtures; they are not buyer service credentials.
- No candidate file exceeded 10 MiB. Native Firebase files and signing-key filenames were absent from the candidate tree.
- Ignore checks cover local client configuration, native Firebase configuration, Android signing, build output, dependencies and console screenshots.
- New packaging documentation passes `git diff --check`. Existing whitespace in preserved design review sources was retained to keep the source snapshot unchanged.

These are limited tree checks, not a complete security review or a scan of prior Git history. Before providing buyer access, inspect the agreed delivery tree and history, confirm rights and review the [handover checklist](HANDOVER.md).

## Evidence boundaries

Native-device, live backend, cloud-provider and distribution checks were not rerun for packaging. Historical evidence and remaining work are described separately in [Readiness](READINESS.md). The README's sample screenshots come from earlier October 2026 captures and are labelled by capture method.

Local configs, credentials, signing material, private sales/monitoring notes, generated browser bundles and bulk archived check outputs were not copied from the owner's working directory. Design source versions were retained; the owner's full archive remains separate.
