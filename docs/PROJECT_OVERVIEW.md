# PetFriendly project overview

PetFriendly combines local discovery with coordination between pet owners and walking helpers. Minsk is the initial market; international city identities and four UI languages support future city-by-city launches.

## Journeys

Owners use Nearby, People, Walking help, Chats and Profile. People includes community and meetup discovery. Places have a dedicated searchable list; favorites appear in the personal profile.

Helpers use Requests, My walks, Chats and Profile. Public helper preferences contain city/district, introduction, experience, dog-size preferences, service districts and weekly availability. A pet is not required. Product roles belong to one internal account and grant no staff privileges.

Requests can receive applications and an assigned helper. Agreement actions are participant-specific; owner-confirmed completion enables eligible reviews. Owner/helper reputation is separate and server-derived. Private handover instructions belong to participant-only views.

Meetups may contain a public map point and gathering label. This is a venue point, not a user's live position. Changing city clears the point; sharing to chat creates a draft with explicit sending.

## Architecture

Flutter is organized by feature, with UI, controllers, repositories and services. Riverpod manages dependencies/state and go_router owns navigation. Demo and backend-backed repositories have different guarantees.

| Path | Responsibility |
| --- | --- |
| `lib/app/` | Shell and routes |
| `lib/core/` | Backend, location, time, storage, media, theme and shared UI |
| `lib/features/nearby/` | Maps, cities, places, filters and reviews |
| `lib/features/community/` | People, communities and meetups |
| `lib/features/walks/` | Roles, preferences, requests, agreements and reputation |
| `lib/features/chat/` | Inbox, conversations, context and media |
| `lib/features/auth/` | Sign-in, confirmation and onboarding entry |
| `lib/features/profiles/` | Personal/pet identity |
| `lib/l10n/` | ARB catalogs, generated localization and bridge |
| `supabase/` | Migrations, constraints, RLS, RPCs and Edge Functions |

Realtime and private Storage integrations do not replace server authorization. Auth tokens use explicitly configured OS secure storage; ordinary preferences hold non-secret UI choices. Read the [security baseline](security.md), which records requirements rather than certifying production readiness or E2EE.

## Geography

GeoNames cities15000 supplies attributed offline identities, aliases, public centres and IANA zones. Canonical identity is independent of UI language; legacy launch-city keys remain stable. City selection does not publish device GPS.

Mapbox renders configured maps. OSM automatic imports include parks/dog parks, pet shops and veterinary clinics within a bounded area, currently 15 km around a public centre. Cafes/restaurants are excluded from automatic imports. Missing pet-access evidence remains unknown.

## Design

Studio uses generous spacing, strong typography, lime accents and bundled Manrope/Golos Text fonts. Reuse `design/tokens.json` and `design/system/components.json` with the [design system](design-system.md).

Preserved browser review sources may include approved, proposed and design-only screens. A connected mock workflow is not proof of native/backend parity. Keep per-screen status and archived versions during further work.
