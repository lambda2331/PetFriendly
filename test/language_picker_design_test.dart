import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/l10n/language_picker.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'widget_test.dart' show MemoryPreferences;

void main() {
  setUpAll(() async {
    for (final font in {
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/lucide_icons_flutter/Lucide':
          'packages/lucide_icons_flutter/assets/lucide.ttf',
      'Manrope': 'assets/fonts/Manrope.ttf',
      'Golos Text': 'assets/fonts/GolosText.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('language picker $platform dark=$dark scale=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(320, 700);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          tester.platformDispatcher.localesTestValue = [const Locale('en')];
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(tester.platformDispatcher.clearLocalesTestValue);
          final preferences = MemoryPreferences();
          final container = ProviderContainer(
            overrides: [preferencesProvider.overrideWithValue(preferences)],
          );
          addTearDown(container.dispose);
          final draft = TextEditingController(text: 'Мой черновик');
          addTearDown(draft.dispose);
          const capture = Key('language-capture');
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: Consumer(
                builder: (context, ref, _) => RepaintBoundary(
                  key: capture,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    locale: ref.watch(languageProvider),
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    localeListResolutionCallback: resolveAppLocale,
                    theme: studioTheme(
                      dark ? Brightness.dark : Brightness.light,
                    ).copyWith(platform: platform),
                    home: Scaffold(
                      body: Column(
                        children: [
                          const LanguageButton(),
                          TextField(controller: draft),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byType(LanguageButton));
          await tester.pumpAndSettle();
          final system = find.byKey(const ValueKey('language-system'));
          expect(tester.widget<ListTile>(system).selected, isTrue);
          expect(
            tester.widget<ListTile>(system).selectedColor,
            studioTheme(
              dark ? Brightness.dark : Brightness.light,
            ).colorScheme.onSurface,
          );
          expect(tester.widget<ListTile>(system).subtitle, isA<Text>());
          expect(
            (tester.widget<ListTile>(system).subtitle as Text).data,
            'English',
          );
          expect(tester.getSize(system).height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
          if (scale == 1 && const bool.fromEnvironment('CAPTURE_LANGUAGE_UI')) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(capture),
            );
            await tester.runAsync(() async {
              final pixels = await boundary.toImage(pixelRatio: 2);
              final bytes = await pixels.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'docs/screenshots/language-picker/widget-${platform.name}-${dark ? 'dark' : 'light'}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              pixels.dispose();
            });
          }
          final polish = find.byKey(const ValueKey('language-pl'));
          await tester.ensureVisible(polish);
          await tester.pumpAndSettle();
          expect(polish.hitTestable(), findsOneWidget);
          await tester.tap(polish);
          await tester.pumpAndSettle();
          expect(system, findsNothing);
          expect(container.read(languageProvider), const Locale('pl'));
          expect(preferences.read('language'), 'pl');
          expect(draft.text, 'Мой черновик');
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
