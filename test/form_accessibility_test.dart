import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'widget_test.dart' show MemoryPreferences, EmptyCatalog;

void main() {
  setUpAll(() async {
    for (final font in {
      'Manrope': 'assets/fonts/Manrope.ttf',
      'Golos Text': 'assets/fonts/GolosText.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  for (final locale in ['ru', 'en', 'be', 'pl']) {
    for (final dark in [false, true]) {
      testWidgets(
        'Meeting labels wrap at 320 points and 200%: $locale dark=$dark',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final prefs = MemoryPreferences()
            ..values.addAll({
              'language': locale,
              'theme': dark ? 'dark' : 'light',
            });
          final container = ProviderContainer(
            overrides: [
              preferencesProvider.overrideWithValue(prefs),
              communityRepositoryProvider.overrideWithValue(
                DemoCommunityRepository(),
              ),
              cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
            ],
          );
          addTearDown(container.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const PetFriendlyApp(),
            ),
          );
          await tester.pumpAndSettle();
          container.read(routerProvider).push('/edit/event');
          await tester.pumpAndSettle();
          for (final key in ['title', 'capacity']) {
            final field = find.byKey(ValueKey('field.$key'));
            await tester.scrollUntilVisible(
              field,
              200,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            expect(field, findsOneWidget);
            final semantics = tester.widget<Semantics>(
              find.ancestor(of: field, matching: find.byType(Semantics)).first,
            );
            final label = semantics.properties.label!;
            final text = find.text(label);
            expect(text, findsOneWidget);
            expect(
              tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
              isFalse,
              reason: label,
            );
            await tester.ensureVisible(field);
            await tester.pumpAndSettle();
            expect(field.hitTestable(), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
