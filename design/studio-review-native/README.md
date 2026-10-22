# Isolated Studio design preview

This is a synthetic, in-memory UI prototype for human approval, not application implementation. No backend SDK or account credentials are used.

`lib/studio_theme.dart`, `lib/generated/`, `lib/message_bridge.dart` and fonts are read-only copies of the existing app at preparation time. Additional component/copy files belong only to this preview. Do not copy `ReviewAppState` into production: existing Riverpod/controllers/repositories and go_router remain authoritative after approval.

Create a fresh isolated Flutter project outside the main checkout (`flutter create --platforms=ios,web --org com.petfriendly.preview --project-name studio_review /tmp/petfriendly-studio-review-20261012`), then copy this folder's pubspec, lib, assets and preview tests into it. Remove the generated counter-app test only in that isolated folder. Run `flutter pub get`, `flutter test test/layout_test.dart` and the preview integration driver on a dedicated Simulator. Build web with base href `/design/studio-review-20261012/app/` and copy `build/web` into that design-only destination.

The integration driver writes fixture captures into `docs/screenshots/studio-review-20261012/`. It does not install to a phone or the shared production Simulator. No third-party design library is introduced.

English handoff: `docs/studio-review-20261012.md`. Human design approval is required before production implementation.
