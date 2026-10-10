import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/nearby/location_service.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';

class EmptyCatalog extends CityCatalogService {
  EmptyCatalog() : super(LocationService());
  @override
  Future<List<Place>> load(String city) async => [];
}

class MemoryPreferences implements PreferencesRepository {
  final values = <String, String>{'locationPrompted': 'yes'};
  @override
  String? read(String key) => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final name in ['Manrope', 'GolosText']) {
      final loader = FontLoader(name == 'GolosText' ? 'Golos Text' : name)
        ..addFont(rootBundle.load('assets/fonts/$name.ttf'));
      await loader.load();
    }
  });
  test(
    'Theme, manual city and favorites survive controller recreation',
    () async {
      final prefs = MemoryPreferences();
      final first = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
      );
      final controller = first.read(prototypeProvider.notifier);
      await controller.setTheme(ThemeMode.dark);
      await controller.setCity('Гродно');
      await controller.favorite('park');
      first.dispose();
      final second = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);
      final state = second.read(prototypeProvider);
      expect(state.theme, ThemeMode.dark);
      expect(state.city, 'Гродно');
      expect(state.manualCity, isTrue);
      expect(state.favorites, contains('park'));
    },
  );
  test('Messages stay isolated by conversation and reject empty input', () {
    final repo = DemoChatRepository();
    final baseline = repo.messages('anna').length;
    repo.send('anna', '  До встречи!  ');
    repo.send('anna', ' ');
    expect(repo.messages('anna').length, baseline + 1);
    expect(repo.messages('anna').last.text, 'До встречи!');
    expect(repo.messages('mark').length, baseline);
  });
  testWidgets('Place favorites and manual city selection are interactive', (
    tester,
  ) async {
    final prefs = MemoryPreferences();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
        ],
        child: const PetFriendlyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Список мест'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Зелёный парк'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Зелёный парк'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('В избранное'));
    await tester.pumpAndSettle();
    expect(prefs.values['favorites'], 'park');
    expect(find.byTooltip('Убрать из избранного'), findsOneWidget);
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton).hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('choose-city')));
    await tester.pumpAndSettle();
    final cityContext = tester.element(find.byKey(const Key('city-input')));
    expect(
      Navigator.of(cityContext),
      Navigator.of(cityContext, rootNavigator: true),
    );
    final barrier = find.byType(ModalBarrier).last;
    expect(
      tester.getRect(barrier),
      Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio,
    );
    // The header is behind the barrier; tapping it dismisses the sheet only.
    await tester.tapAt(tester.getCenter(find.byTooltip('Тёмная тема')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('city-input')), findsNothing);
    expect(find.byTooltip('Тёмная тема'), findsOneWidget);
    await tester.tap(find.byKey(const Key('choose-city')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('city-input')), 'hrod');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('city-suggestion-Гродно')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('city-suggestion-Минск')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('city-suggestion-Гродно')));
    await tester.pumpAndSettle();
    expect(prefs.values['city'], 'Гродно');
    await tester.tap(find.byTooltip('Список мест'));
    await tester.pumpAndSettle();
    expect(find.text('Пока нет мест — добавьте первое'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Five tabs, helper profile and chat sending work on a narrow device',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(MemoryPreferences()),
          ],
          child: const PetFriendlyApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Список мест'), findsOneWidget);
      await tester.tap(find.text('Люди'));
      await tester.pumpAndSettle();
      expect(find.text('Анна и Бруно'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Выгул'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Подробнее и отклики'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Подробнее и отклики'), findsOneWidget);
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Новая переписка'), findsOneWidget);
      expect(find.text('petfriendly'), findsNothing);
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Чаты')),
        findsOneWidget,
      );
      await tester.tap(find.text('Анна и Бруно'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('message-input')),
        'Привет, Бруно!',
      );
      await tester.tap(find.byKey(const Key('send-message')));
      await tester.pumpAndSettle();
      expect(find.text('Привет, Бруно!'), findsOneWidget);
      await tester.tap(find.byType(BackButton).hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Я'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Тема приложения'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Тема приложения'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Community joining and invitations preserve consent and show chat authors',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(MemoryPreferences()),
          ],
          child: const PetFriendlyApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Люди'));
      await tester.pumpAndSettle();
      expect(find.text('Соседи с питомцами'), findsNothing);
      await tester.tap(find.text('Сообщества'));
      await tester.pumpAndSettle();
      expect(find.text('Анна и Бруно'), findsNothing);
      await tester.ensureVisible(find.text('Соседи с питомцами'));
      await tester.tap(find.text('Соседи с питомцами'));
      await tester.pumpAndSettle();
      expect(find.text('Открыть чат сообщества'), findsNothing);
      await tester.ensureVisible(find.text('Вступить в сообщество'));
      await tester.tap(find.text('Вступить в сообщество'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Открыть чат сообщества'));
      await tester.tap(find.text('Открыть чат сообщества'));
      await tester.pumpAndSettle();
      expect(find.text('Анна'), findsOneWidget);
      expect(find.text('Вы'), findsOneWidget);
      await tester.tap(find.byType(BackButton).hitTestable());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Пригласить человека'));
      await tester.tap(find.text('Пригласить человека'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Саша'));
      await tester.pumpAndSettle();
      final input = tester.widget<TextField>(
        find.byKey(const Key('message-input')),
      );
      expect(input.controller!.text, contains('petfriendly://group/'));
      // Invitation remains a draft and does not add the recipient to the group.
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(PetFriendlyApp)),
      );
      final data = scope.read(communityProvider).value!;
      expect(rows(data, 'group_members').length, 2);
      expect(
        find.text('Присоединяйтесь к «Соседи с питомцами»!'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
