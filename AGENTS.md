# PetFriendly project decisions

Use these agreed project settings unless the user changes them.

- Product: mobile community for pet owners: nearby places, people, interest groups, meetings, walking assistance and chat.
- Platforms: iOS and Android using Flutter and Dart.
- Approved visual direction: Studio. Minimal, generous spacing, strong typography, lime accent. Social/lavender is an archived alternative, not the default.
- Fonts: Manrope for headings and wordmark; Golos Text for body, controls and messages. Support Cyrillic. Bundle font assets for production rather than relying on runtime downloads.
- Themes: light, dark and system; system by default. Persist selection locally. Use semantic tokens from design/tokens.json; apply theme to map and overlays too.
- Motion: restrained, purposeful; tap 100 ms, tab change 180 ms, navigation/theme 220 ms, bottom sheet 250 ms. Respect reduced motion. Haptics only for meaningful actions, with a user preference.
- Navigation: Nearby, People, Walking help, Chats, Profile. Nearby retains the Studio greeting and nearby-event banner above the map. Places list is a separate screen with search and filters, opened from the map. Single map markers use category icons; clusters retain counts. Groups and events belong to community modules.
- Nearby map has side insets and rounded corners. City selection and list/fullscreen navigation sit above it. Zoom/location controls appear only in fullscreen; gestures work in both modes. Place filters use compact Material selects.
- Profile uses compact person/pet identity cards; settings open separately from a header gear next to theme. People and communities have separate segments. Community invitations open a message draft and require voluntary joining. Chats show sender and time. Photo selection is currently an in-memory design preview only, with re-encoding to remove original EXIF; production upload/storage is not implemented.
- Favorite places appear inline in the personal profile. Place details include rating/review composition within the sheet and focus on the map without changing manual city. Unrated list rows omit empty rating text; real rating averages come from the server. Source attribution belongs to map/catalog/app information, not the main place-card content.
- Chat uploads now allow photos only: at most 5 MiB before upload, re-encoded without original metadata, at most 1200 px and 1 MiB in private server storage. Reject new videos in the client, Edge Function and SQL write path; keep already stored attachments readable.
- App structure: feature-first, UI/controllers/repositories/services, Riverpod and go_router. Widgets do not contain business logic.
- Planned backend: Supabase Auth, PostgreSQL + PostGIS, Realtime, private Storage and Edge Functions. Mapbox for maps; FCM with APNs configuration for push.
- Server validates privileged changes. Walking assignment must be atomic; chat access requires active membership; public profiles expose a district rather than exact coordinates.
- Documentation: docs/design.md and docs/architecture.md are the baseline. design/prototype.html is the reviewable UI prototype, not a production application.
- Do not introduce payments, live tracking or an AI matching service into the first release without a new product decision.

## Mandatory security baseline

- Account and personal-data security are release requirements. Follow docs/security.md.
- MFA is available to users and mandatory for moderators/admins. Enforce it server-side; recovery must not bypass it.
- Store auth tokens in OS secure storage through an explicitly configured SDK storage adapter; never ordinary preferences or logs.
- Use server authorization/RLS for every private object, including realtime and Storage. Roles are server-controlled.
- Publish only a district, never exact user location or private handover instructions. No background tracking in v1.
- Do not persist plaintext chats/private addresses in Drift in v1. Public catalog caching is permitted.
- Reauthentication is required for security changes, export and deletion. Implement/test session revocation, including existing JWT and realtime access.
- Default push content omits message text. Strip photo EXIF. Minimize data collection and restrict staff access.
- Define retention, export, deletion and backup deletion handling before launch. Test authorization bypass and account recovery.
- Do not claim E2EE or implemented protection from this specification alone. Demo mode and a local Supabase backend are implemented; distinguish tested local protections from unconfigured production services.

## Walking reputation

- User profiles expose a role-specific walking-helper rating: 1–5 stars, published review count and completed walking count. No reviews means "No reviews yet", never zero stars.
- Only the request owner can review the assigned helper after a completed agreement. One review per agreement; no self-review or arbitrary ratings of strangers.
- Rating aggregates are server-derived from published eligible reviews; clients cannot write reputation totals.
- Keep place ratings separate. Include helper replies, reporting and moderation; do not expose private addresses or pet-care instructions in reviews.
- Reviews and counts are decision support, not an identity or safety guarantee. New helpers remain discoverable.

## Launch and sign-in decisions

- First launch market and fallback city: Minsk, Belarus. Nearby initially uses device location with permission; manual city selection is always available and persists until the user switches back to nearby mode. Do not overwrite a manual selection automatically. Venue time zones follow the venue; Minsk uses Europe/Minsk.
- Mapbox: operate within the free tier. Paid usage is not authorized. Verify quotas and account controls before connecting; do not assume automatic billing stops at the free allowance.
- Sign-in: email/password with email confirmation, Google account (the user's "Gmail" request), Apple and Telegram.
- Telegram is planned as a Supabase custom OIDC provider, with email_optional=true and minimal scopes. Validate provider compatibility in staging; never fabricate email or use Telegram username as identity.
- Provider profile data is editable display content only: prefill an unset name, preview a Telegram photo on first onboarding only when no saved photo exists, and offer explicit Google/Telegram photo import in profile editing. Save through the existing private photo pipeline after profile confirmation. Do not replace manually saved identity fields or request Telegram phone/bot messaging scopes for this feature.
- Keep one internal account ID. Linking sign-in methods requires proof of control of both identities; do not merge accounts based only on names or email text.
- Cancellation/dispute rules and data-retention durations are explicitly deferred by the user. Do not invent them or ask again during scaffold work; resolve before public launch.
- Machine-readable planned configuration: design/project-settings.json.

## Approved place catalog source

- MVP uses Mapbox for map rendering and OpenStreetMap for the initial place catalog.
- Respect ODbL attribution and applicable database obligations. The bundled Minsk catalog contains 130 parks/dog parks with source IDs and provenance. Automatic imports include parks/dog parks, pet shops (shop=pet) and veterinary clinics (amenity=veterinary), including selected/detected cities in Belarus and Russia. Automatic imports exclude cafes/restaurants; users may propose them through community moderation. Load the selected/detected city catalog; do not restrict the product to Minsk. The current fetch covers 15 km around the public city centre, not a guaranteed complete administrative area.
- Track source IDs and freshness; deduplicate and preserve independently verified edits.
- Pet access is confirmed by community/venue evidence. Missing tags mean unknown; never assume all cafes/parks allow pets.
- Google Maps and Yandex catalog imports are excluded from the current MVP decision.
- Users may propose public venues by choosing a point on the map. Pending submissions are visible only to their author; publication requires server-controlled moderation with MFA. Pet access stays unknown until separately supported by evidence. Do not publish author IDs or mistake venue coordinates for a user's live location.

## Prototype development

- Flutter code is in lib/. Launch locally with scripts/run-ios.sh; setup and limits are in docs/development.md.
- Theme, manual city and favorite place IDs are the only persisted prototype preferences. Demo chat messages stay in memory.
- Demo login is a preview. Local Supabase email login is functional; never use real personal data in local test fixtures.
- Mapbox renders only when a public token is configured; otherwise show an honest unavailable state. The OSM catalog is real, with unknown pet access where evidence is missing.

<!-- graft:start -->
## Graft — repo context graph

This repo is indexed in `graft/`: small linked markdown nodes that explain each
system and carry exact file:line spans, kept in sync with the code through git.

For ANY task here — understanding how something works, finding where code lives,
or scoping a change — get context from the graph before grepping or opening
source files. Re-ask freely (it's cheap) and reuse literal identifiers you
already have (symbol, error string, file name) as the query. New to this repo?
Run `graft map` first — a token-budgeted orientation (dir clusters, hubs,
hotspots), no LLM, no key.

- Run `graft ask "<your question>" --source` → ranked nodes with the relevant
  code spans inlined (each hit's ≤8-line crux by default; `--full` for whole
  definitions when the crux isn't enough). Match the tool to the task shape:
  for understanding or editing, the top node IS the answer — cite its
  `covers:` file:line spans and edit straight from `--source`. For
  exhaustive tasks ("every occurrence / every caller of this pattern"), ranked
  results are top-N, not complete — run `graft grep "<literal>"` instead
  (exhaustive over indexed files, grouped by enclosing symbol), falling back
  to raw `grep -rn` only for unindexed files.
- `graft skeleton <file>` → every definition's signature + span, ~10× cheaper
  than reading the file; use it to skim an API surface.
- `graft callers <symbol>` gives precomputed, exact edges — who calls this.
  Add `--direction out` for what it calls, or `--depth N` to walk
  transitively for the full blast radius. For structural questions, skip
  ranking and use this directly.
- Or browse: `graft/INDEX.md` lists every node; follow the links.
- Monorepos and folders of multiple repos rank fairly across sub-projects —
  hits carry `[scope/]` labels naming which one they're from. Narrow with
  `graft ask "<task>" --in <scope>/` once you know where you're working.

If a returned span is truncated ("+N more lines"), open the file at that exact
range before finalizing. Only open source files when a node genuinely lacks a
needed detail, and then at the exact file:line the node points to — never
re-read whole files.

After big code changes, refresh the graph with `graft build` (deterministic,
no API key, $0).
<!-- graft:end -->
