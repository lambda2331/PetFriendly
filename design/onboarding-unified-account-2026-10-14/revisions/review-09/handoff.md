# Unified account onboarding — design candidate, 14 October 2026

Review: http://127.0.0.1:8784/design/onboarding-unified-account-2026-10-14/

This is an isolated, interactive browser candidate based on the BA proposal. It does not update approved product configuration or implement Flutter/backend behavior. Review this version before native implementation. All copy in the review documentation is English; phone application copy has en/ru/be/pl variants. User names, settlement fixture names, IANA zones and other canonical content are unchanged.

## Version preservation

`prior-versions-manifest.json` inventories 192 pre-existing authored design/font files with sizes and SHA-256 hashes. All still matched after this work. Existing page directories and archives are untouched. `versions.html` links every inventoried HTML page, the new candidate and frozen copies of the latest onboarding, shell/settings, chat/profile and Walks pages. Frozen references include local font and walking asset copies; paths are rewritten only inside the new snapshot. The candidate imports its snapshot stylesheet, so edits to shared production design assets cannot change this version. Generated build trees and node_modules are excluded from preservation copying.

The old versions remain at their exact URLs. No old prototype URL is repointed. “Frozen” means the approved incumbent at the start of this task, not a claim that every historical variant was approved. The live original references and all existing archives remain available in the version index.

## Scope and journeys

| Screen/state | Entry / behavior | Required next action |
|---|---|---|
| Common profile | After authenticated/security-gated entry. Name + country-qualified city required. Optional photo/district. No global role or pet choice. | Confirm profile → frozen existing Nearby endpoint. |
| Partial profile | Account control → partial. Known city retained; missing name requested. | Complete missing data only. |
| Returning complete profile | Account control → returning. Saved name/photo treated as authoritative. | Skip onboarding → unchanged app reference. |
| Email confirmation | Email fixture. Existing login styling is untouched; this is a transition state. | Confirmed fixture → common profile. Real email status must come from Auth. |
| City picker | Explicit field tap. Search four synthetic catalog fixtures by city/country/region; location is an opt-in fixture. | Choose country-qualified city, or manual settlement + country. |
| Location denied/unavailable | Review Location selector, then explicit location action. | Search/manual remains available; no coordinates requested or published. |
| First walking-help setup | Review First offer/resume control represents explicit intent on a known request. Common identity is reused. | Service city, valid IANA zone, truthful experience or “I’m new”; confirm public details. |
| Optional help preferences | One labelled disclosure on the same form. Intro, public districts, sizes and multiple weekday intervals are optional. | No extra mandatory onboarding step. |
| Return to initiating action | Saved help setup → request confirmation showing the same Bonya fixture. | Explicit Confirm application; saving setup alone does not send one. |
| First own request without pet | A small contextual explanation links the frozen existing pet-form review; select the incumbent pet screen there. | Add own pet using existing form; resume request, then separately submit it. No pet-form redesign. |
| Loading/saving/failure | Review State control. Failure retains draft inputs; retry validates and advances. | Retry or return later in same-session memory. |
| Account switch | A/B control restores isolated drafts and clears transient error/dialog state. | Native implementation must discard stale operations/subscriptions too. |

The endpoint deliberately uses the frozen existing app shell, including its Russian fixture text. It is a reference, not a newly localized or redesigned shell. Walks retains its exact approved cards/tabs/reviews/modals. No Nearby, People, Walks, Chats, Profile, Settings, sign-in styling or general-shell edits are included.

## Provider rules

- Google: prefill only an unset name; editable. Photo import is a separate optional action, never automatic.
- Telegram: editable name suggestion; first-onboarding photo preview when no saved photo exists. No mandatory email, phone scope, username identity or bot messaging. “A” is a synthetic photo-placeholder preview, not a downloaded provider photo.
- Apple supplied name / missing-name fallback: both states are explicitly previews. Apple remains disabled in staging; no enabled Apple sign-in button or authentication claim is introduced.
- Email: confirmation state precedes setup when required. Mock confirmation cannot establish a real verified email.
- Existing manually saved name/photo win over provider fields. Completed profiles skip ordinary setup; account identity is never inferred or merged by name/email. Linking methods still requires proof of control of both identities.
- Provider and Account review selectors reset a fixture intentionally. They are not product UI and do not simulate account linking.

## Native parity specification

Reuse the current Studio review/native components and semantic colors rather than adopting browser default form styling. Fonts are copied bundled Manrope (heading/wordmark) and Golos Text (body/control), with Cyrillic coverage. No runtime font download.

| Property | Logical px / behavior |
|---|---|
| Reference phone | max width 402; height 850; narrow viewport retains 12 px outer review gutter |
| Common content inset | 20 each side; flex scroll area; footer remains reachable |
| Heading | Manrope 700, 28, line-height 1.22; wraps at large text |
| Body / fields | Golos Text 400, 16; support 12; lead 14 / 1.5 |
| Wordmark | Manrope 800, 22, inherited Studio tracking |
| Filled input | 12 padding, 12 radius, 1 px semantic border; soft surface |
| Focus/error | One border only. Error border 1 px; red icon + text immediately beneath relevant field; replaces support text. No second ring. |
| Primary action | inherited lime/on-lime, weight 600, min height 48, width fills footer |
| Footer | top 12, horizontal 20, bottom 8; one home-indicator/safe-area allowance. Native uses actual device inset, never duplicated padding. |
| Sheet | existing Studio radius24 top corners, heading20, content20 sides; constrained scroll; explicit Close |
| Light tokens | bg #f8f9f4, fg #20261d, muted #636b5b, line #dce1d3, soft #eef1e6, lime #d7ef89, on-lime #263510, error #b3261e |
| Dark tokens | inherited frozen Studio dark semantic colors; error #ffb4ab |
| Text scaling | body doubles for 200%; hierarchy/support/controls adapt, long headings wrap; scrolling remains available |
| Motion | existing project timings (tap100/tab180/navigation220/sheet250 ms), respect reduced motion; no new animation concept |

The browser keyboard-height toggle reduces the phone viewport to 600 px; it is a layout proxy, not an OS keyboard. Flutter must use the actual viewInsets, safe area, scrolling and focus behavior on iOS/Android. Existing sheet/input/primary button/photo pipeline/city catalog components should be reused. A contextual helper entry and origin-preserving controller/route are required; neither is a new visual widget family. Keep business rules in controllers/services/repositories, not form widgets.

Supporting errors follow [Material's field validity/supporting-text API](https://github.com/material-components/material-web/blob/main/docs/components/text-field.md). Field use and validation context follow [Apple Text fields](https://developer.apple.com/design/human-interface-guidelines/text-fields). Modal closure/focus follows [Apple Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets). These sources guide mechanics; the established Studio tokens and approved thin borders remain visual authority.

## Validation and preservation evidence

- `node --check app.js` passed; browser console error capture empty.
- Profile screenshots: en/ru/be/pl at390, light. Captured and measured each form without horizontal overflow.
- Profile at320 with enlarged text: all four locales, light/dark captured. Found a long Russian title overflowing inside its content area, corrected wrapping, and confirmed the final Russian width equals scroll width (294). Other initial combinations had no overflow.
- Helper setup: en/ru/be/pl at390, light/dark captured and measured, content/scroll width364 in all eight. Additional English320 enlarged/dark and keyboard-height captures.
- Visually inspected representative English profile, denied city picker, helper and enlarged-text rendering. Captures for the full matrix are available under `evidence/`; not every screenshot represents an independent human usability or screen-reader test.
- Exercised field-level name/city/experience validation, explicit denied-location fallback, provider fixture differences, returning-user skip, retained input after failure, and setup → unsent application confirmation. Saved details do not implicitly send an application.
- Not tested: native iOS/Android pixels, real keyboard, VoiceOver/TalkBack, hardware text scaling, server/Auth/OIDC, actual permission/location, asynchronous photo processing, production GeoNames aliases, secure persistence or stale-account-response races. These are future acceptance work, not browser guarantees.

## Future implementation dependencies — separate approval/work

1. Common completion status independent of legacy product roles; stable five-destination shell and consistent ordinary capabilities require a separate Flutter/server rollout. No shell edit in this task.
2. Server-derived helper readiness/publication, minimum experience/newcomer state and valid public service city/zone. Existing stricter onboarding/RPC contracts must be reconciled before relying on this form.
3. Save helper details atomically/retry safely, preserve origin request/discovery/tab and require explicit application submission. Keep atomic assignment, deduplication, participants-only private data and both review directions.
4. Availability/pause placement remains an annotated future Walking-settings dependency; no new Settings control is designed here. Preserve assigned walks and existing applications; do not implement pause by removing a role.
5. Real international GeoNames autocomplete, aliases, country/region and country-qualified smaller settlements; valid zone lookup/choice. Current picker contains only four review fixtures.
6. Photo re-encoding/private save pipeline after confirmation, saved identity precedence, secure account-scoped draft policy and stale async/account-switch guards. Memory-only draft loss on process restart must be handled explicitly; do not persist private plaintext by convenience.
7. Preserve existing MFA/reauthentication before protected entry/actions, token storage, revocation and server authorization. No security gate is bypassed by this design.
8. Legacy clients/migration readiness, Apple staging enablement and Telegram compatibility remain implementation acceptance work. No account merging or administrative privilege from provider metadata.
9. No new payments, live tracking, identity-verification guarantees or deferred cancellation/retention policy decisions.

No app rebuild, simulator action, deployment or account mutation was performed. Await human mock review before native work.

## Review 02 corrections
- Before editing, Review 01 sources were archived at revisions/review-01/. Frozen source references and all old originals remain untouched.
- Photo setup is now one 112 px avatar control with a small camera badge and one optional hint. Tapping it opens source actions: gallery, explicit provider import when available, remove preview when applicable. The native implementation should use the system [Apple Photos picker](https://developer.apple.com/documentation/PhotosUI/PhotosPicker); this browser fixture uses a synthetic preview, not library access. The badge arrangement is a Studio design choice, not a platform mandate.
- The 48 px location icon sits beside the city search field, with localized tooltip/accessibility name. [Material icon accessibility guidance](https://material-web.dev/components/icon/) supports retaining an accessible name when text is omitted. No automatic permission/location request.
- Manual smaller-settlement entry is shown only after a search has no catalog match. It is retained for international settlements outside cities15000; country qualification remains required.
- Nearby now embeds the approved existing native Nearby review runtime, not the shell-review map placeholder. Its generated app/assets are referenced in place, not duplicated or edited. People uses a copied approved People reference, preserving its cards, segments and details. Preview adapters connect their navigation; neither original page is modified.
- The profile pencil opens the existing full chat/profile editor rather than the shell fixture's bio-only form. Edited name/city/district/bio return to the preview card. This is in-memory preview wiring, not a new profile design or backend update.
- Checked: photo source choices; manual action absent before search and present on no match; actual Nearby and People rendering; profile name edit/save reflected on the card; empty browser console error capture. New captures use review02-* filenames; earlier captures remain preserved.

## Review 03 — human-requested refinements
Review 02 is preserved at revisions/review-02/ before this edit batch. Original pages and frozen assets remain unchanged.
- Avatar now directly opens the image file picker; provider import is a separate one-tap text action. No custom source sheet is required. Selected images are re-encoded through canvas for a local preview; no upload occurs. Account changes guard the pending decode. Native uses the existing system photo pipeline.
- People removes redundant headline minimum-height and reduces heading-to-tabs margin to 8 px; cards, segments and actions remain the approved design. No filler description was added.
- Profile pets restores the divider/section heading plus Add action and compact pet row from the previous profile reference. Add opens the existing pet form. No new form concept.
- Nearby is now a scoped HTML candidate instead of the previously frozen native runtime: Manrope800 greeting30, meeting title700/18, shorter secondary metadata, city selector then Places list on one row, fullscreen at the map’s upper corner. Side inset20 and map radius20 retained. Map remains honestly unavailable. Existing native/runtime versions remain preserved; this candidate has not been ported to Flutter.
- Nearby preview interactions are fixtures: meeting details, city choices, Places list and fullscreen unavailable map. The small new Nearby fixture is Russian only; international search/catalog, other-language copy and native gesture/keyboard validation require implementation follow-up. Do not claim a real map/catalog connection.
- Verified at390: revised photo action wiring, restored pet-section controls, People rendering, Nearby rendering/action placement; local syntax checks. These refinements do not broaden backend or native implementation scope.

## Review 04 — Nearby city and Places corrections
- Review 03 sources are preserved before changes at revisions/review-03/.
- Nearby city picker now follows onboarding: searchable country/region rows, adjacent 48 px location icon with an accessible label, no-match manual settlement/country fallback, and denied/unavailable feedback.
- Detection is explicit only. The Location review control supplies a synthetic permission outcome; no real geolocation is requested. Successful detection switches to nearby selection. Manual selection is remembered in endpoint memory and is not automatically overwritten.
- Places opens the existing compiled /places screen from the preserved Nearby review runtime, including search, category select, filters and original place rows. The one-row sheet is removed. A visible Back action returns to the refined Nearby mock.
- The restored native list uses its existing Minsk/demo fixtures; bridging selected international city/catalog state into that frozen runtime is not implemented. The real Flutter implementation must share its existing selected-city controller. Do not interpret fixture distances/ratings as fresh server results.
- Checked: denied detection keeps search available; successful simulated detection selects Minsk; original Places list rendered; Back returns to Nearby; browser error logs empty. Captures: evidence/review04-city-final.png, review04-city-location.png and review04-places-restored.png.
- No Flutter, runtime build, simulator, server or original source-reference edits.

## Review 05 — Places spacing and scroll ownership
Review 04 is preserved at revisions/review-04/. The Places screen now uses a scoped HTML mock matching the prior two fixture rows and control hierarchy, so the requested layout can be reviewed without rebuilding or editing the frozen Flutter runtime.
- Status area: 16 px top / 8 px bottom; title row minimum64 with 12 px bottom padding.
- Header, search, category/filter controls and result count are fixed.
- Results and attribution occupy a separate flex scroll region with minimum height0 and overflow-y:auto. The surrounding page never scrolls.
- Verified at390 × 400: results scrollTop169; controls top108.8 px unchanged; document scrollTop0. Final phone capture at390 × 844 also saved.
- The scoped HTML filter/detail actions are fixtures, not a replacement implementation of the full native filter/editor contracts. Preserve native behavior during later implementation; only the approved spacing and scroll boundaries should change.
- Captures: evidence/review05-list-scroll.png and evidence/review05-places-fixed.png. Flutter/backend remain unchanged.

## Review 06 — single filter inline
Review 05 is preserved at revisions/review-05/. Replace the filter-sheet launcher with a heart-labelled “Избранные” toggle beside the category select. Accessible label: “Только избранные”; aria-pressed reflects selection. Activating it updates results immediately, with no Apply button or modal. Selected styling uses stronger weight/border plus a filled heart. Empty favorites have a specific explanation; toggling off restores the unfiltered fixture list.
The fixed controls/results-only scroll layout remains intact. Script syntax and the 192 original preservation hashes passed. Browser automation became unavailable during this turn (no enabled browser surfaces), so live click/render verification and a new screenshot remain unverified for this revision. Earlier screenshots show older revisions, not this final toggle.

## Review 07 — eight-comment batch
Review 06 sources are preserved at revisions/review-06/ before changes.
1. Empty favorites/search: icon, clear heading, short explanation and recovery action inside the result region. Suppress the redundant zero-results label and catalog attribution when no rows are displayed. Recovery resets filters; only results scroll.
2. Place details: restore category/city metadata, cached synthetic score, compact Map/Favorite actions and the review section instead of a generic Done-only sheet. Reviews use an explicit unavailable/retry fixture; local review preview does not update aggregates or send server data. Favorite selection updates the in-memory favorites filter. This reconstructs the previous component hierarchy for review; it is not a pixel-verified native restoration.
3. Category: replace the browser-native dropdown with the existing Studio button/choice-sheet pattern and selected trailing check.
4. Remove the global Roles entry from Settings. Contextual walking responsibilities remain in cards/history; server/internal roles are not modified.
5. Back/Close buttons have zero negative header margins and a 12 px title gap. Verified the About Back-button right edge is 12 px before the heading's left edge.
6. Notification permission card keeps 16 px between its description and action; verified computed margin16.
7. Walks uses the preserved original source through a review wrapper; hide only the obsolete account-mode badge. Cards, tabs and original modal behavior remain intact.
8. Shared bottom navigation experiment: only the selected destination shows its label, to the right of the icon. All buttons retain accessible names and 44 px minimum tap width. Applied to Nearby, People, Profile/Chats shell and the Walks wrapper; it is review-only, not a new production decision.
Checked live: empty recovery, category filtering, saving a favorite then favorites filtering, removed role entry, About header gap, notification spacing, neutral Walks badge and navigation rendering. Browser error logs empty. Captures: evidence/review07-*.png. Native accessibility/parity, full native place filter/review contracts and other-language reference copy remain later work.


## Review 08 — review retry and Walks navigation

Preserved Review 07 under revisions/review-07. Replaced the ambiguous review Retry label with “Загрузить отзывы снова”. It now demonstrates error → loading → a labelled sample review in memory, without a network request or rating aggregate changes. Native implementation should retry the reviews repository request and retain the error when that request fails.

Reset inherited Walks span dimensions, margins and backgrounds for the icon and label. Both share the same vertical center. Added 100 ms press feedback and 180 ms selected-label entrance/color transitions; prefers-reduced-motion disables transforms, transitions and entrance animation. Original Walks source, cards and interactions remain frozen.

Browser verification: icon/label centers both 809 px in the frame; retry visibly progresses through loading to the sample review; no browser console errors. Evidence: evidence/review08-walks-nav.png and evidence/review08-reviews-retry.png.


## Review 09 — compact place actions and proposal flow

Archived Review 08 before editing. Map/favorite actions now share one row of compact equal-width buttons; the review composition action aligns right.

Add place now previews public point selection → name/category/optional comment → explicit confirmation → author-only pending status. Point choice uses a clearly labelled schematic with two synthetic public venue points because this reference has no live map. This is not GPS collection. The mock retains drafts in frame memory and escapes entered text, requires a name, offers an existing card for an exact matching fixture name, and never inserts a pending proposal into public results. Categories use the existing choice sheet. Pet access remains unknown. Backend moderation, real map picking, server duplicate detection, submission, account-scoped persistence and production authorization are not implemented by this mock.

Browser checks: action buttons have equal 176 px widths and identical top position; missing-name validation; selected category preserves draft name; confirmation; save preview; reopen private pending status; public list still has two places; no console errors. Evidence: review09-compact-place-actions.png, review09-add-place-confirmation.png, review09-pending-place.png.
