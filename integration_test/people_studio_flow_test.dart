import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import '../test/fixtures/meetup_studio_fixture.dart';
import '../test/fixtures/people_studio_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('People Studio native parity and invitations', (tester) async {
    for (final dark in [false, true]) {
      for (final locale in ['ru', 'en', 'be', 'pl']) {
        final c = meetupStudioContainer(
          locale: locale,
          dark: dark,
          repository: PeopleStudioRepository(),
        );
        tester.platformDispatcher.textScaleFactorTestValue = locale == 'pl'
            ? 2
            : 1;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const PetFriendlyApp(),
          ),
        );
        await tester.pumpAndSettle();
        c.read(routerProvider).go('/people');
        await tester.pumpAndSettle();
        final prefix = '$locale-${dark ? 'dark' : 'light'}';
        await binding.takeScreenshot('$prefix-people');
        if (locale == 'ru') {
          await tester.tap(
            find.byKey(const ValueKey('person-details-$demoAnna')),
          );
          await tester.pumpAndSettle();
          await binding.takeScreenshot('$prefix-pets');
        }
        final tab = find.descendant(
          of: find.byKey(const ValueKey('people-community-segment')),
          matching: find.text(
            'Сообщества'.tr(
              tester.element(
                find.byKey(const ValueKey('people-community-segment')),
              ),
            ),
          ),
        );
        await tester.ensureVisible(tab);
        await tester.tap(tab);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('$prefix-communities');
        await tester.scrollUntilVisible(
          find.text('Соседи с питомцами'),
          180,
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
        await binding.takeScreenshot('$prefix-details');
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('community-invite')),
          120,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.byKey(const ValueKey('community-invite')));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('$prefix-invite');
        await tester.tap(find.byKey(const ValueKey('invite-close')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('community-invite')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        c.dispose();
      }
    }
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}
