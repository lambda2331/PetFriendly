import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PreferencesRepository {
  String? read(String key);
  Future<void> write(String key, String value);
}

class DevicePreferences implements PreferencesRepository {
  DevicePreferences(this.preferences);
  final SharedPreferences preferences;
  @override
  String? read(String key) => preferences.getString(key);
  @override
  Future<void> write(String key, String value) async {
    await preferences.setString(key, value);
  }
}

final preferencesProvider = Provider<PreferencesRepository>(
  (ref) => throw UnimplementedError('Provide local preferences at startup'),
);

@immutable
class PrototypeState {
  const PrototypeState({
    this.theme = ThemeMode.system,
    this.city = 'Минск',
    this.manualCity = false,
    this.favorites = const {},
    this.joined = false,
    this.applied = false,
  });
  final ThemeMode theme;
  final String city;
  final bool manualCity, joined, applied;
  final Set<String> favorites;
  PrototypeState copyWith({
    ThemeMode? theme,
    String? city,
    bool? manualCity,
    Set<String>? favorites,
    bool? joined,
    bool? applied,
  }) => PrototypeState(
    theme: theme ?? this.theme,
    city: city ?? this.city,
    manualCity: manualCity ?? this.manualCity,
    favorites: favorites ?? this.favorites,
    joined: joined ?? this.joined,
    applied: applied ?? this.applied,
  );
}

class PrototypeController extends Notifier<PrototypeState> {
  @override
  PrototypeState build() {
    final prefs = ref.read(preferencesProvider);
    final name = prefs.read('theme');
    return PrototypeState(
      theme: ThemeMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => ThemeMode.system,
      ),
      city: prefs.read('city') ?? 'Минск',
      manualCity: prefs.read('manualCity') == 'true',
      favorites: (prefs.read('favorites') ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toSet(),
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(theme: mode);
    await ref.read(preferencesProvider).write('theme', mode.name);
  }

  Future<void> setCity(String city, {bool manual = true}) async {
    state = state.copyWith(city: city, manualCity: manual);
    final prefs = ref.read(preferencesProvider);
    await prefs.write('city', city);
    await prefs.write('manualCity', '$manual');
  }

  Future<void> favorite(String id) async {
    final favorites = {...state.favorites};
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    state = state.copyWith(favorites: favorites);
    await ref.read(preferencesProvider).write('favorites', favorites.join(','));
  }

  Future<void> clearAccount() async {
    state = state.copyWith(favorites: {}, joined: false, applied: false);
    await ref.read(preferencesProvider).write('favorites', '');
  }

  void join() => state = state.copyWith(joined: !state.joined);
  void apply() => state = state.copyWith(applied: !state.applied);
}

final prototypeProvider = NotifierProvider<PrototypeController, PrototypeState>(
  PrototypeController.new,
);
