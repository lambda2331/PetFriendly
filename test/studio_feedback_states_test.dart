import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/walks/walking_studio_components.dart';
import 'package:petfriendly/l10n/localization.dart';

void main() {
  const captions = {
    'ru': 'Загружаем прогулки…',
    'en': 'Loading walks…',
    'be': 'Загружаем прагулкі…',
    'pl': 'Wczytywanie spacerów…',
  };
  for (final entry in captions.entries) {
    testWidgets(
      'Loading is localized, centered and respects reduced motion: ${entry.key}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(Brightness.dark),
            locale: Locale(entry.key),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: const TextScaler.linear(2),
              ),
              child: child!,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(child: WalkingLoadingState()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.byType(Icon), findsNothing);
        expect(
          tester
              .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator),
              )
              .value,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
