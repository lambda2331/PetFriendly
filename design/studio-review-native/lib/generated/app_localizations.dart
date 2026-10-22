import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_be.dart';
import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('be'),
    Locale('en'),
    Locale('pl'),
    Locale('ru'),
  ];

  /// Закрыть
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get message4ae50d30739d;

  /// Сначала дождитесь завершения сохранения
  ///
  /// In ru, this message translates to:
  /// **'Сначала дождитесь завершения сохранения'**
  String get message0cde2263f6e5;

  /// Демонстрационные данные · PetFriendly 0.1
  ///
  /// In ru, this message translates to:
  /// **'Демонстрационные данные · PetFriendly 0.1'**
  String get message3a74d52afa96;

  /// Часовой пояс места
  ///
  /// In ru, this message translates to:
  /// **'Часовой пояс места'**
  String get messagef97f5193d7b9;

  /// Выберите город в том же часовом поясе, что и место прогулки.
  ///
  /// In ru, this message translates to:
  /// **'Выберите город в том же часовом поясе, что и место прогулки.'**
  String get messagea1c06650b352;

  /// Поиск города или часового пояса
  ///
  /// In ru, this message translates to:
  /// **'Поиск города или часового пояса'**
  String get message207cc1623db9;

  /// Не нашли. Попробуйте название на английском.
  ///
  /// In ru, this message translates to:
  /// **'Не нашли. Попробуйте название на английском.'**
  String get message0fd2db57c60a;

  /// Фото сообщества не добавлено
  ///
  /// In ru, this message translates to:
  /// **'Фото сообщества не добавлено'**
  String get message309aff5a3a47;

  /// ДЕМО
  ///
  /// In ru, this message translates to:
  /// **'ДЕМО'**
  String get messagedf4542c99427;

  /// Новая переписка
  ///
  /// In ru, this message translates to:
  /// **'Новая переписка'**
  String get message517663fc884d;

  /// Светлая тема
  ///
  /// In ru, this message translates to:
  /// **'Светлая тема'**
  String get messageb45bbb457091;

  /// Тёмная тема
  ///
  /// In ru, this message translates to:
  /// **'Тёмная тема'**
  String get messageec1c55d8666a;

  /// Настройки
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get message7f17c7c62a7f;

  /// Запросы
  ///
  /// In ru, this message translates to:
  /// **'Запросы'**
  String get message76dd8ec92a26;

  /// Мои прогулки
  ///
  /// In ru, this message translates to:
  /// **'Мои прогулки'**
  String get messageba808f64fe23;

  /// Чаты
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get message3ba5efad4cd4;

  /// Я
  ///
  /// In ru, this message translates to:
  /// **'Я'**
  String get message8e7c6cca09b5;

  /// Рядом
  ///
  /// In ru, this message translates to:
  /// **'Рядом'**
  String get messagefa01903fa84d;

  /// Люди
  ///
  /// In ru, this message translates to:
  /// **'Люди'**
  String get messagef3920df09cfb;

  /// Выгул
  ///
  /// In ru, this message translates to:
  /// **'Выгул'**
  String get message583180ec5673;

  /// Профиль сейчас недоступен
  ///
  /// In ru, this message translates to:
  /// **'Профиль сейчас недоступен'**
  String get message07a3550a7841;

  /// Ваш режим
  ///
  /// In ru, this message translates to:
  /// **'Ваш режим'**
  String get message9ad513f109f4;

  /// Один аккаунт. Переписки и история остаются с вами.
  ///
  /// In ru, this message translates to:
  /// **'Один аккаунт. Переписки и история остаются с вами.'**
  String get message9869201614f7;

  /// Владелец питомца
  ///
  /// In ru, this message translates to:
  /// **'Владелец питомца'**
  String get messaged7d8c68ec39c;

  /// Помощник по выгулу
  ///
  /// In ru, this message translates to:
  /// **'Помощник по выгулу'**
  String get message6fc6234c12bc;

  /// Изменить роли
  ///
  /// In ru, this message translates to:
  /// **'Изменить роли'**
  String get messaged5b38ac02d9d;

  /// Не удалось переключить режим. Попробуйте снова.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось переключить режим. Попробуйте снова.'**
  String get message4650f6c5db0a;

  /// Помощник
  ///
  /// In ru, this message translates to:
  /// **'Помощник'**
  String get messageffcd1996d108;

  /// Владелец
  ///
  /// In ru, this message translates to:
  /// **'Владелец'**
  String get message926e3b436e29;

  /// Хороший разговор
  /// начинается рядом.
  ///
  /// In ru, this message translates to:
  /// **'Хороший разговор\nначинается рядом.'**
  String get message4b1f8b9cc594;

  /// Люди, встречи и сообщества.
  ///
  /// In ru, this message translates to:
  /// **'Люди, встречи и сообщества.'**
  String get messagebc652384a792;

  /// Пока нет переписок
  ///
  /// In ru, this message translates to:
  /// **'Пока нет переписок'**
  String get messagec55412d56d36;

  /// Познакомьтесь с людьми рядом или присоединитесь к встрече.
  ///
  /// In ru, this message translates to:
  /// **'Познакомьтесь с людьми рядом или присоединитесь к встрече.'**
  String get message8c1e4b83e79a;

  /// Найти компанию
  ///
  /// In ru, this message translates to:
  /// **'Найти компанию'**
  String get messagefd788d92b6eb;

  /// Загружаем переписки
  ///
  /// In ru, this message translates to:
  /// **'Загружаем переписки'**
  String get messagebff943ef3d9c;

  /// Не удалось обновить переписки. Проверьте соединение.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить переписки. Проверьте соединение.'**
  String get message8e208c91b4ce;

  /// Повторить
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get message9e506acb19ac;

  /// Вы
  ///
  /// In ru, this message translates to:
  /// **'Вы'**
  String get messageadb4032a9ddb;

  /// Начать переписку
  ///
  /// In ru, this message translates to:
  /// **'Начать переписку'**
  String get message83d643155ac8;

  /// Непрочитанных сообщений: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Непрочитанных сообщений: {p0}'**
  String message10624d724642(String p0);

  /// Не удалось выбрать вложение. Попробуйте другой файл.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выбрать вложение. Попробуйте другой файл.'**
  String get message2025d80f28a2;

  /// Вы — владелец
  ///
  /// In ru, this message translates to:
  /// **'Вы — владелец'**
  String get messagebcb7c732b1b5;

  /// Вы — помощник
  ///
  /// In ru, this message translates to:
  /// **'Вы — помощник'**
  String get message86b790812012;

  /// Только участники переписки
  ///
  /// In ru, this message translates to:
  /// **'Только участники переписки'**
  String get message01d1dda443b6;

  /// Демо-чат · сообщения только в памяти
  ///
  /// In ru, this message translates to:
  /// **'Демо-чат · сообщения только в памяти'**
  String get message1153059d04bb;

  /// Прогулка · {p0}
  ///
  /// In ru, this message translates to:
  /// **'Прогулка · {p0}'**
  String message56042ae0fd22(String p0);

  /// Не удалось загрузить сообщения. Повторить
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить сообщения. Повторить'**
  String get message5ba8f80d5941;

  /// Участник
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get message76ffe26d00be;

  /// Открыть сообщество
  ///
  /// In ru, this message translates to:
  /// **'Открыть сообщество'**
  String get message15f087779585;

  /// Отправляется…
  ///
  /// In ru, this message translates to:
  /// **'Отправляется…'**
  String get message53726bb80b10;

  /// Не отправлено · повторить
  ///
  /// In ru, this message translates to:
  /// **'Не отправлено · повторить'**
  String get message3a705aeb2673;

  /// Подготовка вложения
  ///
  /// In ru, this message translates to:
  /// **'Подготовка вложения'**
  String get message11a0e7efda26;

  /// {p0} · {p1} МБ
  ///
  /// In ru, this message translates to:
  /// **'{p0} · {p1} МБ'**
  String message9e516806abec(String p0, String p1);

  /// Убрать вложение
  ///
  /// In ru, this message translates to:
  /// **'Убрать вложение'**
  String get messagedc25e7c7bd60;

  /// Добавить фото или видео
  ///
  /// In ru, this message translates to:
  /// **'Добавить фото или видео'**
  String get messagedfa87887f1f4;

  /// Вложения сейчас недоступны. Попробуйте позже.
  ///
  /// In ru, this message translates to:
  /// **'Вложения сейчас недоступны. Попробуйте позже.'**
  String get messagedb4a9d7ae70d;

  /// Написать сообщение…
  ///
  /// In ru, this message translates to:
  /// **'Написать сообщение…'**
  String get message986720f40262;

  /// Отправить
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get message76dcf737a6cd;

  /// Не удалось открыть переписку. Повторите попытку.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть переписку. Повторите попытку.'**
  String get messagee989f2d35ea9;

  /// Повторить загрузку
  ///
  /// In ru, this message translates to:
  /// **'Повторить загрузку'**
  String get message4ead60795573;

  /// Поиск по имени
  ///
  /// In ru, this message translates to:
  /// **'Поиск по имени'**
  String get message595b385ea9de;

  /// Пока некого выбрать. Другой участник появится здесь после регистрации.
  ///
  /// In ru, this message translates to:
  /// **'Пока некого выбрать. Другой участник появится здесь после регистрации.'**
  String get message03e1f5d395bd;

  /// Создать сообщество
  ///
  /// In ru, this message translates to:
  /// **'Создать сообщество'**
  String get message2a680b43f27a;

  /// Не удалось открыть вложение. Повторите попытку.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть вложение. Повторите попытку.'**
  String get message5f3e915498d8;

  /// Видео · {p0} с
  ///
  /// In ru, this message translates to:
  /// **'Видео · {p0} с'**
  String message32a151b43602(String p0);

  /// Фото · повторить
  ///
  /// In ru, this message translates to:
  /// **'Фото · повторить'**
  String get message437c1adb16c9;

  /// Фото в переписке
  ///
  /// In ru, this message translates to:
  /// **'Фото в переписке'**
  String get message160247465439;

  /// Фото
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get messagefb8ffc7377b8;

  /// Видео
  ///
  /// In ru, this message translates to:
  /// **'Видео'**
  String get message8e7b9894c7ef;

  /// Формат видео не поддерживается на устройстве.
  ///
  /// In ru, this message translates to:
  /// **'Формат видео не поддерживается на устройстве.'**
  String get message2dd1a313a442;

  /// Пауза
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get message03498e395a43;

  /// Воспроизвести
  ///
  /// In ru, this message translates to:
  /// **'Воспроизвести'**
  String get messageedf6515d2ea9;

  /// Включить звук
  ///
  /// In ru, this message translates to:
  /// **'Включить звук'**
  String get messagea07b8e6b73f0;

  /// Выключить звук
  ///
  /// In ru, this message translates to:
  /// **'Выключить звук'**
  String get message68f09f6a08ca;

  /// Решение сохранено
  ///
  /// In ru, this message translates to:
  /// **'Решение сохранено'**
  String get message8d4b630efae4;

  /// Не удалось сохранить решение. Проверьте MFA и соединение.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить решение. Проверьте MFA и соединение.'**
  String get message8789b0aefe4b;

  /// Скрыть публикацию
  ///
  /// In ru, this message translates to:
  /// **'Скрыть публикацию'**
  String get message365f1bb58d48;

  /// Завершить рассмотрение
  ///
  /// In ru, this message translates to:
  /// **'Завершить рассмотрение'**
  String get message83dc42a1964c;

  /// Основание решения
  ///
  /// In ru, this message translates to:
  /// **'Основание решения'**
  String get message6af8da01ed23;

  /// Отмена
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get message0ec753be8df9;

  /// Сохранить
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get message4864057d626a;

  /// Модерация
  ///
  /// In ru, this message translates to:
  /// **'Модерация'**
  String get message80ae616e0bcf;

  /// Обновить
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get messagec2f668e54fb6;

  /// Требуется роль модератора и подтверждённая MFA
  ///
  /// In ru, this message translates to:
  /// **'Требуется роль модератора и подтверждённая MFA'**
  String get message97f5fe1bc1d8;

  /// Предложенные места
  ///
  /// In ru, this message translates to:
  /// **'Предложенные места'**
  String get messageb3f67b2b19c8;

  /// Опубликовать
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать'**
  String get messageb3c43a26007d;

  /// Отклонить
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get message5047a0698663;

  /// Нет мест на проверке
  ///
  /// In ru, this message translates to:
  /// **'Нет мест на проверке'**
  String get messagec20a4e93008e;

  /// Жалобы
  ///
  /// In ru, this message translates to:
  /// **'Жалобы'**
  String get message19a91f50d916;

  /// Рассмотрено
  ///
  /// In ru, this message translates to:
  /// **'Рассмотрено'**
  String get message8ff52a34a0f9;

  /// Скрыть
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get message10729118a0e1;

  /// Нет новых жалоб
  ///
  /// In ru, this message translates to:
  /// **'Нет новых жалоб'**
  String get messagec9181d60ae97;

  /// Очередь: до 50 записей. После рассмотрения загрузится следующая партия.
  ///
  /// In ru, this message translates to:
  /// **'Очередь: до 50 записей. После рассмотрения загрузится следующая партия.'**
  String get messagefffdbf73ef8f;

  /// Подтвердите вход
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите вход'**
  String get message075aec641b2a;

  /// Через {p0}
  ///
  /// In ru, this message translates to:
  /// **'Через {p0}'**
  String message34a031ac7bfc(String p0);

  /// С паролем
  ///
  /// In ru, this message translates to:
  /// **'С паролем'**
  String get messagec0b50b959962;

  /// Повторно войдите через связанный провайдер
  ///
  /// In ru, this message translates to:
  /// **'Повторно войдите через связанный провайдер'**
  String get messagefb344a91df7b;

  /// Повторная проверка не пройдена
  ///
  /// In ru, this message translates to:
  /// **'Повторная проверка не пройдена'**
  String get message290cc0423110;

  /// Эта функция доступна после подключения аккаунта
  ///
  /// In ru, this message translates to:
  /// **'Эта функция доступна после подключения аккаунта'**
  String get messagef941f25a6e97;

  /// Ваши данные
  ///
  /// In ru, this message translates to:
  /// **'Ваши данные'**
  String get message81b2cec8b96d;

  /// Не удалось завершить операцию. Повторите позже.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось завершить операцию. Повторите позже.'**
  String get messageeffe73d2bed6;

  /// Безопасность
  ///
  /// In ru, this message translates to:
  /// **'Безопасность'**
  String get messaged4fab139643b;

  /// Личное
  /// остаётся личным.
  ///
  /// In ru, this message translates to:
  /// **'Личное\nостаётся личным.'**
  String get message47302540dbfa;

  /// Публично показывается только район. Точные инструкции выгула доступны участникам договорённости.
  ///
  /// In ru, this message translates to:
  /// **'Публично показывается только район. Точные инструкции выгула доступны участникам договорённости.'**
  String get message74737e8cb674;

  /// Аккаунт
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get message5b16fcdd971f;

  /// Сейчас используется демонстрационный профиль.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас используется демонстрационный профиль.'**
  String get messageabd3be7f1255;

  /// Двухфакторная защита
  ///
  /// In ru, this message translates to:
  /// **'Двухфакторная защита'**
  String get message637e4413bc0a;

  /// Код из приложения-аутентификатора
  ///
  /// In ru, this message translates to:
  /// **'Код из приложения-аутентификатора'**
  String get message1fcf0a112a1e;

  /// Активные сессии
  ///
  /// In ru, this message translates to:
  /// **'Активные сессии'**
  String get message1237e008781b;

  /// Текущая сессия
  ///
  /// In ru, this message translates to:
  /// **'Текущая сессия'**
  String get message837d2985a1bd;

  /// Другая сессия
  ///
  /// In ru, this message translates to:
  /// **'Другая сессия'**
  String get message4f3252f14176;

  /// Не удалось загрузить сессии
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить сессии'**
  String get message4be5a62431e9;

  /// Выйти со всех устройств
  ///
  /// In ru, this message translates to:
  /// **'Выйти со всех устройств'**
  String get message47bc6dd18ad0;

  /// Посмотреть экспорт данных
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть экспорт данных'**
  String get message7dc4678d2f15;

  /// Удалить аккаунт?
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт?'**
  String get message3f04fb4b1325;

  /// Профиль и связанные личные данные будут удалены. Отменить это действие нельзя.
  ///
  /// In ru, this message translates to:
  /// **'Профиль и связанные личные данные будут удалены. Отменить это действие нельзя.'**
  String get message6fd44e9f07c8;

  /// Удалить
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get message86ea33aef5e9;

  /// Удалить аккаунт
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get message0e42e93d21a2;

  /// Не удалось выйти. Повторите попытку.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выйти. Повторите попытку.'**
  String get messagefca1d5a23d7a;

  /// Выйти на этом устройстве
  ///
  /// In ru, this message translates to:
  /// **'Выйти на этом устройстве'**
  String get message534f4a068e11;

  /// Подтвердите действие
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите действие'**
  String get message6128d9a9ebf4;

  /// Пароль
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get message14f7c63cc128;

  /// Код MFA, если включена
  ///
  /// In ru, this message translates to:
  /// **'Код MFA, если включена'**
  String get messagea98fc7736194;

  /// Подтвердить
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get message0467ae4bb88b;

  /// Повторный вход
  /// через {p0}.
  ///
  /// In ru, this message translates to:
  /// **'Повторный вход\nчерез {p0}.'**
  String messageb4833a8d044f(String p0);

  /// Выберите тот же аккаунт {p0}, с которым вошли в PetFriendly.
  ///
  /// In ru, this message translates to:
  /// **'Выберите тот же аккаунт {p0}, с которым вошли в PetFriendly.'**
  String message6311a1409975(String p0);

  /// Выбран другой аккаунт. Действие не будет выполнено.
  ///
  /// In ru, this message translates to:
  /// **'Выбран другой аккаунт. Действие не будет выполнено.'**
  String get message7cb9ab8aeaae;

  /// Проверка истекла. Вернитесь и начните действие заново.
  ///
  /// In ru, this message translates to:
  /// **'Проверка истекла. Вернитесь и начните действие заново.'**
  String get messagef7d551559582;

  /// Проверьте код и повторите попытку.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте код и повторите попытку.'**
  String get messagee74833a9a9a7;

  /// Подтвердить код
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить код'**
  String get message359b06363129;

  /// Продолжить действие
  ///
  /// In ru, this message translates to:
  /// **'Продолжить действие'**
  String get messagee0c92a580912;

  /// Не удалось открыть {p0}. Попробуйте позже.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть {p0}. Попробуйте позже.'**
  String message0240fd39a824(String p0);

  /// Войти через {p0}
  ///
  /// In ru, this message translates to:
  /// **'Войти через {p0}'**
  String message0046fc427f8e(String p0);

  /// Завершите вход на странице {p0} и вернитесь в приложение.
  ///
  /// In ru, this message translates to:
  /// **'Завершите вход на странице {p0} и вернитесь в приложение.'**
  String messagee47f17c9cfc9(String p0);

  /// Повторить вход в аккаунт
  ///
  /// In ru, this message translates to:
  /// **'Повторить вход в аккаунт'**
  String get messagea24e5f71797a;

  /// Откройте письмо для {p0} и подтвердите адрес.
  ///
  /// In ru, this message translates to:
  /// **'Откройте письмо для {p0} и подтвердите адрес.'**
  String message258dedfee5f0(String p0);

  /// После подтверждения вернитесь в приложение. Если открыли письмо на другом устройстве, войдите с email и паролем.
  ///
  /// In ru, this message translates to:
  /// **'После подтверждения вернитесь в приложение. Если открыли письмо на другом устройстве, войдите с email и паролем.'**
  String get message85f5ac7c500d;

  /// Адрес подтверждён — войти
  ///
  /// In ru, this message translates to:
  /// **'Адрес подтверждён — войти'**
  String get message6d017188288f;

  /// Если адрес ожидает подтверждения, письмо будет отправлено.
  ///
  /// In ru, this message translates to:
  /// **'Если адрес ожидает подтверждения, письмо будет отправлено.'**
  String get message1bc57726d4bd;

  /// Повторная отправка недоступна. Попробуйте позже.
  ///
  /// In ru, this message translates to:
  /// **'Повторная отправка недоступна. Попробуйте позже.'**
  String get message1749e230614a;

  /// Отправить повторно через {p0} с
  ///
  /// In ru, this message translates to:
  /// **'Отправить повторно через {p0} с'**
  String message1ff55dc792bd(String p0);

  /// Отправить письмо повторно
  ///
  /// In ru, this message translates to:
  /// **'Отправить письмо повторно'**
  String get message0a62985acad6;

  /// Изменить email
  ///
  /// In ru, this message translates to:
  /// **'Изменить email'**
  String get message6260994326b8;

  /// Новый пароль
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get message5e611d705a8d;

  /// Верните доступ
  /// к аккаунту.
  ///
  /// In ru, this message translates to:
  /// **'Верните доступ\nк аккаунту.'**
  String get messageb932b45ad2c3;

  /// Новый пароль · минимум 12 символов
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль · минимум 12 символов'**
  String get message317fc4baf5ae;

  /// Повторите пароль
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль'**
  String get messagec39e27d0b1d8;

  /// Подтвердите смену пароля кодом из письма.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите смену пароля кодом из письма.'**
  String get message71fbc05fc24a;

  /// Код подтверждения
  ///
  /// In ru, this message translates to:
  /// **'Код подтверждения'**
  String get messagebfee5d1b490b;

  /// Код отправлен
  ///
  /// In ru, this message translates to:
  /// **'Код отправлен'**
  String get messagef8f6b19f3421;

  /// Не удалось отправить код. Повторите позже.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить код. Повторите позже.'**
  String get message51068c92928f;

  /// Отправить код ещё раз
  ///
  /// In ru, this message translates to:
  /// **'Отправить код ещё раз'**
  String get message5c280f2a5253;

  /// Проверьте длину и совпадение паролей
  ///
  /// In ru, this message translates to:
  /// **'Проверьте длину и совпадение паролей'**
  String get message5e0ce8fb6af7;

  /// Пароль изменён
  ///
  /// In ru, this message translates to:
  /// **'Пароль изменён'**
  String get messaged39175aa7a79;

  /// Не удалось изменить пароль. Повторите восстановление доступа.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить пароль. Повторите восстановление доступа.'**
  String get message826df6bd083d;

  /// Сохраняем…
  ///
  /// In ru, this message translates to:
  /// **'Сохраняем…'**
  String get message73bfb5e42401;

  /// Изменить пароль
  ///
  /// In ru, this message translates to:
  /// **'Изменить пароль'**
  String get message5e4fa6bdb7a2;

  /// Начнём с прогулки
  ///
  /// In ru, this message translates to:
  /// **'Начнём с прогулки'**
  String get messageabc2b08d8eb8;

  /// Что вам сейчас нужно?
  ///
  /// In ru, this message translates to:
  /// **'Что вам сейчас нужно?'**
  String get messageea03f645bdb8;

  /// Профиль готов. Выберите первый шаг — остальные разделы всегда рядом.
  ///
  /// In ru, this message translates to:
  /// **'Профиль готов. Выберите первый шаг — остальные разделы всегда рядом.'**
  String get message16bd824605ab;

  /// Найти место для прогулки
  ///
  /// In ru, this message translates to:
  /// **'Найти место для прогулки'**
  String get messageba88deb93bf0;

  /// Парки и площадки в выбранном городе
  ///
  /// In ru, this message translates to:
  /// **'Парки и площадки в выбранном городе'**
  String get message881f8007ff59;

  /// Познакомиться с владельцами
  ///
  /// In ru, this message translates to:
  /// **'Познакомиться с владельцами'**
  String get message63c692ad6d67;

  /// Люди рядом и сообщества по интересам
  ///
  /// In ru, this message translates to:
  /// **'Люди рядом и сообщества по интересам'**
  String get message2a8ed08c7e40;

  /// Найти помощь с выгулом
  ///
  /// In ru, this message translates to:
  /// **'Найти помощь с выгулом'**
  String get messagee8e728fbce78;

  /// Посмотреть раздел и создать заявку
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть раздел и создать заявку'**
  String get message2e28d4db2479;

  /// Перейти к карте
  ///
  /// In ru, this message translates to:
  /// **'Перейти к карте'**
  String get messagea8b4e67065ab;

  /// Предпросмотр: Auth не подключён
  ///
  /// In ru, this message translates to:
  /// **'Предпросмотр: Auth не подключён'**
  String get message6821d156899e;

  /// Слишком много попыток. Попробуйте позже.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много попыток. Попробуйте позже.'**
  String get messagee9f3958bbcb2;

  /// Не удалось войти. Проверьте данные и подтверждение почты.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти. Проверьте данные и подтверждение почты.'**
  String get message925df3235222;

  /// Сервис входа недоступен. Попробуйте позже.
  ///
  /// In ru, this message translates to:
  /// **'Сервис входа недоступен. Попробуйте позже.'**
  String get message1b10862a4cae;

  /// Предпросмотр: {p0} не подключён
  ///
  /// In ru, this message translates to:
  /// **'Предпросмотр: {p0} не подключён'**
  String messagec3b87ac59dfa(String p0);

  /// {p0} ещё не подключён
  ///
  /// In ru, this message translates to:
  /// **'{p0} ещё не подключён'**
  String message380aa0757439(String p0);

  /// Провайдер ещё не настроен на сервере
  ///
  /// In ru, this message translates to:
  /// **'Провайдер ещё не настроен на сервере'**
  String get message27975fb33e13;

  /// Подтвердите email
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите email'**
  String get messaged7c997fb176f;

  /// Создать аккаунт
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get message8d29ff5c8493;

  /// Войти в PetFriendly
  ///
  /// In ru, this message translates to:
  /// **'Войти в PetFriendly'**
  String get message23c1898aef01;

  /// Ваша компания для прогулок.
  ///
  /// In ru, this message translates to:
  /// **'Ваша компания для прогулок.'**
  String get message34fb4991e532;

  /// Демо входа · не вводите реальные пароли.
  ///
  /// In ru, this message translates to:
  /// **'Демо входа · не вводите реальные пароли.'**
  String get message56f72e4a5294;

  /// Введите email
  ///
  /// In ru, this message translates to:
  /// **'Введите email'**
  String get messagee643c76bc43d;

  /// Не менее 12 символов
  ///
  /// In ru, this message translates to:
  /// **'Не менее 12 символов'**
  String get message727ca0beac8b;

  /// Подождите…
  ///
  /// In ru, this message translates to:
  /// **'Подождите…'**
  String get message9674b15f97cf;

  /// Войти
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get message939e95a11ddd;

  /// Уже есть аккаунт
  ///
  /// In ru, this message translates to:
  /// **'Уже есть аккаунт'**
  String get messagebbdb97ba6709;

  /// Если аккаунт существует, письмо отправлено
  ///
  /// In ru, this message translates to:
  /// **'Если аккаунт существует, письмо отправлено'**
  String get message580318597c8b;

  /// Забыли пароль?
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get message42127ad3c475;

  /// или войти через
  ///
  /// In ru, this message translates to:
  /// **'или войти через'**
  String get message73694d652138;

  /// Внешние способы входа подключаются в тестовом окружении.
  ///
  /// In ru, this message translates to:
  /// **'Внешние способы входа подключаются в тестовом окружении.'**
  String get message2a1cc7bbb30b;

  /// Не удалось подготовить двухфакторную проверку
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подготовить двухфакторную проверку'**
  String get messagebc0cf27895f2;

  /// Подтвердите вход.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите вход.'**
  String get message973044930cbd;

  /// Добавьте этот ключ в приложение-аутентификатор. Никому его не передавайте.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте этот ключ в приложение-аутентификатор. Никому его не передавайте.'**
  String get message614e0ffeb9f7;

  /// Код из аутентификатора
  ///
  /// In ru, this message translates to:
  /// **'Код из аутентификатора'**
  String get message615d4a668757;

  /// Код не подошёл. Попробуйте ещё раз.
  ///
  /// In ru, this message translates to:
  /// **'Код не подошёл. Попробуйте ещё раз.'**
  String get message20c41bb522e7;

  /// Проверяем…
  ///
  /// In ru, this message translates to:
  /// **'Проверяем…'**
  String get message350473a96835;

  /// Открываем место…
  ///
  /// In ru, this message translates to:
  /// **'Открываем место…'**
  String get message6a52a8394a11;

  /// Отзыв добавлен в демо · до перезапуска.
  ///
  /// In ru, this message translates to:
  /// **'Отзыв добавлен в демо · до перезапуска.'**
  String get messageb63d30ea1b5b;

  /// Спасибо! Отзыв опубликован.
  ///
  /// In ru, this message translates to:
  /// **'Спасибо! Отзыв опубликован.'**
  String get messagec09627f596b0;

  /// Не удалось отправить. Возможно, вы уже оценили это место.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить. Возможно, вы уже оценили это место.'**
  String get message7e7f95af3e24;

  /// Правила посещения могут измениться. Уточните допуск животных перед визитом.
  ///
  /// In ru, this message translates to:
  /// **'Правила посещения могут измениться. Уточните допуск животных перед визитом.'**
  String get message4dfa61dad124;

  /// Убрать из избранного
  ///
  /// In ru, this message translates to:
  /// **'Убрать из избранного'**
  String get messaged9f48a75fd7a;

  /// В избранное
  ///
  /// In ru, this message translates to:
  /// **'В избранное'**
  String get message5da9e0e83bf6;

  /// На проверке · пока видно только вам
  ///
  /// In ru, this message translates to:
  /// **'На проверке · пока видно только вам'**
  String get message877c1baa61c1;

  /// Загружаем подтверждения правил…
  ///
  /// In ru, this message translates to:
  /// **'Загружаем подтверждения правил…'**
  String get message086515e11e12;

  /// Подтверждения не загрузились · повторить
  ///
  /// In ru, this message translates to:
  /// **'Подтверждения не загрузились · повторить'**
  String get messagecdf6b2c0b7d9;

  /// Проверить сведения о допуске
  ///
  /// In ru, this message translates to:
  /// **'Проверить сведения о допуске'**
  String get message7f9809ed9895;

  /// Показать на карте
  ///
  /// In ru, this message translates to:
  /// **'Показать на карте'**
  String get message86f399f20ecb;

  /// Уточнить данные
  ///
  /// In ru, this message translates to:
  /// **'Уточнить данные'**
  String get messagea844e74aa79a;

  /// Отзывы
  ///
  /// In ru, this message translates to:
  /// **'Отзывы'**
  String get message8dc6ee4c95f5;

  /// Загружаем отзывы…
  ///
  /// In ru, this message translates to:
  /// **'Загружаем отзывы…'**
  String get message9f2c895cf878;

  /// Отзывы не загрузились · повторить
  ///
  /// In ru, this message translates to:
  /// **'Отзывы не загрузились · повторить'**
  String get messageb40d1863ee07;

  /// Вы уже оценили это место
  ///
  /// In ru, this message translates to:
  /// **'Вы уже оценили это место'**
  String get messagef15a050c9945;

  /// Отзывы станут доступны после публикации места.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы станут доступны после публикации места.'**
  String get message7f51476ba243;

  /// Пока нет отзывов.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет отзывов.'**
  String get messagec73e5ef41ce1;

  /// Показать ещё отзывы
  ///
  /// In ru, this message translates to:
  /// **'Показать ещё отзывы'**
  String get messagebbf6601c4a66;

  /// Показаны последние отзывы.
  ///
  /// In ru, this message translates to:
  /// **'Показаны последние отзывы.'**
  String get messagea29c9787fc4a;

  /// Оставить отзыв
  ///
  /// In ru, this message translates to:
  /// **'Оставить отзыв'**
  String get message476475f94a7f;

  /// Ваше впечатление
  ///
  /// In ru, this message translates to:
  /// **'Ваше впечатление'**
  String get message1fc8ddf57951;

  /// Выберите оценку для публикации.
  ///
  /// In ru, this message translates to:
  /// **'Выберите оценку для публикации.'**
  String get message3e373ebc196e;

  /// Оценка: {p0} из 5. Можно публиковать.
  ///
  /// In ru, this message translates to:
  /// **'Оценка: {p0} из 5. Можно публиковать.'**
  String message413fa6dbf7e8(String p0);

  /// {p0} из 5
  ///
  /// In ru, this message translates to:
  /// **'{p0} из 5'**
  String message1f38ce4d9e66(String p0);

  /// Комментарий (необязательно)
  ///
  /// In ru, this message translates to:
  /// **'Комментарий (необязательно)'**
  String get message3279857538dd;

  /// Отзыв публичный. Не указывайте личные сведения.
  ///
  /// In ru, this message translates to:
  /// **'Отзыв публичный. Не указывайте личные сведения.'**
  String get messaged5ff51f71399;

  /// Публикуем…
  ///
  /// In ru, this message translates to:
  /// **'Публикуем…'**
  String get messageb2b4a8f23969;

  /// Опубликовать отзыв
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать отзыв'**
  String get message2bbbb4c9d269;

  /// Минск
  ///
  /// In ru, this message translates to:
  /// **'Минск'**
  String get message4a414a60a4dd;

  /// Не удалось найти город на карте. Можно переместить карту вручную.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось найти город на карте. Можно переместить карту вручную.'**
  String get messageecdae5a020e0;

  /// Ожидаем местоположение. Картой уже можно пользоваться.
  ///
  /// In ru, this message translates to:
  /// **'Ожидаем местоположение. Картой уже можно пользоваться.'**
  String get messageb0b3783ba96c;

  /// Не удалось определить местоположение. Попробуйте ещё раз.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить местоположение. Попробуйте ещё раз.'**
  String get message28911c46d23f;

  /// Местоположение недоступно. Картой можно пользоваться без него.
  ///
  /// In ru, this message translates to:
  /// **'Местоположение недоступно. Картой можно пользоваться без него.'**
  String get message2f01fc6e6e82;

  /// Не удалось изменить масштаб.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить масштаб.'**
  String get message40cfb76b3c40;

  /// Закрыть карту
  ///
  /// In ru, this message translates to:
  /// **'Закрыть карту'**
  String get message1a3fccfcd521;

  /// Обзор карты
  ///
  /// In ru, this message translates to:
  /// **'Обзор карты'**
  String get messagecabb8a9cab58;

  /// Места · {p0}
  ///
  /// In ru, this message translates to:
  /// **'Места · {p0}'**
  String message3ee5bef85b19(String p0);

  /// Список мест
  ///
  /// In ru, this message translates to:
  /// **'Список мест'**
  String get message89e527dd6f01;

  /// На весь экран
  ///
  /// In ru, this message translates to:
  /// **'На весь экран'**
  String get messagefe0e0481ce50;

  /// Приблизить
  ///
  /// In ru, this message translates to:
  /// **'Приблизить'**
  String get message0c937db5aac6;

  /// Отдалить
  ///
  /// In ru, this message translates to:
  /// **'Отдалить'**
  String get messagefea897eb050a;

  /// Моё местоположение
  ///
  /// In ru, this message translates to:
  /// **'Моё местоположение'**
  String get messagee775733e3b0e;

  /// Места рядом
  ///
  /// In ru, this message translates to:
  /// **'Места рядом'**
  String get messageb17b9b86b846;

  /// Места списком
  ///
  /// In ru, this message translates to:
  /// **'Места списком'**
  String get message594067e3bfcd;

  /// Загружаем места города…
  ///
  /// In ru, this message translates to:
  /// **'Загружаем места города…'**
  String get message27e3dbbfc497;

  /// Места временно недоступны
  ///
  /// In ru, this message translates to:
  /// **'Места временно недоступны'**
  String get message25ba851ce48e;

  /// Подтверждения сейчас недоступны
  ///
  /// In ru, this message translates to:
  /// **'Подтверждения сейчас недоступны'**
  String get message63fd87d7165e;

  /// Проверяем подтверждения…
  ///
  /// In ru, this message translates to:
  /// **'Проверяем подтверждения…'**
  String get messagee2bdb385e7f4;

  /// С питомцем
  ///
  /// In ru, this message translates to:
  /// **'С питомцем'**
  String get messagea10c68ba4075;

  /// Подтверждение от {p0}
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение от {p0}'**
  String messagea44b2ae67718(String p0);

  /// Условия: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Условия: {p0}'**
  String message183e219d00b5(String p0);

  /// Публичное подтверждение: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Публичное подтверждение: {p0}'**
  String message6122f5c77171(String p0);

  /// Правила могут измениться. Уточните их перед визитом.
  ///
  /// In ru, this message translates to:
  /// **'Правила могут измениться. Уточните их перед визитом.'**
  String get message7c59e4b64a85;

  /// Уточните правила у администрации места перед визитом.
  ///
  /// In ru, this message translates to:
  /// **'Уточните правила у администрации места перед визитом.'**
  String get messageba29e6e28466;

  /// Отметка каталога: {p0}. Это не подтверждение сообщества или заведения.
  ///
  /// In ru, this message translates to:
  /// **'Отметка каталога: {p0}. Это не подтверждение сообщества или заведения.'**
  String message60d60563138f(String p0);

  /// Допуск питомцев не уточнён
  ///
  /// In ru, this message translates to:
  /// **'Допуск питомцев не уточнён'**
  String get message7a0fc176d5c2;

  /// В каталоге есть неподтверждённое описание правил. Подтверждающих сведений пока нет.
  ///
  /// In ru, this message translates to:
  /// **'В каталоге есть неподтверждённое описание правил. Подтверждающих сведений пока нет.'**
  String get message8bf9548437b6;

  /// Выберите дату реального подтверждения.
  ///
  /// In ru, this message translates to:
  /// **'Выберите дату реального подтверждения.'**
  String get messaged6d4e85f8d2e;

  /// Сведения о допуске опубликованы.
  ///
  /// In ru, this message translates to:
  /// **'Сведения о допуске опубликованы.'**
  String get messagebc708ecc5d39;

  /// Для модерации нужен действующий вход с MFA и роль модератора.
  ///
  /// In ru, this message translates to:
  /// **'Для модерации нужен действующий вход с MFA и роль модератора.'**
  String get message6f6af34d9eb3;

  /// Не удалось опубликовать сведения. Проверьте дату, основание и соединение.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось опубликовать сведения. Проверьте дату, основание и соединение.'**
  String get messagede5188320574;

  /// Отозвать подтверждение?
  ///
  /// In ru, this message translates to:
  /// **'Отозвать подтверждение?'**
  String get message7cac34abe6d1;

  /// Место снова будет показываться без подтверждения допуска.
  ///
  /// In ru, this message translates to:
  /// **'Место снова будет показываться без подтверждения допуска.'**
  String get messageb6b3ae84813e;

  /// Оставить
  ///
  /// In ru, this message translates to:
  /// **'Оставить'**
  String get messagea90b7cbc92c1;

  /// Отозвать
  ///
  /// In ru, this message translates to:
  /// **'Отозвать'**
  String get message9b16ca539e60;

  /// Подтверждение отозвано.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение отозвано.'**
  String get message67f253006df7;

  /// Не удалось отозвать подтверждение. Проверьте вход с MFA и соединение.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отозвать подтверждение. Проверьте вход с MFA и соединение.'**
  String get messageb43a0b443bc8;

  /// Правила для питомцев
  ///
  /// In ru, this message translates to:
  /// **'Правила для питомцев'**
  String get message9e6268c91e70;

  /// Только для модераторов. Нужны реальные сведения сообщества или заведения. Не публикуйте личные адреса и инструкции по уходу.
  ///
  /// In ru, this message translates to:
  /// **'Только для модераторов. Нужны реальные сведения сообщества или заведения. Не публикуйте личные адреса и инструкции по уходу.'**
  String get message609e486c29d6;

  /// Кто подтвердил правила
  ///
  /// In ru, this message translates to:
  /// **'Кто подтвердил правила'**
  String get messagea1dafced06ec;

  /// Сообщество
  ///
  /// In ru, this message translates to:
  /// **'Сообщество'**
  String get message477e5b714f95;

  /// Заведение
  ///
  /// In ru, this message translates to:
  /// **'Заведение'**
  String get message878a1b007147;

  /// Выберите источник
  ///
  /// In ru, this message translates to:
  /// **'Выберите источник'**
  String get messagee77efef50de5;

  /// Правило для собак
  ///
  /// In ru, this message translates to:
  /// **'Правило для собак'**
  String get message47724a7ae271;

  /// С собаками можно
  ///
  /// In ru, this message translates to:
  /// **'С собаками можно'**
  String get message50e2c047734c;

  /// Только на поводке
  ///
  /// In ru, this message translates to:
  /// **'Только на поводке'**
  String get message38fc3621c869;

  /// С собаками нельзя
  ///
  /// In ru, this message translates to:
  /// **'С собаками нельзя'**
  String get message909e57c7764b;

  /// Выберите правило
  ///
  /// In ru, this message translates to:
  /// **'Выберите правило'**
  String get message0f5097cac2b5;

  /// Дата реального подтверждения
  ///
  /// In ru, this message translates to:
  /// **'Дата реального подтверждения'**
  String get message823ac9a06768;

  /// Выбрать дату подтверждения
  ///
  /// In ru, this message translates to:
  /// **'Выбрать дату подтверждения'**
  String get messagebdaabd06e10e;

  /// Основание подтверждения
  ///
  /// In ru, this message translates to:
  /// **'Основание подтверждения'**
  String get messagef0fa28c4cf6a;

  /// Опишите подтверждающие сведения
  ///
  /// In ru, this message translates to:
  /// **'Опишите подтверждающие сведения'**
  String get messagef130c00bbaba;

  /// Условия, если подтверждены
  ///
  /// In ru, this message translates to:
  /// **'Условия, если подтверждены'**
  String get messagefdb7bc74ac73;

  /// Публичное подтверждение заведения · https
  ///
  /// In ru, this message translates to:
  /// **'Публичное подтверждение заведения · https'**
  String get messagec1d65d583b6b;

  /// Публичная ссылка · необязательно
  ///
  /// In ru, this message translates to:
  /// **'Публичная ссылка · необязательно'**
  String get messageb030a8ae56c8;

  /// Добавьте подтверждение заведения
  ///
  /// In ru, this message translates to:
  /// **'Добавьте подтверждение заведения'**
  String get messagea4033c342d84;

  /// Нужна полная ссылка https
  ///
  /// In ru, this message translates to:
  /// **'Нужна полная ссылка https'**
  String get messagee3bde4b7d4b6;

  /// Подтвердить вход с MFA
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить вход с MFA'**
  String get message183924112be1;

  /// Сохраняем сведения. Поля временно недоступны.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняем сведения. Поля временно недоступны.'**
  String get messagebe6a3e29af88;

  /// Опубликовать подтверждение
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать подтверждение'**
  String get message3b54c45d35d3;

  /// Отозвать подтверждение
  ///
  /// In ru, this message translates to:
  /// **'Отозвать подтверждение'**
  String get messaged23ecba34e2d;

  /// Выберите город
  ///
  /// In ru, this message translates to:
  /// **'Выберите город'**
  String get message1fb5d089d1f6;

  /// Найти город
  ///
  /// In ru, this message translates to:
  /// **'Найти город'**
  String get messagebe36cb78e360;

  /// Очистить поиск
  ///
  /// In ru, this message translates to:
  /// **'Очистить поиск'**
  String get messagea736131fb81e;

  /// Другие города
  ///
  /// In ru, this message translates to:
  /// **'Другие города'**
  String get message8a1b17f3eadb;

  /// Выбрать «{p0}»
  ///
  /// In ru, this message translates to:
  /// **'Выбрать «{p0}»'**
  String messageb6163b2a807a(String p0);

  /// Другой город
  ///
  /// In ru, this message translates to:
  /// **'Другой город'**
  String get message8d9b0ff09510;

  /// Рядом со мной
  ///
  /// In ru, this message translates to:
  /// **'Рядом со мной'**
  String get message0fe11a127f09;

  /// Выбран сейчас
  ///
  /// In ru, this message translates to:
  /// **'Выбран сейчас'**
  String get message9055e89ca230;

  /// Местоположение недоступно. Выберите город вручную.
  ///
  /// In ru, this message translates to:
  /// **'Местоположение недоступно. Выберите город вручную.'**
  String get messageebc80ccdfd81;

  /// Хороший день
  /// для прогулки.
  ///
  /// In ru, this message translates to:
  /// **'Хороший день\nдля прогулки.'**
  String get message955e0000838c;

  /// И новой компании для вас двоих.
  ///
  /// In ru, this message translates to:
  /// **'И новой компании для вас двоих.'**
  String get messagea50134fbdba7;

  /// Хороший день для прогулки.
  ///
  /// In ru, this message translates to:
  /// **'Хороший день для прогулки.'**
  String get message76335e1fd1f9;

  /// Добавить место
  ///
  /// In ru, this message translates to:
  /// **'Добавить место'**
  String get message77f62bda6a39;

  /// Сбросить
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get message058f162d2926;

  /// Название или категория
  ///
  /// In ru, this message translates to:
  /// **'Название или категория'**
  String get messagedba0c9fc1cc8;

  /// Категория
  ///
  /// In ru, this message translates to:
  /// **'Категория'**
  String get message19c85838e63f;

  /// Фильтры мест
  ///
  /// In ru, this message translates to:
  /// **'Фильтры мест'**
  String get message3d17b5d1c49a;

  /// Фильтры мест · {p0}
  ///
  /// In ru, this message translates to:
  /// **'Фильтры мест · {p0}'**
  String messagebd287a5e9a02(String p0);

  /// Сбросить фильтры
  ///
  /// In ru, this message translates to:
  /// **'Сбросить фильтры'**
  String get message03ead01c5b2d;

  /// Показать места
  ///
  /// In ru, this message translates to:
  /// **'Показать места'**
  String get messagee649fbf77d5b;

  /// Убрать фильтр допуска
  ///
  /// In ru, this message translates to:
  /// **'Убрать фильтр допуска'**
  String get message0c11f47078b9;

  /// Избранное
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get messageb880e6a10520;

  /// Убрать избранное
  ///
  /// In ru, this message translates to:
  /// **'Убрать избранное'**
  String get message3834f482a88b;

  /// Ближе ко мне
  ///
  /// In ru, this message translates to:
  /// **'Ближе ко мне'**
  String get message04f096a7809c;

  /// Сортировать по названию
  ///
  /// In ru, this message translates to:
  /// **'Сортировать по названию'**
  String get message66964fcc834e;

  /// Загружаем места…
  ///
  /// In ru, this message translates to:
  /// **'Загружаем места…'**
  String get messagecb9b47907637;

  /// Количество мест недоступно
  ///
  /// In ru, this message translates to:
  /// **'Количество мест недоступно'**
  String get message0d1f8e4e6617;

  /// {p0} мест
  ///
  /// In ru, this message translates to:
  /// **'{p0} мест'**
  String message14850c1974ce(String p0);

  /// Места не загрузились · повторить
  ///
  /// In ru, this message translates to:
  /// **'Места не загрузились · повторить'**
  String get message6519c61cb7b2;

  /// Мои места не загрузились · повторить
  ///
  /// In ru, this message translates to:
  /// **'Мои места не загрузились · повторить'**
  String get message5cc41ad1f714;

  /// Загружаем места
  ///
  /// In ru, this message translates to:
  /// **'Загружаем места'**
  String get message331f33cc07ba;

  /// Попробуйте загрузить места ещё раз
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте загрузить места ещё раз'**
  String get messageb541ec9ba08b;

  /// Ничего не нашлось
  ///
  /// In ru, this message translates to:
  /// **'Ничего не нашлось'**
  String get message84f85ce5066e;

  /// Пока нет мест — добавьте первое
  ///
  /// In ru, this message translates to:
  /// **'Пока нет мест — добавьте первое'**
  String get message7db7a8dd6353;

  /// Показать ещё
  ///
  /// In ru, this message translates to:
  /// **'Показать ещё'**
  String get messageb53ec8fb330b;

  /// © OpenStreetMap contributors · ODbL. Отметки допуска из OSM требуют уточнения перед визитом.
  ///
  /// In ru, this message translates to:
  /// **'© OpenStreetMap contributors · ODbL. Отметки допуска из OSM требуют уточнения перед визитом.'**
  String get messageae667e29b799;

  /// Подборка
  ///
  /// In ru, this message translates to:
  /// **'Подборка'**
  String get messagec3d316e42464;

  /// Все места
  ///
  /// In ru, this message translates to:
  /// **'Все места'**
  String get messaged0a7b29c4963;

  /// Сортировка
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get messageed030118aad8;

  /// По названию
  ///
  /// In ru, this message translates to:
  /// **'По названию'**
  String get message33f30bf7231f;

  /// Предложить исправление
  ///
  /// In ru, this message translates to:
  /// **'Предложить исправление'**
  String get message9fe4f347ca78;

  /// Отзыв о месте
  ///
  /// In ru, this message translates to:
  /// **'Отзыв о месте'**
  String get message3aa007f0be71;

  /// Что стоит
  /// уточнить?
  ///
  /// In ru, this message translates to:
  /// **'Что стоит\nуточнить?'**
  String get message796f94d5a701;

  /// Поделитесь
  /// впечатлением.
  ///
  /// In ru, this message translates to:
  /// **'Поделитесь\nвпечатлением.'**
  String get messageaf68461951b3;

  /// Оценка
  ///
  /// In ru, this message translates to:
  /// **'Оценка'**
  String get messagebb3c79d7155b;

  /// Например, правила входа с собакой
  ///
  /// In ru, this message translates to:
  /// **'Например, правила входа с собакой'**
  String get message56a21d1cf64b;

  /// Ваш отзыв
  ///
  /// In ru, this message translates to:
  /// **'Ваш отзыв'**
  String get messagebe3cb9fe8f62;

  /// Исправление будет проверено.
  ///
  /// In ru, this message translates to:
  /// **'Исправление будет проверено.'**
  String get message5dba63f62d7b;

  /// Комментарий будет публичным. Не указывайте личные сведения.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий будет публичным. Не указывайте личные сведения.'**
  String get message3fcb3649b230;

  /// Отправляем. Поля временно недоступны.
  ///
  /// In ru, this message translates to:
  /// **'Отправляем. Поля временно недоступны.'**
  String get message85c034301ee0;

  /// Опишите исправление
  ///
  /// In ru, this message translates to:
  /// **'Опишите исправление'**
  String get messageb26bc8000fc1;

  /// Отправлено
  ///
  /// In ru, this message translates to:
  /// **'Отправлено'**
  String get messageadd0be798503;

  /// Не удалось отправить. Возможно, отзыв уже опубликован.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить. Возможно, отзыв уже опубликован.'**
  String get message5a34fef4feab;

  /// Отправляем…
  ///
  /// In ru, this message translates to:
  /// **'Отправляем…'**
  String get message4cbdc4d6d28e;

  /// Ищем встречи рядом
  ///
  /// In ru, this message translates to:
  /// **'Ищем встречи рядом'**
  String get messageed9365a5c198;

  /// Встречи сейчас недоступны
  ///
  /// In ru, this message translates to:
  /// **'Встречи сейчас недоступны'**
  String get message5402369b901c;

  /// Встречи рядом
  ///
  /// In ru, this message translates to:
  /// **'Встречи рядом'**
  String get messaged01d885857e6;

  /// Откройте встречи и повторите загрузку.
  ///
  /// In ru, this message translates to:
  /// **'Откройте встречи и повторите загрузку.'**
  String get message3a560fa595c2;

  /// В {p0} пока нет встреч.
  ///
  /// In ru, this message translates to:
  /// **'В {p0} пока нет встреч.'**
  String message237991afdb98(String p0);

  /// Создать встречу
  ///
  /// In ru, this message translates to:
  /// **'Создать встречу'**
  String get message15948e737bd7;

  /// Открыть встречи
  ///
  /// In ru, this message translates to:
  /// **'Открыть встречи'**
  String get message0441784192fd;

  /// На проверке · видно только вам
  ///
  /// In ru, this message translates to:
  /// **'На проверке · видно только вам'**
  String get messageb89e6a6393c3;

  /// Парк
  ///
  /// In ru, this message translates to:
  /// **'Парк'**
  String get message20098560d9b9;

  /// Карта мест рядом
  ///
  /// In ru, this message translates to:
  /// **'Карта мест рядом'**
  String get message64ac191fe57d;

  /// Мест на карте: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Мест на карте: {p0}'**
  String message25aa2370e769(String p0);

  /// Загрузка карты
  ///
  /// In ru, this message translates to:
  /// **'Загрузка карты'**
  String get messagec7373346fde5;

  /// Ваше положение отмечено синим
  ///
  /// In ru, this message translates to:
  /// **'Ваше положение отмечено синим'**
  String get messagefea57c06eb11;

  /// Карта пока недоступна
  ///
  /// In ru, this message translates to:
  /// **'Карта пока недоступна'**
  String get messageb640e182bbd9;

  /// Места можно посмотреть списком.
  ///
  /// In ru, this message translates to:
  /// **'Места можно посмотреть списком.'**
  String get message4ac4e956f44d;

  /// Открыть список мест
  ///
  /// In ru, this message translates to:
  /// **'Открыть список мест'**
  String get message824d50c1306c;

  /// Отметьте место на карте
  ///
  /// In ru, this message translates to:
  /// **'Отметьте место на карте'**
  String get messagee88221ca074d;

  /// Место отправлено на проверку. Отметка пока видна только вам.
  ///
  /// In ru, this message translates to:
  /// **'Место отправлено на проверку. Отметка пока видна только вам.'**
  String get messagec5723887df15;

  /// Место добавлено в демо-карту до перезапуска.
  ///
  /// In ru, this message translates to:
  /// **'Место добавлено в демо-карту до перезапуска.'**
  String get messageca55353362f3;

  /// Не удалось добавить место. Проверьте данные и соединение.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось добавить место. Проверьте данные и соединение.'**
  String get messagec538d84c2037;

  /// Ваше открытие для других
  ///
  /// In ru, this message translates to:
  /// **'Ваше открытие для других'**
  String get message8391acdda563;

  /// Добавляйте публичные места. Не отмечайте свой дом, частный адрес или положение другого человека.
  ///
  /// In ru, this message translates to:
  /// **'Добавляйте публичные места. Не отмечайте свой дом, частный адрес или положение другого человека.'**
  String get message2c2558bc13a8;

  /// Название
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get message3de49828e86a;

  /// Введите название
  ///
  /// In ru, this message translates to:
  /// **'Введите название'**
  String get messagedd6e1a08b642;

  /// Кафе
  ///
  /// In ru, this message translates to:
  /// **'Кафе'**
  String get message62fa090db476;

  /// Площадка
  ///
  /// In ru, this message translates to:
  /// **'Площадка'**
  String get messagebf4f87eb47a1;

  /// Ресторан
  ///
  /// In ru, this message translates to:
  /// **'Ресторан'**
  String get messaged50c4d0059d4;

  /// Зоомагазин
  ///
  /// In ru, this message translates to:
  /// **'Зоомагазин'**
  String get message81de872b4d82;

  /// Ветклиника
  ///
  /// In ru, this message translates to:
  /// **'Ветклиника'**
  String get message0aa2129cf1eb;

  /// Отметить на карте
  ///
  /// In ru, this message translates to:
  /// **'Отметить на карте'**
  String get messagecd9eda0841f8;

  /// Точка выбрана
  ///
  /// In ru, this message translates to:
  /// **'Точка выбрана'**
  String get messagec9ca66feb886;

  /// Что здесь интересного?
  ///
  /// In ru, this message translates to:
  /// **'Что здесь интересного?'**
  String get message19961f25d7e8;

  /// Публичное описание, без личных сведений
  ///
  /// In ru, this message translates to:
  /// **'Публичное описание, без личных сведений'**
  String get messagec7e7a2d08df0;

  /// Допуск питомцев пока не уточнён. После проверки место появится в общем каталоге.
  ///
  /// In ru, this message translates to:
  /// **'Допуск питомцев пока не уточнён. После проверки место появится в общем каталоге.'**
  String get messagedd4f0f8ea2d6;

  /// Перед отправкой отметьте место на карте.
  ///
  /// In ru, this message translates to:
  /// **'Перед отправкой отметьте место на карте.'**
  String get messagedfcf7f73dfb5;

  /// Отправляем место…
  ///
  /// In ru, this message translates to:
  /// **'Отправляем место…'**
  String get messagee53283d97cd4;

  /// Карта недоступна. Попробуйте открыть её снова.
  ///
  /// In ru, this message translates to:
  /// **'Карта недоступна. Попробуйте открыть её снова.'**
  String get message118793e6c3de;

  /// Город не найден. Переместите карту вручную.
  ///
  /// In ru, this message translates to:
  /// **'Город не найден. Переместите карту вручную.'**
  String get messagea65dd0bba407;

  /// Карта не настроена. Выбор точки недоступен.
  ///
  /// In ru, this message translates to:
  /// **'Карта не настроена. Выбор точки недоступен.'**
  String get messageba91dd132b53;

  /// Выбор точки станет доступен после загрузки карты.
  ///
  /// In ru, this message translates to:
  /// **'Выбор точки станет доступен после загрузки карты.'**
  String get message5770f389be1e;

  /// Карта недоступна. Попробуйте ещё раз.
  ///
  /// In ru, this message translates to:
  /// **'Карта недоступна. Попробуйте ещё раз.'**
  String get message076589d75107;

  /// Выбираем точку…
  ///
  /// In ru, this message translates to:
  /// **'Выбираем точку…'**
  String get messagef4fd42038f19;

  /// Выбрать эту точку
  ///
  /// In ru, this message translates to:
  /// **'Выбрать эту точку'**
  String get message0f0e5c4000a8;

  /// Выбранная точка места
  ///
  /// In ru, this message translates to:
  /// **'Выбранная точка места'**
  String get message32e54a35bc78;

  /// Ваша репутация
  ///
  /// In ru, this message translates to:
  /// **'Ваша репутация'**
  String get message67de1dc534eb;

  /// Профиль владельца
  ///
  /// In ru, this message translates to:
  /// **'Профиль владельца'**
  String get messaged5a1d7f0c34a;

  /// Профиль не загрузился · повторить
  ///
  /// In ru, this message translates to:
  /// **'Профиль не загрузился · повторить'**
  String get message7ff40d0d0a9d;

  /// Профиль недоступен
  ///
  /// In ru, this message translates to:
  /// **'Профиль недоступен'**
  String get messagefac58c3b106f;

  /// Опыт как владельца
  ///
  /// In ru, this message translates to:
  /// **'Опыт как владельца'**
  String get message99cfd50063ba;

  /// Репутация сейчас недоступна
  ///
  /// In ru, this message translates to:
  /// **'Репутация сейчас недоступна'**
  String get message2272fd1e7146;

  /// Пока нет отзывов
  ///
  /// In ru, this message translates to:
  /// **'Пока нет отзывов'**
  String get message6bc4c140f03f;

  /// {p0} из 5 · {p1} отзывов
  ///
  /// In ru, this message translates to:
  /// **'{p0} из 5 · {p1} отзывов'**
  String message137fe6edcbfd(String p0, String p1);

  /// {p0} завершённых договорённостей
  ///
  /// In ru, this message translates to:
  /// **'{p0} завершённых договорённостей'**
  String message387f0bbc18d0(String p0);

  /// Отзывы помогают принять решение, но не гарантируют безопасность.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы помогают принять решение, но не гарантируют безопасность.'**
  String get messagea95477ee566a;

  /// Отзывы помощников
  ///
  /// In ru, this message translates to:
  /// **'Отзывы помощников'**
  String get messagef13f587ce835;

  /// {p0} из 5 · {p1}
  ///
  /// In ru, this message translates to:
  /// **'{p0} из 5 · {p1}'**
  String message3d797c1d2978(String p0, String p1);

  /// Ответ владельца: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Ответ владельца: {p0}'**
  String message881a224a7e44(String p0);

  /// Пожаловаться на отзыв
  ///
  /// In ru, this message translates to:
  /// **'Пожаловаться на отзыв'**
  String get messagea57d557c565d;

  /// Первый отзыв появится после подтверждённой прогулки.
  ///
  /// In ru, this message translates to:
  /// **'Первый отзыв появится после подтверждённой прогулки.'**
  String get message28ca4fed00a5;

  /// Пожаловаться на профиль
  ///
  /// In ru, this message translates to:
  /// **'Пожаловаться на профиль'**
  String get messageb1a4510cd3b2;

  /// Ответ на отзыв
  ///
  /// In ru, this message translates to:
  /// **'Ответ на отзыв'**
  String get messagecf535012ff9b;

  /// Ответ не опубликован. Текст сохранён — попробуйте снова.
  ///
  /// In ru, this message translates to:
  /// **'Ответ не опубликован. Текст сохранён — попробуйте снова.'**
  String get message4e409e120a03;

  /// Опубликовать ответ
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать ответ'**
  String get message3b68ffeddea4;

  /// Позже
  ///
  /// In ru, this message translates to:
  /// **'Позже'**
  String get messagefd042c9a3a77;

  /// Ответить
  ///
  /// In ru, this message translates to:
  /// **'Ответить'**
  String get messagec6f4665b45af;

  /// Заблокировать пользователя?
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать пользователя?'**
  String get message026ff0fde5ce;

  /// Новые личные сообщения и доступ к профилям будут ограничены.
  ///
  /// In ru, this message translates to:
  /// **'Новые личные сообщения и доступ к профилям будут ограничены.'**
  String get message242c55c538e0;

  /// Назад
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get messagef6dab074d7bb;

  /// Заблокировать
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать'**
  String get message0d57053c516f;

  /// Не удалось выполнить действие. Попробуйте снова.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить действие. Попробуйте снова.'**
  String get message96b0ec7561a1;

  /// Обсудить прогулку
  ///
  /// In ru, this message translates to:
  /// **'Обсудить прогулку'**
  String get messaged9a212ef5ccb;

  /// Помощь с выгулом
  ///
  /// In ru, this message translates to:
  /// **'Помощь с выгулом'**
  String get messagea81c74fa845a;

  /// Попросите соседей о помощи или помогите сами.
  ///
  /// In ru, this message translates to:
  /// **'Попросите соседей о помощи или помогите сами.'**
  String get message658dd455ca5e;

  /// На прогулку
  /// с хорошей компанией.
  ///
  /// In ru, this message translates to:
  /// **'На прогулку\nс хорошей компанией.'**
  String get message9a9e515e0756;

  /// Попросить о выгуле
  ///
  /// In ru, this message translates to:
  /// **'Попросить о выгуле'**
  String get message8138af81bee7;

  /// Мои договорённости
  ///
  /// In ru, this message translates to:
  /// **'Мои договорённости'**
  String get message9a5177c6a23d;

  /// Прогулка с {p0}
  ///
  /// In ru, this message translates to:
  /// **'Прогулка с {p0}'**
  String message9749a2115aac(String p0);

  /// Запросы на прогулку
  ///
  /// In ru, this message translates to:
  /// **'Запросы на прогулку'**
  String get message67f7ac13a1ef;

  /// Пока нет запросов на прогулку.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет запросов на прогулку.'**
  String get message0ceb71d45778;

  /// Питомец
  ///
  /// In ru, this message translates to:
  /// **'Питомец'**
  String get message366010a8d085;

  /// {p0} мин
  ///
  /// In ru, this message translates to:
  /// **'{p0} мин'**
  String messagef3b7422bb310(String p0);

  /// {p0} откликов
  ///
  /// In ru, this message translates to:
  /// **'{p0} откликов'**
  String message3d038bb2ce29(String p0);

  /// Подробнее и отклики
  ///
  /// In ru, this message translates to:
  /// **'Подробнее и отклики'**
  String get messagef9f44250ed68;

  /// История прогулок
  ///
  /// In ru, this message translates to:
  /// **'История прогулок'**
  String get messagea078bfd6abc2;

  /// Помощники
  ///
  /// In ru, this message translates to:
  /// **'Помощники'**
  String get message51ae927ac586;

  /// Выбрать помощника?
  ///
  /// In ru, this message translates to:
  /// **'Выбрать помощника?'**
  String get message0201495c2bfa;

  /// Отменить заявку?
  ///
  /// In ru, this message translates to:
  /// **'Отменить заявку?'**
  String get message484310166485;

  /// Вы создадите договорённость с выбранным помощником. Сначала просмотрите его профиль и обсудите детали прогулки. Отзывы помогают принять решение, но не гарантируют безопасность.
  ///
  /// In ru, this message translates to:
  /// **'Вы создадите договорённость с выбранным помощником. Сначала просмотрите его профиль и обсудите детали прогулки. Отзывы помогают принять решение, но не гарантируют безопасность.'**
  String get messaged15f5f5612a6;

  /// Открытая заявка больше не будет принимать отклики.
  ///
  /// In ru, this message translates to:
  /// **'Открытая заявка больше не будет принимать отклики.'**
  String get messagedcda30343452;

  /// Выбрать помощника
  ///
  /// In ru, this message translates to:
  /// **'Выбрать помощника'**
  String get message94dd8db7ef3a;

  /// Отменить заявку
  ///
  /// In ru, this message translates to:
  /// **'Отменить заявку'**
  String get message38c31abdc2d9;

  /// Не удалось обновить заявку. Проверьте соединение и обновите её: статус мог измениться.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить заявку. Проверьте соединение и обновите её: статус мог измениться.'**
  String get messageeb3808cdd076;

  /// Заявка на выгул
  ///
  /// In ru, this message translates to:
  /// **'Заявка на выгул'**
  String get message6d2b7d187ba6;

  /// Заявка не загрузилась · повторить
  ///
  /// In ru, this message translates to:
  /// **'Заявка не загрузилась · повторить'**
  String get messageee5e75f7e5fd;

  /// Заявка недоступна
  ///
  /// In ru, this message translates to:
  /// **'Заявка недоступна'**
  String get message02dc810e40cb;

  /// Обновить статус заявки
  ///
  /// In ru, this message translates to:
  /// **'Обновить статус заявки'**
  String get message3478d495e092;

  /// Профиль и репутация владельца
  ///
  /// In ru, this message translates to:
  /// **'Профиль и репутация владельца'**
  String get messagead02ad789086;

  /// Чат договорённости
  ///
  /// In ru, this message translates to:
  /// **'Чат договорённости'**
  String get messageda067f8393c2;

  /// {p0} минут
  ///
  /// In ru, this message translates to:
  /// **'{p0} минут'**
  String message1d37f80e1d09(String p0);

  /// Приватные инструкции
  ///
  /// In ru, this message translates to:
  /// **'Приватные инструкции'**
  String get message44709768863d;

  /// Помощник: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Помощник: {p0}'**
  String message068b46482b10(String p0);

  /// Отменить отклик
  ///
  /// In ru, this message translates to:
  /// **'Отменить отклик'**
  String get messagea8f2829e97ad;

  /// Предложить помощь
  ///
  /// In ru, this message translates to:
  /// **'Предложить помощь'**
  String get message602f41cfb486;

  /// Отклики
  ///
  /// In ru, this message translates to:
  /// **'Отклики'**
  String get message06cbeae325ab;

  /// Пока никто не откликнулся.
  ///
  /// In ru, this message translates to:
  /// **'Пока никто не откликнулся.'**
  String get message1c11119e08de;

  /// Профиль и отзывы
  ///
  /// In ru, this message translates to:
  /// **'Профиль и отзывы'**
  String get message844f5b518e8d;

  /// Добавить тестовый отклик Саши
  ///
  /// In ru, this message translates to:
  /// **'Добавить тестовый отклик Саши'**
  String get messagefd506239a903;

  /// Демо: помощник начал прогулку
  ///
  /// In ru, this message translates to:
  /// **'Демо: помощник начал прогулку'**
  String get message80c0e381378b;

  /// Начать прогулку
  ///
  /// In ru, this message translates to:
  /// **'Начать прогулку'**
  String get messagedb943fa7ada9;

  /// Демо: помощник завершил прогулку
  ///
  /// In ru, this message translates to:
  /// **'Демо: помощник завершил прогулку'**
  String get message1e98007eb41a;

  /// Завершить прогулку
  ///
  /// In ru, this message translates to:
  /// **'Завершить прогулку'**
  String get messageed67b4499488;

  /// Подтвердить завершение
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить завершение'**
  String get message4fdde1330fb6;

  /// Оценить помощника
  ///
  /// In ru, this message translates to:
  /// **'Оценить помощника'**
  String get message84a9f8f3891e;

  /// Оценить владельца
  ///
  /// In ru, this message translates to:
  /// **'Оценить владельца'**
  String get message021fbdbf2254;

  /// Доступность отзыва не загрузилась · повторить
  ///
  /// In ru, this message translates to:
  /// **'Доступность отзыва не загрузилась · повторить'**
  String get message34b477d79551;

  /// Сообщить о проблеме
  ///
  /// In ru, this message translates to:
  /// **'Сообщить о проблеме'**
  String get messageb3cdaecc4112;

  /// Не удалось открыть переписку. Проверьте соединение и попробуйте снова.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть переписку. Проверьте соединение и попробуйте снова.'**
  String get message984c19519d3b;

  /// Личные сообщения пользователю «{p0}» будут недоступны.
  ///
  /// In ru, this message translates to:
  /// **'Личные сообщения пользователю «{p0}» будут недоступны.'**
  String message8d2572a4ef7f(String p0);

  /// Пользователь заблокирован
  ///
  /// In ru, this message translates to:
  /// **'Пользователь заблокирован'**
  String get message82fcaddd93c0;

  /// Не удалось заблокировать пользователя. Проверьте соединение и попробуйте снова.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось заблокировать пользователя. Проверьте соединение и попробуйте снова.'**
  String get messageec28638c2572;

  /// Ваш профиль помощника
  ///
  /// In ru, this message translates to:
  /// **'Ваш профиль помощника'**
  String get message18620f06195e;

  /// Профиль помощника
  ///
  /// In ru, this message translates to:
  /// **'Профиль помощника'**
  String get message043abf2ad90d;

  /// Загружаем профиль помощника
  ///
  /// In ru, this message translates to:
  /// **'Загружаем профиль помощника'**
  String get messaged93392a45c0a;

  /// Загружаем профиль…
  ///
  /// In ru, this message translates to:
  /// **'Загружаем профиль…'**
  String get message72bb02a89f31;

  /// Профиль не загрузился
  ///
  /// In ru, this message translates to:
  /// **'Профиль не загрузился'**
  String get message877e1469098d;

  /// Обновляем профиль
  ///
  /// In ru, this message translates to:
  /// **'Обновляем профиль'**
  String get message92b10f9c44a7;

  /// Не удалось обновить профиль. Показаны ранее загруженные сведения.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить профиль. Показаны ранее загруженные сведения.'**
  String get messagec20c124c2a79;

  /// Опыт как помощника
  ///
  /// In ru, this message translates to:
  /// **'Опыт как помощника'**
  String get message5a66960212f5;

  /// Отзывы и опыт помогают принять решение, но не гарантируют безопасность.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы и опыт помогают принять решение, но не гарантируют безопасность.'**
  String get message20606e69b7d0;

  /// Редактировать профиль
  ///
  /// In ru, this message translates to:
  /// **'Редактировать профиль'**
  String get message0755f11f125b;

  /// Открываем чат…
  ///
  /// In ru, this message translates to:
  /// **'Открываем чат…'**
  String get message924e5fd0cc8e;

  /// Действия с профилем
  ///
  /// In ru, this message translates to:
  /// **'Действия с профилем'**
  String get messagedf8147f7087b;

  /// Действия
  ///
  /// In ru, this message translates to:
  /// **'Действия'**
  String get message9978ac34b293;

  /// Блокируем пользователя…
  ///
  /// In ru, this message translates to:
  /// **'Блокируем пользователя…'**
  String get messageb1c89d34ee5e;

  /// Повторить блокировку
  ///
  /// In ru, this message translates to:
  /// **'Повторить блокировку'**
  String get messageb5edd2329ffe;

  /// Отзывы о выгуле
  ///
  /// In ru, this message translates to:
  /// **'Отзывы о выгуле'**
  String get messagebee1d49ce082;

  /// Отзыв о владельце
  ///
  /// In ru, this message translates to:
  /// **'Отзыв о владельце'**
  String get message19cf50ac61b0;

  /// Отзыв о помощнике
  ///
  /// In ru, this message translates to:
  /// **'Отзыв о помощнике'**
  String get messageb40b6c61e3bd;

  /// Как прошла прогулка?
  ///
  /// In ru, this message translates to:
  /// **'Как прошла прогулка?'**
  String get messagef8cc719e17c5;

  /// Отзыв о {p0}
  ///
  /// In ru, this message translates to:
  /// **'Отзыв о {p0}'**
  String messagedaed281f8d81(String p0);

  /// Прогулка с {p0} · {p1}
  ///
  /// In ru, this message translates to:
  /// **'Прогулка с {p0} · {p1}'**
  String message99a6175391a5(String p0, String p1);

  /// Отзыв доступен участнику после подтверждения владельца, один раз по каждой договорённости.
  ///
  /// In ru, this message translates to:
  /// **'Отзыв доступен участнику после подтверждения владельца, один раз по каждой договорённости.'**
  String get message0df0695807df;

  /// Выберите оценку
  ///
  /// In ru, this message translates to:
  /// **'Выберите оценку'**
  String get message43c522c733e4;

  /// Комментарий
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get message829038c9ec94;

  /// Отзыв будет публичным. Не указывайте адреса и контакты.
  ///
  /// In ru, this message translates to:
  /// **'Отзыв будет публичным. Не указывайте адреса и контакты.'**
  String get message036fb5113b63;

  /// Не удалось опубликовать отзыв. Текст сохранён — проверьте соединение и повторите.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось опубликовать отзыв. Текст сохранён — проверьте соединение и повторите.'**
  String get message70bf9258922d;

  /// Ответ опубликован
  ///
  /// In ru, this message translates to:
  /// **'Ответ опубликован'**
  String get message0fdadd6e99ac;

  /// Ответить на отзыв
  ///
  /// In ru, this message translates to:
  /// **'Ответить на отзыв'**
  String get messagedfaf51b365d6;

  /// Изменить ответ
  ///
  /// In ru, this message translates to:
  /// **'Изменить ответ'**
  String get message56bce8cb2713;

  /// Ответ будет публичным. Не указывайте адреса и инструкции по уходу.
  ///
  /// In ru, this message translates to:
  /// **'Ответ будет публичным. Не указывайте адреса и инструкции по уходу.'**
  String get messageec357f7136c2;

  /// Этап {p0} из {p1}: {p2}
  ///
  /// In ru, this message translates to:
  /// **'Этап {p0} из {p1}: {p2}'**
  String message93d23f58f161(String p0, String p1, String p2);

  /// Загружаем предпочтения помощника
  ///
  /// In ru, this message translates to:
  /// **'Загружаем предпочтения помощника'**
  String get message0f04a460f0c5;

  /// Предпочтения недоступны · повторить
  ///
  /// In ru, this message translates to:
  /// **'Предпочтения недоступны · повторить'**
  String get message6765213e1479;

  /// Предпочтения и доступность
  ///
  /// In ru, this message translates to:
  /// **'Предпочтения и доступность'**
  String get messagea51de1b434f1;

  /// Размер собак: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Размер собак: {p0}'**
  String messagee4002bf3fbb0(String p0);

  /// Районы: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Районы: {p0}'**
  String messagebcf3701eacdc(String p0);

  /// Готов обсуждать прогулки
  ///
  /// In ru, this message translates to:
  /// **'Готов обсуждать прогулки'**
  String get messagec50e27eb9737;

  /// Сейчас не принимает новые запросы
  ///
  /// In ru, this message translates to:
  /// **'Сейчас не принимает новые запросы'**
  String get message082f3a59c63a;

  /// Время в {p0}
  ///
  /// In ru, this message translates to:
  /// **'Время в {p0}'**
  String message84fd0ccfc00f(String p0);

  /// Доступность — предпочтение, а не обещание записи.
  ///
  /// In ru, this message translates to:
  /// **'Доступность — предпочтение, а не обещание записи.'**
  String get message78453f85c3b5;

  /// Ваш PetFriendly
  ///
  /// In ru, this message translates to:
  /// **'Ваш PetFriendly'**
  String get message60d688e9bf1d;

  /// Повторить загрузку ролей
  ///
  /// In ru, this message translates to:
  /// **'Повторить загрузку ролей'**
  String get messagedfceefcea364;

  /// Как вы хотите участвовать?
  ///
  /// In ru, this message translates to:
  /// **'Как вы хотите участвовать?'**
  String get message986d9b6ee0bb;

  /// Один аккаунт для питомцев, прогулок и общения.
  ///
  /// In ru, this message translates to:
  /// **'Один аккаунт для питомцев, прогулок и общения.'**
  String get messagea1fbe4942f8c;

  /// Места, встречи и помощь с прогулками для вашего питомца.
  ///
  /// In ru, this message translates to:
  /// **'Места, встречи и помощь с прогулками для вашего питомца.'**
  String get messagedd4dc742d378;

  /// Находите запросы и помогайте другим владельцам. Свой питомец не нужен.
  ///
  /// In ru, this message translates to:
  /// **'Находите запросы и помогайте другим владельцам. Свой питомец не нужен.'**
  String get messagecbc0fe1953f4;

  /// Обе роли
  ///
  /// In ru, this message translates to:
  /// **'Обе роли'**
  String get message4694ba8e759b;

  /// Помогайте другим и заботьтесь о своём питомце. Переключайте режим в любой момент.
  ///
  /// In ru, this message translates to:
  /// **'Помогайте другим и заботьтесь о своём питомце. Переключайте режим в любой момент.'**
  String get message1c6715645def;

  /// Роль можно изменить в профиле. Переписки и история останутся с вами.
  ///
  /// In ru, this message translates to:
  /// **'Роль можно изменить в профиле. Переписки и история останутся с вами.'**
  String get messagec6d4b7bc6855;

  /// Новый пользователь
  ///
  /// In ru, this message translates to:
  /// **'Новый пользователь'**
  String get messagea1f60d3adb50;

  /// Не удалось сохранить роль. Попробуйте снова.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить роль. Попробуйте снова.'**
  String get messagee9456f9a328c;

  /// Продолжить
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get message3f75368ab958;

  /// Не удалось импортировать фото. Попробуйте снова или выберите фото на устройстве.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось импортировать фото. Попробуйте снова или выберите фото на устройстве.'**
  String get message834b2fb85184;

  /// Не удалось сохранить профиль. Ваши данные остались в форме. Попробуйте снова.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить профиль. Ваши данные остались в форме. Попробуйте снова.'**
  String get messagee18ed2351d80;

  /// Заполните поле
  ///
  /// In ru, this message translates to:
  /// **'Заполните поле'**
  String get message7a7e9f66a26e;

  /// Выбрать роль помощника
  ///
  /// In ru, this message translates to:
  /// **'Выбрать роль помощника'**
  String get message8b46b78c5de2;

  /// Знакомство
  ///
  /// In ru, this message translates to:
  /// **'Знакомство'**
  String get messagee31309039c8a;

  /// Предпочтения
  ///
  /// In ru, this message translates to:
  /// **'Предпочтения'**
  String get message7304fe00ec5a;

  /// Повторить загрузку профиля
  ///
  /// In ru, this message translates to:
  /// **'Повторить загрузку профиля'**
  String get messageecdc49301fb2;

  /// Познакомимся?
  ///
  /// In ru, this message translates to:
  /// **'Познакомимся?'**
  String get message70cfab0968e9;

  /// Какие прогулки вам подходят?
  ///
  /// In ru, this message translates to:
  /// **'Какие прогулки вам подходят?'**
  String get message27df61435707;

  /// Расскажите о себе. Свой питомец не нужен.
  ///
  /// In ru, this message translates to:
  /// **'Расскажите о себе. Свой питомец не нужен.'**
  String get message12632234ec91;

  /// Это предпочтения, а не бронирование. Их можно изменить позже.
  ///
  /// In ru, this message translates to:
  /// **'Это предпочтения, а не бронирование. Их можно изменить позже.'**
  String get messagef67ddc898dcd;

  /// Не удалось выбрать фото. Выберите изображение до 8 МБ.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выбрать фото. Выберите изображение до 8 МБ.'**
  String get message9ad668a84bce;

  /// Открываем…
  ///
  /// In ru, this message translates to:
  /// **'Открываем…'**
  String get message60e702f57b3e;

  /// Выбрать фото
  ///
  /// In ru, this message translates to:
  /// **'Выбрать фото'**
  String get message649ff75fdaad;

  /// Фото из Google
  ///
  /// In ru, this message translates to:
  /// **'Фото из Google'**
  String get messageab6257eaf578;

  /// Фото из Telegram
  ///
  /// In ru, this message translates to:
  /// **'Фото из Telegram'**
  String get messagef306a2a41a01;

  /// Отменить выбор
  ///
  /// In ru, this message translates to:
  /// **'Отменить выбор'**
  String get message716e5371c728;

  /// Имя
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get messageaee78fe86022;

  /// Город
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get message95405f676698;

  /// Публичный район · необязательно
  ///
  /// In ru, this message translates to:
  /// **'Публичный район · необязательно'**
  String get messagefdff86c0585a;

  /// Коротко о себе · необязательно
  ///
  /// In ru, this message translates to:
  /// **'Коротко о себе · необязательно'**
  String get messagec754b66d089f;

  /// Опыт с животными · необязательно
  ///
  /// In ru, this message translates to:
  /// **'Опыт с животными · необязательно'**
  String get message1064aceacabb;

  /// Размер собак
  ///
  /// In ru, this message translates to:
  /// **'Размер собак'**
  String get message9b15270d320c;

  /// Небольшие
  ///
  /// In ru, this message translates to:
  /// **'Небольшие'**
  String get message88f361ebd46f;

  /// Средние
  ///
  /// In ru, this message translates to:
  /// **'Средние'**
  String get messagec9b5eb57acf1;

  /// Крупные
  ///
  /// In ru, this message translates to:
  /// **'Крупные'**
  String get message48cec48bb5dc;

  /// Районы, где можете помочь
  ///
  /// In ru, this message translates to:
  /// **'Районы, где можете помочь'**
  String get messagec59229de3c14;

  /// До 10 публичных районов через запятую. Не добавляйте адрес.
  ///
  /// In ru, this message translates to:
  /// **'До 10 публичных районов через запятую. Не добавляйте адрес.'**
  String get message15885b3bd4c7;

  /// Часовой пояс
  ///
  /// In ru, this message translates to:
  /// **'Часовой пояс'**
  String get message47947a0c467b;

  /// Когда вам удобно
  ///
  /// In ru, this message translates to:
  /// **'Когда вам удобно'**
  String get messagef95f004933ab;

  /// Недельные интервалы в выбранном часовом поясе. Можно оставить пустым.
  ///
  /// In ru, this message translates to:
  /// **'Недельные интервалы в выбранном часовом поясе. Можно оставить пустым.'**
  String get message568183ec7cfa;

  /// Удалить интервал
  ///
  /// In ru, this message translates to:
  /// **'Удалить интервал'**
  String get message76294a78d1a7;

  /// Добавить время
  ///
  /// In ru, this message translates to:
  /// **'Добавить время'**
  String get message9cca54b87e3c;

  /// Готов помогать сейчас
  ///
  /// In ru, this message translates to:
  /// **'Готов помогать сейчас'**
  String get messagec9684f50069d;

  /// Покажем это в публичном профиле
  ///
  /// In ru, this message translates to:
  /// **'Покажем это в публичном профиле'**
  String get message239cfbbec36b;

  /// Эти данные будут видны другим пользователям. Указывайте только город и район, без точного адреса и личных инструкций.
  ///
  /// In ru, this message translates to:
  /// **'Эти данные будут видны другим пользователям. Указывайте только город и район, без точного адреса и личных инструкций.'**
  String get message9b3fe599d67b;

  /// Сохранить и открыть запросы
  ///
  /// In ru, this message translates to:
  /// **'Сохранить и открыть запросы'**
  String get message52d23dc8ff56;

  /// Понедельник
  ///
  /// In ru, this message translates to:
  /// **'Понедельник'**
  String get message256d12fe7ff9;

  /// Вторник
  ///
  /// In ru, this message translates to:
  /// **'Вторник'**
  String get message677afb97c3d0;

  /// Среда
  ///
  /// In ru, this message translates to:
  /// **'Среда'**
  String get messagef81e505f9bbb;

  /// Четверг
  ///
  /// In ru, this message translates to:
  /// **'Четверг'**
  String get message903dac9fa4f5;

  /// Пятница
  ///
  /// In ru, this message translates to:
  /// **'Пятница'**
  String get message90f314d3bf46;

  /// Суббота
  ///
  /// In ru, this message translates to:
  /// **'Суббота'**
  String get messageb1dda156ff0d;

  /// Воскресенье
  ///
  /// In ru, this message translates to:
  /// **'Воскресенье'**
  String get message6eb1432a3265;

  /// Время для прогулок
  ///
  /// In ru, this message translates to:
  /// **'Время для прогулок'**
  String get messagec033a50deae3;

  /// День недели
  ///
  /// In ru, this message translates to:
  /// **'День недели'**
  String get messagee7cc928e4172;

  /// Начало: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Начало: {p0}'**
  String messageeb54fb7750b1(String p0);

  /// Окончание: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Окончание: {p0}'**
  String message936c3ac380d2(String p0);

  /// Добавить
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get message559a87f7cc13;

  /// Средняя оценка {p0} из 5
  ///
  /// In ru, this message translates to:
  /// **'Средняя оценка {p0} из 5'**
  String message862606151868(String p0);

  /// Отзывы недоступны
  ///
  /// In ru, this message translates to:
  /// **'Отзывы недоступны'**
  String get messagea35b6e5d22a7;

  /// Оценка недоступна
  ///
  /// In ru, this message translates to:
  /// **'Оценка недоступна'**
  String get message8f7d56b10039;

  /// {p0} · опубликовано
  ///
  /// In ru, this message translates to:
  /// **'{p0} · опубликовано'**
  String messagebc3266a5d2e2(String p0);

  /// завершённых выгулов
  ///
  /// In ru, this message translates to:
  /// **'завершённых выгулов'**
  String get messageca22b00e631a;

  /// завершённый выгул
  ///
  /// In ru, this message translates to:
  /// **'завершённый выгул'**
  String get messagea679f6b15361;

  /// завершённых выгула
  ///
  /// In ru, this message translates to:
  /// **'завершённых выгула'**
  String get messagee54bd9aabd9c;

  /// Опыт недоступен
  ///
  /// In ru, this message translates to:
  /// **'Опыт недоступен'**
  String get message5226e6c162fb;

  /// Повторить загрузку опыта
  ///
  /// In ru, this message translates to:
  /// **'Повторить загрузку опыта'**
  String get message6023e5b18ddc;

  /// Отзывы или опыт сейчас недоступны. Повторите загрузку.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы или опыт сейчас недоступны. Повторите загрузку.'**
  String get message42d01ae06459;

  /// Отзывы сейчас недоступны.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы сейчас недоступны.'**
  String get messagee956509b4a4d;

  /// Отзывы ещё впереди
  ///
  /// In ru, this message translates to:
  /// **'Отзывы ещё впереди'**
  String get messagee06dfa4f2a69;

  /// Первый выгул впереди
  ///
  /// In ru, this message translates to:
  /// **'Первый выгул впереди'**
  String get messagece84293ecd2e;

  /// Новый помощник
  ///
  /// In ru, this message translates to:
  /// **'Новый помощник'**
  String get message1b12dde9a0e2;

  /// Завершённые выгулы уже есть. Владельцы пока не оставили отзывов.
  ///
  /// In ru, this message translates to:
  /// **'Завершённые выгулы уже есть. Владельцы пока не оставили отзывов.'**
  String get messagef6ed8ce8882b;

  /// Помогите владельцу с прогулкой. После завершения он сможет оставить отзыв.
  ///
  /// In ru, this message translates to:
  /// **'Помогите владельцу с прогулкой. После завершения он сможет оставить отзыв.'**
  String get message5251fb350d9d;

  /// Пока нет завершённых выгулов и отзывов. Обсудите опыт и потребности питомца в переписке.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет завершённых выгулов и отзывов. Обсудите опыт и потребности питомца в переписке.'**
  String get messagef5a30329ff08;

  /// Как считается опыт
  ///
  /// In ru, this message translates to:
  /// **'Как считается опыт'**
  String get message00bac6443460;

  /// Здесь учитываются прогулки, в которых вы были помощником. На рейтинг влияют только опубликованные отзывы владельцев после завершённого выгула. Ваши запросы для собственного питомца не учитываются.
  ///
  /// In ru, this message translates to:
  /// **'Здесь учитываются прогулки, в которых вы были помощником. На рейтинг влияют только опубликованные отзывы владельцев после завершённого выгула. Ваши запросы для собственного питомца не учитываются.'**
  String get message45aa64128880;

  /// Здесь учитываются прогулки, в которых этот человек помогал другим владельцам. На рейтинг влияют только опубликованные отзывы после завершённого выгула. Запросы для собственного питомца не учитываются.
  ///
  /// In ru, this message translates to:
  /// **'Здесь учитываются прогулки, в которых этот человек помогал другим владельцам. На рейтинг влияют только опубликованные отзывы после завершённого выгула. Запросы для собственного питомца не учитываются.'**
  String get message56ff0751e702;

  /// Действия с отзывом
  ///
  /// In ru, this message translates to:
  /// **'Действия с отзывом'**
  String get messageec99f9dda205;

  /// Свернуть отзыв
  ///
  /// In ru, this message translates to:
  /// **'Свернуть отзыв'**
  String get messagee0ecf63c9f95;

  /// Читать полностью
  ///
  /// In ru, this message translates to:
  /// **'Читать полностью'**
  String get messagecc4f98cb076a;

  /// Ваш ответ
  ///
  /// In ru, this message translates to:
  /// **'Ваш ответ'**
  String get message83523c6cf235;

  /// Ответ помощника
  ///
  /// In ru, this message translates to:
  /// **'Ответ помощника'**
  String get message1d9ce9d72830;

  /// Выберите часовой пояс города
  ///
  /// In ru, this message translates to:
  /// **'Выберите часовой пояс города'**
  String get message021b09f43776;

  /// Хорошая прогулка начинается со знакомства.
  ///
  /// In ru, this message translates to:
  /// **'Хорошая прогулка начинается со знакомства.'**
  String get message3e64d9846e81;

  /// Дата, время и размер собаки
  ///
  /// In ru, this message translates to:
  /// **'Дата, время и размер собаки'**
  String get message4b7451a8afb8;

  /// Размер собаки
  ///
  /// In ru, this message translates to:
  /// **'Размер собаки'**
  String get message61c1a507c065;

  /// Любой размер
  ///
  /// In ru, this message translates to:
  /// **'Любой размер'**
  String get message431cc8e7a87d;

  /// Небольшая
  ///
  /// In ru, this message translates to:
  /// **'Небольшая'**
  String get message35bf716d9818;

  /// Средняя
  ///
  /// In ru, this message translates to:
  /// **'Средняя'**
  String get message7b84ec2fed83;

  /// Крупная
  ///
  /// In ru, this message translates to:
  /// **'Крупная'**
  String get message4296acb119f3;

  /// Выбрать день
  ///
  /// In ru, this message translates to:
  /// **'Выбрать день'**
  String get message1b2b2152c02a;

  /// Время в выбранный день
  ///
  /// In ru, this message translates to:
  /// **'Время в выбранный день'**
  String get messageead637077af5;

  /// Весь день
  ///
  /// In ru, this message translates to:
  /// **'Весь день'**
  String get message7bd841568fb7;

  /// Утро · 06:00–12:00
  ///
  /// In ru, this message translates to:
  /// **'Утро · 06:00–12:00'**
  String get messageb7d3053970be;

  /// Вечер · 17:00–24:00
  ///
  /// In ru, this message translates to:
  /// **'Вечер · 17:00–24:00'**
  String get message76556691650d;

  /// Выберите день, чтобы уточнить время.
  ///
  /// In ru, this message translates to:
  /// **'Выберите день, чтобы уточнить время.'**
  String get message24058ef0e02b;

  /// Выбрать часовой пояс города
  ///
  /// In ru, this message translates to:
  /// **'Выбрать часовой пояс города'**
  String get message3cf7a713593b;

  /// Показать запросы
  ///
  /// In ru, this message translates to:
  /// **'Показать запросы'**
  String get messagea1906faaea66;

  /// Подходящих запросов пока нет. Попробуйте другой день или район.
  ///
  /// In ru, this message translates to:
  /// **'Подходящих запросов пока нет. Попробуйте другой день или район.'**
  String get messageb1282718acd0;

  /// Договорённости, которым вы уделяете время.
  ///
  /// In ru, this message translates to:
  /// **'Договорённости, которым вы уделяете время.'**
  String get message5948ec11d66b;

  /// Предстоящие
  ///
  /// In ru, this message translates to:
  /// **'Предстоящие'**
  String get messaged43ed8cb4bbc;

  /// Отклик ещё не означает, что вас выбрали. Владелец подтвердит договорённость.
  ///
  /// In ru, this message translates to:
  /// **'Отклик ещё не означает, что вас выбрали. Владелец подтвердит договорённость.'**
  String get messagea06cf5bce520;

  /// Вы пока не откликнулись на запросы.
  ///
  /// In ru, this message translates to:
  /// **'Вы пока не откликнулись на запросы.'**
  String get messagef07272117269;

  /// Здесь появятся ваши договорённости.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся ваши договорённости.'**
  String get message277d13df80ee;

  /// Запросы не загрузились. Данные сейчас недоступны.
  ///
  /// In ru, this message translates to:
  /// **'Запросы не загрузились. Данные сейчас недоступны.'**
  String get message57b06591d163;

  /// Следующие запросы
  ///
  /// In ru, this message translates to:
  /// **'Следующие запросы'**
  String get messagefd5921036852;

  /// Владелец · {p0}
  ///
  /// In ru, this message translates to:
  /// **'Владелец · {p0}'**
  String message244d40ad2eed(String p0);

  /// Отклик отправлен · ждём решения
  ///
  /// In ru, this message translates to:
  /// **'Отклик отправлен · ждём решения'**
  String get messagedeaeff2a8741;

  /// Открыть договорённость
  ///
  /// In ru, this message translates to:
  /// **'Открыть договорённость'**
  String get message0aa1c2d9079d;

  /// Посмотреть запрос
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть запрос'**
  String get messagea9f39971c107;

  /// Оформление
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get messaged206f1bed011;

  /// Фото сохранено
  ///
  /// In ru, this message translates to:
  /// **'Фото сохранено'**
  String get message8f505f82466a;

  /// Фото для просмотра · до перезапуска
  ///
  /// In ru, this message translates to:
  /// **'Фото для просмотра · до перезапуска'**
  String get message9766bfad75b7;

  /// Не удалось сохранить фото. Проверьте соединение и выберите изображение до 8 МБ.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить фото. Проверьте соединение и выберите изображение до 8 МБ.'**
  String get message1749fec018a0;

  /// Вы, питомцы
  /// и ваши истории.
  ///
  /// In ru, this message translates to:
  /// **'Вы, питомцы\nи ваши истории.'**
  String get message47b9cd40b434;

  /// Изменить фото профиля
  ///
  /// In ru, this message translates to:
  /// **'Изменить фото профиля'**
  String get message759783add0dd;

  /// Фото профиля
  ///
  /// In ru, this message translates to:
  /// **'Фото профиля'**
  String get message37842b90ae0b;

  /// Ваш профиль
  ///
  /// In ru, this message translates to:
  /// **'Ваш профиль'**
  String get message3aef68134819;

  /// Район не указан
  ///
  /// In ru, this message translates to:
  /// **'Район не указан'**
  String get messagef1679502b6fe;

  /// В публичном профиле виден только район.
  ///
  /// In ru, this message translates to:
  /// **'В публичном профиле виден только район.'**
  String get messagee721bdacfe97;

  /// Мои питомцы
  ///
  /// In ru, this message translates to:
  /// **'Мои питомцы'**
  String get message9e18d5862dae;

  /// Добавить питомца
  ///
  /// In ru, this message translates to:
  /// **'Добавить питомца'**
  String get message4d9bc4a5beb5;

  /// Фото питомца {p0}
  ///
  /// In ru, this message translates to:
  /// **'Фото питомца {p0}'**
  String messageadb6d1671651(String p0);

  /// Редактировать питомца
  ///
  /// In ru, this message translates to:
  /// **'Редактировать питомца'**
  String get message31ae3642aa66;

  /// Репутация как владелец
  ///
  /// In ru, this message translates to:
  /// **'Репутация как владелец'**
  String get message5435a4e37380;

  /// Роли и режим
  ///
  /// In ru, this message translates to:
  /// **'Роли и режим'**
  String get message86f56e2c6ded;

  /// Загружаем сохранённые места…
  ///
  /// In ru, this message translates to:
  /// **'Загружаем сохранённые места…'**
  String get message87b3d9e523c2;

  /// Избранные места не загрузились.
  ///
  /// In ru, this message translates to:
  /// **'Избранные места не загрузились.'**
  String get messagece236352b617;

  /// Повторить загрузку мест
  ///
  /// In ru, this message translates to:
  /// **'Повторить загрузку мест'**
  String get messaged7ac6cd2344e;

  /// Избранные места
  ///
  /// In ru, this message translates to:
  /// **'Избранные места'**
  String get message01cc4792b87a;

  /// Сохраняйте места на карте — они появятся здесь.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняйте места на карте — они появятся здесь.'**
  String get message2f4c84f8e9e4;

  /// Сохранённые места сейчас недоступны.
  ///
  /// In ru, this message translates to:
  /// **'Сохранённые места сейчас недоступны.'**
  String get message63d9df58a7c3;

  /// Ваш опыт как помощника
  ///
  /// In ru, this message translates to:
  /// **'Ваш опыт как помощника'**
  String get messagea076d73648cb;

  /// Когда вы гуляете с питомцами других владельцев.
  ///
  /// In ru, this message translates to:
  /// **'Когда вы гуляете с питомцами других владельцев.'**
  String get messageef6b94aceac3;

  /// Мои отзывы · {p0}
  ///
  /// In ru, this message translates to:
  /// **'Мои отзывы · {p0}'**
  String messagea9a227373497(String p0);

  /// Мой профиль помощника
  ///
  /// In ru, this message translates to:
  /// **'Мой профиль помощника'**
  String get messagedbdb7654a3a2;

  /// Найти запрос на выгул
  ///
  /// In ru, this message translates to:
  /// **'Найти запрос на выгул'**
  String get messagee465f57578e3;

  /// Тема приложения
  ///
  /// In ru, this message translates to:
  /// **'Тема приложения'**
  String get messagef5e5eb98950f;

  /// Уведомления
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get messageee3c35f31147;

  /// Безопасность и приватность
  ///
  /// In ru, this message translates to:
  /// **'Безопасность и приватность'**
  String get message3f633a5a6211;

  /// Аккаунт, сессии и личные данные
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт, сессии и личные данные'**
  String get message20ea080cb2f2;

  /// Отчёты об ошибках
  ///
  /// In ru, this message translates to:
  /// **'Отчёты об ошибках'**
  String get message14c066aeaae0;

  /// Отправлять технические отчёты в Firebase
  ///
  /// In ru, this message translates to:
  /// **'Отправлять технические отчёты в Firebase'**
  String get messagee477cdeaf8e5;

  /// Не удалось изменить настройку
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить настройку'**
  String get messagee7c1a949faaf;

  /// О приложении и данных
  ///
  /// In ru, this message translates to:
  /// **'О приложении и данных'**
  String get message90050fcfe2b9;

  /// Каталог: © OpenStreetMap contributors · ODbL
  /// https://www.openstreetmap.org/copyright
  ///
  /// Допуск питомцев уточняется по данным сообщества.
  ///
  /// In ru, this message translates to:
  /// **'Каталог: © OpenStreetMap contributors · ODbL\nhttps://www.openstreetmap.org/copyright\n\nДопуск питомцев уточняется по данным сообщества.'**
  String get message67df9668eb2e;

  /// Выходим…
  ///
  /// In ru, this message translates to:
  /// **'Выходим…'**
  String get messagef346b299cdc1;

  /// Выйти из аккаунта
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта'**
  String get message1d5ad05dcb6b;

  /// На этом устройстве
  ///
  /// In ru, this message translates to:
  /// **'На этом устройстве'**
  String get messagef554a379892e;

  /// Не удалось изменить участие
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить участие'**
  String get message33582a5e3d51;

  /// Пригласить в сообщество
  ///
  /// In ru, this message translates to:
  /// **'Пригласить в сообщество'**
  String get message08391f34ef47;

  /// Откроется черновик личного сообщения. Человек сам решит, вступать ли ему.
  ///
  /// In ru, this message translates to:
  /// **'Откроется черновик личного сообщения. Человек сам решит, вступать ли ему.'**
  String get message4b4e86d592be;

  /// Все доступные люди уже участвуют.
  ///
  /// In ru, this message translates to:
  /// **'Все доступные люди уже участвуют.'**
  String get message89eb79601b5a;

  /// Присоединяйтесь к «{p0}»!
  /// petfriendly://group/{p1}
  ///
  /// In ru, this message translates to:
  /// **'Присоединяйтесь к «{p0}»!\npetfriendly://group/{p1}'**
  String messagec8362545abb5(String p0, String p1);

  /// Не удалось открыть приглашение
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть приглашение'**
  String get message0b511f01eb9d;

  /// Сообщество недоступно
  ///
  /// In ru, this message translates to:
  /// **'Сообщество недоступно'**
  String get messagef11b12e634dc;

  /// Фото сообщества
  ///
  /// In ru, this message translates to:
  /// **'Фото сообщества'**
  String get message0ffe26083b2f;

  /// Предпросмотр фото · до перезапуска
  ///
  /// In ru, this message translates to:
  /// **'Предпросмотр фото · до перезапуска'**
  String get message9415614b97a6;

  /// Не удалось открыть фото
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть фото'**
  String get message2543e7c879c1;

  /// Открытое сообщество
  ///
  /// In ru, this message translates to:
  /// **'Открытое сообщество'**
  String get message9bae7b28d155;

  /// Вступаем…
  ///
  /// In ru, this message translates to:
  /// **'Вступаем…'**
  String get message22b9769931b0;

  /// Вступить в сообщество
  ///
  /// In ru, this message translates to:
  /// **'Вступить в сообщество'**
  String get message2e692114d30f;

  /// Открыть чат сообщества
  ///
  /// In ru, this message translates to:
  /// **'Открыть чат сообщества'**
  String get messagef2d30d5ad857;

  /// Пригласить человека
  ///
  /// In ru, this message translates to:
  /// **'Пригласить человека'**
  String get message28c8c2c67fc8;

  /// Участники
  ///
  /// In ru, this message translates to:
  /// **'Участники'**
  String get messagefcb848e42690;

  /// Организатор
  ///
  /// In ru, this message translates to:
  /// **'Организатор'**
  String get message17d9d9622b22;

  /// Выйти из сообщества
  ///
  /// In ru, this message translates to:
  /// **'Выйти из сообщества'**
  String get message17caac1f45a9;

  /// В чате видно имя автора и время каждого сообщения.
  ///
  /// In ru, this message translates to:
  /// **'В чате видно имя автора и время каждого сообщения.'**
  String get message461285515199;

  /// Чат доступен после вступления. Вас не добавляют без вашего согласия.
  ///
  /// In ru, this message translates to:
  /// **'Чат доступен после вступления. Вас не добавляют без вашего согласия.'**
  String get message395a7f5b8d17;

  /// Не удалось изменить участие. Возможно, свободных мест нет.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить участие. Возможно, свободных мест нет.'**
  String get message2e90ca162872;

  /// Чат появится после подключения данных встречи
  ///
  /// In ru, this message translates to:
  /// **'Чат появится после подключения данных встречи'**
  String get message904dbc353c13;

  /// Совместные прогулки
  ///
  /// In ru, this message translates to:
  /// **'Совместные прогулки'**
  String get message3b599536f6db;

  /// Встреча
  ///
  /// In ru, this message translates to:
  /// **'Встреча'**
  String get messagee45a61bc019f;

  /// Выберите прогулку
  ///
  /// In ru, this message translates to:
  /// **'Выберите прогулку'**
  String get message49f67359faa0;

  /// Встреча недоступна. Возможно, её больше нет.
  ///
  /// In ru, this message translates to:
  /// **'Встреча недоступна. Возможно, её больше нет.'**
  String get message7cd4c88be0f6;

  /// Пока нет встреч. Создайте первую.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет встреч. Создайте первую.'**
  String get messageb1955e60d1bc;

  /// {p0} из {p1} участников
  ///
  /// In ru, this message translates to:
  /// **'{p0} из {p1} участников'**
  String messagebe06b85d34df(String p0, String p1);

  /// Вы организатор
  ///
  /// In ru, this message translates to:
  /// **'Вы организатор'**
  String get message37e318fdeb91;

  /// Присоединиться
  ///
  /// In ru, this message translates to:
  /// **'Присоединиться'**
  String get message4198697c8734;

  /// Отменить участие
  ///
  /// In ru, this message translates to:
  /// **'Отменить участие'**
  String get message79b97decc746;

  /// Чат встречи
  ///
  /// In ru, this message translates to:
  /// **'Чат встречи'**
  String get messagec151ef28de83;

  /// Помогите сделать
  /// сообщество безопаснее.
  ///
  /// In ru, this message translates to:
  /// **'Помогите сделать\nсообщество безопаснее.'**
  String get message005704df1e70;

  /// Жалобу увидит модератор. Не добавляйте лишние личные данные.
  ///
  /// In ru, this message translates to:
  /// **'Жалобу увидит модератор. Не добавляйте лишние личные данные.'**
  String get message67197255e129;

  /// Что произошло?
  ///
  /// In ru, this message translates to:
  /// **'Что произошло?'**
  String get message4b476322516b;

  /// Опишите проблему
  ///
  /// In ru, this message translates to:
  /// **'Опишите проблему'**
  String get messagef2074d9e66c3;

  /// Жалоба отправлена
  ///
  /// In ru, this message translates to:
  /// **'Жалоба отправлена'**
  String get message050a2dab17b8;

  /// Не удалось отправить жалобу
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить жалобу'**
  String get messageb11318be3823;

  /// Отправить жалобу
  ///
  /// In ru, this message translates to:
  /// **'Отправить жалобу'**
  String get message0c62c154f11e;

  /// Отправляем жалобу…
  ///
  /// In ru, this message translates to:
  /// **'Отправляем жалобу…'**
  String get message3656f83c7354;

  /// Выйти из формы?
  ///
  /// In ru, this message translates to:
  /// **'Выйти из формы?'**
  String get messageb19e091c9944;

  /// Можно оставить черновик до закрытия приложения. Он не публикуется и не записывается на устройство.
  ///
  /// In ru, this message translates to:
  /// **'Можно оставить черновик до закрытия приложения. Он не публикуется и не записывается на устройство.'**
  String get messagebb88935ad891;

  /// Удалить изменения
  ///
  /// In ru, this message translates to:
  /// **'Удалить изменения'**
  String get message2d15a70b48e2;

  /// Оставить черновик
  ///
  /// In ru, this message translates to:
  /// **'Оставить черновик'**
  String get message0fc6c0d06cc9;

  /// Сначала укажите город встречи
  ///
  /// In ru, this message translates to:
  /// **'Сначала укажите город встречи'**
  String get message4d72b2f8e55f;

  /// Не удалось выбрать точку. Попробуйте снова.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выбрать точку. Попробуйте снова.'**
  String get message85a30e204d73;

  /// Фото недоступно. Выберите другое изображение.
  ///
  /// In ru, this message translates to:
  /// **'Фото недоступно. Выберите другое изображение.'**
  String get messageb5cc2ef39619;

  /// Введите число
  ///
  /// In ru, this message translates to:
  /// **'Введите число'**
  String get messagec78b4f55e7a2;

  /// Дата прогулки
  ///
  /// In ru, this message translates to:
  /// **'Дата прогулки'**
  String get message9d900f020f0e;

  /// Дата встречи
  ///
  /// In ru, this message translates to:
  /// **'Дата встречи'**
  String get message71ee099024d3;

  /// Выбрать
  ///
  /// In ru, this message translates to:
  /// **'Выбрать'**
  String get messagefe4b0c80f09e;

  /// Время начала
  ///
  /// In ru, this message translates to:
  /// **'Время начала'**
  String get messaged0ab03c14d1f;

  /// Выберите часовой пояс места прогулки
  ///
  /// In ru, this message translates to:
  /// **'Выберите часовой пояс места прогулки'**
  String get message19ed7fc9d8d7;

  /// Выберите будущее время в месте прогулки
  ///
  /// In ru, this message translates to:
  /// **'Выберите будущее время в месте прогулки'**
  String get messagedc186d2b3bbe;

  /// Возраст должен быть от 0 до 100
  ///
  /// In ru, this message translates to:
  /// **'Возраст должен быть от 0 до 100'**
  String get messagee2ab213e839d;

  /// От 2 до 100 участников
  ///
  /// In ru, this message translates to:
  /// **'От 2 до 100 участников'**
  String get message939ed792df11;

  /// Добавьте и выберите своего питомца
  ///
  /// In ru, this message translates to:
  /// **'Добавьте и выберите своего питомца'**
  String get messagef71b1c28e749;

  /// Продолжительность от 15 до 240 минут
  ///
  /// In ru, this message translates to:
  /// **'Продолжительность от 15 до 240 минут'**
  String get messagedc74357f92b3;

  /// Данные сохранены. Фото можно добавить позже.
  ///
  /// In ru, this message translates to:
  /// **'Данные сохранены. Фото можно добавить позже.'**
  String get messagefdcb6753efb8;

  /// Сохранено
  ///
  /// In ru, this message translates to:
  /// **'Сохранено'**
  String get messagef0dff5ab4a66;

  /// Не удалось сохранить. Проверьте данные и соединение.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить. Проверьте данные и соединение.'**
  String get message4e22892a49e9;

  /// Давайте познакомимся
  ///
  /// In ru, this message translates to:
  /// **'Давайте познакомимся'**
  String get message0645fbe718fd;

  /// Создаём сообщество…
  ///
  /// In ru, this message translates to:
  /// **'Создаём сообщество…'**
  String get message351052c26392;

  /// Создаём встречу…
  ///
  /// In ru, this message translates to:
  /// **'Создаём встречу…'**
  String get message94a58c2c86dd;

  /// Публикуем заявку…
  ///
  /// In ru, this message translates to:
  /// **'Публикуем заявку…'**
  String get message5ce1f1c664fd;

  /// Добавляем питомца…
  ///
  /// In ru, this message translates to:
  /// **'Добавляем питомца…'**
  String get message4cea4797f5fc;

  /// Сохраняем питомца…
  ///
  /// In ru, this message translates to:
  /// **'Сохраняем питомца…'**
  String get message19201d75daee;

  /// Сохраняем профиль…
  ///
  /// In ru, this message translates to:
  /// **'Сохраняем профиль…'**
  String get messagee2344530c7af;

  /// Черновик восстановлен. До сохранения он виден только вам.
  ///
  /// In ru, this message translates to:
  /// **'Черновик восстановлен. До сохранения он виден только вам.'**
  String get messagef05953369617;

  /// Выбрать фото сообщества
  ///
  /// In ru, this message translates to:
  /// **'Выбрать фото сообщества'**
  String get message501b6b70441b;

  /// Не удалось открыть фото. Максимум 8 МБ.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть фото. Максимум 8 МБ.'**
  String get message53d4df4e067f;

  /// Фото — локальный предпросмотр до перезапуска, без публикации.
  ///
  /// In ru, this message translates to:
  /// **'Фото — локальный предпросмотр до перезапуска, без публикации.'**
  String get message3fea1d99e3b9;

  /// Название сообщества
  ///
  /// In ru, this message translates to:
  /// **'Название сообщества'**
  String get message6d080f825c4c;

  /// О сообществе
  ///
  /// In ru, this message translates to:
  /// **'О сообществе'**
  String get message4a68dd8cf1ef;

  /// Как вас будут видеть другие владельцы питомцев? Имя и фото можно изменить.
  ///
  /// In ru, this message translates to:
  /// **'Как вас будут видеть другие владельцы питомцев? Имя и фото можно изменить.'**
  String get messagebe377c462a13;

  /// Загружаем…
  ///
  /// In ru, this message translates to:
  /// **'Загружаем…'**
  String get messageb00e2401eb97;

  /// Фото из {p0}
  ///
  /// In ru, this message translates to:
  /// **'Фото из {p0}'**
  String messagee32a39491144(String p0);

  /// Район
  ///
  /// In ru, this message translates to:
  /// **'Район'**
  String get message0dddb4e11969;

  /// О себе
  ///
  /// In ru, this message translates to:
  /// **'О себе'**
  String get message312416bd6b59;

  /// Интересы
  ///
  /// In ru, this message translates to:
  /// **'Интересы'**
  String get messagefa4e157472cf;

  /// Имя питомца
  ///
  /// In ru, this message translates to:
  /// **'Имя питомца'**
  String get messagef5877eb4b196;

  /// Вид животного
  ///
  /// In ru, this message translates to:
  /// **'Вид животного'**
  String get message136b5f4791f1;

  /// Собака
  ///
  /// In ru, this message translates to:
  /// **'Собака'**
  String get message596794f4ae1a;

  /// Возраст в годах
  ///
  /// In ru, this message translates to:
  /// **'Возраст в годах'**
  String get message923f88ac18e7;

  /// Характер и особенности
  ///
  /// In ru, this message translates to:
  /// **'Характер и особенности'**
  String get message1ae8a2e2f4bf;

  /// Название встречи
  ///
  /// In ru, this message translates to:
  /// **'Название встречи'**
  String get messageb0e181ce9464;

  /// Количество участников
  ///
  /// In ru, this message translates to:
  /// **'Количество участников'**
  String get message73ce590f1b54;

  /// Сначала добавьте питомца в профиле.
  ///
  /// In ru, this message translates to:
  /// **'Сначала добавьте питомца в профиле.'**
  String get messageb25eec006d87;

  /// Продолжительность, минут
  ///
  /// In ru, this message translates to:
  /// **'Продолжительность, минут'**
  String get messageb1d2aecbaf1d;

  /// Выбрать место на карте
  ///
  /// In ru, this message translates to:
  /// **'Выбрать место на карте'**
  String get messageab243279dfe8;

  /// Точка встречи выбрана
  ///
  /// In ru, this message translates to:
  /// **'Точка встречи выбрана'**
  String get messagee39e548ac7da;

  /// Необязательно
  ///
  /// In ru, this message translates to:
  /// **'Необязательно'**
  String get message30de177fca5b;

  /// Нажмите, чтобы изменить
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы изменить'**
  String get message9a4b491c3ca8;

  /// Убрать точку встречи
  ///
  /// In ru, this message translates to:
  /// **'Убрать точку встречи'**
  String get message6e4be49ad20b;

  /// Где собираемся
  ///
  /// In ru, this message translates to:
  /// **'Где собираемся'**
  String get message869d5223f4cf;

  /// Точку и описание увидят другие пользователи. Выбирайте публичное место.
  ///
  /// In ru, this message translates to:
  /// **'Точку и описание увидят другие пользователи. Выбирайте публичное место.'**
  String get messaged0d23e281e3e;

  /// Выберите перед сохранением
  ///
  /// In ru, this message translates to:
  /// **'Выберите перед сохранением'**
  String get message205356dd7a6b;

  /// Дата и время в месте прогулки
  ///
  /// In ru, this message translates to:
  /// **'Дата и время в месте прогулки'**
  String get messagee5d3b5981249;

  /// Публичное описание
  ///
  /// In ru, this message translates to:
  /// **'Публичное описание'**
  String get messagede1cdaf0d1eb;

  /// Приватные инструкции помощнику
  ///
  /// In ru, this message translates to:
  /// **'Приватные инструкции помощнику'**
  String get messageb526ddbf1bca;

  /// Загружаем фото. Затем можно сохранить.
  ///
  /// In ru, this message translates to:
  /// **'Загружаем фото. Затем можно сохранить.'**
  String get message1341bac612ae;

  /// Демо: изменения хранятся в памяти.
  ///
  /// In ru, this message translates to:
  /// **'Демо: изменения хранятся в памяти.'**
  String get message399addcd0e7b;

  /// Личные данные доступны по правилам аккаунта.
  ///
  /// In ru, this message translates to:
  /// **'Личные данные доступны по правилам аккаунта.'**
  String get message867c35f6aeea;

  /// Место встречи
  ///
  /// In ru, this message translates to:
  /// **'Место встречи'**
  String get messagedea538eebd3f;

  /// Переместите карту и выберите точку сбора в публичном месте.
  ///
  /// In ru, this message translates to:
  /// **'Переместите карту и выберите точку сбора в публичном месте.'**
  String get message426a3fad9bb0;

  /// Знакомьтесь рядом.
  ///
  /// In ru, this message translates to:
  /// **'Знакомьтесь рядом.'**
  String get messageeabcf1f4ee38;

  /// Люди рядом
  ///
  /// In ru, this message translates to:
  /// **'Люди рядом'**
  String get messagea49efe6e86e9;

  /// Сообщества
  ///
  /// In ru, this message translates to:
  /// **'Сообщества'**
  String get message66f2059653b6;

  /// Имя, питомец или интерес
  ///
  /// In ru, this message translates to:
  /// **'Имя, питомец или интерес'**
  String get message9aff32018242;

  /// Название или интерес
  ///
  /// In ru, this message translates to:
  /// **'Название или интерес'**
  String get message8a09f06cda91;

  /// Не удалось загрузить людей и сообщества. Проверьте соединение и попробуйте снова.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить людей и сообщества. Проверьте соединение и попробуйте снова.'**
  String get message0328ac4ae829;

  /// Точное местоположение людей скрыто.
  ///
  /// In ru, this message translates to:
  /// **'Точное местоположение людей скрыто.'**
  String get message2b9cf1ed85bf;

  /// Написать {p0}
  ///
  /// In ru, this message translates to:
  /// **'Написать {p0}'**
  String message4d2b4b63c4b8(String p0);

  /// Переписка недоступна
  ///
  /// In ru, this message translates to:
  /// **'Переписка недоступна'**
  String get message83f6c67ecb86;

  /// Пока никого нет. Загляните позже.
  ///
  /// In ru, this message translates to:
  /// **'Пока никого нет. Загляните позже.'**
  String get message0d14415bf2d4;

  /// Никого не нашли
  ///
  /// In ru, this message translates to:
  /// **'Никого не нашли'**
  String get messagec0ed14dd82fd;

  /// Попробуйте другое имя, питомца или интерес.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте другое имя, питомца или интерес.'**
  String get message055eab447fd5;

  /// Сбросить поиск
  ///
  /// In ru, this message translates to:
  /// **'Сбросить поиск'**
  String get messageeec2d77a2fad;

  /// Найдите сообщество
  ///
  /// In ru, this message translates to:
  /// **'Найдите сообщество'**
  String get messagef9ae3cd4e9a1;

  /// Пока нет сообществ. Создайте своё.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет сообществ. Создайте своё.'**
  String get messagec4b3e11aebb2;

  /// Сообщества не найдены
  ///
  /// In ru, this message translates to:
  /// **'Сообщества не найдены'**
  String get message9b1c54777257;

  /// Вы участвуете
  ///
  /// In ru, this message translates to:
  /// **'Вы участвуете'**
  String get message179a4c29fc0e;

  /// Всё важное
  /// под рукой.
  ///
  /// In ru, this message translates to:
  /// **'Всё важное\nпод рукой.'**
  String get messagecb2b3004e8da;

  /// Не удалось включить уведомления
  ///
  /// In ru, this message translates to:
  /// **'Не удалось включить уведомления'**
  String get message66ab23fd4dbc;

  /// Настроить уведомления
  ///
  /// In ru, this message translates to:
  /// **'Настроить уведомления'**
  String get messagefe35c9ab559a;

  /// Тестовое уведомление без личных данных.
  ///
  /// In ru, this message translates to:
  /// **'Тестовое уведомление без личных данных.'**
  String get messagec42808e89208;

  /// Проверить локальное уведомление
  ///
  /// In ru, this message translates to:
  /// **'Проверить локальное уведомление'**
  String get message66de510f1074;

  /// Облачные push ещё не подключены. Внутренние уведомления доступны в приложении.
  ///
  /// In ru, this message translates to:
  /// **'Облачные push ещё не подключены. Внутренние уведомления доступны в приложении.'**
  String get message297cf77ec513;

  /// Последние события
  ///
  /// In ru, this message translates to:
  /// **'Последние события'**
  String get message2355a3badd7f;

  /// Пока нет новых событий.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет новых событий.'**
  String get message43843ef49670;

  /// Новое сообщение
  ///
  /// In ru, this message translates to:
  /// **'Новое сообщение'**
  String get message9aaab9126496;

  /// Вас выбрали для выгула
  ///
  /// In ru, this message translates to:
  /// **'Вас выбрали для выгула'**
  String get messageea7abe214c11;

  /// Новый отклик на выгул
  ///
  /// In ru, this message translates to:
  /// **'Новый отклик на выгул'**
  String get message1e32e76e0488;

  /// Статус прогулки изменился
  ///
  /// In ru, this message translates to:
  /// **'Статус прогулки изменился'**
  String get message24e6d41f837f;

  /// Обновление встречи
  ///
  /// In ru, this message translates to:
  /// **'Обновление встречи'**
  String get message467e22763678;

  /// Язык приложения
  ///
  /// In ru, this message translates to:
  /// **'Язык приложения'**
  String get message4275cb57eb99;

  /// Как на устройстве
  ///
  /// In ru, this message translates to:
  /// **'Как на устройстве'**
  String get message0860b3491171;

  /// Все страны
  ///
  /// In ru, this message translates to:
  /// **'Все страны'**
  String get messageb15cce3d7ee7;

  /// Страна
  ///
  /// In ru, this message translates to:
  /// **'Страна'**
  String get message7bc2f626288f;

  /// Город, регион или страна
  ///
  /// In ru, this message translates to:
  /// **'Город, регион или страна'**
  String get messagebcbba461b60e;

  /// Введите город и страну
  ///
  /// In ru, this message translates to:
  /// **'Введите город и страну'**
  String get message88dd327792e2;

  /// Меньшие населённые пункты можно указать вручную, добавив страну.
  ///
  /// In ru, this message translates to:
  /// **'Меньшие населённые пункты можно указать вручную, добавив страну.'**
  String get message33e88b747bdc;

  /// Брест
  ///
  /// In ru, this message translates to:
  /// **'Брест'**
  String get message094873973b43;

  /// Возраст не указан
  ///
  /// In ru, this message translates to:
  /// **'Возраст не указан'**
  String get message24120671d526;

  /// В это время переводят часы. Выберите другое время.
  ///
  /// In ru, this message translates to:
  /// **'В это время переводят часы. Выберите другое время.'**
  String get message6422f4b68a3f;

  /// Это время повторяется при переводе часов. Выберите другое время.
  ///
  /// In ru, this message translates to:
  /// **'Это время повторяется при переводе часов. Выберите другое время.'**
  String get message4e1081bbabf3;

  /// Варшава
  ///
  /// In ru, this message translates to:
  /// **'Варшава'**
  String get message1d9bddaea918;

  /// Москва
  ///
  /// In ru, this message translates to:
  /// **'Москва'**
  String get message39ef3db3f651;

  /// Вильнюс
  ///
  /// In ru, this message translates to:
  /// **'Вильнюс'**
  String get message0c766e6b61d0;

  /// Рига
  ///
  /// In ru, this message translates to:
  /// **'Рига'**
  String get message36985485208d;

  /// Киев
  ///
  /// In ru, this message translates to:
  /// **'Киев'**
  String get message29cbedd98e33;

  /// Время не задано
  ///
  /// In ru, this message translates to:
  /// **'Время не задано'**
  String get message5bfdd82d218d;

  /// {p0} · {p1} UTC · часовой пояс места не указан
  ///
  /// In ru, this message translates to:
  /// **'{p0} · {p1} UTC · часовой пояс места не указан'**
  String message10f7ed92c4f4(String p0, String p1);

  /// Дата не указана
  ///
  /// In ru, this message translates to:
  /// **'Дата не указана'**
  String get message089ab0c991d4;

  /// Выберите фото до {p0} МБ
  ///
  /// In ru, this message translates to:
  /// **'Выберите фото до {p0} МБ'**
  String message6621bce60796(String p0);

  /// Слишком большое разрешение фото
  ///
  /// In ru, this message translates to:
  /// **'Слишком большое разрешение фото'**
  String get message794cfc85b0cb;

  /// Договорённость о выгуле
  ///
  /// In ru, this message translates to:
  /// **'Договорённость о выгуле'**
  String get messagecf518012172c;

  /// Личная переписка
  ///
  /// In ru, this message translates to:
  /// **'Личная переписка'**
  String get message2a793f66f34d;

  /// Переписка
  ///
  /// In ru, this message translates to:
  /// **'Переписка'**
  String get messageb0e6ecc2e6cd;

  /// Открыть встречу
  ///
  /// In ru, this message translates to:
  /// **'Открыть встречу'**
  String get message28726b6555e5;

  /// В чаты можно загружать только фото
  ///
  /// In ru, this message translates to:
  /// **'В чаты можно загружать только фото'**
  String get message2236cf3068a6;

  /// Выберите фото до 5 МБ
  ///
  /// In ru, this message translates to:
  /// **'Выберите фото до 5 МБ'**
  String get message61165ddb443f;

  /// Фото после обработки больше 5 МБ. Выберите другое изображение.
  ///
  /// In ru, this message translates to:
  /// **'Фото после обработки больше 5 МБ. Выберите другое изображение.'**
  String get messagecf53210c7fff;

  /// Геолокация выключена. Выберите город вручную.
  ///
  /// In ru, this message translates to:
  /// **'Геолокация выключена. Выберите город вручную.'**
  String get message28ea9cea7c99;

  /// Доступ к геолокации не разрешён. Город можно выбрать вручную.
  ///
  /// In ru, this message translates to:
  /// **'Доступ к геолокации не разрешён. Город можно выбрать вручную.'**
  String get messagede91d9f20bac;

  /// Не удалось найти выбранный город.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось найти выбранный город.'**
  String get message633e233ae0d6;

  /// Не удалось определить город. Выберите его вручную.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить город. Выберите его вручную.'**
  String get messagefd27189df3de;

  /// Собаки разрешены
  ///
  /// In ru, this message translates to:
  /// **'Собаки разрешены'**
  String get message9c20af65fda9;

  /// Собаки на поводке
  ///
  /// In ru, this message translates to:
  /// **'Собаки на поводке'**
  String get messagee3747f6545c2;

  /// Собаки запрещены
  ///
  /// In ru, this message translates to:
  /// **'Собаки запрещены'**
  String get messagee35fa18a4522;

  /// Допуск не подтверждён
  ///
  /// In ru, this message translates to:
  /// **'Допуск не подтверждён'**
  String get message9b43e612e90d;

  /// Подтверждено сообществом
  ///
  /// In ru, this message translates to:
  /// **'Подтверждено сообществом'**
  String get message2f4bdc07dc63;

  /// Подтверждено заведением
  ///
  /// In ru, this message translates to:
  /// **'Подтверждено заведением'**
  String get messagea23fe384e726;

  /// Собаки только на поводке
  ///
  /// In ru, this message translates to:
  /// **'Собаки только на поводке'**
  String get message4301c689a11b;

  /// Правила для питомцев пока неизвестны
  ///
  /// In ru, this message translates to:
  /// **'Правила для питомцев пока неизвестны'**
  String get messagede1348a21e8f;

  /// Уточните правила посещения перед прогулкой.
  ///
  /// In ru, this message translates to:
  /// **'Уточните правила посещения перед прогулкой.'**
  String get message1f7d20aa078a;

  /// Собаки разрешены · отметка OSM
  ///
  /// In ru, this message translates to:
  /// **'Собаки разрешены · отметка OSM'**
  String get message0684985fc1c7;

  /// Собаки на поводке · отметка OSM
  ///
  /// In ru, this message translates to:
  /// **'Собаки на поводке · отметка OSM'**
  String get message9f0b89aa8e29;

  /// Собаки запрещены · отметка OSM
  ///
  /// In ru, this message translates to:
  /// **'Собаки запрещены · отметка OSM'**
  String get messageefb4b2b7b0bd;

  /// Все
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get messagefd08da7a630b;

  /// Парки
  ///
  /// In ru, this message translates to:
  /// **'Парки'**
  String get message057bb673cb59;

  /// Площадки
  ///
  /// In ru, this message translates to:
  /// **'Площадки'**
  String get messagec7397f0b5db4;

  /// Рестораны
  ///
  /// In ru, this message translates to:
  /// **'Рестораны'**
  String get message3886266b6593;

  /// Зоомагазины
  ///
  /// In ru, this message translates to:
  /// **'Зоомагазины'**
  String get message3be39323b5b8;

  /// Ветклиники
  ///
  /// In ru, this message translates to:
  /// **'Ветклиники'**
  String get messagef6c9d7568145;

  /// Любой допуск
  ///
  /// In ru, this message translates to:
  /// **'Любой допуск'**
  String get message6117e6ec54ee;

  /// Разрешено по OSM
  ///
  /// In ru, this message translates to:
  /// **'Разрешено по OSM'**
  String get message7bdf320b4b38;

  /// Нет подтверждения
  ///
  /// In ru, this message translates to:
  /// **'Нет подтверждения'**
  String get messagef9cd9bc8e35c;

  /// Запрещено по OSM
  ///
  /// In ru, this message translates to:
  /// **'Запрещено по OSM'**
  String get messageecfa10af30d6;

  /// ~{p0} м по прямой
  ///
  /// In ru, this message translates to:
  /// **'~{p0} м по прямой'**
  String message82293a962273(String p0);

  /// ~{p0} км по прямой
  ///
  /// In ru, this message translates to:
  /// **'~{p0} км по прямой'**
  String message85efa6b61ccd(String p0);

  /// Положение места
  ///
  /// In ru, this message translates to:
  /// **'Положение места'**
  String get messagea9dfb3cfe2c8;

  /// Переместите карту: метка в центре — ваше место.
  ///
  /// In ru, this message translates to:
  /// **'Переместите карту: метка в центре — ваше место.'**
  String get message484fc68961e9;

  /// Отзывы сейчас недоступны
  ///
  /// In ru, this message translates to:
  /// **'Отзывы сейчас недоступны'**
  String get message95d009718d65;

  /// ★ {p0} · {p1} отзывов
  ///
  /// In ru, this message translates to:
  /// **'★ {p0} · {p1} отзывов'**
  String message77d1fb5fd28b(String p0, String p1);

  /// Опыт сейчас недоступен
  ///
  /// In ru, this message translates to:
  /// **'Опыт сейчас недоступен'**
  String get messagebbf1cff83b1f;

  /// {p0} завершённых выгулов
  ///
  /// In ru, this message translates to:
  /// **'{p0} завершённых выгулов'**
  String message07863f4ea103(String p0);

  /// Отклик отправлен
  ///
  /// In ru, this message translates to:
  /// **'Отклик отправлен'**
  String get message951ebec7b8a5;

  /// Отклик отменён
  ///
  /// In ru, this message translates to:
  /// **'Отклик отменён'**
  String get message955e7c4e168f;

  /// Помощник выбран. Договорённость создана
  ///
  /// In ru, this message translates to:
  /// **'Помощник выбран. Договорённость создана'**
  String get message8b0f1f8ae948;

  /// Тестовый отклик добавлен
  ///
  /// In ru, this message translates to:
  /// **'Тестовый отклик добавлен'**
  String get messagef366eac215a4;

  /// Заявка отменена
  ///
  /// In ru, this message translates to:
  /// **'Заявка отменена'**
  String get messagefa5356be8f63;

  /// Прогулка началась
  ///
  /// In ru, this message translates to:
  /// **'Прогулка началась'**
  String get message2ed204eb3508;

  /// Владелец может подтвердить завершение
  ///
  /// In ru, this message translates to:
  /// **'Владелец может подтвердить завершение'**
  String get message5340d365bb80;

  /// Завершение подтверждено
  ///
  /// In ru, this message translates to:
  /// **'Завершение подтверждено'**
  String get messagee2f8d0888d94;

  /// Заявка обновлена
  ///
  /// In ru, this message translates to:
  /// **'Заявка обновлена'**
  String get message10df66211a0a;

  /// Договорённость
  ///
  /// In ru, this message translates to:
  /// **'Договорённость'**
  String get message7b3e83c2e9fb;

  /// Прогулка
  ///
  /// In ru, this message translates to:
  /// **'Прогулка'**
  String get message3dfcd2dc31c5;

  /// Подтверждение
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение'**
  String get message846aff7071bb;

  /// Завершено
  ///
  /// In ru, this message translates to:
  /// **'Завершено'**
  String get message016bc923f7ff;

  /// Просмотрите профили и отзывы откликнувшихся, затем выберите помощника.
  ///
  /// In ru, this message translates to:
  /// **'Просмотрите профили и отзывы откликнувшихся, затем выберите помощника.'**
  String get message072d474a77d3;

  /// Ваш отклик отправлен. Дождитесь решения владельца.
  ///
  /// In ru, this message translates to:
  /// **'Ваш отклик отправлен. Дождитесь решения владельца.'**
  String get messaged6af38682a9f;

  /// Просмотрите описание прогулки и предложите помощь, если можете участвовать.
  ///
  /// In ru, this message translates to:
  /// **'Просмотрите описание прогулки и предложите помощь, если можете участвовать.'**
  String get messagebc77fea18d7a;

  /// Обсудите детали с владельцем в чате. Когда прогулка начнётся, нажмите «Начать прогулку».
  ///
  /// In ru, this message translates to:
  /// **'Обсудите детали с владельцем в чате. Когда прогулка начнётся, нажмите «Начать прогулку».'**
  String get message7f2a76a01520;

  /// Обсудите детали в чате. Начало прогулки отмечает выбранный помощник.
  ///
  /// In ru, this message translates to:
  /// **'Обсудите детали в чате. Начало прогулки отмечает выбранный помощник.'**
  String get message512875df25af;

  /// По окончании нажмите «Завершить прогулку». Затем владелец подтвердит завершение.
  ///
  /// In ru, this message translates to:
  /// **'По окончании нажмите «Завершить прогулку». Затем владелец подтвердит завершение.'**
  String get messagea4ed6dc14aaf;

  /// Помощник отмечает окончание прогулки. После этого вы сможете подтвердить завершение.
  ///
  /// In ru, this message translates to:
  /// **'Помощник отмечает окончание прогулки. После этого вы сможете подтвердить завершение.'**
  String get messageef93b47bd5f6;

  /// Проверьте, что прогулка завершилась, и нажмите «Подтвердить завершение».
  ///
  /// In ru, this message translates to:
  /// **'Проверьте, что прогулка завершилась, и нажмите «Подтвердить завершение».'**
  String get messageaccfd2fd31e2;

  /// Вы отметили окончание. Дождитесь подтверждения владельца.
  ///
  /// In ru, this message translates to:
  /// **'Вы отметили окончание. Дождитесь подтверждения владельца.'**
  String get message9d1a7265b3ba;

  /// Прогулка завершена. Поделитесь опытом — оставьте отзыв о помощнике.
  ///
  /// In ru, this message translates to:
  /// **'Прогулка завершена. Поделитесь опытом — оставьте отзыв о помощнике.'**
  String get messagee98a1e953c9b;

  /// Прогулка завершена. Ваш отзыв уже сохранён.
  ///
  /// In ru, this message translates to:
  /// **'Прогулка завершена. Ваш отзыв уже сохранён.'**
  String get messagee7aafc25d1c9;

  /// Прогулка завершена. Отзыв владельца появится в вашем профиле, когда будет опубликован.
  ///
  /// In ru, this message translates to:
  /// **'Прогулка завершена. Отзыв владельца появится в вашем профиле, когда будет опубликован.'**
  String get message6962497418cd;

  /// Заявка отменена и больше не принимает отклики.
  ///
  /// In ru, this message translates to:
  /// **'Заявка отменена и больше не принимает отклики.'**
  String get message05ba555dfef8;

  /// Здесь показан текущий статус заявки. Изменять договорённость могут только её участники.
  ///
  /// In ru, this message translates to:
  /// **'Здесь показан текущий статус заявки. Изменять договорённость могут только её участники.'**
  String get messagee83f6a2fe9b1;

  /// Добавьте не больше 28 интервалов
  ///
  /// In ru, this message translates to:
  /// **'Добавьте не больше 28 интервалов'**
  String get messagee02da454b071;

  /// Начало должно быть раньше окончания в пределах одного дня
  ///
  /// In ru, this message translates to:
  /// **'Начало должно быть раньше окончания в пределах одного дня'**
  String get messagebb4cc1e6e161;

  /// Интервалы одного дня не должны пересекаться
  ///
  /// In ru, this message translates to:
  /// **'Интервалы одного дня не должны пересекаться'**
  String get messagec7c78544f4b2;

  /// Укажите город до 120 символов
  ///
  /// In ru, this message translates to:
  /// **'Укажите город до 120 символов'**
  String get message67eba41d5b09;

  /// Сократите описание до указанного ограничения
  ///
  /// In ru, this message translates to:
  /// **'Сократите описание до указанного ограничения'**
  String get message9de5817d88f0;

  /// Выберите размер собак из списка
  ///
  /// In ru, this message translates to:
  /// **'Выберите размер собак из списка'**
  String get message24b3f4e77859;

  /// Укажите до 10 районов, каждый до 100 символов
  ///
  /// In ru, this message translates to:
  /// **'Укажите до 10 районов, каждый до 100 символов'**
  String get message90dc3d113555;

  /// Выберите часовой пояс из списка
  ///
  /// In ru, this message translates to:
  /// **'Выберите часовой пояс из списка'**
  String get message6f7139f2b0ca;

  /// Не удалось сохранить. Проверьте соединение и попробуйте снова.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить. Проверьте соединение и попробуйте снова.'**
  String get messagea670537e7382;

  /// Помощник выбран
  ///
  /// In ru, this message translates to:
  /// **'Помощник выбран'**
  String get message8db62374e5b4;

  /// На прогулке
  ///
  /// In ru, this message translates to:
  /// **'На прогулке'**
  String get message15751266a91c;

  /// Ждёт подтверждения
  ///
  /// In ru, this message translates to:
  /// **'Ждёт подтверждения'**
  String get message7ac8761ffe51;

  /// Отменено
  ///
  /// In ru, this message translates to:
  /// **'Отменено'**
  String get message5ebee19fe902;

  /// Ищем помощника
  ///
  /// In ru, this message translates to:
  /// **'Ищем помощника'**
  String get messageb8b38d3046e7;

  /// {p0} отзывов
  ///
  /// In ru, this message translates to:
  /// **'{p0} отзывов'**
  String message3bd0ab7b8ac9(String p0);

  /// Напишите ответ
  ///
  /// In ru, this message translates to:
  /// **'Напишите ответ'**
  String get message4aadc103f4cd;

  /// Ответ должен быть не длиннее 1000 символов
  ///
  /// In ru, this message translates to:
  /// **'Ответ должен быть не длиннее 1000 символов'**
  String get message2f82f06b396a;

  /// Не удалось опубликовать. Проверьте соединение и повторите.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось опубликовать. Проверьте соединение и повторите.'**
  String get messagea58112409df0;

  /// Как в системе
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get messagef0a22d9d1ac8;

  /// Светлая
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get message8080010c5e7d;

  /// Тёмная
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get messagebd16b234708a;

  /// Сохранить и продолжить
  ///
  /// In ru, this message translates to:
  /// **'Сохранить и продолжить'**
  String get message9c24f1019155;

  /// Опубликовать заявку
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать заявку'**
  String get message3f1997ae2824;

  /// Сохранить питомца
  ///
  /// In ru, this message translates to:
  /// **'Сохранить питомца'**
  String get messagec2d595b2bec8;

  /// Сохранить профиль
  ///
  /// In ru, this message translates to:
  /// **'Сохранить профиль'**
  String get message75bcf434565a;

  /// Новое уведомление
  ///
  /// In ru, this message translates to:
  /// **'Новое уведомление'**
  String get messagecd98843b19d4;

  /// Откройте PetFriendly, чтобы посмотреть подробности.
  ///
  /// In ru, this message translates to:
  /// **'Откройте PetFriendly, чтобы посмотреть подробности.'**
  String get message892a0c4a22c4;

  /// ageYears
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} год} few{{count} года} many{{count} лет} other{{count} года}}'**
  String ageYears(int count);

  /// memberCount
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} участник} few{{count} участника} many{{count} участников} other{{count} участника}}'**
  String memberCount(int count);

  /// reviewCount
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} отзыв} few{{count} отзыва} many{{count} отзывов} other{{count} отзыва}}'**
  String reviewCount(int count);

  /// completedWalkCount
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} завершённый выгул} few{{count} завершённых выгула} many{{count} завершённых выгулов} other{{count} завершённого выгула}}'**
  String completedWalkCount(int count);

  /// Кошка
  ///
  /// In ru, this message translates to:
  /// **'Кошка'**
  String get message42c41e298a1d;

  /// Другое
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get message8f96cac0d466;

  /// завершён
  ///
  /// In ru, this message translates to:
  /// **'завершён'**
  String get message486be4ec3980;

  /// текущий этап
  ///
  /// In ru, this message translates to:
  /// **'текущий этап'**
  String get message99a264302517;

  /// предстоит
  ///
  /// In ru, this message translates to:
  /// **'предстоит'**
  String get messagee23e3eaba01f;

  /// Caption below the completed walk count
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{завершённый выгул} few{завершённых выгула} many{завершённых выгулов} other{завершённого выгула}}'**
  String completedWalkNoun(int count);

  /// Шаг 1 из 2
  ///
  /// In ru, this message translates to:
  /// **'Шаг 1 из 2'**
  String get message29ee26fd254f;

  /// Шаг 2 из 2
  ///
  /// In ru, this message translates to:
  /// **'Шаг 2 из 2'**
  String get messagebe1978ee013c;

  /// О себе и опыте · необязательно
  ///
  /// In ru, this message translates to:
  /// **'О себе и опыте · необязательно'**
  String get message7b24d22634b0;

  /// Можно заполнить позже в профиле.
  ///
  /// In ru, this message translates to:
  /// **'Можно заполнить позже в профиле.'**
  String get messaged52447138753;

  /// Договорились —
  /// можно обсуждать.
  ///
  /// In ru, this message translates to:
  /// **'Договорились —\nможно обсуждать.'**
  String get messagec253c2990498;

  /// Владельцы и ваши прогулки.
  ///
  /// In ru, this message translates to:
  /// **'Владельцы и ваши прогулки.'**
  String get message26916f84479d;

  /// После выбора помощника вы сможете обсудить детали прогулки в чате.
  ///
  /// In ru, this message translates to:
  /// **'После выбора помощника вы сможете обсудить детали прогулки в чате.'**
  String get messagedcafdc9b0189;

  /// Профиль помощника ещё не заполнен. Укажите имя и город, чтобы владельцы могли познакомиться с вами.
  ///
  /// In ru, this message translates to:
  /// **'Профиль помощника ещё не заполнен. Укажите имя и город, чтобы владельцы могли познакомиться с вами.'**
  String get message2845dc344d77;

  /// Предпочтения пока не указаны
  ///
  /// In ru, this message translates to:
  /// **'Предпочтения пока не указаны'**
  String get message32783b8b2a16;

  /// Районы пока не указаны
  ///
  /// In ru, this message translates to:
  /// **'Районы пока не указаны'**
  String get message7a8a03503a52;

  /// Время обсудим в переписке
  ///
  /// In ru, this message translates to:
  /// **'Время обсудим в переписке'**
  String get messagec1a5483b65eb;

  /// Завершённых прогулок пока нет
  ///
  /// In ru, this message translates to:
  /// **'Завершённых прогулок пока нет'**
  String get message4519bc458ddc;

  /// Ваш город и предпочтения недоступны. Повторите загрузку.
  ///
  /// In ru, this message translates to:
  /// **'Ваш город и предпочтения недоступны. Повторите загрузку.'**
  String get message1851e709a6e3;

  /// Фильтры изменены. Примените их, чтобы обновить результаты.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры изменены. Примените их, чтобы обновить результаты.'**
  String get message1dace2803f71;

  /// Для поиска по дате выберите часовой пояс города.
  ///
  /// In ru, this message translates to:
  /// **'Для поиска по дате выберите часовой пояс города.'**
  String get message62f206a28aa3;

  /// Поиск: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Поиск: {p0}'**
  String message17d9acb5f5c7(String p0);

  /// К предстоящим прогулкам
  ///
  /// In ru, this message translates to:
  /// **'К предстоящим прогулкам'**
  String get message3ab0ec6bf2d4;

  /// Завершённые и отменённые договорённости.
  ///
  /// In ru, this message translates to:
  /// **'Завершённые и отменённые договорённости.'**
  String get messagea7d5fe998ec8;

  /// Прогулки не загрузились. Попробуйте ещё раз.
  ///
  /// In ru, this message translates to:
  /// **'Прогулки не загрузились. Попробуйте ещё раз.'**
  String get messageb3bb855fd296;

  /// Следующие прогулки
  ///
  /// In ru, this message translates to:
  /// **'Следующие прогулки'**
  String get messagee97d74e1e324;

  /// Завершённые и отменённые прогулки появятся здесь.
  ///
  /// In ru, this message translates to:
  /// **'Завершённые и отменённые прогулки появятся здесь.'**
  String get message4d92bc2c00a0;

  /// Отправьте отклик. Прогулка появится здесь, когда владелец выберет вас.
  ///
  /// In ru, this message translates to:
  /// **'Отправьте отклик. Прогулка появится здесь, когда владелец выберет вас.'**
  String get message0b8bc74a8f0b;

  /// Район · необязательно
  ///
  /// In ru, this message translates to:
  /// **'Район · необязательно'**
  String get message0fb5bfd22fdc;

  /// Введите район или выберите из найденных.
  ///
  /// In ru, this message translates to:
  /// **'Введите район или выберите из найденных.'**
  String get message7bf8ccff13cb;

  /// Выбрать район
  ///
  /// In ru, this message translates to:
  /// **'Выбрать район'**
  String get message4b4b1fb484b5;

  /// Любой район
  ///
  /// In ru, this message translates to:
  /// **'Любой район'**
  String get message8596f5cbb86f;

  /// Районы появятся после загрузки запросов. Можно ввести район вручную.
  ///
  /// In ru, this message translates to:
  /// **'Районы появятся после загрузки запросов. Можно ввести район вручную.'**
  String get message6863b5c957fe;

  /// Все детали прогулки —
  /// в переписке.
  ///
  /// In ru, this message translates to:
  /// **'Все детали прогулки —\nв переписке.'**
  String get message2723824e690d;

  /// Посмотреть запросы
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть запросы'**
  String get messagea5dd80026537;

  /// Репутация недоступна
  ///
  /// In ru, this message translates to:
  /// **'Репутация недоступна'**
  String get messagef77ec0d8c1dc;

  /// Ваша роль
  ///
  /// In ru, this message translates to:
  /// **'Ваша роль'**
  String get messaged9f5b4e6bda8;

  /// О вас
  ///
  /// In ru, this message translates to:
  /// **'О вас'**
  String get message1a505d939af7;

  /// Свой питомец не нужен.
  ///
  /// In ru, this message translates to:
  /// **'Свой питомец не нужен.'**
  String get message56c2edd9ccfb;

  /// Для прогулок
  ///
  /// In ru, this message translates to:
  /// **'Для прогулок'**
  String get messageca5d8538a54d;

  /// Предпочтения можно изменить позже.
  ///
  /// In ru, this message translates to:
  /// **'Предпочтения можно изменить позже.'**
  String get messagef85c6baf5759;

  /// Ваши прогулки
  /// и переписка.
  ///
  /// In ru, this message translates to:
  /// **'Ваши прогулки\nи переписка.'**
  String get message7b5fbbab74ad;

  /// Переписывайтесь с владельцами. После назначения появится чат прогулки.
  ///
  /// In ru, this message translates to:
  /// **'Переписывайтесь с владельцами. После назначения появится чат прогулки.'**
  String get message1988576ea1cf;

  /// Районы: {p0} из 10
  ///
  /// In ru, this message translates to:
  /// **'Районы: {p0} из 10'**
  String message0433f066f26c(String p0);

  /// Удалить район
  ///
  /// In ru, this message translates to:
  /// **'Удалить район'**
  String get message3267d2dda78c;

  /// Добавить район
  ///
  /// In ru, this message translates to:
  /// **'Добавить район'**
  String get messagecebbf2940a49;

  /// Указывайте публичные районы, без точного адреса.
  ///
  /// In ru, this message translates to:
  /// **'Указывайте публичные районы, без точного адреса.'**
  String get message079a21f978ea;

  /// Этот район уже добавлен
  ///
  /// In ru, this message translates to:
  /// **'Этот район уже добавлен'**
  String get messagec98573fd5523;

  /// Профиль сохранён
  ///
  /// In ru, this message translates to:
  /// **'Профиль сохранён'**
  String get messaged7ae5c2bcdb0;

  /// Найдите прогулку рядом.
  ///
  /// In ru, this message translates to:
  /// **'Найдите прогулку рядом.'**
  String get messagea0b0e776e828;

  /// Как это работает
  ///
  /// In ru, this message translates to:
  /// **'Как это работает'**
  String get messageb9f1fffef424;

  /// Отправьте отклик
  ///
  /// In ru, this message translates to:
  /// **'Отправьте отклик'**
  String get message1340ce217e72;

  /// Отклик — это заявка, ещё не договорённость.
  ///
  /// In ru, this message translates to:
  /// **'Отклик — это заявка, ещё не договорённость.'**
  String get messageca25c6950f96;

  /// Дождитесь выбора
  ///
  /// In ru, this message translates to:
  /// **'Дождитесь выбора'**
  String get message61f3fb91bb65;

  /// Владелец выбирает одного помощника. Выбранная прогулка появится в «Моих прогулках».
  ///
  /// In ru, this message translates to:
  /// **'Владелец выбирает одного помощника. Выбранная прогулка появится в «Моих прогулках».'**
  String get messagede934b6efb66;

  /// Обсудите прогулку
  ///
  /// In ru, this message translates to:
  /// **'Обсудите прогулку'**
  String get message1c5954142ed0;

  /// После выбора договоритесь о деталях в личном чате прогулки.
  ///
  /// In ru, this message translates to:
  /// **'После выбора договоритесь о деталях в личном чате прогулки.'**
  String get message580b57bb6c65;

  /// Отметьте начало и завершение
  ///
  /// In ru, this message translates to:
  /// **'Отметьте начало и завершение'**
  String get message13f6dd068b47;

  /// Помощник отмечает начало прогулки и её завершение.
  ///
  /// In ru, this message translates to:
  /// **'Помощник отмечает начало прогулки и её завершение.'**
  String get message388c779e46bc;

  /// Дождитесь подтверждения
  ///
  /// In ru, this message translates to:
  /// **'Дождитесь подтверждения'**
  String get message253678f6c7d5;

  /// Владелец подтверждает, что прогулка завершена.
  ///
  /// In ru, this message translates to:
  /// **'Владелец подтверждает, что прогулка завершена.'**
  String get message5a20271d15f7;

  /// Оставьте отзыв
  ///
  /// In ru, this message translates to:
  /// **'Оставьте отзыв'**
  String get message0e32e6a0035a;

  /// После подтверждения каждый участник может оставить один отзыв о другом. Оценки владельца и помощника учитываются отдельно.
  ///
  /// In ru, this message translates to:
  /// **'После подтверждения каждый участник может оставить один отзыв о другом. Оценки владельца и помощника учитываются отдельно.'**
  String get messagea1cf9e853e4d;

  /// Следующая страница не загрузилась. Уже найденные прогулки сохранены.
  ///
  /// In ru, this message translates to:
  /// **'Следующая страница не загрузилась. Уже найденные прогулки сохранены.'**
  String get messageb57a95e3610f;

  /// Completed walking agreements as an owner.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} завершённая договорённость} few{{count} завершённые договорённости} many{{count} завершённых договорённостей} other{{count} завершённой договорённости}}'**
  String ownerCompletedCount(int count);

  /// Все встречи
  ///
  /// In ru, this message translates to:
  /// **'Все встречи'**
  String get message569a541c641f;

  /// Чат сообщества
  ///
  /// In ru, this message translates to:
  /// **'Чат сообщества'**
  String get messagee035962d07d7;

  /// Знакомьтесь по интересам и общайтесь вместе.
  ///
  /// In ru, this message translates to:
  /// **'Знакомьтесь по интересам и общайтесь вместе.'**
  String get message2566315efae7;

  /// Мои сообщества
  ///
  /// In ru, this message translates to:
  /// **'Мои сообщества'**
  String get messagea44fb1b5bf6a;

  /// Найти новые
  ///
  /// In ru, this message translates to:
  /// **'Найти новые'**
  String get messagea003b068e9cf;

  /// Вы пока не вступили в сообщества.
  ///
  /// In ru, this message translates to:
  /// **'Вы пока не вступили в сообщества.'**
  String get message0add446625e6;

  /// Пока нет сообществ. Загляните позже.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет сообществ. Загляните позже.'**
  String get messagea84a75b98045;

  /// Показать все сообщества
  ///
  /// In ru, this message translates to:
  /// **'Показать все сообщества'**
  String get message9361f60117a9;

  /// Организатор: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Организатор: {p0}'**
  String message3241340ab4a4(String p0);

  /// Не удалось загрузить сообщество. Проверьте соединение и попробуйте снова.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить сообщество. Проверьте соединение и попробуйте снова.'**
  String get message57a64cc39bbb;

  /// Чат сообщества пока недоступен. Попробуйте обновить данные.
  ///
  /// In ru, this message translates to:
  /// **'Чат сообщества пока недоступен. Попробуйте обновить данные.'**
  String get messagef173477c1ef6;

  /// Ближайшие 7 дней
  ///
  /// In ru, this message translates to:
  /// **'Ближайшие 7 дней'**
  String get message0695df66283c;

  /// В истории пока нет встреч
  ///
  /// In ru, this message translates to:
  /// **'В истории пока нет встреч'**
  String get message4d2042d2cd07;

  /// Встреча отменена
  ///
  /// In ru, this message translates to:
  /// **'Встреча отменена'**
  String get messagedc21d1880187;

  /// Встреча прошла
  ///
  /// In ru, this message translates to:
  /// **'Встреча прошла'**
  String get message422c232b5cda;

  /// Встречи
  ///
  /// In ru, this message translates to:
  /// **'Встречи'**
  String get message81444b09b0cf;

  /// Вы присоединились к встрече
  ///
  /// In ru, this message translates to:
  /// **'Вы присоединились к встрече'**
  String get messageaa7abeea345d;

  /// Дата
  ///
  /// In ru, this message translates to:
  /// **'Дата'**
  String get message232a0ead182b;

  /// Загрузка встреч
  ///
  /// In ru, this message translates to:
  /// **'Загрузка встреч'**
  String get messageef3c662c8a59;

  /// Знакомьтесь и гуляйте вместе.
  ///
  /// In ru, this message translates to:
  /// **'Знакомьтесь и гуляйте вместе.'**
  String get message56425e533035;

  /// Имя не указано
  ///
  /// In ru, this message translates to:
  /// **'Имя не указано'**
  String get messagef8415aabbaf7;

  /// История
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get message1417b7792d57;

  /// Любая дата
  ///
  /// In ru, this message translates to:
  /// **'Любая дата'**
  String get message2941b0da7947;

  /// Мест нет
  ///
  /// In ru, this message translates to:
  /// **'Мест нет'**
  String get messagef4165ef8cd0c;

  /// Место уточнит организатор
  ///
  /// In ru, this message translates to:
  /// **'Место уточнит организатор'**
  String get message09be0340abdb;

  /// Можно присоединиться
  ///
  /// In ru, this message translates to:
  /// **'Можно присоединиться'**
  String get messagea7baa34a406d;

  /// Не удалось изменить участие. Проверьте соединение и наличие свободных мест.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить участие. Проверьте соединение и наличие свободных мест.'**
  String get messageb5185e0b5723;

  /// Подробнее
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get message59589fe2a549;

  /// Подходящих встреч пока нет
  ///
  /// In ru, this message translates to:
  /// **'Подходящих встреч пока нет'**
  String get messagec8b2963e1437;

  /// Поиск встреч
  ///
  /// In ru, this message translates to:
  /// **'Поиск встреч'**
  String get message81bbde0e58a4;

  /// Показать место на карте
  ///
  /// In ru, this message translates to:
  /// **'Показать место на карте'**
  String get message750a4997d1fc;

  /// Попробуйте другую дату или измените поиск.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте другую дату или измените поиск.'**
  String get messagef5d613dc98cf;

  /// Предстоящие встречи
  ///
  /// In ru, this message translates to:
  /// **'Предстоящие встречи'**
  String get messageb1a1258c6247;

  /// Проверьте соединение и повторите загрузку.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте соединение и повторите загрузку.'**
  String get message4e42ce1927e2;

  /// Прошедшие и отменённые
  ///
  /// In ru, this message translates to:
  /// **'Прошедшие и отменённые'**
  String get message72e17336e142;

  /// Сегодня
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get messageb688b4c0d783;

  /// Участие отменено
  ///
  /// In ru, this message translates to:
  /// **'Участие отменено'**
  String get message0af51d68126c;

  /// Участников: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Участников: {p0}'**
  String message98db9b117288(String p0);

  /// Я организую
  ///
  /// In ru, this message translates to:
  /// **'Я организую'**
  String get message1839d4d9f117;

  /// Я участвую
  ///
  /// In ru, this message translates to:
  /// **'Я участвую'**
  String get message6d57b0180642;

  /// Поиск
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get message180f58ab9753;

  /// Вместе по интересам.
  ///
  /// In ru, this message translates to:
  /// **'Вместе по интересам.'**
  String get messageda611f1e5be2;

  /// Мои
  ///
  /// In ru, this message translates to:
  /// **'Мои'**
  String get message49a2bce3a46a;

  /// Новые
  ///
  /// In ru, this message translates to:
  /// **'Новые'**
  String get message32d5a2ea7ad3;

  /// Найдено: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Найдено: {p0}'**
  String message26405b8b6442(String p0);

  /// Пока нет сообществ
  ///
  /// In ru, this message translates to:
  /// **'Пока нет сообществ'**
  String get messageae08a890dc77;

  /// Сообщества появятся здесь, когда их создадут.
  ///
  /// In ru, this message translates to:
  /// **'Сообщества появятся здесь, когда их создадут.'**
  String get messagead855a45a18c;

  /// Попробуйте другое название или сбросьте фильтры.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте другое название или сбросьте фильтры.'**
  String get message4d357f2834c0;

  /// Выберите сообщество по интересам и вступите добровольно.
  ///
  /// In ru, this message translates to:
  /// **'Выберите сообщество по интересам и вступите добровольно.'**
  String get message3b70ea44d549;

  /// Найти сообщество
  ///
  /// In ru, this message translates to:
  /// **'Найти сообщество'**
  String get message70e5ea709ab9;

  /// Вы уже участвуете во всех доступных сообществах.
  ///
  /// In ru, this message translates to:
  /// **'Вы уже участвуете во всех доступных сообществах.'**
  String get message0b82ae44a1b3;

  /// Ваши сообщества находятся во вкладке «Мои».
  ///
  /// In ru, this message translates to:
  /// **'Ваши сообщества находятся во вкладке «Мои».'**
  String get messageebf0fe15caba;

  /// Открыть
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get messageea1f40824607;

  /// В этом городе пока нет предстоящих встреч
  ///
  /// In ru, this message translates to:
  /// **'В этом городе пока нет предстоящих встреч'**
  String get message5eca35cc0e17;

  /// Вы пока не участвуете во встречах
  ///
  /// In ru, this message translates to:
  /// **'Вы пока не участвуете во встречах'**
  String get messagec97531f276d5;

  /// Вы пока не организуете встречи
  ///
  /// In ru, this message translates to:
  /// **'Вы пока не организуете встречи'**
  String get message0b925c3d9851;

  /// Здесь появятся прошедшие и отменённые встречи.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся прошедшие и отменённые встречи.'**
  String get messageb7f8346025bf;

  /// Создайте встречу, чтобы собрать компанию.
  ///
  /// In ru, this message translates to:
  /// **'Создайте встречу, чтобы собрать компанию.'**
  String get message177289f0e29c;

  /// Выберите встречу и присоединитесь к прогулке.
  ///
  /// In ru, this message translates to:
  /// **'Выберите встречу и присоединитесь к прогулке.'**
  String get message0253dfa093af;

  /// Новые встречи появятся здесь.
  ///
  /// In ru, this message translates to:
  /// **'Новые встречи появятся здесь.'**
  String get messageca8ad0cd2efe;

  /// Посмотреть встречи
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть встречи'**
  String get message0f404fdf8f57;

  /// Загрузка людей
  ///
  /// In ru, this message translates to:
  /// **'Загрузка людей'**
  String get message3930be27278b;

  /// Загрузка сообществ
  ///
  /// In ru, this message translates to:
  /// **'Загрузка сообществ'**
  String get message7ff90dfabc89;

  /// Не удалось загрузить людей и сообщества.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить людей и сообщества.'**
  String get message648deacb6361;

  /// Пока нет предстоящих встреч.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет предстоящих встреч.'**
  String get messageb610d14732f0;

  /// Не удалось обновить места.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить места.'**
  String get messageca2860088a0f;

  /// Не удалось загрузить места.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить места.'**
  String get messageae374b391805;

  /// Показаны ранее загруженные места.
  ///
  /// In ru, this message translates to:
  /// **'Показаны ранее загруженные места.'**
  String get message48734fac6745;

  /// Попробуйте загрузить места ещё раз.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте загрузить места ещё раз.'**
  String get messagee1c058edde72;

  /// Список
  ///
  /// In ru, this message translates to:
  /// **'Список'**
  String get message93fd1e0f9feb;

  /// Не удалось загрузить карту.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить карту.'**
  String get message4b9181d8571c;

  /// Перейдите к списку мест.
  ///
  /// In ru, this message translates to:
  /// **'Перейдите к списку мест.'**
  String get messageec57a965fe87;

  /// В каталоге этого города пока нет мест.
  ///
  /// In ru, this message translates to:
  /// **'В каталоге этого города пока нет мест.'**
  String get messaged4198dcfe8f7;

  /// Сообщение должно быть не длиннее 1000 символов
  ///
  /// In ru, this message translates to:
  /// **'Сообщение должно быть не длиннее 1000 символов'**
  String get message9bf3f9251601;

  /// Текущие
  ///
  /// In ru, this message translates to:
  /// **'Текущие'**
  String get messageWalkingb2666bcc85a5;

  /// Мой профиль
  ///
  /// In ru, this message translates to:
  /// **'Мой профиль'**
  String get messageWalking88060502e211;

  /// Выгул и рейтинг
  ///
  /// In ru, this message translates to:
  /// **'Выгул и рейтинг'**
  String get messageWalking7f86482aa519;

  /// Назначенные прогулки
  ///
  /// In ru, this message translates to:
  /// **'Назначенные прогулки'**
  String get messageWalking4d35e7318ef5;

  /// Пока нет назначенных прогулок
  ///
  /// In ru, this message translates to:
  /// **'Пока нет назначенных прогулок'**
  String get messageWalking4dee7cd235cd;

  /// Мои запросы
  ///
  /// In ru, this message translates to:
  /// **'Мои запросы'**
  String get messageWalkingcc610707ac3f;

  /// Мои отклики
  ///
  /// In ru, this message translates to:
  /// **'Мои отклики'**
  String get messageWalking44897002f154;

  /// Вы ещё не назначены
  ///
  /// In ru, this message translates to:
  /// **'Вы ещё не назначены'**
  String get messageWalkingc93b07a7c1d3;

  /// Пока нет отправленных откликов
  ///
  /// In ru, this message translates to:
  /// **'Пока нет отправленных откликов'**
  String get messageWalking9bf4850c4523;

  /// Все даты
  ///
  /// In ru, this message translates to:
  /// **'Все даты'**
  String get messageWalking502fa7aca525;

  /// В этом периоде прогулок пока нет
  ///
  /// In ru, this message translates to:
  /// **'В этом периоде прогулок пока нет'**
  String get messageWalking90234bea14bf;

  /// Репутация по роли
  ///
  /// In ru, this message translates to:
  /// **'Репутация по роли'**
  String get messageWalkingf822dde5b924;

  /// Редактировать условия
  ///
  /// In ru, this message translates to:
  /// **'Редактировать условия'**
  String get messageWalking4ed2a2405c95;

  /// Подробности прогулки
  ///
  /// In ru, this message translates to:
  /// **'Подробности прогулки'**
  String get messageWalking03b406005aa6;

  /// Отклики: {p0}
  ///
  /// In ru, this message translates to:
  /// **'Отклики: {p0}'**
  String messageWalking927e2aa975d8(String p0);

  /// Отзыв уже оставлен
  ///
  /// In ru, this message translates to:
  /// **'Отзыв уже оставлен'**
  String get messageWalking6641971bf29f;

  /// Не удалось загрузить прогулки.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить прогулки.'**
  String get messageWalking1267682ee3c7;

  /// Мои прогулки и опыт
  ///
  /// In ru, this message translates to:
  /// **'Мои прогулки и опыт'**
  String get messageWalking76c5928026fc;

  /// Текущие прогулки, история и отзывы
  ///
  /// In ru, this message translates to:
  /// **'Текущие прогулки, история и отзывы'**
  String get messageWalking91de955f0881;

  /// Условия для прогулок
  ///
  /// In ru, this message translates to:
  /// **'Условия для прогулок'**
  String get messageWalkingdde0047379dc;

  /// Видны только участникам договорённости
  ///
  /// In ru, this message translates to:
  /// **'Видны только участникам договорённости'**
  String get messageWalking80e020cefd8b;

  /// Ответ владельца
  ///
  /// In ru, this message translates to:
  /// **'Ответ владельца'**
  String get messageWalking896aac9bc2d9;

  /// Чат
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get messageWalking8c77e45816c4;

  /// Как проходит прогулка
  ///
  /// In ru, this message translates to:
  /// **'Как проходит прогулка'**
  String get messageWalking7bfacbc95580;

  /// Запрос и выбор
  ///
  /// In ru, this message translates to:
  /// **'Запрос и выбор'**
  String get messageWalking418f53987eaa;

  /// Владелец выбирает одного помощника из откликов. Отклик ещё не означает назначение.
  ///
  /// In ru, this message translates to:
  /// **'Владелец выбирает одного помощника из откликов. Отклик ещё не означает назначение.'**
  String get messageWalkingb7bcff43977a;

  /// Договоритесь в чате
  ///
  /// In ru, this message translates to:
  /// **'Договоритесь в чате'**
  String get messageWalkinge8faea482ade;

  /// После назначения участникам доступен личный чат.
  ///
  /// In ru, this message translates to:
  /// **'После назначения участникам доступен личный чат.'**
  String get messageWalkinge8f813e513f3;

  /// Прогулка и подтверждение
  ///
  /// In ru, this message translates to:
  /// **'Прогулка и подтверждение'**
  String get messageWalkingd8a8c678b900;

  /// Помощник отмечает начало и окончание. Затем владелец подтверждает завершение.
  ///
  /// In ru, this message translates to:
  /// **'Помощник отмечает начало и окончание. Затем владелец подтверждает завершение.'**
  String get messageWalking90e19d941e67;

  /// Что означает рейтинг
  ///
  /// In ru, this message translates to:
  /// **'Что означает рейтинг'**
  String get messageWalkingbab2d7aa8c22;

  /// Опыт владельца и помощника учитывается отдельно — по опубликованным допустимым отзывам.
  ///
  /// In ru, this message translates to:
  /// **'Опыт владельца и помощника учитывается отдельно — по опубликованным допустимым отзывам.'**
  String get messageWalking7f8e0d68b456;

  /// Рейтинг помогает выбрать, но не гарантирует безопасность. У мест — отдельный рейтинг.
  ///
  /// In ru, this message translates to:
  /// **'Рейтинг помогает выбрать, но не гарантирует безопасность. У мест — отдельный рейтинг.'**
  String get messageWalkingb2074fc966de;

  /// Кто может оставить отзыв
  ///
  /// In ru, this message translates to:
  /// **'Кто может оставить отзыв'**
  String get messageWalking66b009980868;

  /// После подтверждённого завершения каждый назначенный участник может оставить один отзыв о другом. Нельзя оценивать себя или человека вне этой договорённости.
  ///
  /// In ru, this message translates to:
  /// **'После подтверждённого завершения каждый назначенный участник может оставить один отзыв о другом. Нельзя оценивать себя или человека вне этой договорённости.'**
  String get messageWalking2bf8d10491d4;

  /// Передача питомца
  ///
  /// In ru, this message translates to:
  /// **'Передача питомца'**
  String get messageWalking0516f084b8d6;

  /// Отзывы о вас как о владельце
  ///
  /// In ru, this message translates to:
  /// **'Отзывы о вас как о владельце'**
  String get messageWalkinga9d94f5032b2;

  /// Отзывы о вас как о помощнике
  ///
  /// In ru, this message translates to:
  /// **'Отзывы о вас как о помощнике'**
  String get messageWalkingca7161f845a8;

  /// Опыт и отзывы
  ///
  /// In ru, this message translates to:
  /// **'Опыт и отзывы'**
  String get messageWalking35cb994b8fc4;

  /// Владелец выбирает помощника из откликов.
  ///
  /// In ru, this message translates to:
  /// **'Владелец выбирает помощника из откликов.'**
  String get messageWalking1ad6b2ba45c0;

  /// Обсудите детали в личном чате после назначения.
  ///
  /// In ru, this message translates to:
  /// **'Обсудите детали в личном чате после назначения.'**
  String get messageWalking53951c3fe7ec;

  /// Помощник отмечает начало и конец, владелец подтверждает завершение.
  ///
  /// In ru, this message translates to:
  /// **'Помощник отмечает начало и конец, владелец подтверждает завершение.'**
  String get messageWalking9e23d3d53775;

  /// Рейтинг основан на отзывах о завершённых прогулках.
  ///
  /// In ru, this message translates to:
  /// **'Рейтинг основан на отзывах о завершённых прогулках.'**
  String get messageWalking8aa4f6e69d65;

  /// Отклик ещё не означает назначение.
  ///
  /// In ru, this message translates to:
  /// **'Отклик ещё не означает назначение.'**
  String get messageWalking7825dcb936ca;

  /// Детали прогулки
  ///
  /// In ru, this message translates to:
  /// **'Детали прогулки'**
  String get messageWalking6959ec61eff5;

  /// Не удалось загрузить прогулку
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить прогулку'**
  String get messageWalking0f3075c129a3;

  /// Прогулка недоступна
  ///
  /// In ru, this message translates to:
  /// **'Прогулка недоступна'**
  String get messageWalking46ca333724cd;

  /// Не удалось обновить статус. Обновите прогулку и попробуйте снова.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить статус. Обновите прогулку и попробуйте снова.'**
  String get messageWalking3059be73c438;

  /// Только для участников этой прогулки
  ///
  /// In ru, this message translates to:
  /// **'Только для участников этой прогулки'**
  String get messageWalking4aa946af3e7f;

  /// Что важно знать
  ///
  /// In ru, this message translates to:
  /// **'Что важно знать'**
  String get messageWalking3a6faeae4f88;

  /// Время места встречи
  ///
  /// In ru, this message translates to:
  /// **'Время места встречи'**
  String get messageWalkingd664c60270d6;

  /// Комментарий · необязательно
  ///
  /// In ru, this message translates to:
  /// **'Комментарий · необязательно'**
  String get messageWalkingfaaca5305132;

  /// Неприемлемое поведение
  ///
  /// In ru, this message translates to:
  /// **'Неприемлемое поведение'**
  String get messageWalkingb5bf28ed0847;

  /// Проблема с сообщениями или фото
  ///
  /// In ru, this message translates to:
  /// **'Проблема с сообщениями или фото'**
  String get messageWalking33f0bf824130;

  /// Причина и комментарий — не более 1000 символов
  ///
  /// In ru, this message translates to:
  /// **'Причина и комментарий — не более 1000 символов'**
  String get messageWalking48d48bd78b8b;

  /// Чат этой прогулки недоступен
  ///
  /// In ru, this message translates to:
  /// **'Чат этой прогулки недоступен'**
  String get messageWalking99cc5f3d96b3;

  /// Как помощник
  ///
  /// In ru, this message translates to:
  /// **'Как помощник'**
  String get messageWalking53ccc1dfe2ff;

  /// Как владелец
  ///
  /// In ru, this message translates to:
  /// **'Как владелец'**
  String get messageWalking1326b72d5619;

  /// Условия прогулок
  ///
  /// In ru, this message translates to:
  /// **'Условия прогулок'**
  String get messageWalking38e6452fe27c;

  /// Где
  ///
  /// In ru, this message translates to:
  /// **'Где'**
  String get messageWalking5d95fca8e04b;

  /// С какими питомцами
  ///
  /// In ru, this message translates to:
  /// **'С какими питомцами'**
  String get messageWalking24513ee9515e;

  /// Когда
  ///
  /// In ru, this message translates to:
  /// **'Когда'**
  String get messageWalking725347e42525;

  /// Доступность
  ///
  /// In ru, this message translates to:
  /// **'Доступность'**
  String get messageWalkinga1c56f5633c4;

  /// Отзывы появляются после подтверждённых прогулок.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы появляются после подтверждённых прогулок.'**
  String get messageWalkingcb5968d45b01;

  /// Передача и уход
  ///
  /// In ru, this message translates to:
  /// **'Передача и уход'**
  String get messageWalking4dc49c143c09;

  /// Заметка владельца
  ///
  /// In ru, this message translates to:
  /// **'Заметка владельца'**
  String get messageWalking4c8b61b41265;

  /// Duration of a walk in minutes
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} минута} few{{count} минуты} many{{count} минут} other{{count} минуты}}'**
  String walkingDurationMinutes(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['be', 'en', 'pl', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'be':
      return AppLocalizationsBe();
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
