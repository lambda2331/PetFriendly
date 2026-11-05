# PetFriendly portfolio surface brief

Mode: Experience for the app demonstration, supported by Read for the case study.

## Confirmed direction

The user is preparing an English Design Engineer portfolio with equal emphasis on design and implementation. The user explicitly requires the web demo to match current application screens and main scenarios, and chose a mocked map. The former HTML recreation has been removed.

## Implementation authority

Product UI comes from canonical `lib/` Flutter screens, theme, routes and repositories. `scripts/build-web-demo.py` applies a reviewed English literal catalog in an ignored build tree and compiles the same implementation. Unknown copy fails the build. There is no maintained second product UI.

The static case study keeps its established Studio identity: local Manrope and Golos Text, #F9F9F6 canvas, #20251E ink, #62695C muted text and restrained #D6ED8A actions. The artifact-first split introduction, scenario links, paired decisions/evidence and implementation/status sections are retained. It collapses to one column on mobile. The thin demo host frames Flutter at a mobile width; it owns no product state.

## Demo boundary

The portfolio flag selects seeded in-memory data, an interactive Flutter mock map and English Material localization; it isolates live backend, Firebase, catalog and location services. The native app-switcher privacy cover is retained for normal builds and omitted for the embedded fictional demo, which must remain visible when focus moves to the case study.

Map geometry is explicitly synthetic. Pan/zoom, category markers, fullscreen, simulated position and new-place point selection work locally. Place sheets, favorites, reviews, list filters, people/community search, meetups, chats, walking requests/agreements and profile/pet forms use the shared application implementation.

Only theme, city and favorite IDs persist. All other public demo changes remain in memory. No live delivery, authentication, moderation, safety guarantee, research result or production-readiness claim is invented.

## Verification

Native analysis and widget/unit tests protect the default application. Focused portfolio-map tests verify zoom, simulated position and English number formatting. Python scanner tests cover nested interpolation, comments, escaping and fail-closed translation coverage. The release web artifact is checked through browser scenarios at desktop and phone widths. The native baseline and design sidecar remain unchanged.

## Extension evidence

`portfolio/assets/site.css` retains the Studio palette and bundled fonts: Manrope display (44–72 px), Golos Text body (16 px), a 1200 px maximum container, layout adjustments at 1000 px and single-column composition at 760 px. Editorial actions use 14 px corners and a 180 ms color transition; reduced-motion CSS removes transitions and smooth scrolling. These case-study treatments do not redefine native components.

The embedded product inherits canonical `studioTheme` typography, semantic light/dark surfaces, capsule controls and 28 px sheet corners. `PetFriendlyApp` retains the shared 220 ms theme transition and its accessibility disable-animation branch. `portfolio_map.dart` uses theme colors for controls, a 24 px embedded clip and fullscreen-only zoom/position controls. Its labeled synthetic geometry is a portfolio adapter, not an OSM map or location service.

`scripts/build-web-demo.py` translates copied Dart literals through `tooling/portfolio/en.json`, fails on unknown copy and compiles with `PORTFOLIO_DEMO`; `demo-host.js` supplies routes and restart only. Restart reloads in-memory demo activity while retaining preferences. Previous HTML-specific focus, persistence and sheet-color observations no longer describe this Flutter artifact. Review captures are under `.impeccable/review/flutter-web/`.

Pre-existing baseline drift remains unmodified: the early `docs/DESIGN.md` table retains older dark muted/border colors and control radii, while later refinements, `design/tokens.json` and the current Flutter theme establish updated contrast colors and capsules. This extension records the shared implementation; it does not certify complete native parity, browser assistive-technology behavior or production services.
