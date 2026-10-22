import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';

class CitySuggestion {
  const CitySuggestion(
    this.name, [
    this.aliases = const [],
    this.country = 'Беларусь',
    this.timeZone = 'Europe/Minsk',
    this.countryCode = 'BY',
    this.label,
    this.region = '',
    this.latitude,
    this.longitude,
    this.population = 0,
  ]);
  final String name;
  final List<String> aliases;
  final String country;
  final String timeZone, countryCode, region;
  final String? label;
  final double? latitude, longitude;
  final int population;
  String get isoCountry => country == 'Россия' ? 'RU' : countryCode;
  String get displayName => label ?? name;
}

// Suggested cities in Belarus and Russia. Other cities remain selectable.
const launchCities = [
  CitySuggestion('Минск', ['Minsk', 'Мінск']),
  CitySuggestion('Гродно', ['Grodno', 'Hrodna', 'Гродна']),
  CitySuggestion('Брест', ['Brest']),
  CitySuggestion('Гомель', ['Gomel', 'Homiel', 'Гомель']),
  CitySuggestion('Витебск', ['Vitebsk', 'Віцебск']),
  CitySuggestion('Могилёв', ['Mogilev', 'Mahilioŭ', 'Магілёў']),
  CitySuggestion('Бобруйск', ['Bobruisk', 'Бабруйск']),
  CitySuggestion('Барановичи', ['Baranovichi', 'Баранавічы']),
  CitySuggestion('Борисов', ['Borisov', 'Барысаў']),
  CitySuggestion('Пинск', ['Pinsk']),
  CitySuggestion('Орша', ['Orsha']),
  CitySuggestion('Новополоцк', ['Novopolotsk', 'Наваполацк']),
  CitySuggestion('Лида', ['Lida', 'Ліда']),
  CitySuggestion('Солигорск', ['Soligorsk', 'Салігорск']),
  CitySuggestion('Мозырь', ['Mozyr', 'Мазыр']),
  CitySuggestion('Полоцк', ['Polotsk', 'Полацк']),
  CitySuggestion('Молодечно', ['Molodechno', 'Маладзечна']),
  CitySuggestion('Жлобин', ['Zhlobin', 'Жлобін']),
  CitySuggestion('Речица', ['Rechitsa', 'Рэчыца']),
  CitySuggestion('Слуцк', ['Slutsk']),
  CitySuggestion('Жодино', ['Zhodino', 'Жодзіна']),
  CitySuggestion('Кобрин', ['Kobrin', 'Кобрын']),
  CitySuggestion('Москва', ['Moscow', 'Moskva'], 'Россия', 'Europe/Moscow'),
  CitySuggestion(
    'Санкт-Петербург',
    [
      'Saint Petersburg',
      'St Petersburg',
      'Петербург',
      'Санкт Петербург',
      'СПб',
    ],
    'Россия',
    'Europe/Moscow',
  ),
  CitySuggestion('Казань', ['Kazan'], 'Россия', 'Europe/Moscow'),
  CitySuggestion(
    'Нижний Новгород',
    ['Nizhny Novgorod'],
    'Россия',
    'Europe/Moscow',
  ),
  CitySuggestion(
    'Ростов-на-Дону',
    ['Rostov-on-Don'],
    'Россия',
    'Europe/Moscow',
  ),
  CitySuggestion('Краснодар', ['Krasnodar'], 'Россия', 'Europe/Moscow'),
  CitySuggestion('Воронеж', ['Voronezh'], 'Россия', 'Europe/Moscow'),
  CitySuggestion('Сочи', ['Sochi'], 'Россия', 'Europe/Moscow'),
  CitySuggestion('Смоленск', ['Smolensk'], 'Россия', 'Europe/Moscow'),
  CitySuggestion(
    'Калининград',
    ['Kaliningrad'],
    'Россия',
    'Europe/Kaliningrad',
  ),
  CitySuggestion('Самара', ['Samara'], 'Россия', 'Europe/Samara'),
  CitySuggestion('Саратов', ['Saratov'], 'Россия', 'Europe/Saratov'),
  CitySuggestion(
    'Екатеринбург',
    ['Yekaterinburg', 'Ekaterinburg'],
    'Россия',
    'Asia/Yekaterinburg',
  ),
  CitySuggestion('Уфа', ['Ufa'], 'Россия', 'Asia/Yekaterinburg'),
  CitySuggestion('Пермь', ['Perm'], 'Россия', 'Asia/Yekaterinburg'),
  CitySuggestion('Челябинск', ['Chelyabinsk'], 'Россия', 'Asia/Yekaterinburg'),
  CitySuggestion('Тюмень', ['Tyumen'], 'Россия', 'Asia/Yekaterinburg'),
  CitySuggestion('Омск', ['Omsk'], 'Россия', 'Asia/Omsk'),
  CitySuggestion('Новосибирск', ['Novosibirsk'], 'Россия', 'Asia/Novosibirsk'),
  CitySuggestion('Красноярск', ['Krasnoyarsk'], 'Россия', 'Asia/Krasnoyarsk'),
  CitySuggestion('Томск', ['Tomsk'], 'Россия', 'Asia/Tomsk'),
  CitySuggestion('Иркутск', ['Irkutsk'], 'Россия', 'Asia/Irkutsk'),
  CitySuggestion('Якутск', ['Yakutsk'], 'Россия', 'Asia/Yakutsk'),
  CitySuggestion('Владивосток', ['Vladivostok'], 'Россия', 'Asia/Vladivostok'),
  CitySuggestion('Хабаровск', ['Khabarovsk'], 'Россия', 'Asia/Vladivostok'),
  CitySuggestion('Магадан', ['Magadan'], 'Россия', 'Asia/Magadan'),
  CitySuggestion(
    'Петропавловск-Камчатский',
    ['Petropavlovsk-Kamchatsky'],
    'Россия',
    'Asia/Kamchatka',
  ),
  CitySuggestion('Анадырь', ['Anadyr'], 'Россия', 'Asia/Anadyr'),
];
List<CitySuggestion> _worldCities = const [];
final Map<String, CitySuggestion> _byKey = {};
final Map<String, List<CitySuggestion>> _byAlias = {};
final Map<String, String> _searchByKey = {};
final Map<String, String> _prefixByKey = {};
Map<String, Map<String, String>> _countryNames = {};
Future<void>? _loading;

/// Load public, bundled data once. Never stores device location.
Future<void> loadWorldCities() => _loading ??= _loadWorldCities();
Future<void> _loadWorldCities() async {
  try {
    final countries =
        jsonDecode(
              await rootBundle.loadString(
                'assets/data/geonames/countries.json',
              ),
            )
            as Map<String, dynamic>;
    _countryNames = countries.map(
      (key, value) => MapEntry(key, Map<String, String>.from(value)),
    );
    final rows =
        jsonDecode(
              await rootBundle.loadString('assets/data/geonames/cities.json'),
            )
            as List;
    final legacyIds = <String>{};
    final result = <CitySuggestion>[];
    for (final raw in rows) {
      final r = raw as List;
      final aliases = (r[10] as List).cast<String>();
      final legacy = launchCities
          .where(
            (c) =>
                c.isoCountry == r[3] &&
                [c.name, ...c.aliases].any(
                  (a) => aliases.any((b) => _normalize(a) == _normalize(b)),
                ),
          )
          .firstOrNull;
      // Keep legacy keys and their catalog/history references, but add coordinates.
      // Only a single (largest) match can claim a legacy key.
      if (legacy != null && legacyIds.add(legacy.name)) {
        result.add(
          CitySuggestion(
            legacy.name,
            [...legacy.aliases, ...aliases],
            legacy.country,
            r[6],
            r[3],
            legacy.name,
            r[5],
            r[7],
            r[8],
            r[9],
          ),
        );
      } else {
        result.add(
          CitySuggestion(
            r[2],
            aliases,
            r[4],
            r[6],
            r[3],
            r[1],
            r[5],
            r[7],
            r[8],
            r[9],
          ),
        );
      }
    }
    for (final city in launchCities.where((c) => !legacyIds.contains(c.name))) {
      result.add(city);
    }
    for (final city in result) {
      final aliases = {
        city.name,
        city.displayName,
        ...city.aliases,
      }.map(_normalize).toSet();
      for (final alias in aliases) {
        final matches = _byAlias.putIfAbsent(alias, () => []);
        if (matches.length < 2) {
          matches.add(city);
        }
      }
      _prefixByKey[city.name] = aliases.join('|');
      _searchByKey[city.name] = _normalize(
        [
          city.name,
          ...aliases,
          city.region,
          city.country,
          city.isoCountry,
          for (final language in ['ru', 'en', 'be', 'pl'])
            _countryNames[language]?[city.isoCountry] ?? city.isoCountry,
        ].join('|'),
      );
    }
    _worldCities = List.unmodifiable(result);
    // Canonical keys are identities. Accent folding can collapse distinct
    // cities (e.g. Benito Juárez and Benito Juarez in Mexico City).
    _byKey.addEntries(result.map((c) => MapEntry(c.name, c)));
  } catch (_) {
    _loading = null;
    rethrow;
  }
}

String _normalize(String value) {
  var result = value.trim().toLowerCase().replaceAll('ё', 'е');
  const folding = {
    'ą': 'a',
    'ć': 'c',
    'ę': 'e',
    'ł': 'l',
    'ń': 'n',
    'ó': 'o',
    'ś': 's',
    'ź': 'z',
    'ż': 'z',
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'ř': 'r',
    'š': 's',
    'ž': 'z',
    'č': 'c',
    'ě': 'e',
    'ď': 'd',
    'ť': 't',
    'ň': 'n',
    'ő': 'o',
    'ű': 'u',
  };
  for (final e in folding.entries) {
    result = result.replaceAll(e.key, e.value);
  }
  return result;
}

bool get worldCitiesLoaded => _worldCities.isNotEmpty;
List<CitySuggestion> get availableCities =>
    _worldCities.isEmpty ? launchCities : _worldCities;
List<String> get availableCountries =>
    availableCities.map((c) => c.isoCountry).toSet().toList()..sort();
String countryName(String code, String language) =>
    _countryNames[language]?[code] ?? _countryNames['en']?[code] ?? code;
List<CitySuggestion> suggestCities(
  String query, {
  String? countryCode,
  int limit = 6,
}) {
  final normalized = _normalize(query);
  final terms = normalized
      .split(RegExp(r'[,\s]+'))
      .where((s) => s.isNotEmpty)
      .toList();
  final matches = availableCities.where((city) {
    if (countryCode != null && city.isoCountry != countryCode) {
      return false;
    }
    final search =
        _searchByKey[city.name] ??
        _normalize([city.name, ...city.aliases, city.country].join('|'));
    return terms.every(search.contains);
  }).toList();
  bool prefix(CitySuggestion city) {
    final names =
        _prefixByKey[city.name] ??
        _normalize([city.displayName, ...city.aliases].join('|'));
    return names.startsWith(normalized) || names.contains('|$normalized');
  }

  return [
    ...matches.where(prefix),
    ...matches.where((c) => !prefix(c)),
  ].take(limit).toList();
}

CitySuggestion? knownCity(String value) {
  final key = _normalize(value);
  final indexed = _byKey[value.trim()];
  if (indexed != null) {
    return indexed;
  }
  final legacy = launchCities
      .where(
        (city) =>
            [city.name, ...city.aliases].any((name) => _normalize(name) == key),
      )
      .firstOrNull;
  if (legacy != null) {
    return _byKey[legacy.name] ?? legacy;
  }
  final matches = _byAlias[key] ?? const <CitySuggestion>[];
  return matches.length == 1 ? matches.first : null; // Never guess a homonym.
}

String canonicalCity(String value) => knownCity(value)?.name ?? value.trim();
String cityGeocodingQuery(String value) {
  final city = knownCity(value);
  if (city == null) {
    return value.trim();
  }
  return city.label == null || launchCities.any((c) => c.name == city.name)
      ? '${city.name}, ${city.country}'
      : city.name.replaceFirst(RegExp(r', #\d+$'), '');
}

/// Reverse geocoding is matched within the detected country, then by public
/// city centre distance. Exact GPS is only used in this in-memory calculation.
String detectedCity(
  String name,
  String? countryCode,
  double latitude,
  double longitude, {
  String? region,
}) {
  final code = countryCode?.toUpperCase();
  final matches = availableCities
      .where(
        (c) =>
            c.isoCountry == code &&
            [
              c.displayName,
              ...c.aliases,
            ].any((a) => _normalize(a) == _normalize(name)),
      )
      .toList();
  double distance(CitySuggestion c) => c.latitude == null
      ? double.infinity
      : math.pow(c.latitude! - latitude, 2).toDouble() +
            math
                .pow(
                  (c.longitude! - longitude) *
                      math.cos(latitude * math.pi / 180),
                  2,
                )
                .toDouble();
  matches.sort((a, b) => distance(a).compareTo(distance(b)));
  if (matches.isNotEmpty && distance(matches.first) < .25) {
    return matches.first.name;
  }
  return [
    name,
    if (region?.isNotEmpty == true) region!,
    if (code?.isNotEmpty == true) code!,
  ].join(', ');
}
