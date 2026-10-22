import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_review/main.dart';

void main() {
  for (final locale in ['ru', 'en', 'be', 'pl'])
    for (final dark in [false, true]) {
      testWidgets('Compact 320px enlarged 200% $locale $dark', (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const ReviewApp());
        await tester.pumpAndSettle();
        final s = tester.state<ReviewAppState>(find.byType(ReviewApp));
        for (final page in [
          'requests',
          'walks',
          'profile',
          'conditions',
          'roles',
          'chat',
          'social',
        ]) {
          s.tab = page == 'walks' ? 'history' : 'current';
          s.captureState(
            page,
            isHelper: true,
            language: locale,
            isDark: dark,
            textScale: 2,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$page');
        }
        s.captureState(
          'requests',
          language: locale,
          isDark: dark,
          textScale: 2,
        );
        await tester.pumpAndSettle();
        s.filters('requests');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'filters');
        Navigator.pop(s.currentContext!);
        await tester.pumpAndSettle();
        s.periodSheet();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'period');
      });
    }
}
