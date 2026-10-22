# Review 45 · F01/F02 preview foundations

Implemented following approval of F01/F02 from Review 44. Review 44 is preserved. This is browser preview infrastructure, not authentication, authorization or backend persistence.

## F01 · Account-scoped memory

`preview-state.js` owns one store in the workflow-map host. Frames receive connections bound to an account and generation. Switching/resetting an account invalidates old connections, including reads and delayed writes. Private state never uses localStorage or sessionStorage. Reloading the host starts a fresh preview session.

Each account has saved identity, helper preferences, stable-ID record collections, favorite place IDs, canonical city-selection context, per-form/per-record drafts, navigation contexts and active owner/helper mode. Device theme/language preferences are a separate store namespace. These preference APIs do not implement the pending theme/language propagation gaps. Returned data is cloned; display names are never object keys. Saved identity is separate from working form drafts and cannot replace the internal account ID.

The frame adapter hydrates the saved identity in onboarding/profile references, retains the approved onboarding working model, rendered form drafts, list query/filter values, scroll positions, meeting drafts and existing meeting event/message records. Password/file inputs are excluded from generic field snapshots. Record APIs for other features are available, but pet collection saving, assignment, shared inbox sending and reputation remain pending feature integrations.

Only the mounted main preview and its nested frames connect. Journey thumbnails cannot mutate the account store. Each frame unregisters capture/subscriptions when removed. Standalone reference pages retain their existing independent fixture behavior; they are not silently merged with the workflow-map session.

## F02 · Navigation context

`preview-host.js` captures the leaving frame before map navigation and maintains an account-specific origin stack. Route context uses screen keys, stable record parameters and owner/helper mode, not translated labels. Existing Back map edges and the review-only Back to origin control restore the actual initiating screen. Browser hash navigation synchronizes the stack. Existing meeting transitions update it without replacing the approved meeting UI. Exact event/member/community parameters survive the return trip.

`preview-frame.js` hydrates models before the workflow driver selects the requested state, then restores fields and scroll after DOM initialization. This ordering preserves open city/date/filter sheets. Search restoration dispatches the existing input handler so both the field value and visible result list match. Review-only frames allow field draft editing but still block action clicks and submit events. This does not enable pending Save, Send, assignment, report or sign-out flows.

Use the workflow map’s **Preview foundations · F01 / F02** controls to switch Account A/B, return to origin, or reset the current account. Reset affects only that account’s preview memory. Existing 48 action gap statuses remain unchanged; F01/F02 are foundations for later approved fixes.

## Verification

- `node checks/preview-state.test.cjs`: isolation, stale reads/writes, clones, stable record IDs, independent form/record drafts, favorite/city namespaces, account-ID integrity, mode-safe history, origin context, reset and fresh-root lifetime.
- Mounted-host regression: 127 screens × light/dark/200% text, 381 passing variants; rendered component counts match the preserved baseline.
- Narrow mounted-host regression: 12 screens × 3 modes, 36 variants without state errors or horizontal overflow.
- Browser smoke checks: helper draft → Profile → Back; Account A/B isolation and restoration; People search and matching result restoration; open helper time picker and parent draft restoration; meeting place-picker return and exact event=park restoration after Profile. Fresh final session has no console errors during the helper/Profile/Back journey.

Native/server integration, standalone-reference consolidation and all feature-specific gap fixes remain separate work.
