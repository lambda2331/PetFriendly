import 'dart:async';
import 'package:flutter/material.dart';
import 'package:petfriendly/features/nearby/location_service.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/auth/onboarding_controller.dart';
import 'package:petfriendly/features/auth/profile_suggestion.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import '../test/widget_test.dart' show MemoryPreferences;

class AuditLocation extends LocationService {
  final pending = Completer<String>();
  @override
  Future<String> nearbyCity() => pending.future;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Approved native onboarding and provider cases', (tester) async {
    Future<void> capture(String name, {bool settle = true}) async {
      if (settle) await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await binding.takeScreenshot(name);
      expect(tester.takeException(), isNull);
    }

    late AuditLocation location;
    Future<ProviderContainer> start({
      String? provider,
      String? name,
      bool dark = false,
    }) async {
      location = AuditLocation();
      final repository = DemoCommunityRepository();
      repository.data['profiles']!.firstWhere(
        (p) => p['id'] == repository.userId,
      )['display_name'] = 'Новый пользователь';
      final container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repository),
          accountModeRepositoryProvider.overrideWithValue(
            DemoAccountModeRepository(),
          ),
          preferencesProvider.overrideWithValue(
            MemoryPreferences()
              ..values['language'] = 'ru'
              ..values['theme'] = dark ? 'dark' : 'light',
          ),
          profileSuggestionProvider.overrideWithValue(
            ProfileSuggestion(
              name: name,
              googlePhoto: provider == 'Google'
                  ? Uri.parse('https://lh3.googleusercontent.com/a-/fixture')
                  : null,
              telegramPhoto: provider == 'Telegram'
                  ? Uri.parse('https://t.me/i/userpic/320/fixture.jpg')
                  : null,
            ),
          ),
          onboardingSignInProvider.overrideWithValue(provider),
          locationServiceProvider.overrideWithValue(location),
          providerPhotoDownloaderProvider.overrideWithValue(
            (uri, provider) async => base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAHXRFWHREZXNjcmlwdGlvbgBQUklWQVRFX0VYSUZfVEVTVNhRoysAAAARSURBVHicY/jPwMDwH4yAGAAd8AP909B9JgAAAABJRU5ErkJggg==',
            ),
          ),
          welcomeTelegramPhotoProvider.overrideWith(
            (ref) async => provider == 'Telegram'
                ? base64Decode(
                    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAHXRFWHREZXNjcmlwdGlvbgBQUklWQVRFX0VYSUZfVEVTVNhRoysAAAARSURBVHicY/jPwMDwH4yAGAAd8AP909B9JgAAAABJRU5ErkJggg==',
                  )
                : null,
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
      container.read(routerProvider).go('/onboarding');
      await tester.pumpAndSettle();
      await container.read(onboardingProvider.future);
      return container;
    }

    var container = await start();
    var c = container.read(onboardingProvider.notifier);
    await capture('onboarding-role');
    c.chooseRole('both', mode: 'owner');
    await capture('onboarding-both-owner');
    c.chooseRole('both', mode: 'helper');
    await capture('onboarding-both-helper');
    c.chooseRole('owner');
    await c.advance();
    await capture('onboarding-profile');
    await tester.tap(find.byKey(const ValueKey('onboarding-city')));
    await capture('onboarding-city-modal');
    await tester.tap(find.byKey(const Key('onboarding-detect-city')));
    await capture('onboarding-city-loading', settle: false);
    location.pending.completeError(StateError('permission denied fixture'));
    await capture('onboarding-city-denied');
    await tester.enterText(
      find.byKey(const Key('city-input')),
      'zzzz-no-settlement',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await capture('onboarding-city-empty');
    await tester.tap(find.byKey(const Key('onboarding-manual')));
    await capture('onboarding-manual-city');
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-manual-city')),
      '',
    );
    await tester.tap(find.byKey(const Key('onboarding-manual-save')));
    FocusManager.instance.primaryFocus?.unfocus();
    await capture('onboarding-manual-city-errors');
    await tester.tap(find.byTooltip('Закрыть').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Закрыть').last);
    await tester.pumpAndSettle();

    await c.advance();
    await capture('onboarding-profile-errors');
    c.field('name', 'Анна Ковалевская');
    c.city('Минск');
    await c.advance();
    await capture('onboarding-pet');
    await c.advance(skipPet: true);
    await capture('onboarding-ready');
    container = await start();
    c = container.read(onboardingProvider.notifier);
    c.chooseRole('helper');
    await c.advance();
    c.field('name', 'Ульяна');
    c.city('Минск');
    await c.advance();
    await capture('onboarding-helper-preferences');
    await c.advance();
    await capture('onboarding-helper-errors');
    c.field('experience', 'Гуляю с собаками друзей уже два года.');
    c.toggleSize('small');
    c.field('areas', 'Центральный район');
    await c.advance();
    await capture('onboarding-availability');
    await tester.tap(find.byKey(const ValueKey('onboarding-zone')));
    await capture('onboarding-zone-modal');
    await tester.enterText(
      find.byKey(const Key('onboarding-zone-search')),
      'zzzz-no-zone',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await capture('onboarding-zone-empty');
    await tester.tap(find.byTooltip('Закрыть').last);
    await tester.pumpAndSettle();
    c.availability([const WeeklyAvailability(day: 0, start: 1020, end: 540)]);
    await c.advance();
    await capture('onboarding-schedule-errors');
    final scheduleBeforeCancel = container
        .read(onboardingProvider)
        .requireValue
        .slots;
    await tester.tap(find.byKey(const ValueKey('onboarding-time-0-end')));
    await capture('onboarding-time-picker');
    await tester.enterText(
      find.byKey(const ValueKey('shared-time-hours')),
      '23',
    );
    await tester.tap(find.byTooltip('Закрыть').hitTestable().last);
    await tester.pumpAndSettle();

    expect(
      container.read(onboardingProvider).requireValue.slots,
      scheduleBeforeCancel,
    );
    c.availability([const WeeklyAvailability(day: 0, start: 540, end: 1020)]);
    await c.advance();
    await capture('onboarding-helper-ready');
    for (final provider in ['google', 'apple', 'telegram']) {
      container = await start(
        provider: {
          'google': 'Google',
          'apple': 'Apple',
          'telegram': 'Telegram',
        }[provider],
        name: provider == 'apple' ? null : 'Артём',
      );
      c = container.read(onboardingProvider.notifier);
      await c.advance();
      await capture('onboarding-$provider');
      if (provider == 'google') {
        await c.importPhoto(
          Uri.parse('https://lh3.googleusercontent.com/a-/fixture'),
          ProfilePhotoProvider.google,
        );
        await capture('onboarding-google-imported');
      }
    }
    container = await start(dark: true);
    c = container.read(onboardingProvider.notifier);
    await c.advance();
    await c.advance();
    await capture('onboarding-dark-errors');
  });
}
