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
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'widget_test.dart' show EmptyCatalog, MemoryPreferences;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final font in {
      'Manrope': 'Manrope',
      'GolosText': 'Golos Text',
    }.entries) {
      await (FontLoader(
        font.value,
      )..addFont(rootBundle.load('assets/fonts/${font.key}.ttf'))).load();
    }
  });
  for (final language in ['ru', 'en']) {
    for (final dark in [false, true]) {
      for (final scenario in [
        ('requests', '/requests', 390.0, 1.0),
        ('profile', '/profile', 390.0, 1.0),
        ('profile-large', '/profile', 320.0, 2.0),
        ('requests-large', '/requests', 320.0, 2.0),
        ('onboarding-large', '/helper/onboarding', 320.0, 2.0),
        ('preferences-large', '/helper/onboarding', 320.0, 2.0),
        ('chats-large', '/chats', 320.0, 2.0),
        ('history-large', '/my-walks', 320.0, 2.0),
        ('roles-large', '/roles', 320.0, 2.0),
        ('walks-large', '/my-walks', 320.0, 2.0),
        ('owner-large', '/owner/$demoAnna', 320.0, 2.0),
      ]) {
        testWidgets(
          '${scenario.$1} $language ${dark ? 'dark' : 'light'} Flutter layout',
          (tester) async {
            tester.view.physicalSize = Size(scenario.$3, 900);
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = scenario.$4;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final account = DemoAccountModeRepository();
            await account.chooseRole('both', mode: 'helper');
            if (scenario.$1.startsWith('profile')) {
              await account.saveHelperProfile(
                const HelperProfile(
                  city: 'Минск',
                  district: 'Центральный район',
                  serviceDistricts: ['Центральный район'],
                  availability: [
                    WeeklyAvailability(day: 0, start: 1080, end: 1200),
                  ],
                ),
              );
            }
            final prefs = MemoryPreferences()..values['language'] = language;
            prefs.values['theme'] = dark ? 'dark' : 'light';
            const captureKey = Key('helper-capture');
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  preferencesProvider.overrideWithValue(prefs),
                  cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
                  communityRepositoryProvider.overrideWithValue(
                    DemoCommunityRepository(
                      seedSamples: !scenario.$1.startsWith('chats'),
                    ),
                  ),
                  accountModeRepositoryProvider.overrideWithValue(account),
                ],
                child: const RepaintBoundary(
                  key: captureKey,
                  child: PetFriendlyApp(),
                ),
              ),
            );
            await tester.pumpAndSettle();
            ProviderScope.containerOf(
              tester.element(find.byType(StudioShell)),
            ).read(routerProvider).go(scenario.$2);
            await tester.pumpAndSettle();
            if (scenario.$1.startsWith('preferences')) {
              await tester.tap(
                find.text(translateForLanguage('Продолжить', locale: language)),
              );
              await tester.pumpAndSettle();
            }
            if (scenario.$1.startsWith('history')) {
              final history = find.text(
                translateForLanguage('История', locale: language),
              );
              await tester.scrollUntilVisible(
                history,
                100,
                scrollable: find.byType(Scrollable).last,
              );
              await tester.tap(history);
              await tester.pumpAndSettle();
            }
            expect(tester.takeException(), isNull);
            if (const bool.fromEnvironment('CAPTURE_HELPER_UI')) {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(captureKey),
              );
              await tester.runAsync(() async {
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File(
                  'docs/screenshots/helper-mode-native/widget-${scenario.$1}-$language-${dark ? 'dark' : 'light'}.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
          },
        );
      }
    }
  }
}
