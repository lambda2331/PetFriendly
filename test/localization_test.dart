import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/time/display_time.dart';
import 'package:petfriendly/core/ui/components.dart';
import 'package:petfriendly/features/auth/login_screen.dart';
import 'package:petfriendly/features/profiles/profile_screen.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'widget_test.dart' show MemoryPreferences;

void main() {
  test(
    'Locale resolution supports regional device locales and a Russian fallback',
    () {
      final supported = AppLocalizations.supportedLocales;
      expect(
        resolveAppLocale([const Locale('pl', 'PL')], supported),
        const Locale('pl'),
      );
      expect(
        resolveAppLocale([const Locale('de'), const Locale('be')], supported),
        const Locale('be'),
      );
      expect(
        resolveAppLocale([const Locale('ja')], supported),
        const Locale('ru'),
      );
    },
  );
  test(
    'Language persists independently of account data and manual city',
    () async {
      final prefs = MemoryPreferences()
        ..values.addAll({'city': 'Warsaw, Mazovia, PL', 'manualCity': 'true'});
      final a = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
      );
      expect(a.read(languageProvider), isNull);
      await a.read(languageProvider.notifier).select('be');
      a.dispose();
      final b = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
      );
      expect(b.read(languageProvider), const Locale('be'));
      await b.read(prototypeProvider.notifier).clearAccount();
      expect(b.read(languageProvider), const Locale('be'));
      expect(b.read(prototypeProvider).city, 'Warsaw, Mazovia, PL');
      await b.read(languageProvider.notifier).select(null);
      expect(b.read(languageProvider), isNull);
      expect(
        () => b.read(languageProvider.notifier).select('invalid'),
        throwsArgumentError,
      );
      b.dispose();
    },
  );
  test(
    'ARB catalogs have complete matching keys and preserve template parameters',
    () {
      final ru =
          jsonDecode(File('lib/l10n/arb/app_ru.arb').readAsStringSync()) as Map;
      final keys = ru.keys
          .where((key) => !(key as String).startsWith('@'))
          .toSet();
      expect(keys.length, greaterThan(900));
      for (final lang in ['en', 'be', 'pl']) {
        final other =
            jsonDecode(File('lib/l10n/arb/app_$lang.arb').readAsStringSync())
                as Map;
        expect(
          other.keys.where((key) => !(key as String).startsWith('@')).toSet(),
          keys,
        );
        for (final key in keys) {
          expect(other[key], isNotEmpty, reason: '$lang $key');
          final tokens = RegExp(r'\{(p\d+)\}');
          expect(
            tokens.allMatches(other[key]).map((m) => m[1]).toSet(),
            tokens.allMatches(ru[key]).map((m) => m[1]).toSet(),
          );
        }
      }
    },
  );
  test('Locale-specific plurals, dates and unknown zones', () {
    expect(memberCount(21, locale: 'en'), '21 members');
    expect(memberCount(21, locale: 'pl'), '21 uczestników');
    expect(memberCount(2, locale: 'be'), '2 удзельнікі');
    expect(ageYears(5, locale: 'pl'), '5 lat');
    expect(stringsFor('pl').reviewCount(2), '2 opinie');
    expect(stringsFor('ru').walkingDurationMinutes(1), '1 минута');
    expect(stringsFor('ru').walkingDurationMinutes(2), '2 минуты');
    expect(stringsFor('ru').walkingDurationMinutes(45), '45 минут');
    expect(stringsFor('en').walkingDurationMinutes(1), '1 minute');
    expect(stringsFor('en').walkingDurationMinutes(45), '45 minutes');
    expect(stringsFor('be').walkingDurationMinutes(1), '1 хвіліна');
    expect(stringsFor('be').walkingDurationMinutes(2), '2 хвіліны');
    expect(stringsFor('be').walkingDurationMinutes(45), '45 хвілін');
    expect(stringsFor('pl').walkingDurationMinutes(1), '1 minuta');
    expect(stringsFor('pl').walkingDurationMinutes(2), '2 minuty');
    expect(stringsFor('pl').walkingDurationMinutes(45), '45 minut');
    expect(stringsFor('be').completedWalkNoun(21), 'завершаны выгул');
    expect(
      readableDate('2026-01-10T12:00:00Z', locale: 'en'),
      contains('January'),
    );
    expect(
      readableDate('2026-01-10T12:00:00Z', locale: 'be'),
      contains('студзеня'),
    );
    expect(
      venueTime('2026-01-10T12:00:00Z', locale: 'pl'),
      contains('nie podano strefy'),
    );
  });
  for (final lang in appLanguages.keys) {
    testWidgets(
      'Settings and sign-in render in $lang; language can be changed before sign-in',
      (tester) async {
        final prefs = MemoryPreferences()..values['language'] = lang;
        final container = ProviderContainer(
          overrides: [preferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const PetFriendlyApp(),
          ),
        );
        await tester.pumpAndSettle();
        container.read(routerProvider).go('/settings');
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsOneWidget);
        final labels = {
          'ru': 'Язык',
          'en': 'Language',
          'be': 'Мова',
          'pl': 'Język',
        };
        expect(find.text(labels[lang]!), findsOneWidget);
        await tester.tap(find.byKey(const Key('settings-language')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('language-en')));
        await tester.pumpAndSettle();
        expect(prefs.values['language'], 'en');
        expect(find.text('Settings'), findsOneWidget);
        expect(container.read(prototypeProvider).city, 'Минск');
        container.read(routerProvider).go('/login');
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Sign in to PetFriendly'), findsOneWidget);
        expect(find.byTooltip('App language'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'User content is preserved and placeholder values are not translated',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Column(
              children: [
                Text('Настройки'),
                Text(
                  'Отзыв о {p0}'.tr(context, arguments: {'p0': 'Настройки'}),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Review of Настройки'), findsOneWidget);
    },
  );
}
