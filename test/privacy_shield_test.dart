import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/ui/privacy_shield.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('Privacy masking handles native focus on $platform', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          home: PrivacyShield(child: Scaffold(body: Text('Content'))),
        ),
      );
      final observer =
          tester.state(find.byType(PrivacyShield)) as WidgetsBindingObserver;
      observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await tester.pump();
      expect(
        find.byIcon(Icons.pets_outlined),
        platform == TargetPlatform.android ? findsNothing : findsOneWidget,
      );
      observer.didChangeAppLifecycleState(AppLifecycleState.hidden);
      await tester.pump();
      expect(find.byIcon(Icons.pets_outlined), findsOneWidget);
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byIcon(Icons.pets_outlined), findsNothing);
    });
  }
}
