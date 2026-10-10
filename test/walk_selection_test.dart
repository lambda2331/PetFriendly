import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/walks_screen.dart';

class SlowAssignment extends DemoCommunityRepository {
  final finish = Completer<void>();
  int assignments = 0;
  SlowAssignment() {
    data['walk_requests']!.first['owner_id'] = demoAlex;
    data['walk_applications']!.add({
      'request_id': data['walk_requests']!.first['id'],
      'helper_id': demoSasha,
    });
  }
  @override
  Future<String?> command(String action, Json values) async {
    if (action == 'assign_walk') {
      assignments++;
      await finish.future;
    }
    return super.command(action, values);
  }
}

void main() {
  testWidgets(
    'Helper selection explains commitment and prevents duplicate submission',
    (tester) async {
      final repository = SlowAssignment();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communityRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: WalkDetailScreen(
              id: repository.data['walk_requests']!.first['id'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(TextButton, 'Выбрать помощника'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Пока нет отзывов'), findsOneWidget);
      expect(find.text('Профиль и отзывы'), findsOneWidget);
      await tester.tap(find.text('Выбрать помощника'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(repository.assignments, 0);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Выбрать помощника'),
        ),
      );
      await tester.pump();
      expect(repository.assignments, 1);
      final select = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Выбрать помощника'),
      );
      expect(select.onPressed, isNull);
      repository.finish.complete();
      await tester.pumpAndSettle();
      expect(find.text('Выбрать помощника'), findsNothing);
      expect(
        find.text('Помощник выбран. Договорённость создана'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
