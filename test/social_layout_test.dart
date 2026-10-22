import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/community/people_screen.dart';
import 'package:petfriendly/features/community/presentation/community_browser.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'widget_test.dart' show MemoryPreferences, EmptyCatalog;

void main() {
  setUpAll(() async {
    for (final font in {
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'Manrope': 'assets/fonts/Manrope.ttf',
      'Golos Text': 'assets/fonts/GolosText.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  for (final locale in ['ru', 'en', 'be', 'pl']) {
    for (final dark in [false, true]) {
      for (final screen in ['meetups', 'communities']) {
        testWidgets(
          '$screen $locale ${dark ? 'dark' : 'light'} 320px 200% reflows',
          (tester) async {
            tester.view.physicalSize = const Size(320, 900);
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = 2;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final repo = DemoCommunityRepository();
            repo.data['groups']!.first['title'] =
                'Соседи с питомцами Александровского района';
            repo.data['groups']!.first['description'] =
                'Знакомимся постепенно, обсуждаем прогулки и помогаем друг другу.';
            repo.data['events']!.first['title'] =
                'Спокойная прогулка по Александровскому скверу';
            final prefs = MemoryPreferences()
              ..values.addAll({
                'theme': dark ? 'dark' : 'light',
                'language': locale,
                'city': 'Минск',
                'manualCity': 'true',
              });
            final container = ProviderContainer(
              overrides: [
                preferencesProvider.overrideWithValue(prefs),
                communityRepositoryProvider.overrideWithValue(repo),
                cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
              ],
            );
            addTearDown(container.dispose);
            const captureKey = Key('social-capture');
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: const RepaintBoundary(
                  key: captureKey,
                  child: PetFriendlyApp(),
                ),
              ),
            );
            await tester.pumpAndSettle();
            container
                .read(routerProvider)
                .go(screen == 'meetups' ? '/events' : '/people');
            await tester.pumpAndSettle();
            if (screen == 'communities') {
              final context = tester.element(find.byType(PeopleScreen));
              final tab = find.descendant(
                of: find.byKey(const ValueKey('people-community-segment')),
                matching: find.text('Сообщества'.tr(context)),
              );
              await tester.ensureVisible(tab);
              await tester.tap(tab);
              await tester.pumpAndSettle();
              await tester.scrollUntilVisible(
                find.byType(CommunityBrowser),
                200,
                scrollable: find.descendant(
                  of: find.byKey(const ValueKey('people-list')),
                  matching: find.byType(Scrollable),
                ),
              );
            }
            if (screen == 'meetups') {
              final context = tester.element(
                find.byKey(const ValueKey('meetup-date-filter')),
              );
              final date = find.byKey(const ValueKey('meetup-date-filter'));
              await tester.ensureVisible(date);
              await tester.tap(date);
              await tester.pumpAndSettle();
              final option = find.text('Ближайшие 7 дней'.tr(context));
              expect(option, findsOneWidget);
              expect(
                tester.renderObject<RenderParagraph>(option).didExceedMaxLines,
                isFalse,
              );
              expect(tester.takeException(), isNull);
              await tester.tap(option);
              await tester.tap(find.text('Применить'.tr(context)));
              await tester.pumpAndSettle();
              await tester.ensureVisible(date);
              await tester.tap(date);
              await tester.pumpAndSettle();
              await tester.tap(find.text('Любая дата'.tr(context)).last);
              await tester.tap(find.text('Применить'.tr(context)));
              await tester.pumpAndSettle();
            }
            if (screen == 'communities') {
              final context = tester.element(find.byType(CommunityBrowser));
              await tester.scrollUntilVisible(
                find.byKey(const ValueKey('social-filter')),
                -200,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.tap(find.byKey(const ValueKey('social-filter')));
              await tester.pumpAndSettle();
              final label = find.text('Мои'.tr(context));
              final paragraph = tester.renderObject<RenderParagraph>(label);
              expect(
                paragraph.didExceedMaxLines,
                isFalse,
                reason: 'Membership labels must remain fully readable',
              );
              await tester.tap(label);
              await tester.pumpAndSettle();
            }
            expect(tester.takeException(), isNull);
            if (const bool.fromEnvironment('CAPTURE_SOCIAL_UI')) {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(captureKey),
              );
              await tester.runAsync(() async {
                final pixels = await boundary.toImage(pixelRatio: 2);
                final bytes = await pixels.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File(
                  'docs/screenshots/meetups-community/widget-$screen-$locale-${dark ? 'dark' : 'light'}-large.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
                pixels.dispose();
              });
            }
          },
        );
      }
    }
  }
}
