# Architecture overview

PetFriendly has two separate presentation runtimes. The static portfolio explains the work and hosts an interaction study. The native Flutter application implements product behavior with optional Supabase services.

## Static portfolio

`portfolio/index.html` is a semantic, responsive case study using the existing Studio identity. It works without JavaScript. An iframe embeds the interactive prototype; a normal link opens the same prototype independently.

`design/prototype.fragment.html` is the single source for the English interaction study. `scripts/build-portfolio.py` wraps it into `portfolio/prototype.html` and `design/prototype.html`. CI detects stale generated files before publication. Fonts and Lucide icons are self-hosted, so the study has no runtime CDN dependency.

The study stores only theme, city, selected tab and favorite IDs in its own browser-storage key. Demo messages remain in memory. It does not request location, send messages, authenticate users or connect to production services.

## Native application

The Flutter implementation is organized by feature. UI components use shared theme primitives; application state uses Riverpod; go_router owns routing. Repositories separate interface behavior from demo or backend data sources.

| Layer | Location | Responsibility |
| --- | --- | --- |
| App composition | `lib/app/` | Routing, application theme, shell and lifecycle |
| Shared infrastructure | `lib/core/` | Backend configuration, storage, location, media and reusable UI |
| Product features | `lib/features/` | Auth, nearby places, profiles, community, chat, walks and settings |
| Server data rules | `supabase/migrations/` | Schema, RLS, privileged operations and derived aggregates |
| Server operations | `supabase/functions/` | Private photo/media access, account deletion, catalog and notifications |

Mapbox renders native maps. OpenStreetMap supplies catalog data with provenance; missing evidence of pet access remains unknown. Manual city choice and location availability are different states.

## Rules behind interaction states

Walking assignment must be atomic. Reviews require an eligible completed agreement; clients do not write reputation totals. Private chat and media access depend on current membership. Tokens use an explicitly configured secure-storage path. These are implementation responsibilities, not guarantees inferred from a design mockup.

## Verification boundaries

Flutter analysis, widget/unit tests, device integration flows and backend checks exercise different layers. A successful static-site build proves none of the native service behavior. Historical staging notes record work at that time; they are not a current service-health report. See [portfolio status](portfolio-status.md).

The detailed original specification is retained in [architecture.md](architecture.md) (Russian).
