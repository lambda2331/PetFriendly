import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/walks/walk_progress.dart';
import 'package:petfriendly/features/walks/walks_screen.dart';

void main() {
  testWidgets(
    'Walking stages are always visible and readable at large text without motion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 1000),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  WalkProgressView(
                    progress: WalkProgress.forRequest(
                      status: 'awaiting_confirmation',
                      owner: true,
                      helper: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Подтверждение'), findsNWidgets(2));
      for (final label in WalkProgress.stages) {
        expect(
          find.text(label),
          label == 'Подтверждение' ? findsNWidgets(2) : findsOneWidget,
        );
      }
      expect(find.text('4 / 5'), findsOneWidget);
      expect(find.byKey(const Key('walk-progress-rail')), findsOneWidget);
      expect(find.byKey(const Key('walk-progress-toggle')), findsNothing);
      expect(find.byKey(const Key('walk-next-step')), findsOneWidget);
      final stage = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == 'Этап 4 из 5: Подтверждение',
      );
      expect(
        tester.getSemantics(stage).label,
        contains('Этап 4 из 5: Подтверждение'),
      );
      semantics.dispose();
      expect(find.byType(AnimatedSize), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Cancelled walking request has its instruction without misleading progress rail',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WalkProgressView(
              progress: WalkProgress.forRequest(
                status: 'cancelled',
                owner: true,
                helper: false,
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('walk-progress-toggle')), findsNothing);
      expect(find.byKey(const Key('walk-progress-rail')), findsNothing);
      expect(find.textContaining('Заявка отменена'), findsOneWidget);
    },
  );
  testWidgets(
    'Five stages remain visible in compact dark layout without interaction',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(Brightness.dark),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: WalkProgressView(
                progress: WalkProgress.forRequest(
                  status: 'assigned',
                  owner: true,
                  helper: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in WalkProgress.stages) {
        expect(
          find.text(label),
          label == 'Договорённость' ? findsNWidgets(2) : findsOneWidget,
        );
      }
      expect(find.text('2 / 5'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byKey(const Key('walk-progress-rail')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
