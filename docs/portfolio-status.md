# Portfolio scope and status

Prepared on 5 November 2026. This document describes the portfolio deliverable, not live service health.

| Surface | Status and limits |
| --- | --- |
| English case study | Static page in `portfolio/`, with links to implementation evidence |
| English browser study | Current Flutter main-screen structure, separate places list, people/community search, compact profile, themes, favorites, demo messaging and simulated walking actions |
| Browser data | Fictional. Theme/city/tab/favorites persist locally; messages, edits and simulated participation are in memory |
| Native application | Flutter iOS/Android alpha; existing UI is primarily Russian |
| Backend | SQL migrations, functions and verification tooling are present; deployment state must be checked separately |
| Product research | No completed user study or measured product outcome is asserted |
| Production release | Not claimed; provider configuration, delivery checks, moderation and policy decisions remain separate work |

The browser adaptation uses current Flutter screen composition and shows the unavailable-map state. It does not replicate the native map renderer, authentication, media uploads or every secondary flow. Its interactive data is synthetic.

Historical native/backend test results and staging setup notes are preserved in [progress.md](progress.md) (Russian). They may describe older configurations and superseded behavior. Read current code and run the relevant checks before relying on them.

The new English documents provide reviewer-facing entry points. Original product specifications and operational history remain in Russian to preserve project context.
