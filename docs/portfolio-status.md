# Portfolio scope and status

Prepared on 5 November 2026. This describes the public demo, not live service health.

| Surface | Status and limits |
| --- | --- |
| English case study | Static page with links to implementation evidence |
| English application | Compiled from current Flutter screens and scenario logic; replaces the old HTML imitation |
| Map | Interactive synthetic map with pan/zoom, category markers, place sheets, fullscreen, simulated position and new-place point selection |
| Main flows | Places/favorites/reviews, people/community search, meetups, chat composition, walking requests/agreements and profile/pet editing use the shared app code |
| Data | Fictional seeded demo repositories; no real accounts or production writes |
| Persistence | Theme/city/favorites use browser preferences; other demo state is in memory |
| Native app | Existing default language and Mapbox integration preserved |
| Live services | Authentication, push delivery, private server storage and privileged security operations require separate configuration and are not claimed as tested here |
| Product evidence | No research outcome, adoption metric, safety guarantee or production readiness is invented |

The user chose a mocked map. Its geometry and positions are illustrative, not an exported live map, route service or current place catalog.

The English catalog localizes a generated build copy of canonical source. Native source strings stay unchanged, so normal mobile builds retain the existing language. Internal geographic search aliases may use Cyrillic; visible interface copy is English.

Historical staging notes remain in [progress.md](progress.md) (Russian). They describe past configurations rather than current service health.
