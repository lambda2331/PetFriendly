import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/features/community/data/community_browse.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/community/people_screen.dart';
import 'fixtures/meetup_studio_fixture.dart';
import 'fixtures/people_studio_fixture.dart';

void main() {
  test('Invite search excludes members and blocked profiles', () {
    final r = PeopleStudioRepository();
    expect(
      invitationCandidates(
        r.data,
        r.userId,
        socialGroup,
        'Екатерина',
      ).single['id'],
      socialKat,
    );
    r.data['blocks'] = [
      {'target_id': socialKat},
    ];
    expect(invitationCandidates(r.data, r.userId, socialGroup, ''), isEmpty);
  });
  testWidgets('Inline pets, community details, nested invitation and copy', (
    tester,
  ) async {
    final r = PeopleStudioRepository();
    final c = meetupStudioContainer(repository: r);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const PetFriendlyApp()),
    );
    await tester.pumpAndSettle();
    c.read(routerProvider).go('/people');
    await tester.pumpAndSettle();
    expect(find.text('Анна'), findsOneWidget);
    expect(find.text('Бруно, Марта +1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('person-details-$demoAnna')));
    await tester.pumpAndSettle();
    expect(find.text('Арчи · собака · спокойный'), findsOneWidget);
    await tester.tap(find.text('Сообщества').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('community-chat')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('community-$socialGroup')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('community-invite')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('invite-search')),
      'Екатерина',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('invite-person-$socialKat')),
      findsOneWidget,
    );
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('invite-copy')));
    await tester.tap(find.byKey(const ValueKey('invite-copy')));
    await tester.pumpAndSettle();
    expect(copied, 'petfriendly://group/$socialGroup');
    await tester.tap(find.byKey(const ValueKey('invite-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('community-invite')), findsOneWidget);
    expect(find.byKey(const ValueKey('invite-search')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('community-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('message-input')), findsOneWidget);
    c.read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('community-invite')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('community-invite')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('invite-person-$socialKat')));
    await tester.pumpAndSettle();
    final input = tester.widget<TextField>(
      find.byKey(const Key('message-input')),
    );
    expect(
      input.controller!.text,
      contains('petfriendly://group/$socialGroup'),
    );
    expect(
      r.data['group_members']!.any(
        (m) => m['group_id'] == socialGroup && m['user_id'] == socialKat,
      ),
      false,
    );
    expect(tester.takeException(), isNull);
  });
  for (final locale in ['ru', 'en', 'be', 'pl']) {
    testWidgets('$locale dark 200% social layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = meetupStudioContainer(
        locale: locale,
        dark: true,
        repository: PeopleStudioRepository(),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const PetFriendlyApp()),
      );
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/people');
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(PeopleScreen)) as dynamic;
      state.setState(() => state.tab = 1);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Соседи с питомцами'),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('people-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(find.text('Соседи с питомцами'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Соседи с питомцами'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('community-invite')),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('community-invite')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('invite-search')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
