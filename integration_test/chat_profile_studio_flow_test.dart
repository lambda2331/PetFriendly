import 'dart:async';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/chat/chat_screen.dart';
import 'package:petfriendly/features/chat/inbox_repository.dart';
import 'package:petfriendly/features/profiles/profile_screen.dart';
import 'package:petfriendly/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/chat/new_chat_screen.dart';
import '../test/widget_test.dart' show MemoryPreferences;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Approved chat/profile Studio native flow', (tester) async {
    final repository = DemoCommunityRepository();
    final uid = repository.userId;
    final profile = repository.data['profiles']!.firstWhere(
      (p) => p['id'] == uid,
    );
    profile['display_name'] = 'Анна Ковалевская';
    profile['district'] = 'Центральный район';
    profile['about'] =
        'Люблю долгие прогулки, тихие парки и компанию с хвостом.';
    repository.data['pets'] = [
      {
        'id': 'studio-cat',
        'owner_id': uid,
        'name': 'Персик',
        'kind': 'Кот',
        'age': 3,
        'temperament': 'Спокойный кот, гуляет на шлейке.',
      },
    ];
    final group = repository.data['groups']!.first;
    await repository.command('join_group', {'group_in': group['id']});
    final container = ProviderContainer(
      overrides: [
        communityRepositoryProvider.overrideWithValue(repository),
        preferencesProvider.overrideWithValue(
          (MemoryPreferences()..values['language'] = 'ru'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PetFriendlyApp(),
      ),
    );
    await tester.pumpAndSettle();
    final router = container.read(routerProvider);
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await binding.takeScreenshot(name);
      expect(tester.takeException(), isNull);
    }

    router.go('/chats');
    await capture('studio-native-chats');
    showNewChatSheet(tester.element(find.text('Чаты').first));
    await capture('studio-native-new-chat');
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
    router.go('/profile');
    await capture('studio-native-profile');
    await tester.tap(find.byTooltip('Последние события'));
    await capture('studio-native-recent-events');
    expect(find.byType(Switch), findsNothing);
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Персик'));
    await capture('studio-native-pet-details');
    Navigator.of(
      tester.element(find.text('Спокойный кот, гуляет на шлейке.')),
    ).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Редактировать профиль'));
    await capture('studio-native-edit-profile');
    Navigator.of(
      tester.element(find.byKey(const ValueKey('field.display_name'))),
    ).pop();
    await tester.pumpAndSettle();
    router.push('/settings');
    await capture('studio-native-settings');
    await tester.tap(find.text('Уведомления'));
    await capture('studio-native-notifications');
    Navigator.of(
      tester.element(find.text('Текст сообщений скрыт в уведомлениях.').last),
    ).pop();
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    router.go('/walks');
    await capture('studio-native-walks');
    router.go('/chats');
    await tester.pumpAndSettle();
    final groupConversation = repository.data['conversations']!.firstWhere(
      (c) => c['kind'] == 'group',
    );
    router.push('/chat/${groupConversation['id']}');
    await capture('studio-native-community-chat');
    await tester.tap(find.byTooltip('О переписке'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'О переписке'));
    await capture('studio-native-community-info');
    await tester.tap(find.byTooltip('Закрыть').hitTestable().last);
    await tester.pumpAndSettle();
    await container.read(prototypeProvider.notifier).setTheme(ThemeMode.dark);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    router.go('/chats');
    await capture('studio-native-full-shell-dark-large-chats');
    await tester.ensureVisible(find.text('Прогулки').first);
    await tester.tap(find.text('Прогулки').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    router.go('/profile');
    await capture('studio-native-full-shell-dark-large-profile');
  });
  testWidgets('Dark 200% native loading and empty states', (tester) async {
    final pending = Completer<CommunityData>();
    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(
          MemoryPreferences()..values['language'] = 'ru',
        ),
        communityProvider.overrideWith(() => _PendingCommunity(pending.future)),
        chatInboxProvider.overrideWith((ref) => Stream.value(<InboxEntry>[])),
      ],
    );
    addTearDown(container.dispose);
    Widget page(Widget body) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: studioTheme(Brightness.dark),
        builder: (ctx, child) => MediaQuery(
          data: MediaQuery.of(
            ctx,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(body: body),
      ),
    );
    await tester.pumpWidget(page(const ChatsScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Пока нет переписок'), findsNothing);
    expect(find.text('Загружаем переписки…'), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await binding.takeScreenshot('studio-native-loading-dark-large');
    pending.complete({});
    await tester.pumpAndSettle();
    expect(find.text('Пока нет переписок'), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await binding.takeScreenshot('studio-native-empty-chats-dark-large');
    await tester.pumpWidget(page(const ProfileScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Добавьте своего питомца'), 200);
    expect(find.text('Добавьте своего питомца'), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await binding.takeScreenshot('studio-native-empty-profile-dark-large');
    expect(tester.takeException(), isNull);
  });
}

class _PendingCommunity extends CommunityController {
  _PendingCommunity(this.pending);
  final Future<CommunityData> pending;
  @override
  Future<CommunityData> build() => pending;
}
