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

The English HTML study offers five tabs, theme switching, place details and favorites, people/community search, local message composition and simulated walking actions. It labels fictional data and distinguishes simulation from real service behavior. Keyboard focus, dialog dismissal and reduced motion are part of the interaction work.

The browser adaptation follows current Flutter screen structure, including the separate places list and compact profile. It shows the unavailable-map fallback. Native authentication, maps, private media and service behavior remain separate; this is not a Flutter web build.

## Outcome and next steps

The deliverable is an inspectable design system, interactive study and native/backend source. Adoption, conversion, research findings and production readiness have not been established.

Next steps: test the discovery-to-conversation journey with pet owners, validate pet-access terminology, compare the study against the native app and complete release checks for live services. The native UI remains primarily Russian; full English localization is separate from this portfolio adaptation.
