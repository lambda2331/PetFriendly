# Языки и города

Выбранные языки: русский, английский, белорусский и польский. Язык устройства используется по умолчанию; резервный — русский. Пользователь может поменять язык на экране входа или в настройках. Выбор хранится на устройстве, сохраняется при выходе из аккаунта и не меняет город/историю/идентичность.

## Добавление перевода

1. Добавить текст в `lib/l10n/arb/app_ru.arb` со стабильным ID `message…` и `@ID.description`, равным исходному тексту. Не переименовывать существующий ID при редактуре перевода.
2. Добавить тот же ID во все остальные ARB. Для переменных использовать placeholders, для чисел — ICU plurals. Новые семантические plural methods можно вызывать через `stringsFor(locale)`.
3. Выполнить `python3 scripts/generate_localization_bridge.py`, затем `flutter gen-l10n` и `dart format lib/l10n`.
4. Использовать явный `.tr(context, arguments: {...})` для UI-копии; исходный пользовательский текст выводить напрямую. API category/status/role values не переводить.
5. Проверить переключение языка, длинный текст, обе темы, plural cases и календарь. Не использовать глобальный изменяемый `Intl.defaultLocale`; чистые форматтеры получают locale явно.

## Справочник

Встроено 34 156 городов из 244 стран и территорий. Источник: [GeoNames cities15000](https://download.geonames.org/export/dump/readme.txt), CC BY 4.0. Он включает города с населением свыше 15 000 и столицы, а не каждый населённый пункт. Регион, ISO-страна, координаты публичного центра и IANA-зона входят в запись. Альтернативные названия ищутся без API на каждую букву; польские диакритики и ё нормализуются в индексе.

Национальные названия стран взяты из [Unicode CLDR](https://github.com/unicode-org/cldr-json) для всех четырёх языков. Названия городов/регионов остаются содержимым географического источника, алиасы позволяют искать на разных языках. Лицензии и дата/hash снимка сохранены рядом с данными в `assets/data/geonames/`.

Новые города имеют независимый от языка интерфейса ключ с регионом и ISO-страной. Для исторических городов Беларуси и России сохраняются старые ключи: существующие чаты, встречи, каталоги и профили не переименовываются. Неоднозначное голое название не выбирает произвольный город: пользователь выбирает строку со страной/регионом. Малые города допускают ручной ввод названия со страной; для встреч/выгула без известной зоны требуется явный выбор часового пояса.

Импорт мест остаётся OpenStreetMap: парки/площадки, зоомагазины и ветеринарные клиники. Он запускается для выбранного/определённого города через существующую авторизованную серверную функцию; автоматические кафе и рестораны исключены. Радиус источника — 15 км вокруг публичного центра, доступность и полнота зависят от OSM/геокодера. Геопозиция пользователя не входит в публичный city key. Подписи Mapbox локализуются SDK по возможности; при отсутствии перевода сохраняются исходные подписи.

## Обновление снимка

Скачать официальные `cities15000.zip`, `admin1CodesASCII.txt`, `countryInfo.txt` и `readme.txt` в ignored `tooling/.cache/geonames/`, а CLDR `territories.json` каждого языка — в `countries-{locale}.json`. Выполнить `python3 scripts/build_world_cities.py`; проверить лицензии, snapshot metadata, ключи/зоны и тесты перед включением обновления. Новые runtime-ключи не должны переименовывать ранее выбранные города без совместимого server-side перехода.

## Minimal language picker

The app-language sheet uses compact56px-minimum rows, a subtle Studio tint for the selected option and normal high-contrast text. iOS uses a trailing checkmark; Android uses radio-style selection indicators. Native names remain visible in every UI language. The system option shows the effective supported device language, including the existing Russian fallback. One divider separates automatic selection from explicit languages; there are no flag icons or separate Save action.

The sheet fits its content and becomes scrollable when text scaling or available height requires it. Selection retains the existing local persistence and leaves the current screen and drafts intact. This is a visual refinement; synchronization with Android’s system app-language setting remains a separate platform integration and is not claimed here.

Widget verification covers both platform presentations, both themes and320px layouts at100%/200% text, with choice persistence and draft retention. Captures are in docs/screenshots/language-picker/. Native accessibility-service certification remains unverified.

The native four-language integration journey passed after this refinement, with light Russian/English and dark Belarusian/Polish picker captures. It confirmed dismissing a selection returns to Settings. Static analysis passed. Native Android interaction and VoiceOver/TalkBack behavior were not exercised.

## Translated layout hardening

Long translations and canonical city names are accommodated by the layout instead of reducing font size. Nearby gives its heading and city selector separate rows. The page scrolls naturally with a280px embedded map, so controls no longer squeeze into the height left below the greeting/banner. Narrow or enlarged catalog-error states put retry below the explanation. Manual city values, map focus and geolocation behavior are unchanged.

Profile content tabs remain equal-width and full-width, but measure their shared height from the translated labels at the current text scale. Chat headers measure title and privacy-subtitle height, explicitly removing the inherited AppBar single-line limit. Walking request card actions can wrap onto a separate line. Helper dropdowns expand to available width and allow variable-height selected/menu labels; a stable filter-panel key keeps it expanded when the date changes.

The78-case targeted suite passed. A new16-case RU/EN/BE/PL × light/dark × normal402px/compact320px200% matrix checks Nearby, People, Walking help, Chats, Profile and a long-named chat. Another8 cases exercise the helper filter panel, date selection and evening dropdown in all languages/both themes at320px200%. Existing map, profile, helper, community-chat, social-layout and localization regressions passed. Analysis is clean. Captures are under docs/screenshots/translated-layout/; user-authored names, descriptions and messages remain in their original language. This does not claim an exhaustive audit of every modal or native screen-reader certification.

The updated native four-language iOS integration journey passed, with long-city Nearby and profile-tab captures in Russian/English light and Belarusian/Polish dark. These synthetic native captures use the honest unconfigured-map state; they do not certify live map tiles. Existing location/focus widget regressions passed. Production-style staging builds are restored after the integration harness.
