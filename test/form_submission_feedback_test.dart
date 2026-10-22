import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/community/presentation/forms.dart';
import 'package:petfriendly/features/community/presentation/report_screen.dart';
import 'widget_test.dart' show MemoryPreferences;

class DelayedFormRepository extends DemoCommunityRepository {
  final pending = Completer<String?>();
  int calls = 0;
  @override
  Future<String?> command(String action, Map<String, dynamic> values) {
    calls++;
    return pending.future;
  }
}

void main() {
  testWidgets('Report shows pending submission and can retry a failure', (
    tester,
  ) async {
    final repository = DelayedFormRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [communityRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: studioTheme(Brightness.light),
          home: const ReportScreen(kind: 'profile', id: 'synthetic'),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Синтетическое описание');
    await tester.ensureVisible(find.text('Отправить жалобу'));
    await tester.tap(find.text('Отправить жалобу'));
    await tester.pump();
    expect(find.text('Отправляем жалобу…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(repository.calls, 1);
    repository.pending.completeError(StateError('synthetic failure'));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось отправить жалобу'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Community creation has a named busy state at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = DelayedFormRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repository),
          preferencesProvider.overrideWithValue(MemoryPreferences()),
        ],
        child: MaterialApp(
          theme: studioTheme(Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const EditScreen(kind: 'group'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('field.title')),
      'Синтетическое сообщество',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(FilledButton, 'Создать сообщество');
    await tester.scrollUntilVisible(
      submit,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    expect(submit.hitTestable(), findsOneWidget);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('Создаём сообщество…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
    repository.pending.completeError(StateError('synthetic failure'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(repository.calls, 1);
    expect(tester.takeException(), isNull);
  });
}
