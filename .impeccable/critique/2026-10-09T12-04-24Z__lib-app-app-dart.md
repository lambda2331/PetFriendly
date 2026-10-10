---
target: PetFriendly app design
total_score: 25
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/Users/artem.dudinskij/Documents/ChatGPT/PetFriendly/lib/app/app.dart"
target_fingerprint: "sha256:f7ca9a697698bf3a096edb187e1517d5dd3eb0ee95f63bfd0a47ea7e9e763d63"
target_path: /Users/artem.dudinskij/Documents/ChatGPT/PetFriendly/lib/app/app.dart
timestamp: 2026-10-09T12-04-24Z
slug: lib-app-app-dart
---
Method: dual-agent (A: /root/design_review · B: /root/implementation_evidence)

PetFriendly design review — 9 October 2026

Studio is worth keeping. The strongest update would make the app more useful at decision points while preserving Manrope/Golos Text, generous spacing, quiet surfaces and lime accents. Scope: current Flutter source, fresh iOS observations and saved light/dark iOS captures checked against source. Android, large text and VoiceOver were not tested. No app code changed.

Design specificity: the owner/pet identities, district privacy and map/community combination fit PetFriendly. Repeated large introductions and generic conversation rows feel less specific. Improve the task hierarchy rather than replacing the visual direction. The deterministic detector ran on lib, returned exit 0 and [] (zero findings). Its coverage of Dart/native behavior is unverified, so this is not a clean bill of health. Both independent reviews agree on inbox states, helper comparison and blank people searches. Native inspection was used instead of a browser surrogate; no overlay was injected.

Design health: 25/40, Acceptable. Scores are provisional design judgments, not measured usability results.

| Heuristic | Score /4 | Main finding |
|---|---:|---|
| Visibility of system status | 2 | Chats conflates unavailable data with empty conversations |
| Match with the real world | 3 | Clear Russian; technical time labels need simplification |
| User control and freedom | 3 | Manual city and back paths work; segment changes clear search |
| Consistency and standards | 3 | Coherent Studio system; title/body styles drift from specification |
| Error prevention | 2 | Walking actions need pending guards; reviews default to five stars |
| Recognition over recall | 2 | Inbox context and applicant reputation absent at decision points |
| Flexibility and efficiency | 3 | Places search/favorites work; inbox triage remains limited |
| Aesthetic and minimalist design | 3 | Calm surfaces; introductory blocks compete with tasks |
| Error recovery | 2 | Retry exists, but several errors and empty searches lack guidance |
| Help and documentation | 2 | Useful privacy guidance; helper selection needs next-step explanation |
| Total | 25/40 | Acceptable |

What works: strong Cyrillic typography and restrained color; privacy guidance near relevant actions; rounded inset map with category markers, count clusters and a separate places list. Preserve these choices and the five labeled navigation destinations.

Priority updates:

1. [P1] Show helper reputation before selection. Applicant rows currently show a name and “Выбрать,” so owners must decide without visible experience. Add server-derived rating, published review count, completed walks, a profile link and “Пока нет отзывов” for newcomers. Explain what selection commits to, then show pending and success states. Do not imply ratings guarantee safety. Suggested command: impeccable shape. Source: lib/features/walks/walks_screen.dart.
2. [P1] Make Chats an informative inbox. Replace repeated “Открыть переписку” subtitles with last-message context, last activity and unread state when supported by real data. Separate loading, failure/retry and genuine emptiness; never fabricate previews or counts. This reduces opening every conversation just to discover urgency. Suggested command: impeccable harden. Source: lib/features/chat/chat_screen.dart.
3. [P2] Give practical content more space. The fresh Nearby screen gives the greeting and empty-event invitation considerable prominence. Keep both, but shorten the empty banner and add a visible “Места списком” label. On Walking help, bring the request action and active agreements earlier. Preserve generous spacing within the content. Suggested command: impeccable layout. Sources: lib/features/nearby/nearby_event_banner.dart, lib/features/nearby/nearby_screen.dart, lib/features/walks/walks_screen.dart.
4. [P2] Make searches and actions recoverable. People checks the unfiltered collection for emptiness, so a nonmatching query can produce a blank area. Filter first, show “Никого не нашли” and “Сбросить поиск,” and retain separate People/Communities queries. Distinguish connection errors from unavailable actions and use specific confirmations such as “Отклик отправлен.” Suggested commands: impeccable clarify and impeccable harden. Source: lib/features/community/people_screen.dart.
5. [P2] Strengthen small headings and verify accessible layouts. Current titleMedium is 15 and bodyMedium is 14; the baseline defines card headings at 18 and body at 15. Map semantic text roles consistently to those tokens rather than enlarging every label. Verify wrapping at large text and spoken control/state labels, especially map controls, event banner and paired filter rows. No overflow or VoiceOver defect was established in this review. Suggested commands: impeccable typeset and native impeccable audit. Sources: lib/core/theme/studio_theme.dart and design/tokens.json.

Cognitive load and emotional journey: the five tabs are appropriate. The heavier burden is missing decision context: users open each chat for urgency and helper profiles for experience. Nearby starts warmly but asks a newcomer to organize the first meeting. A smaller invitation would leave a clearer path to finding a place. Specific post-action feedback should end walking interactions confidently.

Persona red flags: Jordan, a first-timer, must infer the places-list icon and what “Выбрать” means. Casey, using one hand while distracted, must open threads individually and loses search context across segments. Sam needs a separate large-text/VoiceOver verification pass; the tappable event banner plus nested button deserves a duplicate-focus check, not an assumed failure.

Additional updates: require an intentional star selection instead of defaulting to five; show event/walk time in the venue timezone rather than the device timezone outside Minsk; add review dates, helper replies and review-specific reporting to helper reviews. Format session timestamps as readable local dates and use purposeful initials/empty photo states without invented portraits. Do not carry forward defects from superseded catalog or rating screenshots.

Questions to consider: should the first-minute path emphasize finding a place, joining a walk, or creating one? What must be visible before an owner chooses a helper?
