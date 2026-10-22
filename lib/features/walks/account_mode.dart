import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend/backend.dart';
import '../../core/time/display_time.dart';
import '../community/data/community_repository.dart';

/// Product roles never confer staff permissions. The server is authoritative.
class AccountMode {
  const AccountMode({
    this.role = 'both',
    this.mode = 'owner',
    this.needsRoleSelection = true,
    this.pending = false,
    this.error,
  });
  final String role, mode;
  final bool needsRoleSelection, pending;
  final String? error;
  bool get canOwn => role == 'owner' || role == 'both';
  bool get canHelp => role == 'helper' || role == 'both';
  bool get isHelper => mode == 'helper';
  AccountMode copyWith({
    String? role,
    String? mode,
    bool? needsRoleSelection,
    bool pending = false,
    String? error,
  }) => AccountMode(
    role: role ?? this.role,
    mode: mode ?? this.mode,
    needsRoleSelection: needsRoleSelection ?? this.needsRoleSelection,
    pending: pending,
    error: error,
  );
  factory AccountMode.fromJson(Map<String, dynamic> json) {
    final role = json['account_role'], mode = json['active_mode'];
    if (!['owner', 'helper', 'both'].contains(role) ||
        !['owner', 'helper'].contains(mode) ||
        (role != 'both' && role != mode)) {
      throw const FormatException('Invalid account mode');
    }
    return AccountMode(
      role: role as String,
      mode: mode as String,
      needsRoleSelection: json['needs_role_selection'] == true,
    );
  }
}

class WeeklyAvailability {
  const WeeklyAvailability({
    required this.day,
    required this.start,
    required this.end,
  });
  final int day, start, end;
  Map<String, dynamic> toJson() => {'day': day, 'start': start, 'end': end};
  factory WeeklyAvailability.fromJson(Map<String, dynamic> row) =>
      WeeklyAvailability(
        day: row['day'] as int,
        start: row['start'] as int,
        end: row['end'] as int,
      );
  static String? validate(List<WeeklyAvailability> slots) {
    if (slots.length > 28) return 'Добавьте не больше 28 интервалов';
    for (var i = 0; i < slots.length; i++) {
      final a = slots[i];
      if (a.day < 0 ||
          a.day > 6 ||
          a.start < 0 ||
          a.end > 1440 ||
          a.start >= a.end) {
        return 'Начало должно быть раньше окончания в пределах одного дня';
      }
      for (final b in slots.skip(i + 1)) {
        if (a.day == b.day && a.start < b.end && b.start < a.end) {
          return 'Интервалы одного дня не должны пересекаться';
        }
      }
    }
    return null;
  }
}

class HelperProfile {
  const HelperProfile({
    this.city = 'Минск',
    this.district = '',
    this.introduction = '',
    this.experience = '',
    this.timeZone = 'Europe/Minsk',
    this.dogSizes = const [],
    this.serviceDistricts = const [],
    this.availability = const [],
    this.accepting = true,
  });
  final String city, district, introduction, experience, timeZone;
  final List<String> dogSizes, serviceDistricts;
  final List<WeeklyAvailability> availability;
  final bool accepting;
  factory HelperProfile.fromJson(Map<String, dynamic> row) => HelperProfile(
    city: row['city'] as String? ?? '',
    district: row['district'] as String? ?? '',
    introduction: row['introduction'] as String? ?? '',
    experience: row['experience'] as String? ?? '',
    timeZone: row['time_zone'] as String? ?? 'Europe/Minsk',
    dogSizes: List<String>.from(row['dog_sizes'] ?? []),
    serviceDistricts: List<String>.from(row['service_districts'] ?? []),
    availability: (row['availability'] as List? ?? [])
        .map((v) => WeeklyAvailability.fromJson(Map<String, dynamic>.from(v)))
        .toList(),
    accepting: row['accepting'] != false,
  );
  Map<String, dynamic> toParams() => {
    'city_in': city.trim(),
    'district_in': district.trim(),
    'introduction_in': introduction.trim(),
    'experience_in': experience.trim(),
    'time_zone_in': timeZone,
    'dog_sizes_in': dogSizes,
    'service_districts_in': serviceDistricts,
    'availability_in': availability.map((slot) => slot.toJson()).toList(),
    'accepting_in': accepting,
  };
  String? validate() {
    if (city.trim().isEmpty || city.trim().length > 120) {
      return 'Укажите город до 120 символов';
    }
    if (district.trim().length > 100 ||
        introduction.length > 1000 ||
        experience.length > 1000) {
      return 'Сократите описание до указанного ограничения';
    }
    if (dogSizes.toSet().length != dogSizes.length ||
        dogSizes.any((s) => !['small', 'medium', 'large'].contains(s))) {
      return 'Выберите размер собак из списка';
    }
    if (serviceDistricts.length > 10 ||
        serviceDistricts.any((s) => s.trim().isEmpty || s.length > 100)) {
      return 'Укажите до 10 районов, каждый до 100 символов';
    }
    if (!validTimeZone(timeZone)) return 'Выберите часовой пояс из списка';
    return WeeklyAvailability.validate(availability);
  }
}

abstract class AccountModeRepository {
  Future<AccountMode> load();
  Future<AccountMode> chooseRole(String role, {String? mode});
  Future<AccountMode> switchMode(String mode);
  Future<HelperProfile?> loadHelperProfile();
  Future<void> saveHelperProfile(HelperProfile profile);
}

class DemoAccountModeRepository implements AccountModeRepository {
  AccountMode current = const AccountMode();
  HelperProfile? profile;
  @override
  Future<AccountMode> load() async => current;
  @override
  Future<AccountMode> chooseRole(String role, {String? mode}) async {
    if (!['owner', 'helper', 'both'].contains(role)) {
      throw ArgumentError('Invalid role');
    }
    final next = role == 'both' ? mode ?? current.mode : role;
    if (!['owner', 'helper'].contains(next)) {
      throw ArgumentError('Invalid mode');
    }
    return current = AccountMode(
      role: role,
      mode: next,
      needsRoleSelection: false,
    );
  }

  @override
  Future<AccountMode> switchMode(String mode) async {
    if (!['owner', 'helper'].contains(mode) ||
        (current.role != 'both' && current.role != mode)) {
      throw StateError('Mode unavailable');
    }
    return current = current.copyWith(mode: mode);
  }

  @override
  Future<HelperProfile?> loadHelperProfile() async => profile;
  @override
  Future<void> saveHelperProfile(HelperProfile value) async {
    final error = value.validate();
    if (error != null) throw FormatException(error);
    if (!current.canHelp) throw StateError('Helper capability required');
    profile = value;
  }
}

class SupabaseAccountModeRepository implements AccountModeRepository {
  SupabaseAccountModeRepository(this.client, this.userId);
  final SupabaseClient client;
  final String userId;
  void checkAccount() {
    if (client.auth.currentUser?.id != userId) {
      throw StateError('Account changed');
    }
  }

  @override
  Future<AccountMode> load() async {
    checkAccount();
    final data = await client.rpc('my_account_mode');
    checkAccount();
    return AccountMode.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<AccountMode> chooseRole(String role, {String? mode}) async {
    checkAccount();
    await client.rpc(
      'set_account_role',
      params: {'role_in': role, 'mode_in': ?mode},
    );
    return load();
  }

  @override
  Future<AccountMode> switchMode(String mode) async {
    checkAccount();
    await client.rpc('switch_account_mode', params: {'mode_in': mode});
    return load();
  }

  @override
  Future<HelperProfile?> loadHelperProfile() async {
    checkAccount();
    final row = await client
        .from('walking_helper_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    checkAccount();
    return row == null ? null : HelperProfile.fromJson(row);
  }

  @override
  Future<void> saveHelperProfile(HelperProfile profile) async {
    final error = profile.validate();
    if (error != null) throw FormatException(error);
    checkAccount();
    await client.rpc('save_walking_helper_profile', params: profile.toParams());
    checkAccount();
  }
}

final accountModeRepositoryProvider = Provider<AccountModeRepository>((ref) {
  ref.watch(authStateProvider.select((s) => s.value?.id));
  final client = ref.watch(backendProvider);
  if (client == null) return DemoAccountModeRepository();
  return SupabaseAccountModeRepository(
    client,
    client.auth.currentUser?.id ?? '',
  );
});
final helperProfileProvider = FutureProvider<HelperProfile?>(
  (ref) => ref.watch(accountModeRepositoryProvider).loadHelperProfile(),
  retry: (_, _) => null,
);
final accountModeProvider =
    AsyncNotifierProvider<AccountModeController, AccountMode>(
      AccountModeController.new,
    );

class AccountModeController extends AsyncNotifier<AccountMode> {
  @override
  Future<AccountMode> build() =>
      ref.watch(accountModeRepositoryProvider).load();
  Future<void> mutate(
    Future<AccountMode> Function(AccountModeRepository) operation,
  ) async {
    final repository = ref.read(accountModeRepositoryProvider);
    final before = state.value ?? await future;
    if (!ref.mounted || ref.read(accountModeRepositoryProvider) != repository) {
      throw StateError('Account changed');
    }
    if (state.value?.pending == true) return;
    state = AsyncData(before.copyWith(pending: true));
    try {
      final after = await operation(repository);
      if (!ref.mounted ||
          ref.read(accountModeRepositoryProvider) != repository) {
        throw StateError('Account changed');
      }
      state = AsyncData(after);
      ref.invalidate(communityProvider);
    } catch (_) {
      if (ref.mounted &&
          ref.read(accountModeRepositoryProvider) == repository) {
        state = AsyncData(
          before.copyWith(
            error:
                'Не удалось сохранить. Проверьте соединение и попробуйте снова.',
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> chooseRole(String role, {String? mode}) =>
      mutate((r) => r.chooseRole(role, mode: mode));
  Future<void> switchMode(String mode) => mutate((r) => r.switchMode(mode));
  Future<void> saveHelperProfile(HelperProfile profile) => mutate((r) async {
    await r.saveHelperProfile(profile);
    if (!ref.mounted || ref.read(accountModeRepositoryProvider) != r) {
      throw StateError('Account changed');
    }
    ref.invalidate(helperProfileProvider);
    return r.load();
  });
}

/// Public form drafts stay in account-scoped memory, never preferences.
class HelperDraft {
  const HelperDraft({
    this.name = '',
    this.districtEntry = '',
    this.profile = const HelperProfile(),
    this.photo,
    this.step = 0,
  });
  final String name, districtEntry;
  final HelperProfile profile;
  final Uint8List? photo;
  final int step;
}

final helperDraftProvider =
    NotifierProvider<HelperDraftController, HelperDraft?>(
      HelperDraftController.new,
    );

class HelperDraftController extends Notifier<HelperDraft?> {
  @override
  HelperDraft? build() {
    ref.watch(authStateProvider.select((s) => s.value?.id));
    ref.watch(accountModeRepositoryProvider);
    return null;
  }

  void save(HelperDraft draft) => state = draft;
  void clear() => state = null;
}
