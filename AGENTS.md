# PetFriendly project decisions

Use these agreed project settings unless the user changes them.

- Product: mobile community for pet owners: nearby places, people, interest groups, meetings, walking assistance and chat.
- Platforms: iOS and Android using Flutter and Dart.
- Approved visual direction: Studio. Minimal, generous spacing, strong typography, lime accent. Social/lavender is an archived alternative, not the default.
- Fonts: Manrope for headings and wordmark; Golos Text for body, controls and messages. Support Cyrillic. Bundle font assets for production rather than relying on runtime downloads.
- Languages: Russian (`ru`), English (`en`), Belarusian (`be`) and Polish (`pl`). Follow device language by default, fall back to Russian, and persist an explicit device-local language choice. Use Flutter ARB/gen-l10n and locale-aware plural/date/number formatting. Translate application copy only; keep user messages, names, reviews and canonical API values unchanged.
- City selection is international: bundle the attributed GeoNames cities15000 snapshot, search aliases locally, show country/region and allow country-qualified manual smaller settlements. Canonical keys and IANA venue zones are independent of UI language; preserve legacy Belarus/Russia keys. City selection never publishes device GPS.
- Themes: light, dark and system; system by default. Persist selection locally. Use semantic tokens from design/tokens.json; apply theme to map and overlays too.
- Motion: restrained, purposeful; tap 100 ms, tab change 180 ms, navigation/theme 220 ms, bottom sheet 250 ms. Respect reduced motion. Haptics only for meaningful actions, with a user preference.
- Navigation: Nearby, People, Walking help, Chats, Profile. Nearby retains the Studio greeting and nearby-event banner above the map. Places list is a separate screen with search and filters, opened from the map. Single map markers use category icons; clusters retain counts. Groups and events belong to community modules.
- Nearby map has side insets and rounded corners. City selection and list/fullscreen navigation sit above it. Zoom/location controls appear only in fullscreen; gestures work in both modes. Place filters use compact Material selects.
- Profile uses compact person/pet identity cards; settings open separately from a header gear next to theme. People and communities have separate segments. Community invitations open a message draft and require voluntary joining. Chats show sender and time. Photo selection is currently an in-memory design preview only, with re-encoding to remove original EXIF; production upload/storage is not implemented.
- Favorite places appear inline in the personal profile. Place details include rating/review composition within the sheet and focus on the map without changing manual city. Unrated list rows omit empty rating text; real rating averages come from the server. Source attribution belongs to map/catalog/app information, not the main place-card content.
- Chat uploads now allow photos only: at most 5 MiB before upload, re-encoded without original metadata, at most 1200 px and 1 MiB in private server storage. Reject new videos in the client, Edge Function and SQL write path; keep already stored attachments readable.
- Meeting creation optionally selects a public venue point on the map and a short gathering label. Keep the point in account-scoped memory drafts; clear it and its label when the event city changes. Store it atomically through create_event_at_location and expose it under existing event RLS, never as a user's live position. Event cards open a map focused on the selected point.
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

## Walking helper mode

- Approved helper experience is implemented in Flutter: one account can be owner, helper or both. Owner navigation remains Nearby, People, Walking help, Chats, Profile; helper navigation is Requests, My walks, Chats, Profile. Mode switching preserves account identity, conversations and role-labelled history. No pet is required for helpers.
- Helper onboarding uses public city/district, introduction, animal experience, dog-size preferences, service districts and structured weekly availability. Private handover instructions stay in participant-only agreement views.
- Upcoming agreements and unassigned applications stay separate. Date filters use the walk city’s time zone. Eligible owner and helper reviews use separate aggregates and one review per completed agreement per direction.
- UI/API mapping and native verification limits: docs/helper-mode-implementation.md and docs/walking-api.md. Browser design reference remains design/helper-mode.html; it is not the native application.

## Walking reputation

- User profiles expose a role-specific walking-helper rating: 1–5 stars, published review count and completed walking count. No reviews means "No reviews yet", never zero stars.
- After owner-confirmed completion, the request owner may review the assigned helper and the assigned helper may review the owner. One review per agreement in each direction; no self-review or arbitrary ratings of strangers. Keep owner and helper ratings, counts and replies separate; eligibility survives product-role changes.
- Rating aggregates are server-derived from published eligible reviews; clients cannot write reputation totals.
- Keep place ratings separate. Include helper replies, reporting and moderation; do not expose private addresses or pet-care instructions in reviews.
- Reviews and counts are decision support, not an identity or safety guarantee. New helpers remain discoverable.

## Product roles and helper mode

- Keep one internal account ID with product roles owner, helper or both; active mode is owner/helper. These choices never grant moderator/admin privileges or come from untrusted Auth user_metadata.
- Helper-only accounts use focused Requests, My walks, Chats and Profile navigation. New request/pet/community/meeting/venue creation requires owner capability; applying requires helper capability. Existing agreements, history and personal-data management survive role changes.
- No pet is required for helper onboarding. Public helper preferences contain city/district, introduction, experience, dog-size preferences, public service districts and weekly availability in an IANA time zone. Never put GPS, handover addresses or private care instructions there.
- Server/API contract: docs/walking-api.md. Migrations 026–028 implement product roles, private preferences, public helper fields, owner reviews and bounded request/personal-walk queries. UI rollout and cloud status are tracked separately.

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
- Respect ODbL attribution and applicable database obligations. The bundled Minsk catalog contains 130 parks/dog parks with source IDs and provenance. Automatic imports include parks/dog parks, pet shops (shop=pet) and veterinary clinics (amenity=veterinary), including selected/detected cities across countries. Automatic imports exclude cafes/restaurants; users may propose them through community moderation. Load the selected/detected city catalog; do not restrict the product to Minsk. The current fetch covers 15 km around the public city centre, not a guaranteed complete administrative area.
- Track source IDs and freshness; deduplicate and preserve independently verified edits.
- Pet access is confirmed by community/venue evidence. Missing tags mean unknown; never assume all cafes/parks allow pets.
- Google Maps and Yandex catalog imports are excluded from the current MVP decision.
- Users may propose public venues by choosing a point on the map. Pending submissions are visible only to their author; publication requires server-controlled moderation with MFA. Pet access stays unknown until separately supported by evidence. Do not publish author IDs or mistake venue coordinates for a user's live location.

## Prototype development

- Flutter code is in lib/. Launch locally with scripts/run-ios.sh; setup and limits are in docs/development.md.
- Theme, language, manual city and favorite place IDs are the persisted prototype preferences. Demo chat messages stay in memory.
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

## Approved mock flow review

- Preserve approved screen presentation and all previous versions. Business-requirement audits must not replace approved layouts.
- Before adding or changing a mock flow, action or destination, show the user its current screen, expected behavior and gap in the workflow map, and review the proposed change with them. Keep unapproved proposals isolated from the active mock.
- Current review board: design/onboarding-unified-account-2026-10-14/workflow-map.html. Review 18 is the approved pre-BA UI baseline; Reviews 21–26 contain user-requested refinements. Prior versions, including the Review 19 BA proposal, remain archived for comparison.


## Design system instructions

- Before any UI design, mock or Flutter visual update, read `docs/design-system.md` and `design/system/components.json`. Use `design/tokens.json` for semantic foundation values.
- Reference catalog: `design/system/index.html`. Reuse existing shared components with the same intent; do not introduce another font, palette, button size or modal container for an existing pattern.
- Keep current approved screen appearances and all prior versions. Resolve historical token differences through a reviewed migration, never a silent global restyle.
- New actions, destinations and flow behavior must be reviewed in the workflow map with the user before implementation. The design system is not authorization to implement BA proposals.


## Workflow simplification · Review 27 (supersedes earlier UI decisions)

User decision on 14 October 2026: keep sign-in simple with the previous email/password/provider design and password reset. Exclude MFA, data-copy and device-session screens from the current design workflow. There is no moderator product role; user-created public places publish directly, with reporting available for potential removal. The old pre-publication moderation decision is superseded for future designs. Keep pet access unknown until supported by evidence. Server report-removal policy and backend rollout remain separate work; do not assume an automatic deletion threshold. Preserve existing security enforcement while simplifying mock designs. Public communities are discoverable and directly joinable. Keep pending applications in request details, applicant information inline, and agreement lifecycle in participant chat. Review 26 is retained in the version archive.


## Meetings design · Review 28

15 October 2026: Meetings is a third segment within People, alongside People and Communities; keep five bottom navigation destinations. Nearby has an All meetings entry. Public events can be joined without joining the associated community, subject to capacity. Create uses one form, with optional public point/gathering label and optional community association; city changes clear the point and its label. Share an event through an existing chat draft with explicit Send; retain event ID on the message card. Unknown event links never resolve to an unrelated event. Keep walking controls in the fixed chat context, with an elapsed timer during an active walk; no location tracking or automatic completion. Browser-only review implementation is separate from Flutter/backend enforcement. Review 27 is preserved.

## Browser review 30 decisions

- Meetings discovery uses search then compact location/date controls. Creation has one place picker; its search area owns city selection and derives the event time zone. Permission-based geodata is only a proposed initial map centre; browser mocks use sample public points.
- Registration-full public meetings leave nonparticipant discovery but keep shared details accessible; attendance without registration remains possible.
- Optional form fields show separate secondary hints. Walking chat shows a status entry; timer and actor-permitted lifecycle actions open in a compact sheet. Dynamic Island support is a native Live Activity follow-up, not implemented in the browser or native app by this design revision.

## Browser review 34 — city picker reuse

- All active mock city-selection entry points reuse `design/onboarding-unified-account-2026-10-14/nearby-city-picker.js`. Approved onboarding/helper, profile editor and walking-condition forms use `shared-city-adapter.js`; meetings keeps its host adapter. Preserve surrounding layouts and unrelated drafts. Do not add separate city dropdowns or raw city text fields outside the shared manual flow.
- Retain country qualification for manual settlements. Require a valid IANA zone for scheduled service/meeting contexts, and clear stale districts when changing city. Native/backend rollout remains separate.

## Browser review 35 — date/time picker reuse

- Active mock date/time controls use `design/onboarding-unified-account-2026-10-14/shared-date-time.js`. Keep approved form positions and unrelated drafts. Reuse its calendar and explicit 24-hour time sheet rather than native browser date/time visuals or duplicated inline calendars.
- Done commits; close/Escape cancels and restores focus. Preserve date-only and wall-time canonical values in the proper venue/request/service IANA zone. Keep relative-date filters and recurring weekdays as their distinct approved controls. Native/backend rollout remains separate.
