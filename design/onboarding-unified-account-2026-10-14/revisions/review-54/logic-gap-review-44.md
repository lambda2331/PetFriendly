# Review 44 · Remaining logic/wiring proposals

All 48 existing gaps remain unimplemented and awaiting user review. Review 43 is preserved. Approved screen presentation, action statuses and current destinations are unchanged.

## Shared prerequisites

### F01 · One account-scoped preview store

One top-level memory store keyed by account plus stable object IDs; saved records separate from per-form/per-record drafts. Device theme/language preferences stay separate. No new backend persistence is implied.

Acceptance: Switching preview account cannot expose previous private records; refreshing a memory-only preview is labelled honestly.

### F02 · Shared navigation context

Carry origin screen, record ID, filter/search/scroll snapshot and draft key through existing destinations. Keep approved owner/helper navigation and modal dismissal patterns.

Acceptance: Back restores the real origin and its draft rather than a hard-coded unrelated destination.

## Account and preferences · 7 gaps

### A007 · Email confirmation → Continue after confirmation

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Fixture proceeds without real provider confirmation.

Proposed fix: Continue only after the current account’s email-confirmation state is verified. Reuse the existing email screen for pending/resend recovery; review any new expired-link presentation separately.

Expected behavior: An unconfirmed account stays on Email confirmation; confirmation resumes its own onboarding draft.

Acceptance checks:

- Unconfirmed, confirmed and expired-link cases do not skip the gate.
- Resend stays generic and does not reveal whether another account exists.

Dependencies: F01.

### A029 · Public helping preferences → Back with edited preferences

P1 · Review exit semantics · **Awaiting review, not implemented**

Current gap: Needs approved draft/exit behavior.

Proposed fix: Use the existing unsaved-change confirmation. Proposed semantics: Continue editing retains the working draft; Discard returns to the origin with saved preferences unchanged. Do not add a third Keep draft action without separate review.

Expected behavior: Back from edited helper preferences does not silently save or lose changes.

Acceptance checks:

- Continue editing restores every edited value.
- Discard leaves saved preferences unchanged and returns to the initiating request/list.

Dependencies: F01, F02.

### A048 · Edit profile → Cancel / close

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Returns to profile; cross-frame draft safety needs verification.

Proposed fix: Use the same reviewed exit policy as helper preferences: closing an unchanged editor returns directly; a dirty editor asks Continue editing or Discard. Keep working and saved identity separate.

Expected behavior: Cancel never replaces saved profile values with partial edits.

Acceptance checks:

- Continue editing retains name, photo and city draft.
- Discard restores saved identity across profile and other previews.

Dependencies: F01, A029.

### A073 · Place details and reviews → Favorite / unfavorite

P2 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Local reference memory; profile favorites are not synchronized.

Proposed fix: Use one account-scoped favorite-ID set for place list, detail and personal profile; retain existing favorite controls and profile rows.

Expected behavior: Favoriting a place makes the same place appear inline in the profile.

Acceptance checks:

- Unfavorite updates all three surfaces.
- Account switching does not leak another account’s favorite set.

Dependencies: F01.

### A200 · Theme choices → System / light / dark

P2 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Changes local fixture theme; cross-frame propagation needs verification.

Proposed fix: Share System/Light/Dark preference across shell, maps, overlays and child references. Persist the explicit device-local choice, resolving System from current device appearance.

Expected behavior: Changing theme updates all active surfaces without resetting the current form draft.

Acceptance checks:

- A nested picker uses the same theme as its parent.
- System reacts to appearance changes; explicit Light/Dark remains stable.

Dependencies: F01.

### A202 · Language choices → Device / RU / EN / BE / PL

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Selection label only; shell remains untranslated.

Proposed fix: Connect Device/RU/EN/BE/PL to shared application-copy localization and locale formatting across frames. Preserve user content, canonical IDs and venue zones; persist only the device-local choice.

Expected behavior: Language changes update controls and dates without translating a person’s name/message.

Acceptance checks:

- Device fallback is Russian when unsupported.
- Long Polish/Cyrillic labels and 200% text wrap without losing selected values.

Dependencies: F01, A200.

### A209 · Sign out confirmation → Sign out

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Current fixture only closes sheet; no session/draft teardown. Review 26 supplies the destination design; runtime object/state wiring remains a gap.

Proposed fix: After the existing sign-out confirmation, tear down account-scoped private preview state, drafts and subscriptions, then show the approved sign-in screen. Retain only agreed device preferences.

Expected behavior: The next test account cannot read the previous account’s chat or private draft.

Acceptance checks:

- Cancel does not sign out.
- Back cannot resurrect an authenticated private preview; production session revocation needs separate native/server verification.

Dependencies: F01, F02.

## Cities and maps · 4 gaps

### A008 · Profile city selector → Search alias

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Filters four fixture cities; full GeoNames directory not connected.

Proposed fix: Connect the shared Nearby city picker to the bundled GeoNames directory and aliases. Keep the current picker layout and canonical city identity.

Expected behavior: Searching a Polish alias finds the same city ID as its local name, with country and region visible.

Acceptance checks:

- No match offers the existing manual entry flow.
- City selection remains separate from device location.

Dependencies: F01.

### A014 · Manual settlement → Confirm settlement

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Requires name and country; coordinate/zone lookup remains incomplete.

Proposed fix: Retain a country-qualified manual settlement key; never fabricate coordinates. Ask for a valid IANA zone only when the originating scheduling context requires it.

Expected behavior: A small settlement can be saved without pretending that its centre or time zone was resolved.

Acceptance checks:

- Country is retained with the settlement name.
- Meeting/helper scheduling cannot proceed with an invalid required zone.

Dependencies: A008, F01.

### A061 · Nearby city picker → Nearby location

P2 · Native/configuration verification · **Awaiting review, not implemented**

Current gap: Permission preview; real service not configured.

Proposed fix: Keep the browser permission/unavailable preview honest. Native verification is separate: request location explicitly, preserve a manual city until the user chooses Nearby, and publish no GPS.

Expected behavior: Denying location keeps city selection usable; selecting Nearby is an explicit mode change.

Acceptance checks:

- Denied and unavailable location retain manual selection.
- No background tracking or silent GPS publication.

Dependencies: A008.

### A066 · Fullscreen map fallback → Map gestures / zoom / locate

P2 · Native/configuration verification · **Awaiting review, not implemented**

Current gap: No configured renderer; native verification required.

Proposed fix: Retain the unavailable-map fallback until a configured renderer is verified. Verify gestures in inline/fullscreen and zoom/location controls only in fullscreen, after free-tier account controls are checked.

Expected behavior: The mock never pretends that sample points are a functioning map renderer.

Acceptance checks:

- Fallback list remains reachable when the renderer fails.
- No paid usage or new token/account connection is authorized by approving this proposal.

Dependencies: A061.

## Applications and filters · 5 gaps

### A022 · Public helping preferences → Select walking / cat sitting

P2 · Product decision needed · **Awaiting review, not implemented**

Current gap: Local service preference; cat-sitting lifecycle is not connected.

Proposed fix: Product decision required: keep the cat-sitting preference informational without accepting cat-sitting bookings, or review a complete cat-sitting journey separately. Do not reuse walking completion semantics silently.

Expected behavior: The preference does not imply an operational cat-sitting service.

Acceptance checks:

- No cat-sitting booking or completion path is introduced by this proposal.
- A chosen scope is documented before its dependent flow is implemented.

Dependencies: None; product decision first.

### A033 · Application confirmation · compact sheet → Confirm application

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Closes compact confirmation and shows status toast on the request; application record still missing.

Proposed fix: On explicit confirmation, create one application keyed by account and request. Return to the same request with the existing sent toast/pending context; no agreement chat yet.

Expected behavior: Confirming once makes that request show the actor’s pending application.

Acceptance checks:

- Double confirmation cannot create duplicates.
- The application stays separate from upcoming assigned agreements.

Dependencies: F01, A029.

### A126 · Current tab filters → Date selection

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Fixture date range; city-zone semantics need verification.

Proposed fix: Apply the existing date-filter draft only on Apply, evaluating each walking record in that walk city’s IANA zone. Keep the current filter presentation.

Expected behavior: A walk near midnight is included according to its own city date, not the device date.

Acceptance checks:

- Today/range boundaries are verified across two venue zones and a DST boundary.
- Close discards changes; Reset edits only the working filter.

Dependencies: F01.

### A146 · Applications → Choose helper

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Three selectable local applicants; selected identity follows the conversation preview. Atomic assignment remains missing. Review 26 supplies the destination design; runtime object/state wiring remains a gap.

Proposed fix: Confirm the selected applicant for one request and assign atomically in the eventual authoritative implementation. The local preview must reject conflicting assignment and create one participant agreement.

Expected behavior: Choosing Ульяна assigns her to the selected request and opens that agreement’s chat.

Acceptance checks:

- Double selection or two competing applicants cannot create two assignments.
- Other requests and unassigned applications remain unchanged.

Dependencies: F01, A033, A164.

### A152 · Nearby request details → Withdraw application

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Missing approved connected action/confirmation. Review 26 supplies the destination design; runtime object/state wiring remains a gap.

Proposed fix: Reuse the existing withdrawal confirmation for the actor’s exact unassigned application. Cancel retains it; confirm withdraws only that application and restores request/list context.

Expected behavior: Withdrawing from request A does not remove an application to request B.

Acceptance checks:

- Already assigned requests do not use this withdrawal path.
- Pending context and filtered lists update together after confirmation.

Dependencies: F01, A033, F02.

## Pets and requests · 4 gaps

### A050 · Add / edit pet → Save

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Replaces one pet fixture rather than maintaining a collection.

Proposed fix: Store pets by account and stable pet ID. Add appends; Edit updates only the selected pet. Keep the existing pet form and origin-specific return destination.

Expected behavior: Adding a second pet preserves the first; editing its habits changes only that pet.

Acceptance checks:

- Add and Edit use distinct record operations.
- Cancel creates no pet and leaves saved photos/fields unchanged.

Dependencies: F01, A048.

### A053 · Pet details → Edit habits

P2 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Existing habits editor; full pet form route needs consolidation.

Proposed fix: Open the existing pet editor with the selected pet ID and habits section context; save back to that pet’s detail view. Preserve the existing detail/editor layouts.

Expected behavior: Edit habits from Персик never edits another pet or an unrelated default fixture.

Acceptance checks:

- Back/cancel returns to the same pet.
- Save updates the selected pet’s habits in detail and profile.

Dependencies: A050, F02.

### A117 · Current walks and requests → New request (+)

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Existing direct form bypasses no-pet prerequisite.

Proposed fix: Make all New request entry points check owner capability and the owned-pet collection. No pet uses the existing inline notice and pet form, then resumes the unsent request draft.

Expected behavior: An owner with no pet adds one and returns to the same request form.

Acceptance checks:

- Cancel pet creation returns without publishing a request.
- An owner with pets selects by pet ID; helper-only mode cannot create.

Dependencies: A050, F02.

### A217 · Create request → Create request

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Acknowledges local form without adding a persistent request to the list.

Proposed fix: Validate the existing form and create one owner/request record in the account-scoped preview store. Preserve selected pet ID, venue-zone time and private handover fields; show its card on return.

Expected behavior: Publish adds the owner’s new request to Current rather than just closing the form.

Acceptance checks:

- Invalid/failed save retains the complete unsent draft.
- Repeated confirmation creates one request; private care text stays participant-only.

Dependencies: A117, F01.

## Shared conversations and navigation · 14 gaps

### A089 · People list → Chat with person

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Opens reference conversation, separate from shell inbox.

Proposed fix: Open or reuse a direct thread keyed by both account IDs, using the approved direct-chat design and shared inbox. Carry the People origin for Back.

Expected behavior: Chat from a person card opens that person, and the thread appears once in Chats.

Acceptance checks:

- Two people with the same display name remain distinct.
- Draft and back-to-People context survive a round trip.

Dependencies: F01, F02, A164.

### A119 · Current walks and requests → Agreement chat

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Frozen conversation preview; not shared with shell inbox.

Proposed fix: Open the selected agreement’s participant conversation in the approved walking chat. Use the same record in the shell inbox; retain list filters and scroll origin.

Expected behavior: Agreement chat from Current opens the assigned owner/helper and correct pet.

Acceptance checks:

- Unassigned applications cannot open this chat.
- Opening another agreement does not reuse the first agreement’s status or messages.

Dependencies: A164, F01, F02.

### A124 · Current walks and requests → Bottom navigation

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Frozen walking navigation still displays notices instead of routing.

Proposed fix: Route each bottom-navigation item to its selected approved destination rather than a fixture notice. Preserve owner/helper destination sets and each section’s search/filter/scroll snapshot.

Expected behavior: Selecting Chats opens Chats; returning to Walking restores the prior list state.

Acceptance checks:

- All five owner and four helper destinations route by key, not translated label.
- The current marker matches the visible section after Back and mode change.

Dependencies: F02.

### A134 · Agreement details · scheduled → Chat

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Opens isolated walking chat preview.

Proposed fix: Open the selected scheduled/completed agreement’s same participant thread, carrying the detail origin for Back. Completion does not create a second thread.

Expected behavior: Chat from either agreement detail shows that agreement’s history and returns to the same record.

Acceptance checks:

- Scheduled and completed views resolve by agreement ID.
- Private handover details remain restricted to agreement participants.

Dependencies: A119, A164, F02.

### A139 · Agreement details · completed → Chat

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Opens isolated walking chat preview.

Proposed fix: Open the selected scheduled/completed agreement’s same participant thread, carrying the detail origin for Back. Completion does not create a second thread.

Expected behavior: Chat from either agreement detail shows that agreement’s history and returns to the same record.

Acceptance checks:

- Scheduled and completed views resolve by agreement ID.
- Private handover details remain restricted to agreement participants.

Dependencies: A119, A164, F02.

### A164 · Chats inbox → Open conversation

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Shows generic conversation notice.

Proposed fix: Replace the generic notice route with a resolver for the selected conversation type and stable ID: direct, community, meeting or walking. Reuse existing chat designs; retain a recovery view for unknown/inaccessible threads.

Expected behavior: An inbox row opens its own participants, messages and context.

Acceptance checks:

- Unknown IDs never fall back to a default person/thread.
- A draft and scroll position belong to the correct thread and account.

Dependencies: F01, F02.

### A166 · New chat → Search person

P2 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Search input is not wired to results.

Proposed fix: Wire person search to the existing picker results using public account IDs, with the existing no-match presentation. Keep search local in the preview.

Expected behavior: Typing a name filters the selectable public-person list.

Acceptance checks:

- Clearing search restores results.
- No matches does not substitute another person or reveal private profile fields.

Dependencies: F01.

### A167 · New chat → Select person

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Shows shell notice instead of approved conversation.

Proposed fix: Select a person by stable account ID and open/reuse the approved direct thread in the shared inbox. Do not send a message until explicit Send.

Expected behavior: Selecting a person opens a composer for that person without sending or duplicating a thread.

Acceptance checks:

- Cancel keeps the inbox unchanged.
- A matching existing direct thread is reused.

Dependencies: A166, A164.

### A169 · Direct chat design → Type / send message

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Approved isolated reference composer; messages do not share account inbox.

Proposed fix: Append a sent message to the selected direct conversation and shared inbox record, with sender/time and a per-thread draft. Send remains explicit; preserve photos-only constraints.

Expected behavior: A message sent in direct chat appears in that same inbox conversation preview.

Acceptance checks:

- Switching threads keeps unsent drafts separate.
- No send occurs from merely opening a thread or attaching a photo.

Dependencies: A164, F01.

### A174 · Direct chat design → Back

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Needs shared conversation/inbox routing.

Proposed fix: Use an origin-aware Back stack: return to the initiating person/community/agreement detail when applicable, otherwise Chats. Preserve the thread draft and initiating list state.

Expected behavior: Back from a chat opened in People returns to People; an inbox-opened chat returns to Chats.

Acceptance checks:

- Do not implement Back as a hard-coded redirect to an unrelated list.
- Current module marker, search, filters and scroll are restored.

Dependencies: F02, A164.

### A175 · Community chat design → Type / send message

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Approved isolated reference composer; messages do not share account inbox.

Proposed fix: Append messages to the exact community thread only for an active member; update the same inbox record. Keep the approved group conversation layout.

Expected behavior: Sending in one community updates that community’s preview without crossing into a direct thread.

Acceptance checks:

- Membership loss prevents new sends.
- Sender/time, drafts and photo limits stay intact.

Dependencies: A095, A164, F01.

### A180 · Community chat design → Back

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Needs shared conversation/inbox routing.

Proposed fix: Use an origin-aware Back stack: return to the initiating person/community/agreement detail when applicable, otherwise Chats. Preserve the thread draft and initiating list state.

Expected behavior: Back from a chat opened in People returns to People; an inbox-opened chat returns to Chats.

Acceptance checks:

- Do not implement Back as a hard-coded redirect to an unrelated list.
- Current module marker, search, filters and scroll are restored.

Dependencies: F02, A164.

### A187 · Walking chat · agreement controls → Type / send message

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Approved isolated reference composer; messages do not share account inbox.

Proposed fix: Append messages to the selected agreement’s participant-only thread and shared inbox; preserve the pet/status context. Do not expose it to applicants who were not selected.

Expected behavior: Owner/helper see the same agreement conversation across entry points.

Acceptance checks:

- Only the two authorized participants can send/read private handover context.
- Message sending does not change agreement lifecycle state.

Dependencies: A119, A164, F01.

### A192 · Walking chat · agreement controls → Back

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Needs shared conversation/inbox routing.

Proposed fix: Use an origin-aware Back stack: return to the initiating person/community/agreement detail when applicable, otherwise Chats. Preserve the thread draft and initiating list state.

Expected behavior: Back from a chat opened in People returns to People; an inbox-opened chat returns to Chats.

Acceptance checks:

- Do not implement Back as a hard-coded redirect to an unrelated list.
- Current module marker, search, filters and scroll are restored.

Dependencies: F02, A164.

## Communities · 3 gaps

### A095 · Community details → Community chat

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Reference chat exists; shell inbox membership is not shared.

Proposed fix: Connect the community’s exact conversation ID and membership to the shared inbox. Nonmembers use the existing voluntary Join action; opening a public community never joins it automatically.

Expected behavior: A joined member sees the same community thread from details and Chats.

Acceptance checks:

- Nonmember entry does not grant chat access.
- Leaving invalidates participant access while public details remain discoverable.

Dependencies: F01, A164.

### A104 · Community invitation → Copy invitation link

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Copies fixture URL; fresh link resolution targets a hidden preview.

Proposed fix: Copy a stable public community link and resolve it visibly to the existing invitation/community preview. Unknown links use the approved unavailable view; no automatic membership.

Expected behavior: A fresh recipient opens the named community and explicitly chooses Join.

Acceptance checks:

- Copied link resolves the same community ID in a fresh context.
- Missing links never fall back to a different community.

Dependencies: F01, F02.

### A107 · Create community → Create

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Adds local fixture group; owner/refresh/account isolation incomplete.

Proposed fix: Create a group with stable ID, creator ownership and membership in the account-scoped preview store; show it in community list/details and its shared conversation. Keep browser lifetime memory-only.

Expected behavior: A created group stays consistent while navigating in the same preview session.

Acceptance checks:

- Owner capability is checked; product role is not an admin role.
- Reload/reset does not claim server persistence; a different account has no creator privileges.

Dependencies: F01, A095.

## Walking lifecycle and reputation · 6 gaps

### A135 · Agreement details · scheduled → Advance / confirm completion

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Changes shared view status; not agreement-scoped.

Proposed fix: Supersede the older direct-detail advancement proposal. Details stay informational; lifecycle actions open the existing fixed status entry and compact controls in the participant chat. Store state by agreement and actor.

Expected behavior: Only the assigned helper starts/finishes; only the owner confirms that selected agreement.

Acceptance checks:

- Advancing one agreement leaves all others unchanged.
- No automatic completion, tracking or elapsed-time-triggered transition.

Dependencies: F01, A119, A146.

### A136 · Agreement details · scheduled → Review eligibility · unavailable while scheduled

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: A scheduled agreement is not reviewable. Owner-confirmed completion must establish eligibility before opening the review form.

Proposed fix: Do not offer a review for a scheduled agreement. Only owner-confirmed completion enables the existing direction-specific review action in chat/history.

Expected behavior: A scheduled record cannot reach a writable review form through a direct link.

Acceptance checks:

- Eligibility is checked from agreement, actor and completion state.
- Helper and owner review directions remain independent.

Dependencies: A135.

### A140 · Agreement details · completed → Advance / confirm completion

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Changes shared view status; not agreement-scoped.

Proposed fix: Supersede the stale completed-to-scheduled target: completed details must not advance or restart an agreement. Link only to its existing completed chat/status/review context, subject to eligibility.

Expected behavior: Opening a completed agreement cannot move it back to Scheduled.

Acceptance checks:

- No Start/Finish/Confirm mutation is offered after completion.
- Duplicate completion requests do not create a second history entry.

Dependencies: A135, F02.

### A141 · Agreement details · completed → Leave review

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Eligibility uses fixture-wide flags rather than agreement/direction.

Proposed fix: Compute Leave review eligibility from completed agreement ID, author ID and owner/helper direction; route to the matching existing review design.

Expected behavior: Owner and helper each see only their own eligible review action.

Acceptance checks:

- Existing review opens in edit/read context instead of adding a duplicate.
- Role switching does not erase earned eligibility.

Dependencies: A136, A158.

### A158 · Review an agreement → Submit

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Fixture-wide reviewed flag; counts and per-agreement uniqueness incomplete.

Proposed fix: Submit one eligible review per agreement/direction; derive role-specific preview aggregates from eligible published review records. Production totals remain server-controlled.

Expected behavior: A completed owner review updates the helper’s rating/count, not place or owner reputation.

Acceptance checks:

- Duplicate submit is idempotent; no self-review or unrelated account review.
- Zero eligible reviews shows No reviews yet; role changes preserve eligibility.

Dependencies: F01, A135.

### A160 · Reply to walking review → Enter reply / save

P2 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Local reply flag; review-specific thread not shared.

Proposed fix: Attach the reply to the selected review ID and entitled recipient role. Persist it in the shared memory record and return to that review without changing its rating.

Expected behavior: Replying to one helper review appears under that review only.

Acceptance checks:

- Other reviews and role aggregates remain unchanged.
- Account/role changes cannot grant arbitrary reply permission.

Dependencies: A158, F01.

## Reports and activity targets · 5 gaps

### A156 · Walking reviews → Report review

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: No complete active report flow. Review 26 supplies the destination design; runtime object/state wiring remains a gap.

Proposed fix: Reuse the isolated report design with selected review ID and report reason. Acknowledgment confirms receipt only; reporting does not auto-delete or invent a moderator workflow.

Expected behavior: Report from a walking review stays associated with that review and returns to its list.

Acceptance checks:

- Private addresses/instructions are not copied into public report text.
- Removal thresholds and handling policy remain separate unresolved work.

Dependencies: F01, A158.

### A173 · Direct chat design → Report

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Design reference exists; candidate submission/blocked access not connected. Review 26 supplies the destination design; runtime object/state wiring remains a gap.

Proposed fix: Reuse the existing report sheet for the exact conversation/message and author account. Receipt acknowledgment is separate from blocking; do not infer blocked access, auto-removal or a moderation threshold.

Expected behavior: Reporting from the current chat returns to that same conversation; its target cannot change during sheet navigation.

Acceptance checks:

- Report target, reason and return context survive a round trip.
- Reporting alone does not block the person or erase the thread.

Dependencies: A164, F01.

### A179 · Community chat design → Report

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Design reference exists; candidate submission/blocked access not connected. Review 26 supplies the destination design; runtime object/state wiring remains a gap.

Proposed fix: Reuse the existing report sheet for the exact conversation/message and author account. Receipt acknowledgment is separate from blocking; do not infer blocked access, auto-removal or a moderation threshold.

Expected behavior: Reporting from the current chat returns to that same conversation; its target cannot change during sheet navigation.

Acceptance checks:

- Report target, reason and return context survive a round trip.
- Reporting alone does not block the person or erase the thread.

Dependencies: A164, F01.

### A191 · Walking chat · agreement controls → Report

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Design reference exists; candidate submission/blocked access not connected. Review 26 supplies the destination design; runtime object/state wiring remains a gap.

Proposed fix: Reuse the existing report sheet for the exact conversation/message and author account. Receipt acknowledgment is separate from blocking; do not infer blocked access, auto-removal or a moderation threshold.

Expected behavior: Reporting from the current chat returns to that same conversation; its target cannot change during sheet navigation.

Acceptance checks:

- Report target, reason and return context survive a round trip.
- Reporting alone does not block the person or erase the thread.

Dependencies: A164, F01.

### A212 · Activity → Open event

P1 · Proposed wiring · **Awaiting review, not implemented**

Current gap: Context-specific notices/details; not every target connected.

Proposed fix: Resolve each activity item by object type and stable object ID to the existing meeting, chat or request design. Unknown/inaccessible targets use the existing recovery view.

Expected behavior: A chat notification opens its thread; a meeting activity opens that meeting, not a default lake fixture.

Acceptance checks:

- Deleted/inaccessible targets do not fall back to a different object.
- Return restores activity scroll/context without joining an event.

Dependencies: A164, F02, F01.

