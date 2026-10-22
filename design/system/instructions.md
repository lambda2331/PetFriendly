# PetFriendly Studio design system

Use this instruction set before creating or changing app designs. Studio is the approved direction: quiet neutral surfaces, strong typography, generous spacing and a lime accent. Review 28 is the current browser review candidate; it does not grant blanket approval to change other screens or business flows.

## Authority and preservation

1. The user's current request and agreed product decisions take precedence.
2. [AGENTS.md](../AGENTS.md), [design.md](design.md) and [security.md](security.md) govern behavior and release constraints.
3. [design/tokens.json](../design/tokens.json) supplies semantic foundation values. [components.json](../design/system/components.json) records the reviewed component contracts and scoped exceptions.
4. Reuse existing Flutter widgets and the active browser shared refinements. Approved screenshots and preserved versions establish visual continuity.

Before adding or changing an action, destination or flow, show the current design, missing behavior and proposed result in the [workflow map](../design/onboarding-unified-account-2026-10-14/workflow-map.html). Review it with the user before implementation. A BA gap is not permission to replace a layout. Archive the candidate before changes; never edit frozen references or prior-version files.

The reference catalog documents shared conventions. User-requested control refinements apply to matching active mocks; unrelated layouts, business flows and preserved versions stay unchanged.

## Fonts and typography

Bundle [Manrope.ttf](../assets/fonts/Manrope.ttf) and [GolosText.ttf](../assets/fonts/GolosText.ttf), including their OFL licenses. No runtime font download. Manrope serves headings, identity names and the wordmark; Golos Text serves body copy, buttons, forms, metadata and messages. CSS may use the existing `Golos` family alias. Support Cyrillic and Latin.

| Role | Family | Size / weight | Line height |
|---|---|---|---|
| Screen title | Manrope | 32 / 700 | 1.12 |
| Shared sheet title | Manrope | 20 / 700 | 1.35 |
| Person, pet or place name | Manrope | 18 / 700 | 1.35 |
| Body and form values | Golos Text | 16 / 400 | 1.4 |
| Main action label | Golos Text | 16 / 600 | 1.4 |
| Metadata | Golos Text | 14 / 400 | 1.45 |
| Small supporting label | Golos Text | 12 / 500 | 1.4 |

Keep name and metadata on separate lines in a context row. A place or person name must not look like a footnote. Prefer a short verb on a button: Send, Create, Choose, Save. Add the object only when the context is ambiguous. Avoid repeating the same sentence in heading, paragraph and action. Do not shrink text to force a translation to fit.

## Semantic color tokens

Use token names, not new local hex values. Lime belongs to the main action and selected states. Keep long text neutral. Theme the whole surface, including map overlays, sheets, system areas and media placeholders. System is the default theme.

| Token | Light | Dark |
|---|---|---|
| `background` | #F9F9F6 | #141614 |
| `surface` | #FFFFFF | #20231F |
| `textPrimary` | #20251E | #F4F5EF |
| `textSecondary` | #62695C | #BBC2B4 |
| `border` | #E4E7DD | #41483C |
| `subtle` | #EEF1E7 | #292F25 |
| `hero` | #E7EDDA | #293121 |
| `accent` | #D6ED8A | #D6ED8A |
| `onAccent` | #253314 | #253314 |
| `error` | #B3261E | #FFB4AB |
| `sheet` | #FFFFFF | #272C25 |

Browser aliases map as follows: `--bg` → background, `--fg` → textPrimary, `--muted` → textSecondary, `--line` → border, `--soft` → subtle, `--lime` → accent, `--onlime` → onAccent. Use color plus text/shape to convey state. Body text contrast must be at least 4.5:1; large text and meaningful control boundaries at least 3:1.

## Spacing and structure

Use the foundation spacing scale: 4, 8, 12, 16, 20, 24, 32, 40. Related controls use 8–12 px gaps; separate sections use 20–32. Reviewed sheet/list bodies use 20 px side padding; existing general page layouts may use 24. Preserve the host layout instead of normalizing all pages without review.

Use flat rows for people, pets, places, applicants and favorites. A single divider separates adjacent records; do not stack a last-row divider and a footer divider. Cards are for a distinct object or grouped information, not every field. Default elevation is none. Keep the approved card, map and sheet shapes; avoid introducing gradients, decorative glass or new shadow systems.

Compact editor/detail headers center titles using equal 48 px leading and trailing slots. Sheet headings stay left with a close action on the right. In list screens, header, segments, search and filters stay fixed; only results scroll. Bottom navigation stays fixed and respects safe areas.

## Buttons and action rows

- Main actions: 48 px minimum height; 44 px absolute minimum hit target. Golos Text 16/600. Existing action silhouettes are pill-shaped.
- Primary: accent background, onAccent text, no decorative border.
- Secondary: neutral background, textPrimary label and one border.
- Tertiary: text action, with a comfortable hit target; no additional filled treatment.
- Icon-only: 48 × 48 px hit target, usually a 20 px icon; always an accessible name.
- Paired actions fill the row equally, use a 12 px gap, 8 px horizontal button padding and match height. Secondary/Cancel left, primary right. At large text, stack instead of clipping.
- Loading preserves button size and readable purpose, prevents duplicate submission, and restores enabled state after error. Disabled and keyboard-focus states must be visible.

Use the same action pair for place Map/Favorite, confirmation Cancel/Send, block Cancel/Block and related paired decisions. Do not shrink just one action or leave unbalanced empty space.

## Forms and selection

Fields have visible labels outside the control, 48 px minimum height, 12 px inner padding, subtle background and a single border. Use the foundation control radius for new fields; preserve reviewed field exceptions. Focus changes the existing field border; do not add a second outer outline. An invalid focused field keeps its single error border. Keep visible keyboard focus on buttons and selection marks. Show optional status once. Errors explain the recovery next to the field and preserve the draft.

Reuse the reviewed anchored mock select for short lists (soft 48 px trigger, trailing chevron, selected check mark, Escape/outside dismissal and arrow-key navigation), with transparent resting options and a hover-only subtle fill. Selection uses a check mark and weight, without a persistent background. Use a shared searchable selection sheet for cities or longer catalogs. Related criteria belong in one filter sheet with explicit Apply and Reset. Preserve unapplied filter drafts. Do not add the rejected extra result/filter summary line to Walking Current.

Checkboxes permit independent selections; radios select exactly one value in a named group. Reviewed selection marks are 24 px inside a 48 px row. Keep native checked semantics, keyboard interaction and visible focus. Use the same mark and spacing in every section of a filter sheet. The selected radio is a single accent-filled circle with an 8 px foreground dot; avoid double rings. Center the checkbox tick with an 18 px SVG mask and a two-axis translation.

Ratings use five equal-width stars across the available row, with an 8 px gap and at least 48 px tap height. Selected stars use the lime/foreground combination. Expose labels 1–5, selected value and keyboard selection. A new review starts unset; editing may hydrate the saved value. No reviews means “No reviews yet”, never zero stars. Place ratings and role-specific walking reputation stay separate.

## Context, identity and status rows

A context row contains a 48 px neutral icon/image tile with 12 px radius, a 12 px gap, an 18 px Manrope name and 14 px metadata underneath. Reuse it for application confirmation, selected venue point, walking review context and request identity. If editable, the whole row is one labelled action with a trailing chevron; do not split metadata and Change into two unrelated controls.

Person/pet identity rows use the existing 48/56/72 px avatar variants. Community cover images may use the established 2:1 media ratio. Preserve circular versus rounded-square variants by role; never replace every avatar shape globally. Use initials or a neutral category icon when no photo exists.

Record type and lifecycle status share one row beneath the identity where width permits, wrapping only for large text or long labels. A status uses a subtle filled chip and state icon; a record type uses a transparent chip with a category icon and primary text. Reviewed chips use 14 px metadata text, 32 px minimum height, 6 × 10 px padding and 8 px radius. “Walk”, “My request” and “Nearby request” identify record type; “Scheduled”, “Looking for help” and “Completed” describe lifecycle. Do not imitate a list group heading above each record.

## Sheets, confirmations and feedback

Reuse the existing shared sheet container: title/close header, scrollable body, safe-area-aware actions, 28 px foundation radius and at most 88% viewport height for long sheets. Keep the header accessible while the body scrolls. Trap focus, allow Escape when cancellable and restore focus to the opener. A compact confirmation has one question, a context row, necessary consequence text and an action pair.

Simple sent/saved acknowledgements are status toasts on the originating screen, not full success pages. Use the primary accent/lime background with onAccent text and a matching check icon, without an additional border or icon badge. Avoid inverse dark banners in light theme. Preserve request/list context. Blocking must explain the intended effect; local mock behavior must not imply a server-enforced block. A missing conversation connection is a wiring gap, not a new empty product page.

Empty states have a concise heading, meaningful reason and recovery when useful. Error states keep existing content or draft and offer retry. Loading indicators describe a pending operation; do not imply live tracking or server activity.

## Photos, maps and chat

Photos open the gallery directly. Provider import is an explicit separate inline action and must not overwrite saved identity without confirmation. Offer removal. Local previews validate JPEG/PNG/WebP and a 5 MiB source limit, decode, resize to at most 1200 px and re-encode without original EXIF. These design previews do not imply production upload or storage. Production photos use the existing private pipeline and its stricter storage limits.

Inline maps retain side insets and rounded corners. Zoom/location controls appear only in fullscreen. Keep manual city selection until the user changes it. Public venue point selection must not publish device GPS; unavailable maps show an honest state and a useful list fallback.

Chats show sender, time and conversation context. Keep one account identity and membership-appropriate access. Photos are the only new upload type. Do not design live tracking, payments or AI matching into v1.

## Motion, language and accessibility

Use foundation timing: tap 100 ms, tab 180 ms, navigation/theme 220 ms, sheet 250 ms; curve `cubic-bezier(0.2, 0, 0, 1)`. Respect reduced motion; haptics require user preference and meaningful actions.

Support RU, EN, BE and PL. Device language by default, Russian fallback, explicit choice stored locally. Flutter uses ARB/gen-l10n and locale-aware plural/date/number formatting. Preserve user names, messages, reviews and canonical API values. Venue/walk time zones are independent of UI language.

Verify 200% text, keyboard-visible forms, long Cyrillic/Polish labels, light/dark themes, safe areas, screen-reader names, keyboard focus and minimum hit targets. Wrap/stack rather than ellipsizing important actions or hiding selected values.

## Existing implementation entry points

| Pattern | Reuse first |
|---|---|
| Theme and fonts | `design/tokens.json`, `lib/core/theme/studio_theme.dart` |
| Shared sheets | `StudioSheetHeader`, `showStudioSelectionSheet` in `lib/core/ui/components.dart`; `StudioReviewSheet` in `lib/core/ui/studio_review.dart` |
| Identity and metadata | `studioIdentityText`, `studioSheetText`; walking identity/body/meta styles |
| Walking status/action rows | `WalkingStatusLabel`, `WalkingRowActions` in `lib/features/walks/walking_studio_components.dart` |
| Dates and calendar | `WalkingDateField`, `WalkingCalendar`; city-time utilities |
| Browser shared controls | `design/onboarding-unified-account-2026-10-14/mock-system.css` is the final component layer after `shared-refinements.css` and screen styles. |
| Browser component behavior | Active app/endpoint/walking/people/places wrappers; never frozen scripts |

The browser and Flutter mappings are existing reuse locations, not a claim of pixel parity or newly shipped native widgets. Keep business logic in controllers/repositories/services.

## Known older-token differences

The foundation file retains older and scoped values. `typography.body` is 16 while older `typeScale.body` is 15; general control text is 14 while reviewed main actions use 16. Generic page padding is 24 while reviewed sheets/lists use 20. Field radii and some sheet heading sizes differ across preserved versions. Browser colors also contain near-matching historical literals.

For new work, use semantic foundations plus the named component contract. For existing approved screens, preserve the component’s appearance. Record the surface and reason for an exception, and review a migration before normalizing values across views. Do not silently rewrite tokens, old designs or production widgets to resolve these differences.

## Current mock alignment

Review 25 applies the shared component contract to all nine active browser mock sources and their workflow previews. Keep `mock-system.css` last in the cascade. It supplies variable font weights, role-based Manrope/Golos typography, 16/600 action labels, 48 px controls, single field borders, shared component colors generated from the foundation, and large-text role sizes. Screen markup, actions, routes, map/card shapes and image assets are preserved. The previous presentation remains in `revisions/review-24/`.

Intentional retained variants: Nearby’s greeting and event hero headings keep their approved scale; compact category captions use the 12 px supporting-label role; time-entry digits keep their approved 18/32 px numeric treatment; existing 12 px field corners remain a reviewed exception. Navigation labels use their approved compact label treatment. Toggle tracks remain 48 × 28 px inside 48 px button targets. Calendar controls keep seven columns with at least 44 × 48 px targets and a 4 px gap. These variants are not reasons to reduce standard form or action-label sizes.

The audit covers the 67 renderable workflow states plus the standalone moderation mock, including nested pet forms. Workflow-only gaps with no mock file remain documented; this consistency pass does not create new product flows. Browser checks do not establish native or server implementation.

## Workflow destination designs

Review 26 adds 58 review states using the same final component layer. `workflow-additions.json` is the canonical authored registry; `workflow-additions.js` is its shared UI renderer and local review navigator. After changing registry content, run `scripts/sync-workflow-review-designs.py` and update its screen/actions in `workflow-data.json`. The additional page/sheet structure lives in `workflow-additions.css`; load `mock-system.css` last. Keep the original nine screen sources unchanged when adding isolated destinations.

New destinations have status `design-proposal` and are available through the workflow map’s “New designs for review” filter. Treat their guarded transitions as designs for review, not proof of authentication, authorization, publication or deletion. Credentials and QR areas are not operational. New code must never introduce a client-controlled staff role, email-only MFA bypass, account merging by text, public handover instructions or client-written reputation aggregates.

The map now has 125 renderable states and no empty design destinations. The seven previously missing destinations are covered. Account-scoped store, caller/object IDs, real Auth/provider callbacks, server enforcement and other runtime gaps remain separately visible. Cancellation/dispute policy, data/backup retention durations and recovery without a backup factor are not invented by these designs. Browser copy is a Russian review reference; native rollout still requires the agreed RU/EN/BE/PL ARB localization.

[Workflow completion report](workflow-screen-completion.md) records coverage and validation. [Review 25](../design/onboarding-unified-account-2026-10-14/revisions/review-25/workflow-map.html) preserves the previous candidate.

## Future update workflow

1. Read these instructions, the component contract and the current surface in the workflow map.
2. Identify the existing reusable component with the same intent; confirm which states and locales are affected.
3. Review any new action/destination/flow behavior with the user first.
4. Archive the current candidate. Change only authorized active surfaces, applying the shared fix to matching active uses.
5. Inspect the changed states in a bounded pass; check representative themes, large text, keyboard behavior and localized labels. Browser checks do not establish native/server protection.
6. Update the workflow map, handoff and component contract if a convention intentionally changes. Preserve archived/frozen sources and verify their hashes.

[Open the standalone component catalog](../design/system/index.html). The catalog is a reference surface; its theme controls do not affect the app.


## Review 27 · simplification decisions (14 October 2026)

The active browser workflow supersedes Review 26. Preserve Review 26 before editing. Keep Manrope headings, Golos controls/body, semantic colors and 48 px targets. Compact dialogs use 12 px header inset, 8–12 px content/footer gaps and content height; avoid page-size confirmation views.

- Sign-in uses the incumbent email/password form plus direct Google/Apple/Telegram actions. Password recovery is a link from that form. MFA, device-session management, provider linking and data-copy journeys are excluded from the active mock. This design change does not disable implemented server or native protections.
- Public places publish directly from the form, with pet access unknown. No moderator product role or pre-publication review queue. Reports are accessible from place details; report-based removal needs a separate server rule. Do not invent a deletion threshold or claim reports enforce removal.
- Public communities are discoverable and directly joinable. Members, rules and meetings open from visible rows in community details. Tapping a member opens their direct conversation; no message is sent automatically. Invitation links are received in chat and open the public community; invitations never join or send automatically.
- Pending responses belong to compact request details. Applicant reputation/experience stays in the applicant list. Keep its request context fixed while applicants scroll. Do not add a separate helper-selection profile.
- Assigned walk, start, finish and completion status live in the participant chat. Handover instructions are collapsed and private to agreement participants. Preserve atomic assignment and owner-confirmed review eligibility.
- Browser state changes are fixtures only. Never weaken authorization or imply real authentication, publication, report handling, secure deletion or recovery from a design preview.


## Review 28 · public meetings and walking time (15 October 2026)

Keep the five bottom destinations. Public meeting discovery is the third segment in People, beside People and Communities, and is also reachable through All meetings in the Nearby banner. Community → Meetings uses the same event catalog with a community filter.

Author the meeting module in `design/onboarding-unified-account-2026-10-14/meetings-reference.html`, `meetings.js` and `meetings.css`; its review states and transitions belong in workflow-data.json. Do not add another duplicate event renderer to workflow-additions.json. All of these sources use mock-system.css and the Studio typography and color tokens.

- Public meetings allow voluntary joining without community membership, subject to capacity. Joining a meeting never joins its community. A shared link never joins or sends automatically.
- Create is one form with title, venue city, date/time in its IANA zone, duration, optional public point/gathering label, optional community association, description and optional capacity. No pet is required. Owner capability is required in production. Changing event city clears both point and gathering label; keep the rest of the working draft. Use create_event_at_location atomically when integrating. Never use a venue point as a user's live position.
- Share opens a picker of existing permitted conversations, then a meeting-card draft. Explicit Send appends a local fixture message only. A received card opens that exact event ID; an unknown ID shows an unavailable state and never another event. A real shared-inbox/API integration remains separate.
- A consistent 48 px/back-control + centered 20 px Manrope title + balanced trailing slot header is used for event details and forms. Body is 16 px Golos, identities 18 px Manrope and metadata 14 px Golos.
- Social sign-in icons supplement labelled provider buttons; use the retained local SVG brand assets at 24 px. Keep the full button label, a 48 px target and a visible focus state.
- No-pet notices use a subtle surface and a normal lime primary action. Keep a single divider before community Leave.
- The walking timer belongs in the fixed conversation context, alongside the plan and Start/Finish action. Show elapsed time, not an automatic countdown expiry. Scheduled walks show Start; active walks show elapsed time and Finish. Do not repeat the same status below the timer. Production requires a server-derived started_at timestamp, actor authorization and owner-confirmed completion. No GPS, background tracking, charges or automatic completion is introduced. The running timer after local Start and 12:34 read-only fixture are design demonstrations only.
- Browser examples are in memory. No real meeting is published, chat message sent or account permission granted. Created fixture event links do not resolve across reloads/tabs; show Not found rather than a different event. The map remains honestly unavailable until configured.


### Review 30 — field hints and compact status controls

Keep optionality out of field names. Show a secondary `Необязательно` hint adjacent to the control and associate it through `aria-describedby`; retain a persistent label. Use this treatment across active profile, pet, community, place, meeting and review mocks. Never transform user-authored content.

Meeting discovery places search first, followed by compact location and date controls. Keep selected values visible, preserve search when a date changes, and use an explicit Apply/Reset date sheet with draft cancellation. Place selection owns its search area; avoid asking for both a city and a place in meeting creation. Initial map centre may use already-authorized geodata, with a manual fallback. Venue city/time zone are derived from the chosen public point, independent of personal location. Browser fixtures use sample points and do not request GPS.

Walking chat keeps a compact status entry. Open progress, elapsed time and role-permitted actions in a content-sized sheet; helper starts/finishes, owner confirms. Live Activities / Dynamic Island are a possible native iOS follow-up, not implemented by browser HTML. Timer metadata is elapsed/planned time, never live location.


### Review 31 — meeting search and place picker

Use one search row followed by 48 px location/filter icon actions, with accessible names, tooltips and active-filter feedback. Keep selected city/date visible as secondary text below. Place picking reuses the search pattern, shared identity rows and a single explicit selection confirmation. Preserve form drafts when opening auxiliary selections; back cancels temporary place changes. The main meeting workflow preview accepts local taps and keeps the review catalog synchronized; thumbnails remain read-only.


### Review 32 — reuse Nearby city control

Meeting discovery reuses Nearby's named city selector: pin, flexible city name and trailing chevron, 48 px minimum, 12 px border radius. Search follows with the filter icon. Omit the redundant city/date summary line. The optional no-place action in the picker uses the shared full-width outlined secondary button, centered and equal in height to the primary action. This supersedes Review 31's icon-only city action and scope line on meeting discovery.


### Review 33 — shared city-picker behavior

Use Nearby's city-picker implementation for meeting discovery and meeting-place search, including search, country/region metadata and manual fallback. Host callbacks may route the chosen value to a feature-specific draft. Manual meeting cities require an explicit valid IANA time zone; do not infer it from a free-text label. Keep the original Nearby integration as the default.


### Review 34 — one city picker across active mock screens

Every city-selection entry point must reuse `nearby-city-picker.js`. Use `shared-city-adapter.js` for approved onboarding/helper forms, profile editing and walking conditions; meetings keeps its feature-specific host adapter. Preserve the containing form and its unrelated draft fields. Do not replace the shared picker with a native city dropdown, raw city input or duplicated search dialog. Manual settlement/country inputs belong inside the shared manual-entry flow. Retain country qualification; require an explicit IANA zone when scheduling needs it. Clear an old district when changing its city. Keep developer-only fixture controls, read-only city context, archived alternatives and frozen approved source snapshots separate from active product city selection.


### Review 35 — shared date and time pickers

Active browser date/time selection uses `shared-date-time.js` and the shared Studio tokens. Keep field positions and existing form drafts. Use the same 48 px trigger with a leading calendar/clock icon, value and trailing chevron. Calendar uses Monday-first localized headings, one keyboard tab stop for dates, arrow/week/month navigation, lime selection and explicit Done. Time uses labeled numeric hours/minutes with validated 00:00–23:59 entry and leading zeroes. Done applies the canonical value; close, backdrop and Escape discard picker edits and return focus. Calendar body scrolls under the fixed action at large text.

Retain date-only values and wall times in their existing venue/request/service IANA zone. Do not convert a selected date through device time or use a helper's service zone for an owner's request. Only show a zone known to the current context. Existing form validation remains authoritative and must focus the visible picker trigger, not its canonical hidden input.

Recurring weekdays and relative-date filters retain their approved compact selection patterns; read-only timestamps are not picker controls. Browser formatting uses the existing approved 24-hour entry convention with localized date labels (ru/en/be/pl). Native/backend scheduling implementation is unchanged.

### Review 36 · Filter consistency

Active browser filters share Studio typography, 48 px targets, selected checks/radios and visible keyboard focus. Keep short single-choice filters (place category, people district, community membership) anchored to their approved trigger. Group related criteria in the shared scrollable bottom sheet with a fixed action footer: Reset changes the draft, Apply commits, and Close/Escape/backdrop discard. Retain quick favorites/unread toggles and content segments in their approved locations. Active filter feedback belongs on the trigger; do not add redundant summary rows.

Places keeps its approved category/favorites row. Walking history keeps its compact date menu. Reuse `shared-filters.js` in browser hosts; frozen references and native/backend implementation remain unchanged. Review 35 is preserved.

### Review 37 · Bottom sheets and modals

Active browser hosts reuse `shared-overlays.js` and `shared-overlays.css`. Sheets use the semantic sheet surface and one 40% scrim. Header padding is 12 px vertically and 20 px horizontally, with a left-aligned Manrope title and a 48 px close action. The body uses 8 px top, 20 px side/bottom padding and internal scrolling. Keep the header accessible, the content height compact and the maximum height at 88%. Existing footers and home indicators respect safe areas. Preserve approved field order, inline actions and full-screen layouts. Approved 24 px sheet silhouettes remain an explicit legacy exception to the 28 px sheet token.

Only the top dialog is modal and interactive. Trap keyboard focus there, close one layer on Escape/backdrop using its existing close or back callback, and restore the opener when available. Auxiliary city/date/time pickers preserve their parent form draft. Do not move confirmations to new routes or add drag handles, swipe dismissal, new actions or simulated server effects during this consistency pass. Browser adaptation does not change native Flutter behavior. Review 36 is preserved.

### Review 38 · Buttons and action rows

Active browser hosts reuse `shared-actions.css`. Main actions share Golos Text 16/600, centered 20 px icons with 8 px icon/label gaps, 48 px minimum targets and pill silhouettes. Standalone actions use 12 px vertical / 16 px horizontal padding; action pairs use 8 px horizontal padding. Keep 24 px provider marks in their approved grid.

Paired rows have a 12 px gap, equal widths and matching heights. At 200% text, stack paired actions in equal-height rows so long labels wrap. Icon actions retain a 48 px square target and 20 px icon. Text actions use the same action typography and a 48 px target; contextual menu rows also reach 48 px. Preserve approved action order, single-action alignment, compact weekday/calendar choices, and the filter footer's compact Reset / expanding Apply hierarchy. Shared focus, hover/pressed and disabled treatments retain the existing button semantics and loading behavior. No routes, labels, callbacks or native/backend behavior change. Review 37 is preserved.

### Review 39 · Form fields, labels and validation

Active browser hosts reuse `shared-forms.js` and `shared-forms.css`. Keep visible labels outside fields and link the caption separately from optional/helper text. Controls share body typography, 48 px minimum height, 12 px padding, the subtle surface and a single border. Preserve approved 12/14 px shapes; square manual-city fields use the reviewed 12 px shape. Search, chat composers and compact selections keep their approved patterns.

Helper and error messages use 14 px text (scaled with large text), 8 px spacing and semantic secondary/error colors. Associate existing hints and errors with the affected field, expose each invalid control, and keep an invalid focused field's single error border without an outer outline or shadow. Manual-city errors focus the missing field or invalid time zone using the existing validator. Keep messages adjacent and actionable, retain drafts, and do not add acceptance rules or change native/backend validation in this browser consistency pass. Review 38 is preserved.


### Review 40 · Empty, loading and error states

Active browser hosts reuse `shared-states.js` and `shared-states.css`. Empty results, loading and recoverable failures share Studio spacing, semantic foregrounds, 18 px Manrope headings, 16 px Golos explanations and existing 48 px recovery actions. Keep status copy specific to the content and retain the surrounding approved header, filters and navigation. Inline loading/errors stay next to their affected content; save failures retain alert semantics and entered values. Status updates are polite live regions, decorative indicators are hidden from assistive technology and reduced motion disables indicator animation. Existing retry, reset, return and saving callbacks remain authoritative; do not simulate new network operations or alter server rules.

Date-only triggers use a compact localized numeric date on one line, with the full localized date available as a tooltip. Meeting date/time fields stack when the form is too narrow; retain canonical date values and the venue time zone. Large-text meeting headings may wrap their action to avoid horizontal overflow. Approved regular layouts remain intact. Review 39 is preserved. Native Flutter/backend implementation is unchanged.


### Review 41 · Headers, back controls and navigation

Active browser hosts reuse `shared-navigation.js` and `shared-navigation.css`. Page headers share 20 px Manrope title typography, a single semantic divider and 48 px back/action targets with 20 px icons. Keep approved centered versus left-aligned title variants, root greetings, wordmarks and chat identity headers. Back navigates through its existing feature callback; Close dismisses the current modal. Do not replace either with an unrelated route or add a back button to a root destination. Places headers use the same 8 px / 12 px centered-header insets as meetings.

Bottom navigation uses 8 px top, 12 px side and at least 12 px bottom safe-area padding, 48 px targets and 22 px icons. Retain the approved lime current-section pill and compact 12 px current label. Use one `aria-current="page"`, localized accessible names and Profile terminology. Legacy active classes are adapted to the same current-section semantics. Keep owner/helper destination sets and approved ordering. Tab groups retain existing selection and scrolling behavior; add a group name when missing and visible keyboard focus. Buttons use explicit button types; decorative navigation icons are hidden from assistive technology. Browser mock callbacks, drafts and route graph remain unchanged. Review 40 is preserved; native/backend implementation is unchanged.


### Review 42 · Typography, spacing and alignment

Active browser hosts reuse `shared-typography.css` after the shared component styles. Root toolbar and meeting-list titles use the 32/700 Manrope screen role with 1.12 line height. Introductions, profile biographies, candidate experience and private detail paragraphs use 16/400 Golos body text with 1.4 line height. Supporting notes, time-zone context and hints use the 14 px metadata role with 1.45 line height; keep field-specific helper/error styling authoritative. Large text uses the existing semantic size variables, never a smaller fixed fallback.

Use 4 px name/metadata gaps in meeting rows/cards, 24 px between helper introduction and its next section, and 16 px above the app introduction. Copy columns have zero minimum width; long identity names and descriptions wrap without moving adjacent actions outside their columns. Preserve approved page composition, alignment, 20/24 px side insets, root greeting and hero scales, chat message line height, compact navigation/status labels, image dimensions, control padding and section structure. This consistency pass changes browser presentation only. Review 41 is preserved.


### Review 43 · Final mock review

Community-meetings search/filter controls have a 16 px top inset below the page header. Keep this space when opening filters over the same list; point-picker tools retain their own existing inset. Other approved layouts and feature callbacks are retained. Review 42 is preserved. The final browser audit passes 127 screens in light/dark/200% text (381 variants) and 12 narrow screens (36 variants). All 397 registered action targets resolve; 48 known logic/wiring gaps remain explicitly marked. This is a visual mock review, not native/backend readiness or approval of proposed flows.


### Review 45 · Shared preview state and navigation foundations

F01/F02 are implemented in the workflow-map host using `preview-state.js`, `preview-host.js` and `preview-frame.js`. Mounted and nested previews share account-scoped memory, stable-ID records, separate saved identity/working drafts, UI context and an origin stack. Account switching invalidates old frame connections. Fields, list filters, scroll and exact record parameters restore on return; hydration preserves auxiliary picker/sheet states. Password/file fields and journey thumbnails are excluded. Review-only actions/submits stay disabled; dependent feature saves, sends and privileged transitions remain pending. The account/reset/back controls live on the review board, outside approved app layouts. Standalone reference behavior and native/backend implementation are unchanged. Review 44 is preserved. See `preview-foundations.md` in the workflow directory for scope and tests.
