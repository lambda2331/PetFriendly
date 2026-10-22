import 'package:petfriendly/features/walks/account_mode.dart';
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

class ApplicationConfirmationRepository extends DemoCommunityRepository {
  bool changedAccount = false;
  int applications = 0;
  @override
  String get userId => changedAccount ? demoSasha : super.userId;
  ApplicationConfirmationRepository() {
    data['walk_requests']!.first['owner_id'] = demoAnna;
    data['walk_applications'] = [];
  }
  @override
  Future<String?> command(String action, Json values) async {
    if (action == 'apply_walk') {
      applications++;
      data['walk_applications']!.add({
        'request_id': values['request_in'],
        'helper_id': userId,
      });
      return null;
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
        find.widgetWithText(OutlinedButton, 'Выбрать помощника'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Пока нет отзывов'), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);
      await tester.tap(find.text('Выбрать помощника'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.textContaining('станет помощником этой прогулки'),
        findsOneWidget,
      );
      expect(repository.assignments, 0);
      await tester.tap(find.byKey(const Key('walk-confirm-submit')));
      await tester.pump();
      expect(repository.assignments, 1);
      final select = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Выбрать помощника'),
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
  for (final changeAccount in [false, true]) {
    testWidgets(
      'Application needs explicit confirmation and rejects account replacement=$changeAccount',
      (tester) async {
        final repository = ApplicationConfirmationRepository();
        final mode = DemoAccountModeRepository();
        await mode.chooseRole('helper');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              communityRepositoryProvider.overrideWithValue(repository),
              accountModeRepositoryProvider.overrideWithValue(mode),
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
        final offer = find.widgetWithText(FilledButton, 'Предложить помощь');
        await tester.ensureVisible(offer);
        await tester.tap(offer);
        await tester.pumpAndSettle();
        expect(find.text('Отправить отклик?'), findsOneWidget);
        expect(repository.applications, 0);
        await tester.tap(find.widgetWithText(OutlinedButton, 'Отмена'));
        await tester.pumpAndSettle();
        expect(repository.applications, 0);
        expect(repository.data['walk_applications'], isEmpty);
        await tester.ensureVisible(offer);
        await tester.tap(offer);
        await tester.pumpAndSettle();
        repository.changedAccount = changeAccount;
        await tester.tap(find.byKey(const Key('walk-confirm-submit')));
        await tester.pumpAndSettle();
        expect(repository.applications, changeAccount ? 0 : 1);
        expect(
          repository.data['walk_applications'],
          changeAccount ? isEmpty : hasLength(1),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
