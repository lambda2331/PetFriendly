import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/ui/components.dart';
import 'package:petfriendly/features/auth/first_action_screen.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'First actions have labeled adequate touch targets in $brightness',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                accountModeRepositoryProvider.overrideWithValue(
                  DemoAccountModeRepository(),
                ),
              ],
              child: MaterialApp(
                theme: studioTheme(brightness),
                home: const FirstActionScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        } finally {
          semantics.dispose();
        }
      },
    );
  }
  testWidgets(
    'Reduced motion disables sheet and press animations; keyboard stays in sheet',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(Brightness.light),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Builder(
                builder: (context) => Scaffold(
                  body: Column(
                    children: [
                      PressButton(onTap: () {}, child: const Text('Нажать')),
                      FilledButton(
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          sheetAnimationStyle: studioSheetAnimation(context),
                          builder: (_) => const Padding(
                            padding: EdgeInsets.all(24),
                            child: TextField(
                              decoration: InputDecoration(labelText: 'Поиск'),
                            ),
                          ),
                        ),
                        child: const Text('Открыть поиск'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
        Duration.zero,
      );
      await tester.tap(find.text('Открыть поиск'));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(TextField));
      final route = ModalRoute.of(context)!;
      expect(route.transitionDuration, Duration.zero);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        ModalRoute.of(FocusManager.instance.primaryFocus!.context!),
        same(route),
      );
      await tester.enterText(find.byType(TextField), 'Минск');
      expect(find.text('Минск'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
