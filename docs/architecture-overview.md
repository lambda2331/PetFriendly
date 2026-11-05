# Architecture overview

PetFriendly uses the same Flutter screens and scenario logic for mobile and the English portfolio demo. A static case study and thin iframe host introduce the application; there is no second handwritten product UI.

## Shared application

| Layer | Location | Responsibility |
| --- | --- | --- |
| App composition | `lib/app/` | Routing, theme, shell and lifecycle |
| Shared infrastructure | `lib/core/` | Configuration, preferences, location, media and components |
| Product features | `lib/features/` | Places, profiles, community, chats, walking and account flows |
| Server rules | `supabase/migrations/` | RLS, privileged operations and aggregates |
| Server operations | `supabase/functions/` | Private media, account deletion, catalogs and notifications |

Riverpod owns state and repository selection; go_router owns routes. Native maps use Mapbox. The portfolio flag selects a Flutter-only interactive map with synthetic geometry and markers. Place sheets, reviews, list filters, profile favorites and navigation remain the application’s existing widgets.

## Public demo boundary

`AppConfig.portfolio` is a compile-time flag, disabled for normal builds. It prevents backend activation and Firebase initialization, selects seeded demo data, suppresses real geolocation and avoids external catalog import. The map adapter also supports fullscreen controls and choosing a point for a new place. It never requests live tiles.

In-memory changes reset on reload. Only theme, manual city and favorite IDs persist. Native production authorization is not simulated as a security guarantee: the serverless demo shows interaction and state transitions, not live service behavior.

## English build

`scripts/build-web-demo.py` copies canonical source into ignored `build/portfolio-source/`. A reviewed catalog translates Dart literal text segments, retaining nested interpolation expressions. Scanner tests cover comments, nested strings, escaped text and missing translations. New untranslated copy fails the build. Internal search aliases are separately allowlisted and stay unchanged.

The build compiles that source with the portfolio flag and writes ignored `portfolio/app/`. A published manifest records the canonical source digest, file count and sandbox mode. Native source remains Russian by default; runtime locale switching is outside this adaptation.

## Verification

Native analysis and tests protect shared behavior. Translation tests protect the build transformation. A release web build and browser scenario checks verify the actual English artifact. These checks do not establish production readiness, account-security certification or external service delivery.
