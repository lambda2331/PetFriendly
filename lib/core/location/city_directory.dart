class CitySuggestion {
  const CitySuggestion(
    this.name, [
    this.aliases = const [],
    this.country = 'Беларусь',
    this.timeZone = 'Europe/Minsk',
  ]);
  final String name;
  final List<String> aliases;
  final String country;
  final String timeZone;
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
String _normalize(String value) =>
    value.trim().toLowerCase().replaceAll('ё', 'е');
List<CitySuggestion> suggestCities(String query) {
  final normalized = _normalize(query);
  final matches = launchCities
      .where(
        (city) => [
          city.name,
          ...city.aliases,
        ].any((name) => _normalize(name).contains(normalized)),
      )
      .toList();
  bool prefix(CitySuggestion city) => [
    city.name,
    ...city.aliases,
  ].any((name) => _normalize(name).startsWith(normalized));
  return [
    ...matches.where(prefix),
    ...matches.where((city) => !prefix(city)),
  ].take(6).toList();
}

String canonicalCity(String value) =>
    launchCities
        .where(
          (city) => [
            city.name,
            ...city.aliases,
          ].any((name) => _normalize(name) == _normalize(value)),
        )
        .firstOrNull
        ?.name ??
    value.trim();

CitySuggestion? knownCity(String value) =>
    launchCities.where((city) => city.name == canonicalCity(value)).firstOrNull;
String cityGeocodingQuery(String value) {
  final city = knownCity(value);
  return city == null ? value.trim() : '${city.name}, ${city.country}';
}
