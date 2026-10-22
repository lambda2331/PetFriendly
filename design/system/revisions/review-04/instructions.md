# PetFriendly Studio design system

Use this instruction set before creating or changing app designs. Studio is the approved direction: quiet neutral surfaces, strong typography, generous spacing and a lime accent. Review 25 is the current browser review candidate; it does not grant blanket approval to change other screens or business flows.

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

## Future update workflow

1. Read these instructions, the component contract and the current surface in the workflow map.
2. Identify the existing reusable component with the same intent; confirm which states and locales are affected.
3. Review any new action/destination/flow behavior with the user first.
4. Archive the current candidate. Change only authorized active surfaces, applying the shared fix to matching active uses.
5. Inspect the changed states in a bounded pass; check representative themes, large text, keyboard behavior and localized labels. Browser checks do not establish native/server protection.
6. Update the workflow map, handoff and component contract if a convention intentionally changes. Preserve archived/frozen sources and verify their hashes.

[Open the standalone component catalog](../design/system/index.html). The catalog is a reference surface; its theme controls do not affect the app.
