import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/ui/components.dart';
import 'package:petfriendly/core/media/preview_photos.dart';

double contrast(Color a, Color b) {
  final values = [a.computeLuminance(), b.computeLuminance()]..sort();
  return (values.last + .05) / (values.first + .05);
}

Color token(String value) =>
    Color(int.parse('FF${value.substring(1)}', radix: 16));

void main() {
  test('Every text role uses a bundled Studio family', () {
    for (final brightness in Brightness.values) {
      final text = studioTheme(brightness).textTheme;
      for (final style in [
        text.displayLarge,
        text.displayMedium,
        text.displaySmall,
        text.headlineLarge,
        text.headlineMedium,
        text.headlineSmall,
        text.titleLarge,
        text.titleMedium,
        text.titleSmall,
        text.bodyLarge,
        text.bodyMedium,
        text.bodySmall,
        text.labelLarge,
        text.labelMedium,
        text.labelSmall,
      ]) {
        expect(style?.fontFamily, anyOf('Manrope', 'Golos Text'));
      }
    }
  });

  test(
    'Studio text remains legible on every semantic surface and matches tokens',
    () {
      final tokens = jsonDecode(File('design/tokens.json').readAsStringSync());
      for (final brightness in Brightness.values) {
        final theme = studioTheme(brightness);
        final colors =
            tokens['colors'][brightness == Brightness.dark ? 'dark' : 'light'];
        final studio = theme.extension<StudioColors>()!;
        expect(theme.scaffoldBackgroundColor, token(colors['background']));
        expect(theme.colorScheme.surface, token(colors['surface']));
        expect(theme.bottomSheetTheme.backgroundColor, token(colors['sheet']));
        expect(theme.dialogTheme.backgroundColor, token(colors['sheet']));
        expect(
          theme.colorScheme.onSurfaceVariant,
          token(colors['textSecondary']),
        );
        expect(studio.line, token(colors['border']));
        for (final surface in [
          theme.scaffoldBackgroundColor,
          theme.colorScheme.surface,
          theme.bottomSheetTheme.backgroundColor!,
          studio.tint,
          studio.hero,
        ]) {
          expect(
            contrast(theme.colorScheme.onSurface, surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(theme.colorScheme.onSurfaceVariant, surface),
            greaterThanOrEqualTo(4.5),
          );
        }
        expect(
          contrast(StudioColors.onLime, StudioColors.lime),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(
            theme.colorScheme.error,
            theme.bottomSheetTheme.backgroundColor!,
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );

  testWidgets(
    'Actual photographs and empty frames keep proportions at narrow and wide widths',
    (tester) async {
      final bytes = await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 20, 40),
          Paint()..color = Colors.blue,
        );
        final image = await recorder.endRecording().toImage(20, 40);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return data!.buffer.asUint8List();
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(previewPhotosProvider.notifier)
          .put('profile:fixture', bytes!);
      for (final width in [320.0, 600.0]) {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: studioTheme(Brightness.dark),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Center(
                    child: SizedBox(
                      width: width,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CommunityCover(
                            id: 'group:fixture',
                            previewBytes: bytes,
                          ),
                          const CommunityCover(id: 'group:empty'),
                          const IdentityPicture(
                            id: 'profile:fixture',
                            icon: Icons.person_outline,
                            size: 64,
                          ),
                          const IdentityPicture(
                            id: 'profile:empty',
                            icon: Icons.person_outline,
                            size: 64,
                            name: 'Анна Иванова',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final covers = find.byType(CommunityCover);
        expect(tester.getSize(covers.first), Size(width, width / 2));
        expect(tester.getSize(covers.last).height, lessThan(width / 2));
        for (final element in find.byType(IdentityPicture).evaluate()) {
          expect(
            tester.getSize(find.byWidget(element.widget)),
            const Size(64, 64),
          );
        }
        expect(find.text('АИ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Compact heading and metadata keep long Cyrillic content readable',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Scaffold(
              body: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScreenIntro(
                        'Заявка на прогулку с питомцем',
                        compact: true,
                      ),
                      MetadataLine(
                        items: [
                          'Центральный район',
                          '10 октября 2026 · 15:30 · UTC+3',
                          '45 минут',
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Центральный район'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
