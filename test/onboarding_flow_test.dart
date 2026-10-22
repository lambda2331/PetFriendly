import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/auth/onboarding_controller.dart';
import 'package:petfriendly/features/auth/onboarding_screen.dart';
import 'package:petfriendly/features/auth/profile_suggestion.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/location_service.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'widget_test.dart' show MemoryPreferences;

class PendingLocation extends LocationService {
  final result = Completer<String>();
  @override
  Future<String> nearbyCity() => result.future;
}

class FailedProfile extends DemoCommunityRepository {
  bool fail = true;
  @override
  Future<String?> command(String action, Json values) async {
    if (action == 'profile' && fail) throw StateError('offline');
    return super.command(action, values);
  }
}

class SwitchingAccount extends DemoCommunityRepository {
  String activeId = demoAlex;
  @override
  String get userId => activeId;
}

DemoCommunityRepository fresh([DemoCommunityRepository? value]) {
  final repo = value ?? DemoCommunityRepository();
  repo.data['profiles']!.firstWhere(
    (p) => p['id'] == repo.userId,
  )['display_name'] = 'Новый пользователь';
  return repo;
}

ProviderContainer containerFor({
  DemoCommunityRepository? repository,
  DemoAccountModeRepository? account,
  ProfileSuggestion suggestion = const ProfileSuggestion(),
  PendingLocation? location,
}) => ProviderContainer(
  overrides: [
    communityRepositoryProvider.overrideWithValue(repository ?? fresh()),
    accountModeRepositoryProvider.overrideWithValue(
      account ?? DemoAccountModeRepository(),
    ),
    preferencesProvider.overrideWithValue(MemoryPreferences()),
    profileSuggestionProvider.overrideWithValue(suggestion),
    if (location != null) locationServiceProvider.overrideWithValue(location),
  ],
);
Future<void> profile(ProviderContainer container) async {
  final c = container.read(onboardingProvider.notifier);
  await c.advance();
  c.field('name', 'Анна');
  c.city('Минск');
  expect(await c.advance(), true);
}

void main() {
  test(
    'Owner follows role/profile/optional pet; inline errors preserve draft',
    () async {
      final container = containerFor();
      addTearDown(container.dispose);
      await container.read(onboardingProvider.future);
      final c = container.read(onboardingProvider.notifier);
      await c.advance();
      expect(await c.advance(), false);
      expect(
        container.read(onboardingProvider).requireValue.errors.keys,
        containsAll(['name', 'city']),
      );
      c.field('name', '   ');
      expect(
        container.read(onboardingProvider).requireValue.errors['name'],
        isNotNull,
      );
      c.field('name', 'Анна');
      c.city('Минск');
      expect(await c.advance(), true);
      expect(
        container.read(onboardingProvider).requireValue.step,
        OnboardingStep.pet,
      );
      expect(await c.advance(skipPet: true), true);
      expect(
        container.read(onboardingProvider).requireValue.step,
        OnboardingStep.ready,
      );
    },
  );
  test(
    'Helper has no pet step and persists separate structured preferences',
    () async {
      final account = DemoAccountModeRepository();
      final container = containerFor(account: account);
      addTearDown(container.dispose);
      await container.read(onboardingProvider.future);
      final c = container.read(onboardingProvider.notifier);
      c.chooseRole('both', mode: 'helper');
      await profile(container);
      expect(
        container.read(onboardingProvider).requireValue.step,
        OnboardingStep.preferences,
      );
      expect(await c.advance(), false);
      expect(
        container.read(onboardingProvider).requireValue.errors.keys,
        containsAll(['experience', 'sizes', 'areas']),
      );
      c.field('experience', 'Гуляю с собаками семьи');
      c.field('areas', 'Центральный');
      c.toggleSize('small');
      await c.advance();
      c.zone('');
      expect(await c.advance(), false);
      expect(
        container.read(onboardingProvider).requireValue.errors['zone'],
        isNotNull,
      );
      c.zone('Europe/Minsk');
      expect(
        container.read(onboardingProvider).requireValue.errors['zone'],
        isNull,
      );
      c.availability([const WeeklyAvailability(day: 0, start: 1020, end: 540)]);
      expect(await c.advance(), false);
      c.availability([const WeeklyAvailability(day: 0, start: 540, end: 1020)]);
      expect(await c.advance(), true);
      expect(account.profile!.availability.single.start, 540);
      expect(account.current.role, 'both');
      expect(account.current.mode, 'helper');
      expect(
        container.read(onboardingProvider).requireValue.step,
        OnboardingStep.ready,
      );
    },
  );
  test('Save failure keeps data and permits retry', () async {
    final repo = fresh(FailedProfile()) as FailedProfile;
    final container = containerFor(repository: repo);
    addTearDown(container.dispose);
    await container.read(onboardingProvider.future);
    final c = container.read(onboardingProvider.notifier);
    await c.advance();
    c.field('name', 'Анна');
    c.city('Минск');
    expect(await c.advance(), false);
    expect(
      container.read(onboardingProvider).requireValue.text('name'),
      'Анна',
    );
    expect(container.read(onboardingProvider).requireValue.failure, isNotNull);
    repo.fail = false;
    expect(await c.advance(), true);
  });
  test(
    'Pet photo failure retries existing pet instead of creating duplicate',
    () async {
      final repo = fresh();
      final original = repo.data['pets']!.length;
      final container = containerFor(repository: repo);
      addTearDown(container.dispose);
      await container.read(onboardingProvider.future);
      final c = container.read(onboardingProvider.notifier);
      await profile(container);
      c.field('petName', 'Персик');
      c.photo(Uint8List.fromList([1]), pet: true);
      expect(
        await c.advance(
          writePhoto: (id, bytes) async => throw StateError('offline'),
        ),
        false,
      );
      expect(repo.data['pets']!.length, original + 1);
      expect(container.read(onboardingProvider).requireValue.petId, isNotNull);
      c.field('petName', 'Персик II');
      expect(await c.advance(writePhoto: (id, bytes) async => true), true);
      expect(repo.data['pets']!.length, original + 1);
      expect(repo.data['pets']!.last['name'], 'Персик II');
    },
  );
  test(
    'Skipping optional pet ignores an invalid unfinished pet draft',
    () async {
      final container = containerFor();
      addTearDown(container.dispose);
      await container.read(onboardingProvider.future);
      await profile(container);
      final c = container.read(onboardingProvider.notifier);
      c.field('habits', 'x' * 1001);
      expect(await c.advance(skipPet: true), true);
      expect(
        container.read(onboardingProvider).requireValue.step,
        OnboardingStep.ready,
      );
    },
  );
  test('A late photo save cannot advance a different account', () async {
    final repo = SwitchingAccount();
    fresh(repo);
    final container = containerFor(repository: repo);
    addTearDown(container.dispose);
    await container.read(onboardingProvider.future);
    final c = container.read(onboardingProvider.notifier);
    await c.advance();
    c.field('name', 'Отредактированное имя');
    c.city('Минск');
    c.photo(Uint8List.fromList([1]));
    final photoSave = Completer<bool>();
    final started = Completer<void>();
    final save = c.advance(
      writePhoto: (id, bytes) {
        started.complete();
        return photoSave.future;
      },
    );
    await started.future;
    repo.activeId = demoAnna;
    container.invalidate(communityProvider);
    container.invalidate(onboardingProvider);
    await container.read(onboardingProvider.future);
    photoSave.complete(true);
    expect(await save, false);
    expect(container.read(onboardingProvider).requireValue.accountId, demoAnna);
    expect(
      container.read(onboardingProvider).requireValue.text('name'),
      isNot('Отредактированное имя'),
    );
  });
  test(
    'Apple and Telegram claims never require a real email for profile suggestions',
    () {
      for (final provider in ['apple', 'custom:telegram']) {
        final user = User.fromJson({
          'id': demoAlex,
          'aud': 'authenticated',
          'created_at': '2026-01-01T00:00:00Z',
          'app_metadata': {'provider': provider},
          'user_metadata': {'full_name': 'Анна'},
        });
        expect(ProfileSuggestion.fromUser(user).name, 'Анна');
        expect(ProfileSuggestion.fromUser(user).googlePhoto, isNull);
      }
      final apple = User.fromJson({
        'id': demoAlex,
        'aud': 'authenticated',
        'created_at': '2026-01-01T00:00:00Z',
        'email': 'private@privaterelay.appleid.com',
        'app_metadata': {'provider': 'apple'},
        'user_metadata': <String, dynamic>{},
      });
      expect(ProfileSuggestion.fromUser(apple).name, isNull);
    },
  );
  test('Manual city wins over late location result', () async {
    final location = PendingLocation();
    final container = containerFor(location: location);
    addTearDown(container.dispose);
    await container.read(onboardingProvider.future);
    final c = container.read(onboardingProvider.notifier);
    final locating = c.locateCity();
    c.city('Варшава');
    location.result.complete('Минск');
    expect(await locating, false);
    expect(
      container.read(onboardingProvider).requireValue.text('city'),
      'Варшава',
    );
    expect(container.read(onboardingProvider).requireValue.manualCity, true);
  });
  test(
    'Provider suggestions do not overwrite manual fields; Apple missing name stays empty',
    () async {
      final container = containerFor(
        suggestion: const ProfileSuggestion(name: 'Google Name'),
      );
      addTearDown(container.dispose);
      expect(
        (await container.read(onboardingProvider.future)).text('name'),
        'Google Name',
      );
      container.read(onboardingProvider.notifier).field('name', 'Моё имя');
      expect(
        container.read(onboardingProvider).requireValue.text('name'),
        'Моё имя',
      );
      final apple = containerFor();
      addTearDown(apple.dispose);
      expect((await apple.read(onboardingProvider.future)).text('name'), '');
    },
  );
  test(
    'Completed profile is recognized without replacing saved name',
    () async {
      final repo = DemoCommunityRepository(),
          account = DemoAccountModeRepository();
      await account.chooseRole('owner');
      final container = containerFor(
        repository: repo,
        account: account,
        suggestion: const ProfileSuggestion(name: 'Provider Name'),
      );
      addTearDown(container.dispose);
      final draft = await container.read(onboardingProvider.future);
      expect(draft.alreadyComplete, true);
      expect(draft.text('name'), 'Алекс');
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'Studio onboarding inline fields and layout at 200% dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final container = containerFor();
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: studioTheme(dark ? Brightness.dark : Brightness.light),
              home: const OnboardingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        container
            .read(onboardingProvider.notifier)
            .chooseRole('both', mode: 'helper');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('onboarding-start-owner')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const ValueKey('onboarding-start-owner')));
        await tester.pumpAndSettle();
        expect(container.read(onboardingProvider).requireValue.mode, 'owner');
        expect(tester.takeException(), isNull);
        container.read(onboardingProvider.notifier).chooseRole('owner');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Продолжить'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Продолжить'));
        await tester.pumpAndSettle();
        expect(find.text('Введите имя, чтобы продолжить.'), findsOneWidget);
        expect(find.text('Район'), findsOneWidget);
        expect(find.text('Район · необязательно'), findsNothing);
        final field = tester.widget<TextField>(
          find.byKey(const ValueKey('onboarding-name')),
        );
        expect(
          (field.decoration!.focusedBorder as OutlineInputBorder)
              .borderSide
              .width,
          2,
        );
        expect(field.focusNode!.hasFocus, true);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
