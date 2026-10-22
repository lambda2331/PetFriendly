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
