# Review 46 · A164 shared conversation routing

A164 is implemented on the workflow board using the Review 45 F01 account store and F02 navigation stack. This is a local memory-only browser preview, separate from Flutter and backend authorization.

Inbox rows carry stable conversation IDs. The shared resolver requires an existing supported record, active local access and current account membership. Direct, community, meeting and walking records open their existing approved renderers with their own participants, messages and record context. Unknown or inaccessible IDs use the existing unavailable screen; they never fall back to an unrelated conversation. Opening a thread does not join a meeting or community.

Composer drafts are keyed by account and conversation ID. Matching display names do not share a draft. F02 captures the inbox search, tab and scroll context before opening a conversation and restores the origin on Back. F01 preserves message scroll separately per thread. Account switching invalidates stale ports; account reset clears drafts. Reload clears all private preview memory.

Sending, new-chat creation, membership changes and walking lifecycle actions remain separately pending. A164 changes no CSS foundation or approved screen layout. Existing composer submit remains unavailable for these routed records until its separate sending action is implemented.

Review 45 is preserved in `revisions/review-45/` with its snapshot SHA-256 manifest. All older archives and frozen layout sources remain unchanged. The workflow map marks only A164 connected; 47 action gaps remain.

Validation: `checks/preview-state.test.cjs`, `checks/preview-conversations.test.cjs`, `checks/conversation-check.html`, and the 127-screen foundation regression. Browser journeys additionally check actual inbox-row navigation, composer restoration, account switching and Back.
