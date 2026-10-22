> Review 20 status: the Review 19 implementation below is historical and archived. The active mock restores approved Review 18 UI. Missing actions are mapped in [workflow-map.html](workflow-map.html) and await user review before flow changes.

# Business requirements audit — active browser mocks

**Follow-up:** Review 19 implements the mock-flow repairs and adds coverage scenarios; see [repair and verification notes](handoff.md#review-19--business-flow-repairs-preserving-studio-ui). This report below retains the pre-repair findings as audit evidence.

**Date:** 14 October 2026. **Candidate:** onboarding-unified-account-2026-10-14, through Review 18. **Result:** requirements are partially represented; the candidate is not yet a complete, coherent end-to-end product mock.

The strongest coverage is common profile entry, contextual helper preferences, Current search/filters, voluntary community membership, place proposals, and shared place-detail presentation. The largest gaps are shared identity/state, working navigation out of Walks, actual conversation targets, and completion of request → application → assignment → agreement → eligible review journeys.

This is a read-only business-analysis audit. No mock, frozen reference, archive, Flutter source, or backend was changed. Only this report was added. Findings below come from tracing the active HTML/JavaScript and its imported references; this audit did not perform a new browser click-through or security test. Previous browser checks recorded in `handoff.md` support particular interactions, not the entire requirements set. “Code-traced” means the actual handler/result was inspected; it does not claim runtime verification. Static labels, controls, and text alone are not counted as completed workflows.

## Requirement precedence and scope

1. Current session decisions take precedence: one account can request help and help others concurrently; no mode-switch UI. Cat sitting is a proposed browser preference, not an approved/implemented complete request/API workflow. Review 18 removes the Current summary line; Show and Date remain in the combined filter sheet.
2. AGENTS project decisions, `docs/design.md`, `docs/architecture.md`, `docs/security.md`, `docs/walking-api.md`, `docs/helper-mode-implementation.md`, and `design/project-settings.json` form the baseline. Older owner/helper navigation-mode requirements describe the existing native/server contract, not a requirement to restore mode switching in this candidate.
3. `handoff.md` records intentional design-preview limits. Synthetic fixtures, memory-only data, unavailable maps, simulated permissions/authentication, and unconnected production integrations are not defects by themselves. A misleading or disconnected **mock action** can still be a gap even when backend integration is intentionally absent.
4. Cancellation/dispute rules and retention durations remain explicitly deferred. This report does not invent policies, deadlines, refunds, dispute outcomes, or retention periods.

## Active-surface inventory and coverage

Archived revisions, frozen alternative screen selectors, and old links in `versions.html` are reference material, not additional active product screens. The active chain is root `index.html`/`app.js` → `endpoint.html`/`endpoint-adapter.js` → Nearby, People, Walks, Chats and Profile; its editors and place renderer are included below.

| Surface / requirement | Active source | Coverage and evidence level | Remaining business gap |
|---|---|---|---|
| Auth entry/provider choices | `app.js:18–20,27,40`; imported sign-in references are historical | Confirmation and supplied/missing provider-name states are code-traced fixtures. Returning complete profile skips setup. No fresh auth verification. | Actual sign-in, password recovery, MFA gate and linking journeys are not represented in the active candidate. See C01. |
| Common/partial profile | `app.js:20,24,40` | Name and country-qualified city validation, optional district/photo, partial completion, no mandatory role/pet; code-traced. | Saved identity does not hydrate downstream app; BA01. |
| Photo/provider suggestion | `app.js:23,34`; editor import `profile-edit-reference.html:1` | Explicit Google import, Telegram preview, re-encoding for root local photo, saved-profile authority fixture. | Saved photo is not bridged into shell; invalid/failed root photo has no explanatory recovery; BA01/BA10. |
| Onboarding city/manual/location fallback | `app.js:19,30,35–38` | Four searchable country/region fixtures, explicit simulated detection, country-required manual entry; code-traced. | Selected city is disconnected from app; manual helper settlement borrows previous zone; BA01/BA07. Full directory is intentionally not present. |
| Helper preference page | `app.js:26,39–40,47,51–56,65–79` | Request/profile entry, no own pet, experience-or-beginner validation, service choices, dog-size conditional fields, weekday/time inputs and sorted/deleteable intervals; code-traced. | Saved vs edited drafts are conflated; origin/request context and return-list state not carried through; BA02. |
| First request without pet | `app.js:55–60`; `pet-edit-reference.html:1`; `walking-reference.html:15` | Review shortcut opens existing pet editor; saving prefills request name/care, no automatic publication; code-traced. | Normal Create bypasses prerequisite; one pet is overwritten and actual request publication is not represented; BA03/BA04. |
| Nearby greeting/event/map | `nearby-reference.html:1`; `nearby-city-picker.js:1–12`; `endpoint-adapter.js:18–20,29–32` | Greeting/banner, explicit city picker, honest unavailable-map and Places navigation; city retained within endpoint instance. | Different-city list/proposal/event content stays Minsk; remembered selection resets when root recreates endpoint; BA01/BA07. No live map validation claimed. |
| Places list | `places-reference.html:1–4,10,25–30` | Name/category/favorites, empty-result recovery, fixed controls and result scroll; code-traced and prior handoff checks. | Shared favorites and selected city absent; catalog/filter variants incomplete; BA06/BA07/C02. |
| Place details/reviews/map focus | `places-reference.html:12–25,55–58`; `endpoint-adapter.js:45–50` | Shared Nearby/Profile renderer, profile unrated fixtures omit rating, error/loading/retry, review composition, named unavailable-map destination; code-traced. | Favorites not synchronized; composed review not displayed as submitted content, duplicate rule unspecified; BA06/BA10. Real map focus is untestable here. |
| Public place proposal | `places-reference.html:32–51` | Synthetic public point → name/category/comment → explicit confirmation → author-only pending preview. Unknown pet access retained; no public insertion; code-traced. | Local proposal disappears across reference recreation; selected city ignored; existing pending proposal can be overwritten. BA07/BA09. |
| People | `people-reference.html:1`; `../../references/people-community-studio/app.js:29–37,42` | Separate People/Community queries and filters, pet details, empty/loading/error/retry, person chat; code-traced. | Shell Chats is a separate disconnected fixture; state resets on section navigation. BA01/BA05. |
| Community detail/create/join/leave/invite | `../../references/people-community-studio/app.js:23,26,40–43` | Voluntary join, joined-only group chat, visible member summary, recipient-specific invitation draft, copy fallback, creation adds local group; code-traced. | Invitation deep link opens hidden second preview; created links don't resolve in a fresh instance; members/rules/events not represented. BA08/C03. |
| Meeting detail/join/chat | `endpoint-adapter.js:29–36` | Organiser, public venue/time, participant count changes on Join/Leave, chat only after join; code-traced. | No creation/picker or event-specific state; meeting chat is a read-only notice. BA05/C03. |
| Walks Current | `walking-reference.html:3–14` | Search + combined Show/Date draft filters, Apply/Reset/cancel, active badge, mixed own/request/nearby cards, no removed summary; code-traced and prior handoff checks. | Navigation buttons outside Walks only show notices; own applications never appear. BA02/BA04. |
| Walk request/create/candidates | imported `../../frozen/design/walks-studio-review/app.js:25,28` | Form with calendar/duration/public district/private instructions; applicant snippet; fixture selection moves to chat. | Publish only closes/toasts; selection lacks explicit confirmation/record identity; BA04. |
| Agreement actions/private details | imported Walks `app.js:24–28` | Owner fixture can confirm when awaiting; private handover is in agreement detail, not nearby request. | Assigned-helper start/finish inaccessible in visible owner-only instance; actions not record-specific. BA04. |
| Walk History/Reviews | imported Walks `app.js:20–22,25,28,45–49` | Search/date fixture, separate role aggregate display, review/rating/reply controls. | One actor-wide reviewed/reply flag, no record eligibility/moderation/report path; conflicting identity and review editor. BA01/BA11. |
| Chats list/new chat | imported shell `app.js:12–13,31–33,46` | Search, tabs, unread labels, new-chat person row; static/list actions code-traced. | Every row opens the same generic read-only conversation; BA05. |
| Profile/edit/pets | `endpoint-adapter.js:7–16,39–40`; editor wrappers | Compact person/pet cards, profile text saves, Add Pet and helper preference entry; code-traced. | Name/photo/city not unified; Add replaces one pet; pet detail remains hard-coded; BA01/BA03. |
| Profile favorites | `endpoint-adapter.js:45–50`; `places-reference.html:57–58` | Correct distinct places, shared renderer, named map fallback preserves endpoint manual city; code-traced. | Removing favorite doesn't remove row; Nearby saves don't appear; BA06. |
| Settings/theme/language | imported shell `app.js:15,33,41–44` | Separate settings, theme/system choice and language choice controls exist. | Language changes only label; root settings don't propagate to references or persist; BA07. |
| Notifications/activity | imported shell `app.js:3,16–24,27,45` | Categories, mark-all-read, unread filtering and missing-event destination code-traced. | Conversation/application/agreement notification targets are generic descriptions, not real corresponding object screens; BA05/BA04. Permission is intentionally simulated. |
| Security/privacy/account management | imported shell `app.js:31–33` | Security placeholder and logout confirmation are static coverage only. | MFA/sessions/privacy/export/delete absent; Logout only closes dialog; C01/BA12. |

Ranges in this matrix are orientation only. Precise actionable evidence is linked below. Long minified lines contain several functions.

## Prioritized fixes for the current mock

**P1** = blocks or misrepresents a core journey. **P2** = breaks continuity or prevents requirement review. These are mock changes, not claims about production-server defects. Preserve the frozen sources; implement fixes in candidate adapters/shared preview state.

### BA01 — P1: Give all active mocks one account-scoped source of preview state

**Trigger:** finish common profile, enter Profile/Walks/People, save a profile change, leave and return, or switch account.

**Current:** root `draft` saves only to root memory. Shell Profile stays Anna; Walks Reviews identifies Artem; request details can identify Artem while shell identifies Anna. Editor/profile/pet/city state belongs to new child iframe instances. Root account switch isolates root drafts but does not transfer a coherent account into references. See [root init/save](app.js:20), [root save](app.js:40), [shell identity adapter](endpoint-adapter.js:7), [Walks review identity](../../frozen/design/walks-studio-review/app.js:21), [request owner](../../frozen/design/walks-studio-review/app.js:25).

**Expected action/result:** establish a top-level memory-only store keyed by account ID, with saved identity, saved preferences, pets, favorite IDs, city selection and records. Child screens receive snapshot/context and report mutations by stable IDs. Distinguish display names from identity. Scope drafts to account + form + record; returning to sections must not instantiate unrelated default people.

**Acceptance:** save “Test owner” and chosen city; every own profile/request/history shows that actor. Edit it and navigate away/back: same result. Account B sees no A chats/pet drafts/preferences; switching back follows the explicitly documented memory-draft behavior. No plaintext personal data is added to disk.

### BA02 — P1: Complete the first-offer/resume journey with a request ID and a real pending application

**Trigger:** Apply on nearby request → helper setup → Save → Confirm; then return to Current or reapply.

**Current:** `openHelperSetup('request')` carries only a generic origin. Confirmation is always Bonya/Minsk/18:00. Confirm sets `page='sent'`; no application is created and no request card changes. Returning shows default nearby entry with Apply again. Entering the root form recreates endpoint, so its query/date/type restoration doesn't survive this journey. The `helperSaved` boolean and mutable `draft` also allow unsaved edits to coexist with a previously saved-ready flag. See [context entry](app.js:47), [confirmation content](app.js:27), [confirmation/save](app.js:40), [Current Apply](walking-reference.html:13), [endpoint-only filter memory](endpoint-adapter.js:54).

**Expected action/result:** carry request ID plus return destination/filter/scroll snapshot; save preferences separately from a working draft. Confirm explicitly creates one mock application for that request. Restore Current, show Applied/pending with withdrawal action and a distinct own-application context; don't expose agreement chat/private instructions until selected. Closing setup returns to initiating list/detail. Cancelling draft edits restores saved values or offers explicit keep/discard behavior.

**Acceptance:** first setup saves without sending; Confirm creates exactly one application; repeat Apply is disabled or opens existing application; withdraw updates state. Back before Confirm sends none. Request name/time/city remains the selected request, filters survive, and Profile preference edits never send an application.

### BA03 — P1: Connect pet prerequisite, Add Pet and pet details to owned pet records

**Trigger:** tap normal Walks “+” with no pet; add a second pet; open the newly added pet; begin a request.

**Current:** only review control “First request, no pet” opens prerequisite flow. Normal plus always opens a text field prefilled Persik. Profile Add replaces `petPreview`, not a list; detail title/kind remain Persik/cat/British from frozen shell. Editor photo/care do not all transfer into Profile. See [normal plus/create](../../frozen/design/walks-studio-review/app.js:22), [text pet input](../../frozen/design/walks-studio-review/app.js:25), [single-pet replacement](endpoint-adapter.js:11), [updatePetPreview](endpoint-adapter.js:16), [fixed detail](../../frozen/design/shell-settings-studio-review/app.js:33), [contextual resume](app.js:55).

**Expected action/result:** normal Create checks owned pet collection. No pet → contextual Add Pet, then resume the unsent request draft. Existing pets → select by ID, not arbitrary name. Add appends a pet; Edit changes the chosen ID; details/photo/species/care read that record. Cancel returns without publishing.

**Acceptance:** add cat A and dog B, both remain; opening B shows B. Request selects B. With no pets, normal plus reaches Add flow and returns to same request; cancelling preserves request draft and adds nothing.

### BA04 — P1: Model request publication, selection and agreement stages as object-specific actions

**Trigger:** Publish own request, open Responses, Choose helper, start/finish/confirm a walk, or open corresponding activity event.

**Current:** `createRequest()` remembers input, closes and shows “saved”; Current still renders hard-coded rows. `choose()` immediately mutates one view's status and opens chat, with no selection confirmation or request identity. Active candidate exposes only owner `views[0]`, leaving helper start/finish actions unreachable without hidden controls. `advance()` changes every fixture view status; request ownership differs from current account. Activity application/agreement targets show explanatory notices. See [publish/choose/advance](../../frozen/design/walks-studio-review/app.js:28), [visible owner instance](walking-reference.html:1), [stage action](../../frozen/design/walks-studio-review/app.js:24), [notification notice](../../frozen/design/shell-settings-studio-review/app.js:31).

**Expected action/result:** Publish adds one owned open request with submitted pet/date/duration/district and separated private instructions. Responses opens that request's applicants and profiles/reputation. Choose opens an explicit confirmation, then creates one assigned agreement/chat and removes pending actions. Current handles owner and assigned-helper relationships concurrently under one account; helper Start → Finish → awaiting owner confirmation; owner Confirm → History + eligible reviews. Each command updates only its record and handles duplicate/unavailable/conflict fixture outcomes.

**Acceptance:** submitted values appear in list/detail; no publication on close; choose-confirm-cancel works; unselected applicant cannot open private instructions/chat; helper cannot self-confirm completion; unrelated record statuses remain unchanged. Existing open-request cancellation can be represented without inventing a new cancellation/dispute policy.

### BA05 — P1: Route Chats, notification targets and Walks navigation to their real destinations

**Trigger:** open any Chats row, New Chat result, message notification, meeting chat; tap Nearby/People/Chats/Profile from Walks.

**Current:** all shell chat rows and new-chat results open generic `conversation` content with no composer/history; event meeting chat is one read-only bubble. People and agreement chats work in separate references but don't share shell inbox. Walks nav uses `notice(...,'noticeDraft')` for non-Walks destinations; navigation refinement changes labels/motion only. See [same chat target](../../frozen/design/shell-settings-studio-review/app.js:13), [conversation placeholder](../../frozen/design/shell-settings-studio-review/app.js:31), [new-chat handler](../../frozen/design/shell-settings-studio-review/app.js:46), [meeting chat preview](endpoint-adapter.js:30), [Walks nav](../../frozen/design/walks-studio-review/app.js:26), [label-only refinement](navigation-refinement.js:1).

**Expected action/result:** use conversation IDs/kinds; inbox rows and events open the selected conversation, preserving messages/draft/scroll/unread state. People-created direct chats and joined-community/meeting/agreement chats appear in common inbox. Route all five Walks destinations through parent navigation. Show missing/deleted/unauthorized targets as unavailable with recovery.

**Acceptance:** tap two distinct rows: distinct titles/history. Send/retry preserves message and avoids duplicates; blocked/non-member cannot compose. Return and reopen preserves draft. Every bottom-nav destination works from Walks and returns without resetting its filters.

### BA06 — P2: Synchronize favorite places and preserve list state

**Trigger:** favorite in Nearby, view Profile, remove favorite from Profile, reopen list/details.

**Current:** Places uses an iframe-local empty Set; Profile always renders two fixed rows and adds each to a newly created local Set when opened. Remove updates only current iframe, never removes Profile row; reopening re-favorites it. Query/category/favorites reset after frame recreation. Shared detail/map renderer itself is present and map destination preserves manual city inside same endpoint. See [local Set](places-reference.html:3), [toggle](places-reference.html:24), [Profile-only forced favorite](places-reference.html:58), [fixed Profile rows](../../frozen/design/shell-settings-studio-review/app.js:11).

**Expected action/result:** favorite IDs use shared account store, list and Profile subscribe to same selection. Add/remove changes both screens immediately; close/back retains list query/category/scroll. Named map fallback remains honest and never changes manual city.

**Acceptance:** favorite Park in list → Profile includes Park once; remove → disappears and list heart clears; reopen doesn't restore removed item; A favorites isolated from B. No-live-map state isn't mistaken for actual map focus.

### BA07 — P2: Apply city, language and theme consistently across active references

**Trigger:** choose Warsaw, create/open place/request/meeting; change language or theme in Settings/root review controls; return from helper setup.

**Current:** Nearby remembers city only inside endpoint; Places/proposals/events/nearby request remain Minsk. Root service/profile city doesn't bridge to endpoint. Shell `selectLanguage()` changes only `languageSetting`, not application copy. Child People/Walks default ru; root theme/language/large-text controls are not consistently propagated. Manual service settlement inherits previous IANA zone with no resolution. See [city state](endpoint-adapter.js:18), [manual city](nearby-city-picker.js:9), [Minsk places](places-reference.html:1), [shell language](../../frozen/design/shell-settings-studio-review/app.js:43), [root embedding](app.js:32), [manual service zone](app.js:38).

**Expected action/result:** pass canonical city/country/zone/selection and explicit theme/locale to every active screen; preserve manual selection until explicit nearby action. Use clearly labelled empty/unavailable fixtures for unsupported cities rather than Minsk content under another city. Resolve manual-zone ambiguity before time-sensitive save; no silently borrowed zone. Translate authored controls/status/date formatting while retaining names/messages/user content.

**Acceptance:** English/Belarusian/Polish changes all controls across nav, never user names/messages. Warsaw request/detail uses Warsaw zone; city change doesn't publish location. Setting dark/system persists within review session and references match. Device-local persistence and full GeoNames lookup remain native requirements, not claimed by this memory-only candidate.

### BA08 — P2: Make community invitations open the intended visible community

**Trigger:** copy/send invitation URL, open it in a fresh candidate view; invite to newly created group.

**Current:** `communityLink()` targets current wrapper URL. URL handler sets `views[1].sheet`, but wrapper hides second preview; recipient sees first People view rather than invited community. Fresh script initializes only seed groups, so created group IDs cannot resolve. Invitation itself correctly drafts a direct message and does not auto-join. See [link builder](../../references/people-community-studio/app.js:23), [URL handler](../../references/people-community-studio/app.js:43), [hidden preview](people-reference.html:1).

**Expected action/result:** resolve community ID into visible view, show named detail and explicit Join. For memory-only created groups, either maintain shared session resolver or clearly say invitation cannot resolve outside session; don't create an apparently functional broken link. Removed/private/no-access group shows unavailable state.

**Acceptance:** open seed invitation → correct visible detail, membership unchanged until Join; sending only sends draft after explicit Send. Opening unknown/expired ID explains failure. Joining exposes correct chat and adds membership exactly once.

### BA09 — P2: Preserve proposal/draft continuity and distinguish cancel from save

**Trigger:** create place/community/request; close or navigate away with changes; return; submit two place proposals.

**Current:** some same-frame drafts survive, but closing request before submit never invokes `rememberForm`; child destruction loses community/place drafts. Place pending state supports one proposal and overwrites it. Helper text mutates original saved draft directly. No general continue/discard/keep-draft confirmation matches documented requirement. See [request draft stored only on submit](../../frozen/design/walks-studio-review/app.js:28), [community draft/close](../../references/people-community-studio/app.js:42), [single pending proposal](places-reference.html:33), [submit overwrite](places-reference.html:50), [direct helper draft mutation](app.js:21).

**Expected action/result:** per-account/per-record working drafts with explicit dirty-exit decisions. Successful local save commits once and clears working draft; cancellation doesn't mutate saved record. Pending place submissions form author-only records, with reopening/edit/resubmit states as permitted by baseline; public catalog unchanged until moderation preview outcome. No need for real backend.

**Acceptance:** type request/private instructions, close → choice to continue/discard/keep; reopen retained draft. Save clears it. Two proposals remain separately accessible only to their author. Failure retains input and permits retry without duplicate records.

### BA10 — P2: Make review composition, photo validation and failure feedback observable

**Trigger:** submit a place review; retry review loading; select oversized/invalid root profile photo; submit a recoverably failing mutation.

**Current:** place review stores stars/body but renders only “Your review saved”; a blank body is accepted with default five stars, and repeated save overwrites a Map entry without a stated rule. Existing loaded fixture review is replaced by that acknowledgement. Root oversized photo silently returns; decode failure is unhandled. People and Walks chat attachments use raw object URLs rather than the root/editor re-encoded preview. See [place composition/save](places-reference.html:25), [saved review replaces content](places-reference.html:14), [root photo](app.js:34), [People attachment](../../references/people-community-studio/app.js:42), [Walk attachment](../../frozen/design/walks-studio-review/app.js:28).

**Expected action/result:** after local review Save, show submitted rating/body as a labelled preview while preserving other reviews; required/optional comment follows agreed place-review rule (not walking rule). Define create vs edit behavior before enforcing any new place-review eligibility policy. Show file-size/type/decode errors with retry, keep prior valid photo, and use one re-encoding preview pipeline. Provide mutation saving/error/retry fixtures for reviewed core actions without claiming real upload or aggregate changes.

**Acceptance:** submitted text/stars visible; Cancel preserves previous review and draft as chosen; retry loading doesn't delete local review. Invalid photo gives readable feedback, no unintended publication; photos remain memory-only. No server rating aggregate changes claimed.

### BA11 — P2: Make walking reviews eligible per agreement and direction

**Trigger:** review from History/chat, switch Owner/Helper review aggregate, reply, edit helper preferences from Reviews.

**Current:** History always renders a completed fixture; submission sets actor-wide `reviewed` and one `reply` boolean, so roles/agreements are not independent. Reply renders fixed “Thanks for walk” rather than submitted text. Public helper profile/completed-count/no-review/unavailable/reporting flows are absent. Reviews pencil opens old Conditions editor separate from shared helper preference page. See [review role display/editor](../../frozen/design/walks-studio-review/app.js:21), [reply display](../../frozen/design/walks-studio-review/app.js:22), [form comment required](../../frozen/design/walks-studio-review/app.js:25), [review/reply mutation](../../frozen/design/walks-studio-review/app.js:28). Baseline: `docs/walking-api.md:95–104`; comment is optional in `docs/design.md:85`.

**Expected action/result:** key review by agreement + reviewer + direction. Only completed owner-confirmed agreement gives owner→assigned-helper and assigned-helper→owner action. Disable duplicate review while preserving the other direction/other records. Show real preview reply text; route preferences pencil to same shared settings. Add public role reputation with no-reviews/unavailable and report states, keeping place ratings separate.

**Acceptance:** unselected applicant/stranger/self/premature review unavailable; rating required, comment optional; writing one direction doesn't suppress other eligible direction; reply text matches input. Public profile reports published review count and completed count separately, with no zero-star placeholder or safety guarantee.

### BA12 — P2: Make Logout an actual preview transition

**Trigger:** Settings → Logout → Confirm.

**Current:** Confirm closes sheet only and leaves authenticated fixture/account content visible. See [logout confirmation handler](../../frozen/design/shell-settings-studio-review/app.js:33).

**Expected action/result:** move candidate to signed-out entry, clear account-scoped transient private state and pending asynchronous results, and explain it is a preview. Cancel keeps signed-in state. Session revocation still requires native/server verification, outside this mock.

**Acceptance:** Confirm cannot reveal previous private view via Back; Cancel changes nothing. Starting another account doesn't inherit previous chat/private-instruction state.

## Requirements not yet represented sufficiently for business sign-off

These are **coverage additions**, not bugs in intentionally unconnected integrations. Build reviewable flows only when advancing that feature; don't portray production integration as completed.

- **C01 — Auth/security/privacy/account management:** active sign-in form/error/cancel/recovery; email confirmation status refresh; provider cancellation/missing data; linking with proof of both identities; MFA enrolment/challenge/recovery; active sessions/revoke; privacy/block list; reauthenticated export/delete with consequences. Current Security is explanatory text. Prototype these action/results with simulated server outcomes; security enforcement must still be tested separately. Retention durations remain deferred, not invented. Sources: `docs/security.md`, shell `app.js:31`.
- **C02 — Catalog/detail variants:** selected-city catalog unavailable/loading/error, pet-shop/vet categories, pet-access unknown/allowed/denied/community/venue evidence/error, sort by name/distance and pet-access filter, real detail content and review count, unrated catalog row. Current two-row fixture supports only parks/playgrounds and unknown access. Map markers/clusters/gestures/venue picking cannot be reviewed through the unavailable-map placeholder; retain that honest state. Sources: `design/project-settings.json` navigation/places, `docs/design.md:174,210`, `places-reference.html:2`.
- **C03 — Community/meeting journeys:** members full list, rules/events within community, create/edit meeting including optional public point + gathering label, cancel picker preserves selected point, city change clears point+label, join full/cancelled/changed/no-access states, meeting-specific chat. Current meeting is one detail fixture and member summary is read-only. Sources: `docs/design.md:57–73,359–363`, People `app.js:40`, adapter `endpoint-adapter.js:30`.
- **C04 — Request discovery and unavailable actions:** city/district/dog-size search and request detail, own pending/unselected/withdrawn applications, selected/closed/expired/deleted request, concurrent duplicate/selection conflict outcomes, role-specific allowed actions. Current Show/Date filters are correctly consolidated but cover only three fixtures. Sources: `docs/walking-api.md:48–93`.
- **C05 — Moderation/report:** report place/user/message/review with reason, author-visible submitted result, and a separately authorized moderator preview for pending venue/review decisions. Do not expose moderator powers through a normal profile or imply client labels enforce MFA. Sources: AGENTS, `docs/security.md`, `docs/walking-api.md:104`.
- **C06 — Cross-cutting states:** offline/read-only, mutation pending/duplicate prevention/failure/retry/partial success, permission denial and stale object/no-access for each actual journey. Current review controls don't propagate consistently to child references; the shell may show ready fixtures while root State says failure/loading. Add record-specific fixture scenarios, not success toasts alone. Sources: `docs/design.md:89–99`, `docs/helper-mode-implementation.md:49–54`.

## Deliberate limitations / decisions requiring separate work

- Browser mocks do not verify Mapbox rendering, quotas, native permissions/gestures/keyboard/accessibility, GeoNames full directory, real authentication, secure storage, RLS/realtime/Storage, MFA enforcement, network persistence, FCM/APNs, or production moderation. Their absence is not converted into P1 mock bugs.
- Cat sitting can be selected and saved as a preference; a cat-sitting request/service-duration/care/assignment/review flow has not been approved or implemented. Decide that scope before advertising discoverable cat-sitting requests. Existing cat pets must continue to work in the agreed pet model; no dogs-only registration gate.
- Owner/helper server roles remain part of the native contract. Unified account UI needs an implementation mapping later; do not infer permissions from UI text or bring mode switching back merely to fit the old mock.
- Cancellation/dispute policy and retention durations remain intentionally deferred. Existing allowed-action/API paths can be reviewed, but no new deadlines/financial penalties/arbitration/retention numbers are authorized.
- Payments, live tracking, AI matching, E2EE and verified-safety claims remain excluded/unclaimed.

## Recommended fix order and retest journeys

1. **BA01 shared account/record store first.** It is the dependency for real identity, continuity and isolation, and prevents parallel patchwork callback fixes.
2. **BA05 navigation and conversation targets**, then **BA03 pets** and **BA04 request/agreement objects**. These make the core path executable.
3. **BA02 first offer/application/return context**, **BA06 favorites**, **BA07 locale/city/theme** and **BA09 dirty drafts**, all on that shared state.
4. **BA08 invitation links**, **BA10 action feedback/media/reviews**, **BA11 eligible walking reputation**, **BA12 logout**.
5. Add prioritized C01–C06 coverage when reviewing those features. Resolve deferred policy decisions only before their required launch milestone.

Retest with one account that owns a cat and dog and also helps another owner: sign in → common profile → request without pet → add/select pet → publish → review applicants → select → participant chat → assigned-helper start/finish → owner confirmation → separate eligible reviews; separately apply to another request → setup → explicit confirm → pending/withdraw. Repeat with errors/cancel, two accounts, four languages, two cities, dark/system/large text, and return navigation. Verify favorites and community invitations across sections. Record browser tests separately from native/backend/security checks; retain old revisions as evidence, not as a substitute for current active flow coverage.
