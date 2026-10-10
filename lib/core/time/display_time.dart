import '../location/city_directory.dart';
import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

bool _ready = false;
void _initialize() {
  if (_ready) return;
  data.initializeTimeZones();
  _ready = true;
}

// Known cities have venue zones; unknown cities require an explicit
// selection; the device's zone must never determine a venue's local time.
const _belarusCities = {
  'минск',
  'мінск',
  'minsk',
  'гродно',
  'гродна',
  'grodno',
  'hrodna',
  'брест',
  'brest',
  'гомель',
  'gomel',
  'homiel',
  'витебск',
  'віцебск',
  'vitebsk',
  'могилёв',
  'могилев',
  'магілёў',
  'mogilev',
  'mahilioŭ',
  'бобруйск',
  'бабруйск',
  'bobruisk',
  'барановичи',
  'баранавічы',
  'baranovichi',
  'борисов',
  'барысаў',
  'borisov',
  'пинск',
  'pinsk',
  'орша',
  'orsha',
  'новополоцк',
  'наваполацк',
  'novopolotsk',
  'лида',
  'ліда',
  'lida',
  'солигорск',
  'салігорск',
  'soligorsk',
  'мозырь',
  'мазыр',
  'mozyr',
  'полоцк',
  'полацк',
  'polotsk',
  'молодечно',
  'маладзечна',
  'molodechno',
  'жлобин',
  'жлобін',
  'zhlobin',
  'речица',
  'рэчыца',
  'rechitsa',
  'слуцк',
  'slutsk',
  'жодино',
  'жодзіна',
  'zhodino',
  'кобрин',
  'кобрын',
  'kobrin',
};

String? cityTimeZone(String? city) => city == null
    ? null
    : knownCity(city)?.timeZone ??
          (_belarusCities.contains(city.trim().toLowerCase())
              ? 'Europe/Minsk'
              : null);

bool validTimeZone(String? zone) {
  if (zone == null || zone.isEmpty) return false;
  _initialize();
  return tz.timeZoneDatabase.locations.containsKey(zone);
}

List<String> get venueTimeZones {
  _initialize();
  return tz.timeZoneDatabase.locations.keys
      .where((name) => name.contains('/') && !name.startsWith('Etc/'))
      .toList()
    ..sort();
}

DateTime venueDateTime(DateTime instant, String zone) {
  _initialize();
  return tz.TZDateTime.from(instant.toUtc(), tz.getLocation(zone));
}

/// Interpret picker components as wall time at the venue, independent of host
/// timezone. Reject skipped/repeated DST times rather than silently shifting.
DateTime venueWallTimeToUtc(DateTime wall, String zone) {
  _initialize();
  final location = tz.getLocation(zone);
  final wallMs = DateTime.utc(
    wall.year,
    wall.month,
    wall.day,
    wall.hour,
    wall.minute,
  ).millisecondsSinceEpoch;
  final candidates = <int>{};
  for (final offset in location.zones.map((z) => z.offset).toSet()) {
    final instant = DateTime.fromMillisecondsSinceEpoch(
      wallMs - offset.inMilliseconds,
      isUtc: true,
    );
    final local = tz.TZDateTime.from(instant, location);
    if (local.year == wall.year &&
        local.month == wall.month &&
        local.day == wall.day &&
        local.hour == wall.hour &&
        local.minute == wall.minute) {
      candidates.add(instant.millisecondsSinceEpoch);
    }
  }
  if (candidates.length != 1) {
    throw FormatException(
      candidates.isEmpty
          ? 'В это время переводят часы. Выберите другое время.'
          : 'Это время повторяется при переводе часов. Выберите другое время.',
    );
  }
  return DateTime.fromMillisecondsSinceEpoch(candidates.single, isUtc: true);
}

String _clock(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _date(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';
const _months = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

String timeZoneLabel(String zone, {DateTime? at}) {
  final date = venueDateTime(at ?? DateTime.now(), zone);
  final minutes = date.timeZoneOffset.inMinutes;
  final hours = minutes.abs() ~/ 60;
  final remainder = minutes.abs() % 60;
  final offset =
      'UTC${minutes < 0 ? '−' : '+'}$hours${remainder == 0 ? '' : ':${remainder.toString().padLeft(2, '0')}'}';
  final place = switch (zone) {
    'Europe/Minsk' => 'Минск',
    'Europe/Warsaw' => 'Варшава',
    'Europe/Moscow' => 'Москва',
    'Europe/Vilnius' => 'Вильнюс',
    'Europe/Riga' => 'Рига',
    'Europe/Kyiv' => 'Киев',
    _ => zone.split('/').last.replaceAll('_', ' '),
  };
  return '$place · $offset';
}

String venueTime(dynamic value, {String? city, String? timeZone}) {
  final parsed = DateTime.tryParse('$value');
  if (parsed == null) return 'Время не задано';
  final zone = timeZone ?? cityTimeZone(city);
  if (!validTimeZone(zone)) {
    return '${_date(parsed.toUtc())} · ${_clock(parsed.toUtc())} UTC · часовой пояс места не указан';
  }
  final date = venueDateTime(parsed, zone!);
  return '${_date(date)} · ${_clock(date)} · ${timeZoneLabel(zone, at: parsed)}';
}

String readableLocalDateTime(dynamic value) {
  final parsed = DateTime.tryParse('$value')?.toLocal();
  return parsed == null
      ? 'Дата не указана'
      : '${_date(parsed)} · ${_clock(parsed)}';
}

String readableDate(dynamic value) {
  final parsed = DateTime.tryParse('$value')?.toLocal();
  return parsed == null ? 'Дата не указана' : _date(parsed);
}

/// Compact local-time labels for the inbox. Threads retain full timestamps.
String compactChatTime(dynamic value, {DateTime? now}) {
  final parsed = value is DateTime ? value : DateTime.tryParse('$value');
  if (parsed == null) return '';
  final date = parsed.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  if (date.year == today.year &&
      date.month == today.month &&
      date.day == today.day) {
    return _clock(date);
  }
  const months = [
    'янв.',
    'фев.',
    'мар.',
    'апр.',
    'мая',
    'июн.',
    'июл.',
    'авг.',
    'сен.',
    'окт.',
    'ноя.',
    'дек.',
  ];
  return '${date.day} ${months[date.month - 1]}${date.year == today.year ? '' : ' ${date.year}'}';
}
