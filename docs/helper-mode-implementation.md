# Walking-helper mode — Flutter implementation

Updated 10 October 2026. The approved [helper-mode design](helper-mode-design.md) is now connected to the Flutter application. The HTML prototype remains a review artifact; it does not supply production state or authorization.

## What is implemented

| Area | Flutter behavior |
| --- | --- |
| Account entry | Authenticated account entry reads the server role/mode, then offers owner, helper or both where selection is required. No pet is required for a helper. |
| Navigation | Owners retain Nearby, People, Walking help, Chats and Profile. Helper mode shows Requests, My walks, Chats and Profile. A discoverable mode control switches a both-role account without creating another identity. |
| Helper onboarding | Two steps collect editable identity, public city/district, introduction and animal experience, followed by dog-size preferences, service districts, weekly availability and its IANA time zone. Existing photo selection/import uses the profile photo pipeline. |
| Requests | Public pet and owner summaries, public area, date/time and optional duration; compact city/district/date/time/size filtering; bounded pages and retry states. Applying is labelled separately from assignment. |
| My walks | Upcoming agreements and applications are separate views; history is a secondary route within the screen. Personal queries use all historical roles so changing product roles does not hide existing relationships. |
| Agreement | Existing request detail, applications, atomic assignment, authorized private chat and role-specific start/finish/owner-confirmation actions remain the workflow. |
| Chat | The agreement context identifies the pet, participant role and state, and links back to the agreement. Existing sender/time, text/photo messages, pending delivery and recovery behavior are reused. |
| Profiles | Helper profile exposes helper experience and public preferences; own-profile actions edit or reply. Owner profile exposes a distinct owner reputation, reviews and recipient replies. Public profile contact/report/block actions are subordinate to the relevant walk action. |
| Reviews | Owner → helper and assigned helper → owner review routes remain distinct. Confirmed completion and one review in each direction determine eligibility; missing reviews show “Пока нет отзывов”, unavailable data has a separate state. |

Role selection, focused helper navigation, public helper preferences, personal walks queries and owner reputation were proposed additions in the design. They now have Flutter UI and repository integration. Owner navigation and the personal profile’s person/pet identity, favorites and walking experience remain in place.

## Routes and components

| Route | Purpose |
| --- | --- |
| `/auth/complete` | Account-aware entry after authentication |
| `/roles` | Role selection or later role changes |
| `/helper/onboarding` | Helper identity/preferences editing |
| `/requests`, `/my-walks` | Focused helper destinations |
| `/profile` | Existing owner profile or own helper profile according to active mode |
| `/walk/:id` | Request/assigned agreement and eligible actions |
| `/chat/:id` | Existing authorized conversation with walk context |
| `/helper/:id`, `/owner/:id` | Role-labelled public/self reputation views |
| `/review/:id?role=helper` | Owner reviewing the assigned helper |
| `/review/:id?role=owner` | Assigned helper reviewing the owner |

`account_mode.dart` owns the role/profile repositories, asynchronous account controller and account-scoped memory draft. `helper_onboarding.dart` presents the two-step form. `helper_requests_screen.dart` contains the two list destinations and reusable request row/result states. `walking_repository.dart` adapts discovery, personal lists, owner reputation and review commands. Existing `walks_screen.dart`, walking profile components and chat components provide agreement actions, helper reviews and conversation rendering. `app.dart` owns routes, shell destinations and the mode switch.

## Real API versus demo

With a configured signed-in Supabase client, roles use `my_account_mode`, `set_account_role` and `switch_account_mode`; preferences use `walking_helper_profiles` and `save_walking_helper_profile`. Discovery uses `search_walk_requests`; personal views use `my_walks` with `role_in=all`. Owner reputation uses server-derived `owner_stats` and published `walk_owner_reviews`; review commands use `review_walk` or `review_walk_owner`. Existing assignment, private-detail, chat, reply/report/block APIs remain authoritative. See [walking API contract](walking-api.md).

Without a backend, account roles/preferences, synthetic requests/reviews and chat are an in-memory preview. Demo aggregates are derived from demo fixtures; they are not production reputation. Demo data resets with the preview lifecycle and does not create cloud accounts, agreements, reviews or uploads. Production aggregate totals are not client-writable.

Migrations 026–028 were already deployed to staging in the preceding backend task. This UI rollout adds no migration or deployment. Earlier local backend workflow/security tests and read-only cloud smoke tests do not establish that the new mobile screens have completed a real cloud agreement flow.

## Interaction, privacy and accessibility

- Studio typography, semantic light/dark themes, rounded restrained actions and existing motion preferences are reused. Long content wraps; lists/forms scroll rather than relying on fixed content heights.
- Selected tabs and roles have semantic selection; loading and recoverable errors have readable labels. Form labels remain visible in focused and unfocused states. Pending writes disable duplicate submission.
- Helper onboarding keeps an account-scoped memory draft, including selected photo, after recoverable failures. Its name/photo/preferences saves are separate operations: partial success is possible, so retrying retains form content instead of claiming an atomic profile transaction.
- Role/mode changes preserve account identity, conversation access and agreement history. Account changes invalidate account-scoped state; helper drafts are not plaintext disk caches.
- Public discovery/preferences contain district-level labels, never GPS or private care instructions. Private instructions remain in authorized participant detail views under server permissions. A discovery applicant does not gain an assigned agreement’s chat or handover details.
- Reviews and helper experience support decisions; they are not verification or safety guarantees. Ratings for places, owners and helpers remain separate. No payment, live tracking, subscription gate or new cancellation/dispute policy was added.
- Photo messages reuse the existing photo-only pipeline and limits; the UI adds no video upload path. Browser/mockup review cannot certify VoiceOver/TalkBack, native keyboard behavior, physical-device readability or server authorization.

## Design refinement — 10 October 2026

- Discovery distinguishes draft filters from the query currently displayed. City changes apply immediately; district/date/size changes have explicit apply/reset and public district suggestions. Unknown city time zones have actionable guidance. Later pages preserve loaded rows during loading or recoverable failure.
- My walks keeps upcoming agreements and applications distinct; History has its own heading, explanation and route back. At enlarged text sizes the two controls stack with complete labels.
- Helper Chats uses helper-specific guidance and Requests as its empty-state action. Direct conversations with owners remain distinct from assignment-specific agreement chats.
- Onboarding shows two-step progress and a persistent safe-area action above the keyboard. Biography/experience are optional disclosure. Long labels wrap outside inputs with semantic labels. Service districts are removable chips, with count, length/duplicate/maximum constraints; the pending district is included when saving.
- Own helper profile places readiness and discovery before detailed preferences. No reviews and no completed walks form a compact summary; unavailable data retains retry instead of impersonating an empty profile. Public preferences remain scoped to the viewed person.
- Requests offers concise, optional workflow guidance covering application, owner selection, participant chat, start/finish, owner confirmation and separate eligible reviews. It introduces no new product rules.
- Interface-authored weekday labels, validation and new copy use the existing four-language localization system. User-entered names and districts are not translated.

## Validation and remaining acceptance

Latest verification (10 October refinement): the full Flutter suite had 272 passing tests and two failures: a city-search performance threshold under concurrent machine load, and a help-return assertion that did not scroll to its lazily rendered row. The corrected discovery tests plus the isolated city checks passed all 17 cases. Final onboarding/profile/recovery/localization checks passed 56 cases, including two newly added recovery tests; the last locale-format correction passed 15 further targeted cases. Final static analysis reports no issues. All 44 RU/EN widget-render cases passed: eleven screen scenarios, both themes, including 320px layouts at 200% text. These are fresh Flutter rasters, explicitly labelled `widget-*`, rather than fresh native-device captures. The independent source/visual reassessment is 35/40, improved from 26/40; test passes do not award heuristic points.

Earlier native iOS onboarding and same-identity mode-switch checks belong to the preceding rollout. The current Mac lock prevented new native interaction and screen-reader confirmation. Final iOS Simulator debug and Android debug builds succeeded; their outcomes are recorded in [progress](progress.md). The Impeccable detector was attempted once but does not support Dart; its empty output is not automated Flutter clearance. No browser overlay or critique server was started.

Real staging acceptance still needs a signed-in owner/helper agreement flow: apply, assign, participant chat/photo, helper start/finish, owner confirm, both eligible review directions and replies. Confirm both themes, compact phones, enlarged system text, safe areas, keyboard behavior and screen-reader navigation on iOS/Android. Cloud backend deployment status and mobile build/install status are separate facts.

The public owner profile currently loads the latest 40 published reviews. Requests and walking lists paginate. No new production deployment was performed.

## Review 60 Flutter alignment — 16 October 2026

The Flutter adoption keeps the Studio presentation and the existing owner/helper
shells. Meetings is now the third People segment, with dedicated details,
community-scoped discovery, shared city selection, staged date filters, and a
single creation form. The venue picker owns its search-area city and does not
change Nearby's manual city. Duration, optional community association and an
optional capacity are submitted together with the public venue. Duration is 15–480
minutes in 15-minute increments, validated in the form and creation RPC. Full meetings
leave nonparticipant discovery while their exact shared details remain readable.

Meeting sharing uses accessible existing conversations and an account-scoped
composer attachment draft. Existing text/photos remain in the draft; only Send
transmits the canonical public event link through the existing authenticated
message RPC. The message card reopens that event, without joining the recipient.
Inbox previews describe the shared content instead of exposing its link syntax.
New chat preserves its search route or sheet, query and conversation draft on Back; unknown conversation IDs recover without
substituting demo messages. Activity entries route by their stored context ID.

Walking chat keeps its compact status entry. Timer and actor-permitted lifecycle
actions open in a shared sheet. The elapsed clock uses actual start/finish
metadata, never the planned start or location tracking; older records without
clock metadata show an unknown duration. Agreement details, including completed
history, reopen the same conversation and restore the details sheet on Back.
Current/history filters stage changes; shared date/time sheets commit explicitly.
An owner without a pet can add one and return to the existing request form.
Community details expose members, rules and community meetings.

Apply `supabase/migrations/202610160029_review60_native_parity.sql` before using
this client against a configured backend. Existing RPCs remain available; the
new creation RPC validates owner capability and community membership atomically.
Walking timestamps are recorded by a server trigger, with the existing lifecycle
authorization unchanged. This repository change does not deploy the migration or
configure production Auth, maps, push, Storage or Live Activities.

The pre-change Flutter sources/tests/migrations are preserved with checksums in
`design/flutter-revisions/pre-review60-20261016-093009/`. Browser Review 60 and all
its prior archived screen definitions remain unchanged. Native captures and the
final verification captures are in `docs/screenshots/review60-native/final/` and
`docs/checks/review60-native/`. iOS simulator and isolated PostgreSQL contract
checks are separate from production authorization and Android acceptance. Android
packaging requires an installed Android SDK, which is absent on this machine.

The broad Flutter suite completed with 490 passing tests and 38 failures. All 38
failures reproduce in the preserved pre-change sources; the baseline comparison
is saved in `docs/checks/review60-native/baseline-comparison.json`. The broad suite
is therefore not green. Targeted Review 60 checks and native simulator acceptance
are recorded separately; they do not imply full staging or Android acceptance.
