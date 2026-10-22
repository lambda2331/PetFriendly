import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/ui/components.dart';
import 'package:petfriendly/core/ui/studio_review.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/place_details_sheet.dart';
import 'package:petfriendly/features/nearby/city_sheet.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'package:petfriendly/features/nearby/places_list_screen.dart';
import 'widget_test.dart' show EmptyCatalog, MemoryPreferences;
import 'package:petfriendly/features/nearby/city_catalog.dart';

void main() {
  setUpAll(() async {
    for (final font in {
      'Manrope': 'assets/fonts/Manrope.ttf',
      'Golos Text': 'assets/fonts/GolosText.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  testWidgets(
    'Icon-only destinations retain names, tap actions and selection',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(320, 874);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backendProvider.overrideWithValue(null),
            preferencesProvider.overrideWithValue(MemoryPreferences()),
            cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
          ],
          child: const PetFriendlyApp(),
        ),
      );
      await tester.pumpAndSettle();
      final profile = find.byKey(const ValueKey('nav-4'));
      expect(tester.getSemantics(profile).label, 'Я');
      expect(
        tester
            .getSemantics(profile)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(
        find.descendant(of: profile, matching: find.byType(Text)),
        findsNothing,
      );
      await tester.ensureVisible(profile);
      await tester.tap(profile);
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(profile)
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      expect(
        find.descendant(of: profile, matching: find.text('Я')),
        findsOneWidget,
      );
      final title = tester.widget<Text>(find.text('Профиль'));
      expect(title.style?.fontSize, 32);
      expect(title.style?.height, 1.12);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Shared localized segments scroll whole labels and support keys',
    (tester) async {
      tester.view.physicalSize = const Size(320, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(Brightness.dark),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => StudioSegmentTabs<int>(
                  entries: const {
                    0: 'Ludzie',
                    1: 'Społeczności',
                    2: 'Spotkania',
                  },
                  value: selected,
                  onChanged: (value) => setState(() => selected = value),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final community = find.text('Społeczności');
      final text = tester.renderObject<RenderParagraph>(community);
      expect(
        text
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 12),
            )
            .map((box) => box.top)
            .toSet()
            .length,
        1,
      );
      await tester.ensureVisible(community);
      await tester.tap(community);
      await tester.pumpAndSettle();
      expect(selected, 1);
      final ink = tester.widget<InkWell>(
        find.ancestor(of: community, matching: find.byType(InkWell)),
      );
      ink.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(selected, 2);
      expect(find.text('Spotkania').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Place select caption stays outside a working selection control',
    (tester) async {
      var value = 'all';
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(Brightness.light),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Padding(
                padding: const EdgeInsets.all(20),
                child: PlaceSelect<String>(
                  label: 'Категория',
                  value: value,
                  choices: const {'all': 'Все места', 'park': 'Парк'},
                  onChanged: (next) => setState(() => value = next),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byKey(ValueKey('Категория:$value'));
      final caption = find.text('Категория');
      expect(
        tester.getRect(caption).bottom,
        lessThan(tester.getRect(field).top),
      );
      final captionStyle = tester.widget<Text>(caption).style;
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Парк').last);
      await tester.pumpAndSettle();
      expect(value, 'park');
      expect(tester.widget<Text>(caption).style, captionStyle);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Compact international city search stays usable at 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(Brightness.light),
        home: Scaffold(
          body: CitySheet(city: 'Минск', onSelected: (_) {}, onLocate: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const Key('city-input'))).height,
      lessThan(100),
    );
    expect(find.byKey(const Key('city-nearby')).hitTestable(), findsOneWidget);
    await tester.enterText(find.byKey(const Key('city-input')), 'Warsaw');
    await tester.pumpAndSettle();
    expect(find.textContaining('Польша'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'Place heading/close stay visible while review scrolls, dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final place = Place(
          'sheet-test',
          'Тестовый парк',
          'Парк',
          'Минск',
          null,
          0,
          List.filled(8, 'Длинное описание публичного места.').join(' '),
          'unknown',
          Icons.park,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              backendProvider.overrideWithValue(null),
              preferencesProvider.overrideWithValue(MemoryPreferences()),
              communityRepositoryProvider.overrideWithValue(
                DemoCommunityRepository(),
              ),
            ],
            child: MaterialApp(
              theme: studioTheme(dark ? Brightness.dark : Brightness.light),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showPlace(context, place),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('open-place-review')));
        await tester.tap(find.byKey(const Key('open-place-review')));
        await tester.pumpAndSettle();
        final comment = find.byKey(const Key('inline-place-review'));
        await tester.ensureVisible(comment);
        await tester.enterText(comment, 'Черновик отзыва');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        await tester.ensureVisible(comment);
        await tester.pumpAndSettle();
        final header = find.byType(StudioReviewSheetHeader);
        expect(find.text(place.name).hitTestable(), findsOneWidget);
        final close = find.descendant(
          of: header,
          matching: find.byTooltip('Закрыть'),
        );
        expect(close.hitTestable(), findsOneWidget);
        expect(tester.getRect(header).bottom, lessThan(574));
        expect(find.text('Черновик отзыва'), findsOneWidget);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(find.byType(PlaceDetailsSheet), findsNothing);
        expect(find.text('Open'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
