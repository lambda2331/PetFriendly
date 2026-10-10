# Настройка сервисов PetFriendly

Порядок подключения: Mapbox → облачный Supabase/email → Google → Apple → Telegram → Firebase/APNs. Пользовательское ревью интерфейса остаётся после завершения этапов. Бесплатные тарифы и отсутствие платных действий — действующее ограничение проекта.

Готово локально: отдельные конфигурации iOS/Android, проверка параметров без печати ключей, импорт клиентских параметров Firebase. Аккаунт Mapbox зарегистрирован пользователем и доступен без карты. Его Default public token подключён к обеим локальным конфигурациям; нативные тесты реальных тайлов/маркеров и обеих тем прошли на iOS/Android. Остальные внешние сервисы ещё не активированы.

## Файлы и запуск

```sh
python3 scripts/configure_services.py init
python3 scripts/configure_services.py check --platform ios --config config/app.ios.local.json
./scripts/run-configured.sh ios
./scripts/run-configured.sh android
```

Init сохраняет существующие файлы, права новых файлов — 600. Все `*.local.json` исключены из Git. Файлы уже созданы с локальным Supabase: `app.ios.local.json` и `app.android.local.json`. Android Emulator использует 10.0.2.2 вместо loopback Mac. При подключении облака URL и publishable key заменяются в обоих файлах. Пример структуры — config/app.example.json.

Клиенту передаются только publishable/anon ключ Supabase, публичный Mapbox token и клиентские параметры Firebase. OAuth secrets, `.p8`, Firebase service account и Supabase server key хранятся на сервере/в защищённом локальном файле. Не присылать их в чат. Клиентские параметры тоже не выводятся проверкой.

## 1. Mapbox

Для текущего аккаунта выбран **demo access без платёжного способа**: это пробный доступ с пониженными usage caps и отключением API при достижении лимита. В этом режиме Mapbox автоматически выдаёт один Default public token; создавать/вращать отдельные токены нельзя. Лимиты сбрасываются ежемесячно, если аккаунт их не достиг. Обновление до standard access не происходит автоматически. [Условия demo access](https://docs.mapbox.com/accounts/guides/demo-access/).

Порядок для нового или изменённого аккаунта:

1. Войти в [Mapbox Account](https://account.mapbox.com/), проверить тариф и раздел Maps SDKs for Mobile. На 08.10.2026 опубликована бесплатная квота 25 000 MAU; условия конкретного аккаунта необходимо проверить. [Тарифы](https://www.mapbox.com/pricing).
2. Проверить использование и задать spending alerts. У стандартного аккаунта Mapbox нет жёсткого spending cap; уведомление не останавливает расходы. Текущий demo access, в отличие от standard, ограничивает использование сервисов. Подключение предназначено для локального теста, бесплатная квота не гарантирует нулевой счёт при распространении приложения. [Ограничения расходов](https://docs.mapbox.com/accounts/faq/can-i-set-up-a-cap-for-monthly-spending/).
3. В разделе Access tokens получить public token `pk.` с минимальными правами чтения для карт; отдельный проектный token, если тариф позволяет. Не добавлять платёжный способ ради нового token. [Управление токенами](https://docs.mapbox.com/accounts/guides/tokens/).
4. После проверки аккаунта записать token в MAPBOX_ACCESS_TOKEN в обоих локальных файлах. Запустить приложение, открыть карту, проверить Минск, маркеры, карточки и обе темы. Пока token не задан, карта не вызывает Mapbox.

Готовность: тайлы реально загрузились на обеих платформах, атрибуция видна, данные учёта использования проверены. Проверка файла не подтверждает лимит аккаунта.

## 2. Supabase и email

Создать отдельный staging-проект на бесплатном тарифе; не использовать чужую существующую production-базу. Внести URL/Publishable key в оба клиентских файла, USE_DEMO_DATA=false. Секреты PostgreSQL и server key нужны только CLI/серверу. Применить миграции и seed из репозитория, развернуть delete-account и dispatch-notifications; сначала проверить локальные команды и целевой project ref перед операциями с облаком.

В Auth разрешить точный redirect `petfriendly://auth/callback` для локального теста. В provider console используется другой URL — серверный callback Supabase. Не путать эти адреса. Для распространяемой сборки подготовить подтверждённые HTTPS App/Universal Links. Подтверждение email оставить включённым; SMTP настраивать в Supabase, пароль SMTP не попадает в приложение. [Redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls), [SMTP](https://supabase.com/docs/guides/auth/auth-smtp).

Готовность: подтверждение email, вход, восстановление с MFA, отзыв сессий и удаление проверены уже в staging. Местоположение и приватные инструкции не публикуются.

## 3. Google

В Google Cloud настроить OAuth consent screen и тестовых пользователей. Для текущего браузерного OAuth создать Web application client; в Authorized redirect URI вставить callback из Supabase Google provider. Client ID/Secret вводятся в Supabase. Затем AUTH_GOOGLE_ENABLED=true в обоих файлах. Firebase не является обязательным условием Google-входа через Supabase. [Инструкция Supabase](https://supabase.com/docs/guides/auth/social-login/auth-google).

Готовность: вход через системный браузер возвращает приложение, отмена не ломает навигацию, повторный вход возвращает тот же аккаунт. Не объединять личности по имени/email без подтверждения контроля.

## 4. Apple

Нужен Apple Developer account с доступом к идентификаторам. Текущий Bundle ID: `com.petfriendly.petfriendly`; Android package совпадает. Для текущего OAuth настроить Services ID, домен и return URL Supabase, signing key и client secret в Supabase. `.p8` не помещать в клиент. Apple OAuth secret требует обновления не реже чем раз в 6 месяцев. AUTH_APPLE_ENABLED включить только после настройки. [Инструкция Supabase](https://supabase.com/docs/guides/auth/social-login/auth-apple).

Готовность: вход, скрытый email и повторный вход проверены; план ротации записан. Покупка membership сейчас не авторизована и автоматически не выполняется.

## 5. Telegram

Настроить приложение входа через BotFather, зарегистрировать redirect URI из формы custom provider Supabase. Создать OIDC provider `custom:telegram`, issuer `https://oauth.telegram.org`, email_optional=true, scopes `openid profile`, без доступа к телефону и отправке сообщений. Client ID/Secret взять из Telegram Login, не подменять их произвольным bot token. Отдельного UserInfo endpoint у Telegram нет — совместимость чтения ID token проверяется в staging. PKCE и nonce-проверку оставить включёнными. [Telegram Login](https://core.telegram.org/bots/telegram-login), [Custom providers Supabase](https://supabase.com/docs/guides/auth/custom-oauth-providers).

Готовность: discovery и настоящий вход проверены в staging, аккаунт без email создаётся штатно. После проверки — AUTH_TELEGRAM_ENABLED=true. Telegram username не служит первичным идентификатором.

## 6. Firebase/APNs

В Firebase создать Android и iOS приложения с package/Bundle ID `com.petfriendly.petfriendly`. Скачать клиентские конфигурации в config/google-services.json и config/GoogleService-Info.plist (оба пути исключены из Git), затем импортировать:

```sh
python3 scripts/configure_services.py firebase --platform android --source config/google-services.json
python3 scripts/configure_services.py firebase --platform ios --source config/GoogleService-Info.plist
```

Импорт не перезаписывает Supabase/Mapbox, проверяет идентификатор приложения и разделяет разные Firebase App IDs платформ. Приложение инициализируется через FirebaseOptions, сгенерированные значения берутся из dart-define.

Для iOS настроить Push Notifications capability и Background Modes → Remote notifications в Xcode, загрузить APNs authentication key в Firebase. Signing зависит от Apple Team. Method swizzling для FCM оставить включённым. [FCM Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started?hl=en).

Firebase service account JSON хранить только в серверном секрете FIREBASE_SERVICE_ACCOUNT_JSON. Функцию dispatch-notifications вызывать защищённым серверным планировщиком; service-role credential не давать клиентам. Регистрация токена происходит после явного включения уведомлений пользователем. Push не содержит текст чата/адрес.

Готовность: локальное уведомление, foreground/background push, отказ в разрешении, ротация device token и удаление аккаунта проверены на устройствах. Серверная очередь сама по себе не подтверждает доставку.


## Текущее облачное окружение

Аккаунт Supabase создан пользователем. Организация petsfriendly, проект petfriendly-staging (ref cbkmxtplhcdomyeyrwyi), Free, eu-west-1 / Ireland. В форме создания отключено автоматическое раскрытие новых таблиц, включено автоматическое RLS. Проект сообщает Healthy. Облачные миграции и сервисы считаются настроенными только после фактического применения и проверок.

## Текущая техническая поставка

На 8 октября 2026 в cloud staging выполнены миграции **001–012** и импортированы **130 парков Минска**. Проверен публичный клиентский ключ (Data API HTTP 200), созданы отдельные `config/app.ios.staging.local.json` и `config/app.android.staging.local.json`, права 600, файлы исключены из Git. Локальные конфигурации сохранены. Проверен облачный вход синтетического подтверждённого аккаунта; доставка писем пользователям ещё не проверена.

Применён следующий пакет:

```sh
python3 scripts/prepare-staging.py --from-version 202610080009
```

`tooling/.logs/staging-bundle/202610080012/03-upgrade-from-009.sql` атомарно добавляет 010–012 с проверкой исходной версии и записью истории. `02-catalog.sql` импортирует 130 публичных парков Минска. Начальную поставку `01-schema.sql` нельзя запускать в уже существующей базе. Пакет и каталог применены после подтверждения пользователя; SQL Editor показал успешное выполнение.

010 — private Storage для фото профиля, питомца, сообщества. Загрузка через upload-photo: проверка активной сессии и владельца, PNG до 8 МБ и 1200×1200, серверное декодирование и новая JPEG-кодировка. Чтение через авторизованный Storage API с RLS и блокировками, без публичных/signed URLs. Изображения на клиенте только в памяти. Удаление аккаунта очищает принадлежащие ему объекты до удаления auth user; ошибки требуют повторной попытки. Экспорт JSON содержит ссылки на собственные объекты; полный архив с байтами фотографий пока не реализован. Замена удаляет старый объект; очистка осиротевших файлов после удаления отдельного питомца/сообщества и резервные копии требуют отдельного процесса до запуска.

011 — экран модерации предложенных мест и жалоб. Сервер требует управляемую сервером роль и aal2. Очереди до 50 записей, решения о жалобах записываются с основанием. Можно скрывать места и отзывы о помощнике. Проверка содержимого жалоб на чат/профиль, ответы помощника, апелляции и полный процесс расследования ещё не реализованы. Приватные инструкции выгула не включены в очередь.

012 — серверный поиск, фильтры и страницы по 40 мест; запросы ввода отложены на 300 мс, устаревшие ответы не заменяют текущую выдачу. Название, категория, допуск и избранное фильтруются до пагинации. Поиск «ближе ко мне» использует полный городской набор локально: точный GPS в поисковый API не передаётся. Карта по-прежнему загружает городской каталог пакетами по 500; пространственная выдача по viewport потребуется при масштабировании.

Все четыре функции **развёрнуты в cloud**. У city-catalog legacy Verify JWT отключён с согласия пользователя: действующий пользователь и отзыв сессии проверяются внутри функции/RPC. Для upload-photo и delete-account такое переключение ожидает отдельного подтверждения; до него новые JWT аккаунтов могут отклоняться шлюзом. dispatch-notifications сохраняет проверку JWT и серверную авторизацию RPC; FCM и планировщик не настроены. Облачная проверка dispatch: анонимный запрос отклонён (403), серверный запрос честно сообщает отсутствие FCM (503). Exact redirect `petfriendly://auth/callback` сохранён. Google, Apple и Telegram выключены до настройки и реального теста.

Google 2-Step Verification включена пользователем, Firebase Console доступна. Мастер создания PetFriendly staging подготовлен: ожидается согласие пользователя на Firebase Terms; Developer Program отключена. Firebase проект, FCM service account и APNs пока отсутствуют. Бесплатный Spark достаточен для FCM; платный Blaze не подключать. Apple Developer membership отсутствует; покупка не авторизована. Поэтому Apple-вход, APNs и TestFlight остаются внешними зависимостями. Пользователь подтвердил отсутствие домена/DNS. SMTP не настроен; домен не покупается автоматически.

Локальная проверка: 45 backend, 12 security, 18 submissions, 13 place reviews, 12 city catalog, 13 photos, 20 moderation/search — **133 успешные проверки**. Flutter: 21 тест и чистый анализ. Нативные iOS и Android сценарии email/search/pet прошли; 133 проверки относятся к локальному backend. Отдельно прошли 19 cloud-проверок: вход синтетического аккаунта, private bucket, поиск/пагинация, ограничение модерации, экспорт, TOTP, старый aal1 и отзыв JWT/import. Это не подтверждает email delivery, все положительные роли модератора, облачный realtime или push на физических устройствах. Android upload key создан локально; APK/AAB подписаны и проверены, ключ нужно безопасно сохранить перед публикацией.

## Продолжение — 9 октября 2026

Firebase проект **PetFriendly staging**, ID `petfriendly-staging`, номер `304245930767`, создан пользователем. Зарегистрированы Android и iOS приложения с `com.petfriendly.petfriendly`. Firebase-проект и приложения подтверждены UI; план Spark подтверждён UI: No-cost ($0/month). SDK параметры ещё не импортированы: кнопки скачивания конфигураций в in-app browser не вернули файл, а Google Cloud Credentials показывает ошибки API keys/OAuth clients/service accounts. Попытка перезагрузки не исправила ошибки. Google Auth Platform wizard доступен: App name подготовлен, support email ожидает согласия пользователя. Создание web OAuth client, серверного FCM account/key и секретов ещё не выполнено.

Для файла из Firebase Console → Project settings → General → Your apps:

```sh
python3 scripts/configure_services.py firebase --platform android --source config/google-services.json --config config/app.android.staging.local.json
python3 scripts/configure_services.py firebase --platform ios --source config/GoogleService-Info.plist --config config/app.ios.staging.local.json
```

Новый `--config` позволяет импортировать в выбранную staging-конфигурацию, сохраняя локальные настройки. Все параметры остаются клиентскими; серверные credentials не входят в app config.

Cloud realtime: **12 проверок прошли**. Настоящие WebSocket подписки, положительная доставка двум пользователям, отсутствие чужих уведомлений и текста чата в payload; после отзыва JWT уже открытая подписка не получает новые события, независимая авторизованная подписка продолжает работать. Старый JWT не читает сообщения. Скрипт `node scripts/verify_staging_realtime.mjs` ограничен единственным staging ref, использует синтетические accounts и удаляет их через Auth Admin. Сами сообщения/notifications/memberships удалены каскадно. После двух запусков остались четыре пустых conversation UUID без участников и сообщений: удаление через server Data API запрещено ACL. SQL inspection/cleanup этих служебных записей остаётся незавершённым. Не запускать этот скрипт против production.

Обнаружено: service_role в cloud не имеет SELECT на device_tokens (HTTP 403), что мешает push worker даже после подключения FCM. Подготовлена и применена локально **013_push_permissions**: только `select, delete` на device_tokens для server service_role, клиентские RLS не изменены. Cloud 013 ещё не применена; bundle `tooling/.logs/staging-bundle/202610090013/03-upgrade-from-012.sql` подготовлен в SQL Editor, ожидается согласие на права/предупреждение. upload-photo/delete-account legacy Verify JWT остаётся ON, согласие на переключение ожидается.

### Результаты согласованного продолжения

013 применена в cloud: сервер читает device_tokens (HTTP 200), клиентские RLS не менялись. upload-photo/delete-account legacy JWT OFF сохранён. 12 cloud security проверок MFA/deletion прошли: обычный anonymous/старый aal1 не удаляет, свежий aal2 удаляет auth account. 12 соответствующих local проверок также прошли.

Google branding сохранён и проверен: PetFriendly staging, согласованный support/contact email. User Data Policy принята после отдельного согласия. Web client «PetFriendly staging Supabase» подготовлен с единственным `https://cbkmxtplhcdomyeyrwyi.supabase.co/auth/v1/callback`; credentials ещё не созданы.

Облачный photo test обнаружил HTTP 200 и CF-Cache-Status HIT при повторном GET уже скачанного фото после блокировки; metadata query уже возвращает пустой набор, новый URL отклоняется. Поэтому local-only результат RLS не считается подтверждением немедленного cloud отзыва файлов. В upload-photo подготовлен cacheControl=0 для новых неизменяемых объектов. 15 local photo checks прошли; Deploy updates и cloud повторный тест ожидают согласования. Старые скачанные байты/копии отозвать нельзя. [Документация CDN](https://supabase.com/docs/guides/storage/cdn/smart-cdn).

### Firebase configs и проверка Google — 9 октября 2026

Пользователь завершил настройку провайдера. Google ENABLED проверен в dashboard и public Auth settings. Android/iOS Firebase files получены из Downloads, проверены по project ID/bundle ID, скопированы в ignored config с правами 600 и импортированы в staging app configs. Параметры не выводились. Firebase SDK успешно инициализирован в запущенной iOS trial-сборке; это не проверка доставки push.

Для проверки Google создан отдельный ignored `config/test-google.ios.local.json` с Google flag=true; базовые staging flags остаются выключенными до end-to-end проверки. Safari в iOS Simulator открыл настоящую страницу Google для callback staging. Ввод пароля/кодов передан пользователю; возврат и сессия ещё не проверены.

FCM auto-init выключен в AndroidManifest/Info.plist до явного разрешения. enable проверяет разрешение и наличие signed-in user, затем включает token registration. Серверный FCM account/secret, планировщик, Android background delivery, физические устройства и APNs всё ещё не настроены/не проверены.

Исправление фото: read-photo выдаёт байты только через POST после свежего getUser и metadata RLS; ответы private/no-store, запрос ограничен 1024 байт. 014 удаляет direct Storage SELECT policy; Flutter получает Uint8List через function invocation. 18 local photo проверок прошли, в том числе одинаковый POST после блока/отзыва, direct Storage deny, metadata strip, удаление объектов через listing и отказ старого JWT удалённого аккаунта. 21 Flutter test и analyze прошли. Cloud function/014/legacy switch подготовлены, ожидают подтверждения; cloud проверка ещё впереди.

### Проверено 9 октября: Google и выдача фото

Google OAuth ENABLED, реальный вход и восстановление сессии проверены на iOS Simulator. AUTH_GOOGLE_ENABLED включён в staging-конфигурациях обеих платформ; Android OAuth ещё требует отдельной проверки. Серверная выдача read-photo и миграция 014 применены с согласия пользователя, 18 облачных проверок прошли. Клиентские Firebase параметры импортированы для iOS/Android; это не подтверждает реальную push-доставку.

### Подготовка серверного FCM sender

В Google Cloud открыт несохранённый мастер petfriendly-fcm-sender для проекта petfriendly-staging. Предложена отдельная роль config/fcm-sender-role.json с единственным разрешением cloudmessaging.messages.create; аккаунт/роль ещё не созданы и право не назначено. Требуется согласие пользователя на новый серверный доступ. Создание и ввод приватного JSON-ключа выполняет пользователь; хранить его только в серверном секрете Supabase FIREBASE_SERVICE_ACCOUNT_JSON. Если Google не разрешит custom role для этого разрешения, более широкая роль не назначается автоматически.

## Обновление staging — 9 октября 2026, миграции 015–018

Cloud database обновлена с 014 до 018 одной транзакцией. Каталог: 130 мест. Новые серверные функции прошли 38 облачных API smoke-проверок; 150 локальных backend-проверок прошли до поставки. Права доступа и отзыв существующего JWT проверены без использования реальных личных данных. Авторизация отложена пользователем; Telegram flags остаются выключенными в основных конфигурациях, SMTP/FCM/APNs требуют следующих этапов.
