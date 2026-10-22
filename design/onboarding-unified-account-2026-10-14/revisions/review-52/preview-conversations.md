# Review 46 · A164 shared conversation routing

A164 is implemented on the workflow board using the Review 45 F01 account store and F02 navigation stack. This is a local memory-only browser preview, separate from Flutter and backend authorization.

Inbox rows carry stable conversation IDs. The shared resolver requires an existing supported record, active local access and current account membership. Direct, community, meeting and walking records open their existing approved renderers with their own participants, messages and record context. Unknown or inaccessible IDs use the existing unavailable screen; they never fall back to an unrelated conversation. Opening a thread does not join a meeting or community.

Composer drafts are keyed by account and conversation ID. Matching display names do not share a draft. F02 captures the inbox search, tab and scroll context before opening a conversation and restores the origin on Back. F01 preserves message scroll separately per thread. Account switching invalidates stale ports; account reset clears drafts. Reload clears all private preview memory.

Sending, new-chat creation, membership changes and walking lifecycle actions remain separately pending. A164 changes no CSS foundation or approved screen layout. Existing composer submit remains unavailable for these routed records until its separate sending action is implemented.

Review 45 is preserved in `revisions/review-45/` with its snapshot SHA-256 manifest. All older archives and frozen layout sources remain unchanged. The workflow map marks only A164 connected; 47 action gaps remain.

Validation: `checks/preview-state.test.cjs`, `checks/preview-conversations.test.cjs`, `checks/conversation-check.html`, and the 127-screen foundation regression. Browser journeys additionally check actual inbox-row navigation, composer restoration, account switching and Back.

## Review 47 · A169 direct message send

A169 now enables explicit text Send only for a resolved shared direct thread opened from the inbox. The existing composer, messages and buttons retain their approved geometry and styles. A successful send appends a unique message ID, current-account sender and timestamp to that conversation record, updates its inbox last-message/time and recent-activity order, and clears only that thread's sent draft. Focus returns to the composer and the conversation scrolls to the new message without changing the F02 navigation stack.

Whitespace-only and over-1000-code-unit text cannot send. The 1000-unit limit matches the existing textarea maxlength. Resolution checks current local access and membership again at Send; a stale account port cannot write. Rejection preserves the draft. Other conversation drafts, unrelated forms, inbox search/tab/scroll context, account identity and Back remain intact. Opening, typing, Enter within the multiline textarea and account switching do not send. The normal empty composer disables Send, so repeated activation after a successful send does not duplicate the message.

This remains a synchronous, memory-only design preview: no delivery, network request, backend authorization or durable message storage is claimed. Shared group, meeting and walking send actions remain pending. Attachment controls and their existing photos-only/metadata-removal constraints are unchanged; A169 does not enable a new attachment flow.

Review 46 is preserved in `revisions/review-46/`. Only A169 changes action status in Review 47, leaving 46 action gaps. Verification adds `checks/preview-direct-send.test.cjs`, the 12 conversation renderer variants (including enabled direct versus disabled other Send controls), and actual browser Send → inbox → thread/account switch → Back journeys. All 127 screen definitions and existing CSS remain unchanged from Review 46.

## Review 48 · A175 community message send

A175 enables explicit text Send in the exact shared community conversation opened from the inbox. It reuses the A169 message-write contract through separate direct/community entry points, so each rejects other conversation types. A community send also requires its stable community association and current local active thread access/membership. Opening a community chat never grants membership. A095 community joining/lifecycle wiring remains pending; this revision uses the existing active-member fixture and rechecks it at Send.

Successful Send appends one uniquely identified message with sender and time, updates only that community's inbox last-message/time and recent order, and clears only its sent draft. The approved group header, sender/time bubbles, composer and buttons are retained. Other community/direct/form drafts and the F02 navigation stack are unchanged. After sending, the composer keeps focus and messages scroll to the new bubble.

Blank/oversized sends do not mutate state. Membership/access loss blocks the new message, preserves the draft and routes to the existing unavailable screen. Stale account callbacks cannot write. Account switches isolate records and drafts. Typing, multiline Enter and opening a thread never send. The existing 1000-unit textarea limit and attachment controls/photos-only constraints are unchanged; no new attachment flow is enabled. Meeting/walking sending remains pending.

This is memory-only browser behavior, without network delivery, production authorization or membership enforcement claims. Review 47 is preserved in `revisions/review-47/`. Only A175 changes action status in Review 48, leaving 45 gaps. Validation includes `checks/preview-community-send.test.cjs`, regression suites for A164/A169/F01/F02, 12 conversation renderer variants and the browser membership-loss fixture `checks/community-membership-check.html`. All 127 screen definitions and active CSS remain unchanged.

## Review 49 · restored A181 meeting message send

Historical A181 belonged to `chat-meeting-design` in Review 27. Review 28 replaced that screen with the current `meeting-chat` renderer and removed A181 from the active registry. The user's explicit A181 request restores that action on the current approved meeting chat. No old screen or layout is reinstated. The 45 existing pending action gaps remain unchanged; the review board now retains 49 action reviews, including restored A181.

Explicit meeting Send uses the exact shared conversation ID and its stable event association. It rechecks current local active access/membership before appending a uniquely identified message with sender/time. The inbox reads the same record's last message and recent-activity order. Success clears only the sent conversation draft; other meeting, direct, community and form drafts remain independent. Send leaves the F02 navigation route/stack intact, retains composer focus and scrolls messages to the new bubble. Enter submits the existing single-line meeting composer exactly once.

The existing meeting header, message bubbles and composer geometry are preserved. Shared meeting text uses the same 1000-unit bound as direct/community sending, reflected by maxlength on the existing input. Blank/oversized or stale-account sends cannot mutate messages. Membership/access loss preserves the draft and reuses the unavailable screen. Opening or sending never joins the event or community and does not modify event records, registration, capacity or meeting sharing. The existing isolated share-draft preview remains separate.

This is memory-only browser text sending, not backend delivery or production authorization. Walking sending and other unapproved actions remain pending. Review 48 is preserved in `revisions/review-48/`. Verification includes `checks/preview-meeting-send.test.cjs`, the direct/community/F01/F02 regressions, 12 conversation renderer variants and `checks/meeting-membership-check.html` for membership loss immediately before Send. All 127 screen definitions and active CSS remain unchanged.

## Review 50 · A187 walking message send

A187 enables explicit text Send for an existing shared walking conversation opened from the inbox. Resolution requires a stable agreement ID, distinct owner and assigned-helper account IDs, active local thread access, and current-account membership. Only that owner or helper can resolve/read/send the walking thread; adding an unselected applicant to member IDs does not grant access. The same resolver gates inbox rows and routed content. These are local fixture checks, not server authorization or A119 assignment/lifecycle implementation.

Success appends one message with unique ID, sender and time to the exact conversation record and updates its inbox last-message/time and recent order. It clears only the sent thread draft, retains focus and scrolls to the new message. The approved walking header, pet/time/status context, message bubbles and single-line composer remain in place. Counterpart names follow the current owner/helper actor. Shared walking text uses the same 1000-unit bound as the other shared send controls. Button Send and Enter submit once; blank/oversized/stale-account sends do not write. Attachment controls and their existing photos-only constraints are unchanged.

No send changes assignment, starts/finishes/confirms a walk, changes request/agreement lifecycle records or exposes private context to applicants. Participation/access loss blocks the send, preserves its draft and uses the existing unavailable screen. Other walking/direct/community/meeting/form drafts remain separate; F01/F02 retain the thread/account and inbox search/tab/scroll/Back context. Product mode is not an authorization role and does not change participant identity.

This is account-scoped memory-only browser behavior. It does not deliver messages across devices/accounts, persist private messages on reload or implement Flutter/backend enforcement. Review 49 is preserved in `revisions/review-49/`. Only A187 changes action status in Review 50, leaving 44 pending gaps. All 127 screen definitions and active CSS remain unchanged. Validation includes `checks/preview-walking-send.test.cjs`, all shared-send/F01/F02 regression suites, 12 renderer variants and the participation-loss browser fixture `checks/walking-membership-check.html`.

## Review 51 · A165 / A167 shared New chat

A165 was already the connected picker-opening edge; A167 was its missing person-selection/create/reuse step. Both controls now use the shared F01/F02 host. The approved New chat sheet, single public person fixture, header, search field, row and spacing are retained. A166 picker search remains pending: its text is preserved as UI context, but filtering behavior is not changed by this revision.

The selected person is keyed by the fixture's stable public account ID, never display name. `startDirect` reuses an existing direct conversation for the current account/person pair, retaining its ID, messages, unread state and composer draft. When none exists, it creates one empty account-scoped conversation and inbox entry with that pair. Repeated selection reuses it; changed display names or product mode do not create duplicates. Unknown/self selections cannot create a thread. An inaccessible or inconsistent existing pair uses recovery rather than creating a replacement that bypasses access. New chat creates no message and never auto-sends a draft.

The actual inbox plus button opens the existing picker through F02. Selecting its person navigates to the approved direct conversation; Back returns to the picker with its input retained, then Close/Escape/backdrop returns to the inbox with previous list context and focus on New chat. Existing direct drafts survive reuse; newly created threads use the existing A169 Send implementation. Other conversation/form drafts and other accounts' messages remain separate. Inactive frame ports cannot start a conversation after account switching.

This remains memory-only preview behavior with the existing public sample directory, without backend creation, durable storage, network delivery or a new People/lookup flow. Review 50 is preserved in `revisions/review-50/`. A167 is the only gap newly completed, leaving 43; A165's existing connected behavior is now implemented through the shared host. All 127 screen definitions and active CSS remain unchanged. Validation adds `checks/preview-new-chat.test.cjs`, shared-send/F01/F02 regressions and 15 conversation/picker variants, plus browser create/reuse, explicit Send, Back/Close/Escape, focus and account-switch journeys.

The A167 map edge opens the picker for selection; its resolved targets document direct chat/recovery. A static map click does not choose a default person or open an unrelated isolated chat.

## Review 52 · A166 public-person search

The existing New chat input now filters the existing approved public-person fixture by normalized, case-insensitive partial name. Unicode NFKC normalization and surrounding-whitespace trimming keep matching predictable. `searchDirectPeople` returns only public `id`/`name` fields and excludes the current account. Private profile data, conversation text and account IDs are not searched. Results preserve the stable public ID used by A167; filtering never substitutes another person or derives identity from the result's index/display name.

The approved person row remains in its original sheet position. Matching toggles that row's visibility by stable ID. No matches hide it and reuse the existing shared `state-center search-empty` presentation with a polite status region. Clearing restores the same row and ID. No header, modal container, font, palette, spacing or action layout is changed. The same public sample directory remains in use; this is not a backend lookup or directory expansion.

F01 field snapshots restore the query in its account-scoped New chat context. Filtering runs after restoration as well as on input, so a restored no-match query cannot display an unrelated default person. Back from the direct thread returns to the filtered picker; Close/Escape and reopening retain its query. Other conversation and form drafts are untouched. Searching never creates a conversation or sends a message, and stale account ports cannot search or mutate UI state.

Review 51 is preserved in `revisions/review-51/`. Only A166 changes action status in Review 52, leaving 42 pending gaps. All 127 screen definitions and active CSS remain unchanged. Verification adds `checks/preview-people-search.test.cjs`, existing New chat/shared-send/F01/F02 suites, browser match/no-match/clear/select/query-restoration/account-isolation checks and 18 renderer variants covering matching and empty picker states in light/dark/large modes.
