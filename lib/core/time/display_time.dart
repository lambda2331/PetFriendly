import '../../l10n/localization.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../location/city_directory.dart';
// GeoNames includes IANA links such as Africa/Kinshasa. The default trimmed
// database omits these valid identifiers and blocks scheduling in those cities.
import 'package:timezone/data/latest_all.dart' as data;
import 'package:timezone/timezone.dart' as tz;

bool _ready = false;
void _initialize() {
  if (_ready) {
    return;
  }
  data.initializeTimeZones();
  initializeDateFormatting();
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
  if (zone == null || zone.isEmpty) {
    return false;
  }
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

String _date(DateTime date, String locale) {
  _initialize();
  return DateFormat.yMMMMd(locale).format(date);
}

String timeZoneLabel(String zone, {DateTime? at, String locale = 'ru'}) {
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
  return '${translateForLanguage(place, locale: locale)} · $offset';
}

String venueTime(
  dynamic value, {
  String? city,
  String? timeZone,
  String locale = 'ru',
}) {
  final parsed = DateTime.tryParse('$value');
  if (parsed == null) {
    return translateForLanguage('Время не задано', locale: locale);
  }
  final zone = timeZone ?? cityTimeZone(city);
  if (!validTimeZone(zone)) {
    return translateForLanguage(
      '{p0} · {p1} UTC · часовой пояс места не указан',
      locale: locale,
      arguments: {
        'p0': _date(parsed.toUtc(), locale),
        'p1': _clock(parsed.toUtc()),
      },
    );
  }
  final date = venueDateTime(parsed, zone!);
  return '${_date(date, locale)} · ${_clock(date)} · ${timeZoneLabel(zone, at: parsed, locale: locale)}';
}

String readableLocalDateTime(dynamic value, {String locale = 'ru'}) {
  final parsed = DateTime.tryParse('$value')?.toLocal();
  return parsed == null
      ? translateForLanguage('Дата не указана', locale: locale)
      : '${_date(parsed, locale)} · ${_clock(parsed)}';
}

String readableDate(dynamic value, {String locale = 'ru'}) {
  final parsed = DateTime.tryParse('$value')?.toLocal();
  return parsed == null
      ? translateForLanguage('Дата не указана', locale: locale)
      : _date(parsed, locale);
}

/// Compact local-time labels for the inbox. Threads retain full timestamps.
String compactChatTime(dynamic value, {DateTime? now, String locale = 'ru'}) {
  final parsed = value is DateTime ? value : DateTime.tryParse('$value');
  if (parsed == null) {
    return '';
  }
  final date = parsed.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  if (date.year == today.year &&
      date.month == today.month &&
      date.day == today.day) {
    return _clock(date);
  }
  _initialize();
  if (locale == 'ru' || locale == 'be') {
    return '${DateFormat.MMMd(locale).format(date)}${date.year == today.year ? '' : ' ${date.year}'}';
  }
  return (date.year == today.year
          ? DateFormat.MMMd(locale)
          : DateFormat.yMMMd(locale))
      .format(date);
}
