import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/nearby/pet_access.dart';
import 'package:petfriendly/features/nearby/pet_access_widgets.dart';

Map<String, dynamic> record({
  String confirmation = 'community',
  String policy = 'allowed',
}) => {
  'confirmation': confirmation,
  'policy': policy,
  'observed_at': '2026-01-01T12:00:00Z',
  'verified_at': '2026-01-02T12:00:00Z',
  'basis': 'Синтетическое подтверждение правил публичного места',
  'conditions': 'На поводке',
};

void main() {
  test(
    'OSM allow tag remains an unconfirmed catalog hint for every category',
    () {
      for (final category in ['Парк', 'Кафе', 'Площадка']) {
        final place = catalogPlace({
          'id': 'synthetic',
          'name': 'Синтетическое место',
          'category': category,
          'pet_access': 'yes',
          'latitude': 53.9,
          'longitude': 27.56,
          'source_id': 'node/synthetic',
        }, 'Минск');
        expect(place.accessEvidence, isNull);
        expect(petAccessLabel(place.accessEvidence), 'Допуск не подтверждён');
        expect(catalogPetPolicy(place.petAccess), PetAccessPolicy.allowed);
      }
    },
  );
  test(
    'Unattributed legacy allow claims are not treated as evidence or OSM data',
    () {
      expect(catalogPetPolicy('Можно с питомцем'), PetAccessPolicy.unknown);
      expect(catalogPetPolicy('Собаки разрешены'), PetAccessPolicy.unknown);
      expect(PetAccessEvidence.fromJson({'pet_access': 'yes'}), isNull);
    },
  );
  test('Evidence requires actual source, policy, chronology and basis', () {
    expect(PetAccessEvidence.fromJson(record()), isNotNull);
    expect(PetAccessEvidence.fromJson({...record(), 'basis': ''}), isNull);
    expect(
      PetAccessEvidence.fromJson({...record(), 'observed_at': null}),
      isNull,
    );
    expect(
      PetAccessEvidence.fromJson({...record(), 'confirmation': 'osm'}),
      isNull,
    );
    expect(
      PetAccessEvidence.fromJson({
        ...record(),
        'observed_at': '2026-02-01T00:00:00Z',
      }),
      isNull,
    );
  });
  test('Venue confirmation requires a public HTTPS reference', () {
    expect(PetAccessEvidence.fromJson(record(confirmation: 'venue')), isNull);
    expect(
      PetAccessEvidence.fromJson({
        ...record(confirmation: 'venue'),
        'reference_url': 'https://example.test/venue-rules',
      }),
      isNotNull,
    );
    expect(
      PetAccessEvidence.fromJson({
        ...record(confirmation: 'venue'),
        'reference_url': 'http://example.test/venue-rules',
      }),
      isNull,
    );
  });
  testWidgets('Unknown rules show no made-up confirmation date or conditions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(Brightness.light),
        home: const Scaffold(
          body: PetAccessRules(catalogHint: 'Собаки разрешены · отметка OSM'),
        ),
      ),
    );
    expect(find.text('Допуск не подтверждён'), findsOneWidget);
    expect(find.textContaining('Это не подтверждение'), findsOneWidget);
    expect(find.textContaining('Подтверждение от'), findsNothing);
    expect(find.textContaining('Условия:'), findsNothing);
  });
  testWidgets(
    'Confirmed prohibition is explicit and reflows with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final evidence = PetAccessEvidence.fromJson({
        ...record(confirmation: 'venue', policy: 'forbidden'),
        'conditions': 'Кроме собак-проводников по опубликованным правилам',
        'reference_url': 'https://example.test/venue-rules',
      })!;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(Brightness.dark),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: ListView(
                children: [
                  PetAccessRules(
                    catalogHint: 'Допуск питомцев не уточнён',
                    evidence: evidence,
                  ),
                  PetAccessStatus(evidence: evidence),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Подтверждено заведением'), findsOneWidget);
      expect(find.text('С собаками нельзя'), findsOneWidget);
      expect(
        find.textContaining('Подтверждение от 1 января 2026'),
        findsOneWidget,
      );
      expect(find.textContaining('Условия:'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('С собаками нельзя · Подтверждено заведением'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.textContaining('С собаками нельзя · Подтверждено заведением'),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    },
  );
}
