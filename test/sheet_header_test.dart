import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/ui/components.dart';

void main() {
  testWidgets('Shared sheet header fits enlarged title and invokes close', (
    tester,
  ) async {
    var closed = false;
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(Brightness.dark),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StudioSheetHeader(
                title: 'Правила для питомцев',
                subtitle: 'Парк в выбранном городе',
                onClose: () => closed = true,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Правила для питомцев'), findsOneWidget);
    expect(find.text('Парк в выбранном городе'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Закрыть'));
    expect(closed, isTrue);
  });
  testWidgets('Saving sheet explains disabled close and omits empty subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(Brightness.light),
        home: const Scaffold(
          body: StudioSheetHeader(
            title: 'Правила для питомцев',
            subtitle: ' ',
            closeEnabled: false,
          ),
        ),
      ),
    );
    final close = find.byTooltip('Сначала дождитесь завершения сохранения');
    expect(close, findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
    expect(find.text(' '), findsNothing);
  });
}
