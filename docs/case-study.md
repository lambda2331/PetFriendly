# PetFriendly — Design Engineering case study

[Explore the live case study](https://lambda2331.github.io/PetFriendly/) · [Try the prototype](https://lambda2331.github.io/PetFriendly/prototype.html)

## Overview

PetFriendly explores a neighborhood community for pet owners: nearby places, people and interest groups, shared walks, walking assistance and chat. Minsk, Belarus is the initial market. The project brings interface design, interaction prototyping and native implementation into one repository.

This is a personal project. The portfolio demonstrates design engineering across a visual system, browser interactions, Flutter UI and backend constraints. The repository does not establish external team roles, a research program or business results; none are invented here.

## Product hypothesis

A place alone is not enough to plan a shared walk. People also need a suitable location, compatible company and a way to agree on details. PetFriendly brings those tasks into a neighborhood context. This premise still needs research and usability validation.

## Design decisions

### Translate a visual language into a working system

Studio uses Manrope for headings and Golos Text for body copy. Neutral surfaces carry the interface; lime identifies selected navigation and primary actions. Semantic tokens, shared Flutter components and light/dark themes make the design reproducible beyond a single screen.

### Keep location useful and optional

Manual city selection persists until the user deliberately returns to nearby mode. Public profiles use a district, not exact coordinates. A map-unavailable state leads to a browsable places list. Missing pet-access evidence stays unknown rather than being converted into an endorsement.

### Connect trust-related UI to server rules

Walking help proceeds through request, offers, assignment and completion. Reviews are tied to completed agreements. Membership governs chat access. This connects what users see to server authorization and transactional behavior.

## Interactive evidence

The English demo compiles the current Flutter screens, repositories and scenario logic. A thin HTML host frames the app without recreating its UI. A reviewed build catalog provides English text; a literal scanner preserves nested Dart interpolation, and missing translations fail the build.

The user chose a mocked map. The Flutter map adapter supports pan/zoom, category markers, fullscreen, simulated position and selecting a point for a new place. Place details, favorites, reviews and list navigation use the existing app widgets. People/community search, meetups, chat composition, walking requests and profile/pet editing also use the shared implementation.

All demo data is fictional and stays in memory except theme, manual city and favorite preferences. Portfolio mode disconnects live account, backend, catalog and Firebase services. The demonstration exercises interaction and state logic, not production delivery or security guarantees.

## Outcome and next steps

The deliverable is an inspectable design system, interactive study and native/backend source. Adoption, conversion, research findings and production readiness have not been established.

Next steps: test the discovery-to-conversation journey with pet owners, validate pet-access terminology, compare the study against the native app and complete release checks for live services. Native builds keep their existing default language; the portfolio is a reproducible English compile-time adaptation, not a runtime language switch.
