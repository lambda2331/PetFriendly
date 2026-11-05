# Portfolio surface brief

Mode: Experience, supported by Read.

Audience: reviewers assessing Design Engineering capability. User confirmed a balance of design and implementation.

Direction: extend the established Studio world. Artifact-first split introduction, a working embedded prototype, three scenario links, paired decision/evidence sections, an architecture strip and explicit implementation limits. Preserve the current native design language rather than introducing a new identity.

Visual sources: AGENTS.md, design/tokens.json, docs/DESIGN.md, design/prototype.fragment.html. Fonts: local Manrope and Golos Text. Colors: canvas #F9F9F6, ink #20251E, muted #62695C, lime #D6ED8A, on-lime #253314, tint #EEF1E7. Wide grid with generous spacing, responsive single-column content, filled rounded actions.

Interaction contract: try the design without sign-in; tabs and themes respond; details trap focus and dismiss; favorites persist; search changes visible people; messages remain in memory; walking actions give labeled demo feedback; reset clears only prototype state. English reviewer-facing copy throughout.

Evidence boundaries: the HTML study follows current Flutter main-screen layout but does not implement native services, native UI primarily Russian, research and business outcomes unverified. Do not invent contributor history or validation.

## Shipped extension evidence

The portfolio extends Studio; `docs/DESIGN.md`, `design/tokens.json` and the incumbent design sidecar remain unchanged. Source evidence is `portfolio/assets/site.css`, `portfolio/assets/prototype.css` and `portfolio/assets/prototype.js`, checked against `lib/core/theme/studio_theme.dart:32–259` and the current screen refinements in `docs/DESIGN.md`.

- Palette and type: the case study reuses the light Studio palette and bundled Manrope/Golos Text. Its editorial display grows from 44 to 72 px, with 16 px body text; the embedded app retains 32 px screen headings, 18 px card titles and 15 px body text. Its light/dark/system colors follow the current native theme for canvas, text, borders, tint and lime.
- Layout and shape: the case-study container caps at 1200 px, changes at 1000 px and stacks at 760 px. The app frame caps at 402 px, uses 24 px content insets and contracts insets to 18 px below 370 px. App cards use 24 px corners, sheets 28 px upper corners and capsule actions with 48 px targets. The surrounding editorial page uses 14 px action corners and a restrained frame shadow; these are portfolio treatments, not new native rules.
- Motion: the app body enters in 180 ms, theme colors transition in 220 ms and sheets enter in 250 ms. Reduced-motion CSS removes animation and transitions; the case study also disables smooth scrolling. The browser does not reproduce every native motion or haptic behavior.
- Behavior: five main tabs, theme choice, manual city, people search, place favorites, in-memory chats and labeled demo actions are implemented. Sheets make background regions inert, trap Tab, dismiss with Escape and restore focus using the triggering action/ID when rendering replaces the original element. Community rows carry stable IDs. Directional icons render as SVG.
- Preview limits: no live map or native service connection, full native-flow parity, production security verification or research outcomes are implied. The browser additionally persists the selected tab alongside theme, city and favorite IDs; this is portfolio navigation behavior, not a change to native persistence scope.

Pre-existing documentation drift is not canonized: the early `docs/DESIGN.md` table still names older dark muted/border colors and rectangular controls, while its later refinements, `design/tokens.json` and the current Flutter theme establish updated contrast colors and capsules. The browser also uses the dark surface color for sheets rather than the native dark sheet token. Preserve these distinctions when extending the portfolio; baseline reconciliation and native parity are outside this pass.
