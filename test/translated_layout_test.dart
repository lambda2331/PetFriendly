import 'package:petfriendly/features/profiles/profile_screen.dart';
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
      for (final large in [false, true]) {
        testWidgets(
          '$locale dark=$dark enlarged=$large translated shell and headers',
          (tester) async {
            tester.view.physicalSize = Size(large ? 320 : 402, 900);
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = large ? 2 : 1;
            addTearDown(tester.view.reset);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final repo = DemoCommunityRepository();
            const city = 'San Francisco, California, US';
            const title = 'Соседи с питомцами Александровского района';
            repo.data['groups']!.first['title'] = title;
            final conversation = {
              'id': 'translated-chat',
              'kind': 'group',
              'context_id': repo.data['groups']!.first['id'],
            };
            repo.data['conversations']!.add(conversation);
            repo.data['group_members']!.add({
              'group_id': repo.data['groups']!.first['id'],
              'user_id': demoAlex,
            });
            final prefs = MemoryPreferences()
              ..values.addAll({
                'city': city,
                'manualCity': 'true',
                'language': locale,
                'theme': dark ? 'dark' : 'light',
              });
            final container = ProviderContainer(
              overrides: [
                preferencesProvider.overrideWithValue(prefs),
                communityRepositoryProvider.overrideWithValue(repo),
                cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
              ],
            );
            addTearDown(container.dispose);
            const capture = Key('translated-capture');
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: const RepaintBoundary(
                  key: capture,
                  child: PetFriendlyApp(),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final router = container.read(routerProvider);
            for (final route in [
              '/nearby',
              '/people',
              '/walks',
              '/chats',
              '/profile',
              '/chat/${conversation['id']}',
            ]) {
              router.go(route);
              await tester.pumpAndSettle();
              if (route == '/nearby') {
                final cityButton = find.byKey(const Key('choose-city'));
                await tester.scrollUntilVisible(
                  cityButton,
                  200,
                  scrollable: find.byType(Scrollable).first,
                );
                await tester.pumpAndSettle();
                final label = find.descendant(
                  of: cityButton,
                  matching: find.text(city.split(',').first),
                );
                expect(
                  tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
                  isFalse,
                );
                expect(
                  tester.getSize(cityButton).width,
                  lessThanOrEqualTo(tester.view.physicalSize.width),
                );
                expect(container.read(prototypeProvider).city, city);
              }
              if (route == '/profile') {
                final context = tester.element(find.byType(ProfileScreen));
                final entry = find.text('Избранные места'.tr(context));
                await tester.scrollUntilVisible(
                  entry,
                  200,
                  scrollable: find.byType(Scrollable).first,
                );
                await tester.pumpAndSettle();
                expect(
                  tester.renderObject<RenderParagraph>(entry).didExceedMaxLines,
                  isFalse,
                );
                expect(find.byType(TabBar), findsNothing);
              }
              if (route.startsWith('/chat/')) {
                final titleText = find.descendant(
                  of: find.byType(AppBar),
                  matching: find.text(title),
                );
                expect(
                  tester
                      .renderObject<RenderParagraph>(titleText)
                      .didExceedMaxLines,
                  isFalse,
                );
              }
              expect(
                tester.takeException(),
                isNull,
                reason: '$locale $route enlarged=$large',
              );
              if (!large &&
                  const bool.fromEnvironment('CAPTURE_TRANSLATED_UI') &&
                  (route == '/nearby' ||
                      route == '/profile' ||
                      route.startsWith('/chat/'))) {
                final boundary = tester.renderObject<RenderRepaintBoundary>(
                  find.byKey(capture),
                );
                await tester.runAsync(() async {
                  final pixels = await boundary.toImage(pixelRatio: 2);
                  final bytes = await pixels.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  final name = route.startsWith('/chat/')
                      ? 'chat'
                      : route.substring(1);
                  final file = File(
                    'docs/screenshots/translated-layout/$locale-${dark ? 'dark' : 'light'}-$name.png',
                  );
                  await file.parent.create(recursive: true);
                  await file.writeAsBytes(bytes!.buffer.asUint8List());
                  pixels.dispose();
                });
              }
            }
          },
        );
      }
    }
  }
}
