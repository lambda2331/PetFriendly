import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Assert the public navigation semantics, independently of its approved skin.
void expectNativeBranches(WidgetTester tester, List<int> branches) {
  for (var branch = 0; branch < 7; branch++) {
    expect(
      find.byKey(ValueKey('nav-$branch')),
      branches.contains(branch) ? findsOneWidget : findsNothing,
    );
  }
}

void expectNativeSelectedBranch(WidgetTester tester, int branch) {
  final entries = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith('nav-') &&
        widget.properties.selected == true,
  );
  expect(entries, findsOneWidget);
  expect(tester.widget<Semantics>(entries).key, ValueKey('nav-$branch'));
}

/// Wait for transient feedback/route overlays to stop covering the actual tap
/// point. Never invoke a callback through a barrier or silence a missed tap.
Future<void> tapNativeReady(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final deadline = DateTime.now().add(const Duration(seconds: 8));
  while (target.hitTestable().evaluate().isEmpty &&
      DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(target.hitTestable(), findsOneWidget,
      reason: 'The control must be visible and receive the pointer event');
  await tester.tap(target);
  await tester.pumpAndSettle();
}
