import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/walks/helper_requests_screen.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'helper_discovery_design_test.dart' show mount, discoveryFixture;

void main() {
  for (final locale in ['ru', 'en', 'be', 'pl']) {
    for (final dark in [false, true]) {
      testWidgets('helper filters $locale dark=$dark 320px 200%', (
        tester,
      ) async {
        await mount(
          tester,
          const RequestsScreen(),
          discoveryFixture(),
          locale: locale,
          dark: dark,
          scale: 2,
        );
        final context = tester.element(find.byType(RequestsScreen));
        await tester.tap(find.byTooltip('Фильтры'.tr(context)));
        await tester.pumpAndSettle();
        final expansion = find.text('Дата, время и размер собаки'.tr(context));
        await tester.scrollUntilVisible(
          expansion,
          200,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('walking-sheet-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(expansion.hitTestable());
        await tester.pumpAndSettle();
        final day = find.text('Выбрать день'.tr(context));
        await tester.scrollUntilVisible(
          day,
          150,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('walking-sheet-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(day.hitTestable());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Готово'.tr(context)).last);
        await tester.pumpAndSettle();
        final time = find.byKey(const ValueKey('any'));
        await tester.scrollUntilVisible(
          time,
          200,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('walking-sheet-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(time.hitTestable());
        await tester.pumpAndSettle();
        final evening = find.text('Вечер · 17:00–24:00'.tr(context)).last;
        await tester.ensureVisible(evening);
        await tester.pumpAndSettle();
        expect(
          tester.renderObject<RenderParagraph>(evening).didExceedMaxLines,
          isFalse,
        );
        await tester.tap(evening);
        await tester.pumpAndSettle();
        final selected = find.descendant(
          of: find.byKey(const ValueKey('evening')),
          matching: find.text('Вечер · 17:00–24:00'.tr(context)),
        );
        expect(
          tester.renderObject<RenderParagraph>(selected).didExceedMaxLines,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
