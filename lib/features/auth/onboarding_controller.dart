import '../../core/time/display_time.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backend/backend.dart';
import '../../core/media/preview_photos.dart';
import '../../core/storage/prototype_store.dart';
import '../community/data/community_repository.dart';
import '../nearby/location_service.dart';
import '../walks/account_mode.dart';
import 'profile_suggestion.dart';
import 'onboarding_replay.dart';

enum OnboardingStep { role, profile, pet, preferences, availability, ready }

typedef OnboardingPhotoWriter =
    Future<bool> Function(String id, Uint8List bytes);

class OnboardingDraft {
  const OnboardingDraft({
    required this.accountId,
    this.step = OnboardingStep.role,
    this.role = 'owner',
    this.mode = 'owner',
    this.values = const {},
    this.errors = const {},
    this.sizes = const [],
    this.slots = const [],
    this.zone = 'Europe/Minsk',
    this.photo,
    this.petPhoto,
    this.petId,
    this.busy = false,
    this.photoBusy = false,
    this.locating = false,
    this.failure,
    this.alreadyComplete = false,
    this.manualCity = false,
  });
  final String accountId, role, mode, zone;
  final OnboardingStep step;
  final Map<String, String> values, errors;
  final List<String> sizes;
  final List<WeeklyAvailability> slots;
  final Uint8List? photo, petPhoto;
  final String? petId, failure;
  final bool busy, photoBusy, locating, alreadyComplete, manualCity;
  String text(String key) => values[key] ?? '';
  bool get helper => mode == 'helper';
  OnboardingDraft copy({
    OnboardingStep? step,
    String? role,
    String? mode,
    Map<String, String>? values,
    Map<String, String>? errors,
    List<String>? sizes,
    List<WeeklyAvailability>? slots,
    String? zone,
    Uint8List? photo,
    Uint8List? petPhoto,
    String? petId,
    bool? busy,
    bool? photoBusy,
    bool? locating,
    String? failure,
    bool? manualCity,
  }) => OnboardingDraft(
    accountId: accountId,
    step: step ?? this.step,
    role: role ?? this.role,
    mode: mode ?? this.mode,
    values: values ?? this.values,
    errors: errors ?? this.errors,
    sizes: sizes ?? this.sizes,
    slots: slots ?? this.slots,
    zone: zone ?? this.zone,
    photo: photo ?? this.photo,
    petPhoto: petPhoto ?? this.petPhoto,
    petId: petId ?? this.petId,
    busy: busy ?? this.busy,
    photoBusy: photoBusy ?? this.photoBusy,
    locating: locating ?? this.locating,
    failure: failure,
    alreadyComplete: alreadyComplete,
    manualCity: manualCity ?? this.manualCity,
  );
}

final onboardingProvider =
    AsyncNotifierProvider<OnboardingController, OnboardingDraft>(
      OnboardingController.new,
    );
final onboardingSignInProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).value;
  final provider = user?.appMetadata['provider'];
  return switch (provider) {
    'google' => 'Google',
    'apple' => 'Apple',
    'custom:telegram' => 'Telegram',
    _ => null,
  };
});

/// Account-scoped, memory-only setup; repositories retain server authorization.
class OnboardingController extends AsyncNotifier<OnboardingDraft> {
  int _cityGeneration = 0, _photoGeneration = 0;
  @override
  Future<OnboardingDraft> build() async {
    ref.watch(authStateProvider.select((s) => s.value?.id));
    final repository = ref.watch(communityRepositoryProvider);
    ref.watch(accountModeRepositoryProvider);
    final uid = repository.userId;
    if (uid == null) throw StateError('Account unavailable');
    final mode = await ref.read(accountModeProvider.future);
    final data = await ref.read(communityProvider.future);
    final profile = findRow(data, 'profiles', uid) ?? {};
    final existingName = '${profile['display_name'] ?? ''}'.trim();
    final hasName =
        existingName.isNotEmpty && existingName != 'Новый пользователь';
    final helper = mode.isHelper
        ? await ref.read(helperProfileProvider.future)
        : null;
    final prototype = ref.read(prototypeProvider);
    final replay = ref.watch(onboardingReplayProvider);
    final complete =
        !replay &&
        !mode.needsRoleSelection &&
        hasName &&
        (!mode.isHelper || helper != null);
    final initial = OnboardingDraft(
      accountId: uid,
      step: replay || mode.needsRoleSelection
          ? OnboardingStep.role
          : !hasName
          ? OnboardingStep.profile
          : mode.isHelper && helper == null
          ? OnboardingStep.preferences
          : OnboardingStep.ready,
      role: mode.needsRoleSelection ? 'owner' : mode.role,
      mode: mode.needsRoleSelection ? 'owner' : mode.mode,
      values: {
        'name': hasName
            ? existingName
            : ref.read(profileSuggestionProvider).name ?? '',
        'district': '${profile['district'] ?? ''}',
        'city': helper?.city ?? (prototype.manualCity ? prototype.city : ''),
        'experience': helper?.experience ?? '',
        'areas': helper?.serviceDistricts.join(', ') ?? '',
        'kind': 'Кот',
        'about': '${profile['about'] ?? ''}',
      },
      sizes: helper?.dogSizes ?? [],
      slots: helper?.availability ?? [],
      zone: helper?.timeZone ?? 'Europe/Minsk',
      photo: ref.read(previewPhotosProvider)['profile:$uid'],
      alreadyComplete: complete,
      manualCity: prototype.manualCity,
    );
    if (!complete && initial.photo == null) {
      final repositoryAtStart = repository;
      // Existing saved photos are checked by this provider before any Telegram preview.
      unawaited(
        Future<void>(() async {
          try {
            final bytes = await ref.read(welcomeTelegramPhotoProvider.future);
            if (ref.mounted &&
                ref.read(communityRepositoryProvider) == repositoryAtStart &&
                state.value?.accountId == uid &&
                state.value?.photo == null &&
                bytes != null) {
              state = AsyncData(
                state.requireValue.copy(
                  photo: bytes,
                  photoBusy: false,
                  errors: {...state.requireValue.errors}..remove('photo'),
                ),
              );
            }
          } catch (_) {
            /* Optional provider photo never blocks setup. */
          }
        }),
      );
    }
    return initial;
  }

  bool _current(OnboardingDraft draft, CommunityRepository repository) =>
      ref.mounted &&
      ref.read(communityRepositoryProvider) == repository &&
      repository.userId == draft.accountId &&
      state.value?.accountId == draft.accountId;
  void field(String key, String value) {
    final d = state.requireValue;
    if (d.busy) return;
    final valid = switch (key) {
      'name' => value.trim().isNotEmpty && value.trim().length <= 80,
      'petName' => value.trim().isNotEmpty,
      'experience' => value.trim().isNotEmpty && value.length <= 1000,
      'areas' =>
        value.split(',').where((part) => part.trim().isNotEmpty).isNotEmpty &&
            value.split(',').where((part) => part.trim().isNotEmpty).length <=
                10 &&
            value.split(',').every((part) => part.trim().length <= 100),
      'district' => value.length <= 100,
      'habits' => value.length <= 1000,
      _ => true,
    };
    state = AsyncData(
      d.copy(
        values: {...d.values, key: value},
        errors: valid ? ({...d.errors}..remove(key)) : d.errors,
      ),
    );
  }

  void chooseRole(String role, {String? mode}) {
    final d = state.requireValue;
    if (d.busy) return;
    state = AsyncData(
      d.copy(role: role, mode: role == 'both' ? mode ?? d.mode : role),
    );
  }

  void city(String city, {bool manual = true}) {
    _cityGeneration++;
    final d = state.requireValue;
    state = AsyncData(
      d.copy(
        values: {...d.values, 'city': city},
        manualCity: manual,
        zone: cityTimeZone(city) ?? '',
        errors: {...d.errors}..remove('city'),
        locating: false,
      ),
    );
  }

  Future<bool> locateCity() async {
    final d = state.requireValue,
        repository = ref.read(communityRepositoryProvider);
    final generation = ++_cityGeneration;
    state = AsyncData(
      d.copy(locating: true, errors: {...d.errors}..remove('city')),
    );
    try {
      final found = await ref.read(locationServiceProvider).nearbyCity();
      if (!_current(d, repository) || generation != _cityGeneration) {
        return false;
      }
      city(found, manual: false);
      return true;
    } catch (_) {
      if (_current(d, repository) && generation == _cityGeneration) {
        state = AsyncData(
          state.requireValue.copy(
            locating: false,
            errors: {
              ...state.requireValue.errors,
              'city': 'Местоположение недоступно. Выберите город вручную.',
            },
          ),
        );
      }
      return false;
    }
  }

  void photo(Uint8List bytes, {bool pet = false}) {
    _photoGeneration++;
    state = AsyncData(
      pet
          ? state.requireValue.copy(
              petPhoto: bytes,
              errors: {...state.requireValue.errors}..remove('photo'),
            )
          : state.requireValue.copy(
              photo: bytes,
              photoBusy: false,
              errors: {...state.requireValue.errors}..remove('photo'),
            ),
    );
  }

  Future<void> importPhoto(Uri uri, ProfilePhotoProvider provider) async {
    final d = state.requireValue,
        repository = ref.read(communityRepositoryProvider);
    final generation = ++_photoGeneration;
    state = AsyncData(d.copy(photoBusy: true));
    try {
      final bytes = await ref.read(providerPhotoDownloaderProvider)(
        uri,
        provider,
      );
      if (_current(d, repository) && generation == _photoGeneration) {
        state = AsyncData(
          state.requireValue.copy(
            photo: bytes,
            photoBusy: false,
            errors: {...state.requireValue.errors}..remove('photo'),
          ),
        );
      }
    } catch (_) {
      if (_current(d, repository) && generation == _photoGeneration) {
        state = AsyncData(
          state.requireValue.copy(
            photoBusy: false,
            errors: {
              ...state.requireValue.errors,
              'photo':
                  'Не удалось загрузить фото. Можно выбрать своё или добавить позже.',
            },
          ),
        );
      }
    }
  }

  void toggleSize(String size) {
    final d = state.requireValue;
    state = AsyncData(
      d.copy(
        sizes: d.sizes.contains(size)
            ? d.sizes.where((s) => s != size).toList()
            : [...d.sizes, size],
        errors: {...d.errors}..remove('sizes'),
      ),
    );
  }

  void availability(List<WeeklyAvailability> slots) => state = AsyncData(
    state.requireValue.copy(
      slots: slots,
      errors: {...state.requireValue.errors}..remove('availability'),
    ),
  );
  void zone(String zone) => state = AsyncData(
    state.requireValue.copy(
      zone: zone,
      errors: {...state.requireValue.errors}..remove('zone'),
    ),
  );
  void back() {
    final d = state.requireValue;
    if (d.busy) return;
    final previous = switch (d.step) {
      OnboardingStep.profile => OnboardingStep.role,
      OnboardingStep.pet ||
      OnboardingStep.preferences => OnboardingStep.profile,
      OnboardingStep.availability => OnboardingStep.preferences,
      OnboardingStep.ready =>
        d.helper ? OnboardingStep.availability : OnboardingStep.pet,
      _ => d.step,
    };
    state = AsyncData(d.copy(step: previous, errors: {}));
  }

  Future<bool> advance({
    bool skipPet = false,
    OnboardingPhotoWriter? writePhoto,
  }) async {
    final d = state.requireValue,
        repository = ref.read(communityRepositoryProvider);
    if (d.busy || d.photoBusy) return false;
    final errors = <String, String>{};
    if (d.step == OnboardingStep.profile) {
      if (d.text('name').trim().isEmpty) {
        errors['name'] = 'Введите имя, чтобы продолжить.';
      } else if (d.text('name').trim().length > 80) {
        errors['name'] = 'Сократите имя до 80 символов.';
      }
      if (d.text('city').trim().isEmpty) {
        errors['city'] = 'Определите или выберите город.';
      }
      if (d.text('district').length > 100) {
        errors['district'] = 'Сократите район до 100 символов.';
      }
    }
    if (d.step == OnboardingStep.pet &&
        !skipPet &&
        d.text('petName').trim().isEmpty) {
      errors['petName'] = 'Введите имя питомца.';
    }
    if (d.step == OnboardingStep.pet &&
        !skipPet &&
        d.text('habits').length > 1000) {
      errors['habits'] = 'Сократите описание до 1000 символов.';
    }
    if (d.step == OnboardingStep.preferences) {
      if (d.text('experience').trim().isEmpty) {
        errors['experience'] = 'Расскажите об опыте с животными.';
      } else if (d.text('experience').length > 1000) {
        errors['experience'] = 'Сократите описание до 1000 символов.';
      }
      if (d.sizes.isEmpty) {
        errors['sizes'] = 'Выберите хотя бы один размер собак.';
      }
      final areas = d
          .text('areas')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (areas.isEmpty) {
        errors['areas'] = 'Укажите хотя бы один район для прогулок.';
      } else if (areas.length > 10 || areas.any((s) => s.length > 100)) {
        errors['areas'] = 'Укажите до 10 районов, каждый до 100 символов';
      }
    }
    if (d.step == OnboardingStep.availability) {
      if (!validTimeZone(d.zone)) {
        errors['zone'] = 'Выберите часовой пояс из списка';
      }
      final invalid = WeeklyAvailability.validate(d.slots);
      if (invalid != null) {
        errors['availability'] = d.slots.any((slot) => slot.end <= slot.start)
            ? 'Окончание должно быть позже начала.'
            : invalid;
      }
    }
    if (errors.isNotEmpty) {
      state = AsyncData(d.copy(errors: errors));
      return false;
    }
    state = AsyncData(d.copy(busy: true, errors: {}));
    try {
      switch (d.step) {
        case OnboardingStep.role:
          await ref
              .read(accountModeProvider.notifier)
              .chooseRole(d.role, mode: d.mode);
          if (!_current(d, repository)) return false;
          state = AsyncData(
            state.requireValue.copy(step: OnboardingStep.profile, busy: false),
          );
        case OnboardingStep.profile:
          await ref.read(communityProvider.notifier).command('profile', {
            'display_name': d.text('name').trim(),
            'district': d.text('district').trim(),
          });
          if (!_current(d, repository)) return false;
          await ref
              .read(prototypeProvider.notifier)
              .setCity(d.text('city'), manual: d.manualCity);
          if (!_current(d, repository)) return false;
          if (d.photo != null && writePhoto != null) {
            if (!await writePhoto('profile:${d.accountId}', d.photo!)) {
              throw StateError('Photo save failed');
            }
          }
          if (!_current(d, repository)) return false;
          state = AsyncData(
            state.requireValue.copy(
              step: d.helper ? OnboardingStep.preferences : OnboardingStep.pet,
              busy: false,
            ),
          );
        case OnboardingStep.pet:
          if (!skipPet) {
            var id = d.petId;
            if (id == null) {
              id = await repository.command('pet', {
                'name': d.text('petName').trim(),
                'kind': d.text('kind'),
                'temperament': d.text('habits').trim(),
              });
              if (!_current(d, repository)) return false;
              if (id == null) {
                throw StateError('Pet creation did not return an ID');
              }
              state = AsyncData(state.requireValue.copy(petId: id));
            } else {
              await repository.command('pet', {
                'id': id,
                'name': d.text('petName').trim(),
                'kind': d.text('kind'),
                'temperament': d.text('habits').trim(),
              });
            }
            ref.invalidate(communityProvider);
            if (d.petPhoto != null && writePhoto != null) {
              if (!await writePhoto('pet:$id', d.petPhoto!)) {
                throw StateError('Photo save failed');
              }
            }
          }
          if (!_current(d, repository)) return false;
          state = AsyncData(
            state.requireValue.copy(step: OnboardingStep.ready, busy: false),
          );
        case OnboardingStep.preferences:
          state = AsyncData(
            d.copy(step: OnboardingStep.availability, busy: false),
          );
        case OnboardingStep.availability:
          final helper = HelperProfile(
            city: d.text('city'),
            district: d.text('district'),
            introduction: d.text('about'),
            experience: d.text('experience'),
            dogSizes: d.sizes,
            serviceDistricts: d
                .text('areas')
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
            availability: d.slots,
            timeZone: d.zone,
          );
          final invalid = helper.validate();
          if (invalid != null) {
            state = AsyncData(
              d.copy(errors: {'availability': invalid}, busy: false),
            );
            return false;
          }
          await ref
              .read(accountModeProvider.notifier)
              .saveHelperProfile(helper);
          if (!_current(d, repository)) return false;
          state = AsyncData(
            state.requireValue.copy(step: OnboardingStep.ready, busy: false),
          );
        case OnboardingStep.ready:
          return true;
      }
      return true;
    } catch (_) {
      if (_current(d, repository)) {
        state = AsyncData(
          state.requireValue.copy(
            busy: false,
            failure:
                'Не удалось сохранить. Данные остаются в форме. Проверьте соединение и повторите.',
          ),
        );
      }
      return false;
    }
  }
}
