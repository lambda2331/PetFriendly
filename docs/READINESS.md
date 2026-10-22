# Readiness and verification

PetFriendly is a pre-launch product asset with implemented application/backend code and remaining production acceptance. No verified revenue, customer base or retention figures are represented.

## Current packaging snapshot · 22 October 2026

Static analysis and the international Node check pass. The full four-worker Flutter suite records **561 passing tests and 2 failures**. Sequential rechecking passes all five city-directory tests; the meetup details/chat Back navigation test still fails because its expected widget is absent. That test needs investigation before using this journey in a buyer demonstration. See [the exact results](PACKAGE_CHECKS.md).

## Recorded evidence

| Record | Scope |
| --- | --- |
| International audit, 16 October 2026 | 34,156 city records, 244 country/territory groups and 356 IANA identifiers checked locally; 79 Flutter tests and two Node checks passed |
| Buyer rehearsal, 17 October 2026 | 163 selected unit/widget checks and 157 local server checks passed; native localization, meetup and Unicode journeys passed |
| Native rehearsal limits | Compact walking chat overflowed at 320×640, text 200%, keyboard inset 220; another imported widget test had a native TestTextInput harness incompatibility |
| Manual demo, 17 October 2026 | Startup with location denied, Minsk catalog/details/favorites, helper onboarding without a pet and return to owner role were exercised |

These are historical snapshot results, not fresh verification of every file in this branch. Later visual work has separate evidence. Do not assume an old finding is resolved or applies to every device without a matching retest. Gallery images use synthetic content; earlier native captures and widget renders are labeled separately.

Fresh packaging checks are recorded in [PACKAGE_CHECKS.md](PACKAGE_CHECKS.md).

## Before a walkthrough

- Prepare persistent synthetic profiles, a pet, meetup and agreement chat in an isolated environment. Ordinary demo lists start empty; integration fixtures do not persist into the normal app.
- Rehearse current routes. The old profile tabs and “Experience and reviews” entry no longer exist; some historical integration targets expect them.
- Retest compact chat, enlarged text and keyboard behavior on the intended device.
- Confirm Mapbox token, quotas, billing controls and tile loading before promising a live map.
- Keep sample city/district values coherent during international search demonstrations.

## Before public launch

| Area | Acceptance work |
| --- | --- |
| Identity | Buyer-owned providers, mail delivery, callbacks, linking and recovery |
| Notifications | FCM/APNs credentials/capabilities and physical-device delivery |
| Walking | Complete cloud request → application → assignment → lifecycle → eligible review, including authorization |
| Maps/catalog | Live behavior in launch cities, freshness, attribution and geocoder ambiguity |
| Operations | Recovery, revocation, retention/export/deletion and backup handling |
| Distribution | Signing, current store requirements and physical-device checks |
| Business | Cancellation/dispute rules and retention durations remain owner decisions; acquisition and monetization are unvalidated |

Platform payments, background tracking and AI matching are outside v1. No security certification, global availability guarantee or store-acceptance guarantee is made.
