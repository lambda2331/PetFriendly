import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';

double contrast(Color foreground, Color background) {
  final luminance = [
    foreground.computeLuminance(),
    background.computeLuminance(),
  ]..sort();
  return (luminance.last + .05) / (luminance.first + .05);
}

void main() {
  for (final brightness in Brightness.values) {
    test('$brightness action states remain readable and focus is visible', () {
      final theme = studioTheme(brightness);
      final styles = [
        theme.filledButtonTheme.style!,
        theme.elevatedButtonTheme.style!,
        theme.outlinedButtonTheme.style!,
      ];
      for (final style in styles) {
        for (final states in <Set<WidgetState>>[
          {},
          {WidgetState.hovered},
          {WidgetState.pressed},
          {WidgetState.focused},
          {WidgetState.disabled},
          {WidgetState.disabled, WidgetState.hovered, WidgetState.focused},
        ]) {
          final foreground = style.foregroundColor!.resolve(states)!;
          final background = Color.alphaBlend(
            style.backgroundColor!.resolve(states)!,
            theme.colorScheme.surface,
          );
          expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
        }
        final focused = style.side!.resolve({WidgetState.focused})!;
        expect(focused.width, greaterThanOrEqualTo(2));
        final focusBackground = Color.alphaBlend(
          style.backgroundColor!.resolve({WidgetState.focused})!,
          theme.colorScheme.surface,
        );
        expect(
          contrast(focused.color, focusBackground),
          greaterThanOrEqualTo(3),
        );
      }
      final outlined = theme.outlinedButtonTheme.style!;
      expect(outlined.backgroundColor!.resolve({}), Colors.transparent);
      expect(outlined.side!.resolve({})!.width, 1);
      // Tertiary controls keep their own border-free hierarchy.
      expect(theme.textButtonTheme.style!.side, isNull);
    });

    testWidgets('$brightness capsules support narrow multilingual large text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(brightness),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Center(
                  child: SizedBox(
                    width: 280,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add),
                          label: const Text('Создать заявку на прогулку'),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Request walking assistance'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Напісаць паведамленне'),
                        ),
                        const OutlinedButton(
                          onPressed: null,
                          child: Text('Napisz wiadomość do opiekuna'),
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
      expect(tester.takeException(), isNull);
      for (final type in [FilledButton, ElevatedButton, OutlinedButton]) {
        for (final element in find.byType(type).evaluate()) {
          final size = tester.getSize(find.byWidget(element.widget));
          expect(size.height, greaterThanOrEqualTo(48));
          expect(size.width, lessThanOrEqualTo(280));
        }
      }
    });
  }
}
