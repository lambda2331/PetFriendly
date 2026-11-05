# PetFriendly

**A neighborhood for people and their pets — explored through design and code.**

PetFriendly is a personal **Design Engineering** project: a Studio visual system, an interactive browser prototype, a native Flutter application and a Supabase backend. It connects nearby places, pet owners, communities, walking help and chat.

[**View the case study →**](https://lambda2331.github.io/PetFriendly/) · [**Try the interactive prototype →**](https://lambda2331.github.io/PetFriendly/prototype.html) · [**Run locally →**](docs/getting-started.md)

![PetFriendly English case study and interactive Studio prototype](portfolio/assets/preview.png)

## What to explore

- **Design decisions:** semantic themes, restrained motion, readable typography and reusable components.
- **Interaction design:** discover a place, search people, send a demo message and offer walking help in the [English browser study](https://lambda2331.github.io/PetFriendly/prototype.html).
- **Native implementation:** Flutter/Dart, Riverpod, go_router, bundled fonts and feature-based repositories.
- **Backend behavior:** PostgreSQL/PostGIS, Supabase Auth, RLS, private media and Edge Functions.
- **Engineering evidence:** [Flutter tests](test/), [native integration flows](integration_test/), [backend verification scripts](scripts/) and [CI](.github/workflows/checks.yml).

## Design engineering focus

| Decision | Interface consequence | Implementation |
| --- | --- | --- |
| One Studio visual language | Consistent light/dark surfaces and action hierarchy | [Design tokens](design/tokens.json), [Flutter theme](lib/core/theme/studio_theme.dart) |
| Location remains optional | Manual city selection and a usable places-list fallback | [Nearby feature](lib/features/nearby/) |
| Pet access requires evidence | Unknown access stays unknown | [Place catalog and access flows](lib/features/nearby/) |
| Trust is enforced beyond the screen | Membership-based chat and reviews tied to completed walks | [Database migrations](supabase/migrations/), [Edge Functions](supabase/functions/) |

## Two different ways to experience the project

| | Browser design study | Native application |
| --- | --- | --- |
| Purpose | Quick, interactive portfolio demonstration | Application implementation |
| Language | English | Primarily Russian; initial market: Minsk |
| Data | Fictional people, places and ratings | Demo repositories or configured Supabase services |
| Maps | No live map or location request | Mapbox with a configured public token; OSM catalog |
| Persistence | Theme, city, tab and saved places in browser storage; messages and edits in memory | Local preferences and server-backed data, depending on configuration |
| Requirements | A modern browser | Flutter SDK and iOS/Android toolchain |

The browser adaptation follows the current Flutter main-screen structure: tab-specific headers, a separate places list, people/community search, walking requests, chat empty state and compact profile cards. It shows the native unavailable-map fallback and simulates selected flows. It is **not a Flutter web build**; native authentication, maps and live services remain separate.

## Run the portfolio

Python 3 is sufficient. No npm installation, account or API key is needed.

```sh
git clone https://github.com/lambda2331/PetFriendly.git
cd PetFriendly
python3 scripts/build-portfolio.py
python3 -m http.server 4173 --directory portfolio
```

Open [localhost:4173](http://localhost:4173). Fonts and icons are self-hosted. Edit `design/prototype.fragment.html`, then regenerate both prototype entry points with the build script.

## Run the native app

Install the Flutter version pinned in [CI](.github/workflows/checks.yml), then:

```sh
flutter pub get
flutter run --dart-define=USE_DEMO_DATA=true
```

Choose an iOS simulator or Android emulator. Demo mode needs no backend credentials. A live Mapbox map requires a public token; place browsing remains available without one. See the [English setup guide](docs/getting-started.md) for configuration and checks.

## Project status

This is an alpha and a portfolio case study. The repository contains native app flows and backend implementation, but that does not establish production readiness, security certification or service delivery. Research, usability testing and production rollout remain separate work. No adoption or business-impact metrics are claimed.

The case study, prototype, README and new reviewer guides are in English. Historical product specifications, development notes and much of the native UI remain in Russian; they are retained as implementation context.

- [Case study in Markdown](docs/case-study.md)
- [Getting started](docs/getting-started.md)
- [Architecture overview](docs/architecture-overview.md)
- [Current portfolio scope and limitations](docs/portfolio-status.md)
- Historical specifications: [design](docs/design.md), [architecture](docs/architecture.md), [security](docs/security.md), [development log](docs/progress.md) — Russian

## Repository structure

```text
portfolio/                 GitHub Pages case study and generated browser demo
lib/                       Native Flutter application, organized by feature
assets/                    Bundled fonts and source-attributed place catalog
design/                    Tokens, project settings and prototype source
supabase/                  SQL migrations and Edge Functions
test/                      Flutter widget and unit tests
integration_test/          Native integration scenarios
scripts/                   Build and backend verification tools
docs/                      Reviewer guides and historical specifications
```

## Publishing and checks

[Portfolio Pages](.github/workflows/pages.yml) validates local links, English web content and generated-file consistency, then publishes **only `portfolio/`** on changes to `master`. Native source and configuration are not included in the Pages artifact.

```sh
python3 scripts/build-portfolio.py --check
python3 scripts/check-portfolio.py
flutter analyze
flutter test
```

Backend verification scripts require a deliberately configured local or staging environment; the static portfolio does not run them.

## Assets and attribution

Manrope and Golos Text are bundled under their respective [SIL Open Font Licenses](assets/fonts/). The web prototype uses [Lucide](https://lucide.dev/) icons under the ISC license; the pinned distribution and license are in `portfolio/assets/`. Native maps use Mapbox; place data retains OpenStreetMap source provenance and attribution. Fictional locations in the browser study are not an OSM catalog export.

No repository-wide software license has been selected. Third-party asset licenses apply to their respective assets.
