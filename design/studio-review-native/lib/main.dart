import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'studio_theme.dart';
import 'generated/app_localizations.dart';
import 'message_bridge.dart';
import 'preview_copy.dart';

void main() => runApp(const ReviewApp());

class ReviewApp extends StatefulWidget {
  const ReviewApp({super.key});
  @override
  State<ReviewApp> createState() => ReviewAppState();
}

class ReviewAppState extends State<ReviewApp> {
  bool dark = false, helper = false, joined = false, communityJoined = false;
  bool applied = false, selected = false, reviewed = false, replied = false;
  bool favorites = true, allChats = false, busy = false, failSave = false;
  String draftRoles = 'both';
  bool draftHelper = false;
  bool filtersApplied = false, expandedReview = false;
  String locale = 'ru', page = 'nearby', scenario = 'populated';
  String tab = 'current', social = 'people', period = 'any', role = 'helper';
  String city = 'Минск', district = 'all', size = 'any', time = 'any';
  String walkState = 'selected', productRoles = 'both';
  double scale = 1;
  final List<String> history = [];
  final message = TextEditingController(), review = TextEditingController();
  final bio = TextEditingController(
    text: 'Люблю спокойные прогулки. Есть опыт ухода за собаками.',
  );
  final search = TextEditingController(), report = TextEditingController();
  final messages = <String>[];
  BuildContext? currentContext;
  String t(String s) =>
      previewCopy[s]?[locale] ??
      translateMessage(lookupAppLocalizations(Locale(locale)), s, {});
  void go(String destination) => setState(() {
    history.add(page);
    if (destination == 'roles') {
      draftRoles = productRoles;
      draftHelper = helper;
    }
    page = destination;
  });
  void back() => setState(() {
    if (history.isNotEmpty) page = history.removeLast();
  });
  void root(String destination) => setState(() {
    page = destination;
    history.clear();
    scenario = 'populated';
  });
  void captureState(
    String destination, {
    String state = 'populated',
    bool isHelper = false,
    String language = 'ru',
    bool isDark = false,
    double textScale = 1,
  }) {
    setState(() {
      page = destination;
      scenario = state;
      helper = isHelper;
      locale = language;
      dark = isDark;
      scale = textScale;
      history.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    final q = Uri.base.queryParameters;
    page = q['page'] ?? page;
    helper = q['mode'] == 'helper';
    dark = q['theme'] == 'dark';
    locale = ['ru', 'en', 'be', 'pl'].contains(q['locale'])
        ? q['locale']!
        : 'ru';
    scale = double.tryParse(q['scale'] ?? '1') ?? 1;
    scenario = q['state'] ?? scenario;
    tab = q['tab'] ?? tab;
    social = q['segment'] ?? social;
  }

  @override
  void dispose() {
    for (final c in [message, review, bio, search, report]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: reviewTheme(Brightness.light),
    darkTheme: reviewTheme(Brightness.dark),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: Locale(locale),
    supportedLocales: const [
      Locale('ru'),
      Locale('en'),
      Locale('be'),
      Locale('pl'),
    ],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Builder(
      builder: (context) {
        currentContext = context;
        return shell(context);
      },
    ),
  );
  bool get detailPage => ![
    'nearby',
    'social',
    'walks',
    'requests',
    'chats',
    'profile',
  ].contains(page);
  Widget shell(BuildContext context) {
    final nav = helper
        ? ['requests', 'walks', 'chats', 'profile']
        : ['nearby', 'social', 'walks', 'chats', 'profile'];
    final labels = helper
        ? ['Запросы', 'Мои прогулки', 'Чаты', 'Я']
        : ['Рядом', 'Люди', 'Выгул', 'Чаты', 'Я'];
    final icons = helper
        ? [
            Icons.list_alt,
            Icons.pets_outlined,
            Icons.chat_bubble_outline,
            Icons.person_outline,
          ]
        : [
            Icons.explore_outlined,
            Icons.people_outline,
            Icons.pets_outlined,
            Icons.chat_bubble_outline,
            Icons.person_outline,
          ];
    return PopScope(
      canPop: history.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) back();
      },
      child: Scaffold(
        appBar:
            page == 'chat' || page == 'community-chat' || page == 'meetup-chat'
            ? chatBar(context)
            : AppBar(
                leading: detailPage
                    ? IconButton(
                        key: const Key('back'),
                        tooltip: t('Назад'),
                        onPressed: back,
                        icon: const Icon(Icons.arrow_back),
                      )
                    : null,
                automaticallyImplyLeading: false,
                titleSpacing: detailPage ? 0 : 20,
                title: detailPage
                    ? Text(title())
                    : Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'petfriendly'),
                            TextSpan(
                              text: '.',
                              style: TextStyle(
                                color: dark
                                    ? StudioColors.lime
                                    : const Color(0xFF587322),
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                actions: [
                  if (!detailPage)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Center(
                        child: Text(
                          t(helper ? 'Помощник' : 'Владелец'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  if (page == 'profile')
                    IconButton(
                      tooltip: t('Настройки'),
                      onPressed: () => go('settings'),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  IconButton(
                    key: const Key('preview-controls'),
                    tooltip: t('Настройки макета'),
                    onPressed: lab,
                    icon: const Icon(Icons.tune, size: 20),
                  ),
                ],
              ),
        body: page.endsWith('chat')
            ? chat(context)
            : RefreshIndicator(
                onRefresh: refresh,
                child: ListView(
                  key: ValueKey('$page-$tab-$social'),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: content(context),
                ),
              ),
        bottomNavigationBar: detailPage
            ? null
            : NavigationBar(
                selectedIndex: nav.contains(page) ? nav.indexOf(page) : 0,
                onDestinationSelected: (i) => root(nav[i]),
                destinations: [
                  for (int i = 0; i < nav.length; i++)
                    NavigationDestination(
                      icon: Icon(icons[i]),
                      label: t(labels[i]),
                    ),
                ],
              ),
      ),
    );
  }

  String reputationSummary(double rating, int count, int completed) =>
      '${NumberFormat('0.0', locale).format(rating)} · ${lookupAppLocalizations(Locale(locale)).reviewCount(count)}${completed > 0 ? ' · ${lookupAppLocalizations(Locale(locale)).completedWalkCount(completed)}' : ''}';
  String dateLabel() => DateFormat.MMMMd(locale).format(DateTime(2026, 10, 18));
  String duration(int minutes) =>
      lookupAppLocalizations(Locale(locale)).walkingDurationMinutes(minutes);
  String title() => t(switch (page) {
    'settings' => 'Настройки',
    'roles' => 'Роль и режим',
    'conditions' => 'Условия прогулок',
    'edit-conditions' => 'Редактировать условия',
    'request' => 'Запрос на прогулку',
    'create-request' => 'Попросить о выгуле',
    'places' => 'Места рядом',
    'place' => 'Место',
    'community' => 'Сообщество',
    'meetup' => 'Встреча',
    'create-meetup' => 'Создать встречу',
    'public-helper' => 'Профиль помощника',
    'owner' => 'Профиль владельца',
    'onboarding' => 'Настройка помощника',
    _ => 'PetFriendly',
  });
  Future<void> refresh() async {
    setState(() => busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted)
      setState(() {
        busy = false;
        scenario = 'populated';
      });
  }

  void feedback(String text) => ScaffoldMessenger.of(
    currentContext!,
  ).showSnackBar(SnackBar(content: Text(t(text))));
  Widget heading(
    BuildContext c,
    String text, {
    VoidCallback? action,
    String? label,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(t(text), style: Theme.of(c).textTheme.headlineSmall),
        ),
        if (action != null)
          IconButton(
            tooltip: t(label ?? 'Обновить'),
            onPressed: action,
            icon: const Icon(Icons.refresh_outlined),
          ),
      ],
    ),
  );
  Widget caption(BuildContext c, String text) =>
      Text(t(text), style: Theme.of(c).textTheme.bodySmall);
  Widget group(BuildContext c, String name, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t(name), style: Theme.of(c).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
  Widget avatar(
    BuildContext c,
    String initials, {
    bool pet = false,
    double diameter = 48,
  }) => Container(
    width: diameter,
    height: diameter,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: StudioColors.of(c).tint,
      borderRadius: BorderRadius.circular(pet ? 14 : diameter / 2),
    ),
    child: pet
        ? const Icon(Icons.pets_outlined, size: 24)
        : Text(initials, style: Theme.of(c).textTheme.titleSmall),
  );
  Widget row(
    BuildContext c,
    String name,
    String subtitle, {
    IconData? icon,
    VoidCallback? onTap,
    String? initials,
    bool pet = false,
    Widget? trailing,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (initials != null)
            avatar(c, initials, pet: pet)
          else if (icon != null)
            Icon(icon, size: 22),
          if (initials != null || icon != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t(name), style: Theme.of(c).textTheme.titleMedium),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  caption(c, subtitle),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else if (onTap != null)
            const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
  Widget tabs(
    BuildContext c,
    List<String> labels,
    int value,
    ValueChanged<int> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: LayoutBuilder(
      builder: (c, b) {
        final scroll = scale > 1.3 || b.maxWidth < 330;
        final children = [
          for (int i = 0; i < labels.length; i++)
            Semantics(
              selected: i == value,
              button: true,
              child: InkWell(
                onTap: () => onChanged(i),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: i == value ? 2 : 1,
                        color: i == value
                            ? Theme.of(c).colorScheme.onSurface
                            : StudioColors.of(c).line,
                      ),
                    ),
                  ),
                  child: Text(
                    t(labels[i]),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: i == value
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
        ];
        return scroll
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: children),
              )
            : Row(children: children.map((w) => Expanded(child: w)).toList());
      },
    ),
  );
  Widget action(
    String text,
    VoidCallback? tap, {
    bool primary = true,
    IconData? icon,
  }) => primary
      ? FilledButton(onPressed: tap, child: Text(t(text)))
      : OutlinedButton.icon(
          onPressed: tap,
          icon: Icon(icon ?? Icons.arrow_forward, size: 18),
          label: Text(t(text)),
        );
  Widget navAction(
    BuildContext c,
    String text,
    VoidCallback tap, {
    IconData icon = Icons.chevron_right,
  }) => row(c, text, '', onTap: tap, icon: icon);
  Widget stateBlock(BuildContext c, String kind) {
    if (kind == 'loading')
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            caption(c, 'Загружаем…'),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 24),
            for (int i = 0; i < 3; i++)
              Container(
                height: 72,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: StudioColors.of(c).tint,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
          ],
        ),
      );
    final empty = kind == 'empty';
    final denied = kind == 'permission';
    final offline = kind == 'offline';
    final unavailable = kind == 'unavailable';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            empty
                ? Icons.search_off
                : denied
                ? Icons.lock_outline
                : Icons.cloud_off_outlined,
          ),
          const SizedBox(height: 12),
          Text(
            t(
              empty
                  ? 'Ничего не найдено'
                  : denied
                  ? 'Доступ недоступен'
                  : offline
                  ? 'Нет подключения'
                  : unavailable
                  ? 'Данные недоступны'
                  : 'Не удалось загрузить',
            ),
            style: Theme.of(c).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            t(
              empty
                  ? 'Измените фильтры или попробуйте позже.'
                  : denied
                  ? 'Доступ к чату зависит от участия.'
                  : offline
                  ? 'Сохранённые данные остаются на экране.'
                  : unavailable
                  ? 'Это не означает, что отзывов или прогулок нет.'
                  : 'Проверьте подключение и повторите попытку.',
            ),
          ),
          const SizedBox(height: 12),
          action(
            empty ? 'Сбросить фильтры' : 'Повторить',
            () {
              setState(() {
                scenario = 'populated';
                filtersApplied = false;
              });
            },
            primary: false,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  Widget cityFilter(BuildContext c, {bool list = false}) => Column(
    children: [
      row(
        c,
        city,
        t('Город поиска'),
        icon: Icons.location_city_outlined,
        onTap: citySheet,
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => filters(list ? 'places' : 'requests'),
            icon: const Icon(Icons.tune, size: 18),
            label: Text(
              filtersApplied
                  ? '${t('Фильтры')} · ${[period != 'any', district != 'all', size != 'any', time != 'any'].where((v) => v).length}'
                  : t('Фильтры'),
            ),
          ),
          if (filtersApplied)
            TextButton(
              onPressed: () {
                setState(() {
                  filtersApplied = false;
                  period = 'any';
                  district = 'all';
                  size = 'any';
                  time = 'any';
                });
              },
              child: Text(t('Сбросить')),
            ),
        ],
      ),
    ],
  );
  List<Widget> content(BuildContext c) => switch (page) {
    'nearby' => nearby(c),
    'social' => socialPage(c),
    'walks' => walks(c),
    'requests' => requests(c),
    'profile' => profile(c),
    'chats' => chats(c),
    'places' => places(c),
    'place' => place(c),
    'community' => community(c),
    'meetup' => meetup(c),
    'settings' => settings(c),
    'roles' => roles(c),
    'conditions' => conditions(c),
    'edit-conditions' => editConditions(c),
    'request' => request(c),
    'public-helper' => publicHelper(c),
    'owner' => owner(c),
    'create-request' => createRequest(c),
    'create-meetup' => createMeetup(c),
    'edit-profile' => [
      TextFormField(
        initialValue: 'Александра Ковальская',
        decoration: InputDecoration(labelText: t('Имя')),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: bio,
        maxLines: 3,
        decoration: InputDecoration(labelText: t('О себе')),
      ),
      const SizedBox(height: 16),
      row(c, city, '', onTap: citySheet, icon: Icons.location_city_outlined),
      const SizedBox(height: 24),
      action('Сохранить', save),
    ],
    'map' => [
      map(c),
      const SizedBox(height: 16),
      caption(c, 'Схема публичного места · демонстрация'),
      action(
        'Список мест',
        () => go('places'),
        primary: false,
        icon: Icons.format_list_bulleted,
      ),
    ],
    'onboarding' => onboarding(c),
    _ => [Text(page)],
  };
  List<Widget> nearby(BuildContext c) => [
    Text(
      t('Хороший день для прогулки.'),
      style: Theme.of(c).textTheme.headlineLarge,
    ),
    const SizedBox(height: 12),
    Text(
      t('И новой компании для вас обоих.'),
      style: TextStyle(color: Theme.of(c).colorScheme.onSurfaceVariant),
    ),
    const SizedBox(height: 24),
    InkWell(
      onTap: () {
        setState(() => social = 'meetups');
        go('social');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StudioColors.of(c).hero,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('Прогулка в парке'),
              style: Theme.of(c).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            caption(c, '${dateLabel()} · 11:00 · Парк Победы'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(t('Все встречи'))),
                const Icon(Icons.arrow_forward),
              ],
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 24),
    heading(c, 'Места рядом'),
    row(c, city, '', icon: Icons.location_city_outlined, onTap: citySheet),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => go('places'),
          icon: const Icon(Icons.format_list_bulleted, size: 18),
          label: Text(t('Список мест')),
        ),
        OutlinedButton.icon(
          onPressed: () => go('map'),
          icon: const Icon(Icons.open_in_full, size: 18),
          label: Text(t('На карте')),
        ),
      ],
    ),
    const SizedBox(height: 16),
    map(c),
    if (scenario != 'populated') stateBlock(c, scenario),
  ];
  Widget map(BuildContext c) => Container(
    height: 180,
    decoration: BoxDecoration(
      color: StudioColors.of(c).tint,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Stack(
      children: [
        Center(
          child: Icon(
            Icons.map_outlined,
            size: 64,
            color: Theme.of(c).colorScheme.outline,
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          right: 16,
          child: caption(c, 'Схема публичного места · демонстрация'),
        ),
      ],
    ),
  );
  List<Widget> places(BuildContext c) => [
    heading(c, 'Места рядом', action: refresh),
    searchField('Поиск мест'),
    cityFilter(c, list: true),
    const SizedBox(height: 16),
    if (scenario != 'populated')
      stateBlock(c, scenario)
    else ...[
      row(
        c,
        'Парк Победы',
        'Минск · Парк',
        icon: Icons.park_outlined,
        onTap: () => go('place'),
      ),
      const Divider(height: 1),
      row(
        c,
        'Парк Челюскинцев',
        'Минск · Парк',
        icon: Icons.park_outlined,
        onTap: () => go('place'),
      ),
    ],
  ];
  List<Widget> place(BuildContext c) => [
    heading(c, 'Парк Победы'),
    caption(c, 'Минск · Парк'),
    const SizedBox(height: 16),
    map(c),
    group(c, 'Для прогулки', [
      Text(t('Допуск питомцев не подтверждён')),
      caption(c, 'Данные места не являются гарантией допуска.'),
    ]),
    const SizedBox(height: 16),
    action(
      favorites ? 'Убрать из избранного' : 'В избранное',
      () => setState(() => favorites = !favorites),
      primary: false,
      icon: Icons.bookmark_outline,
    ),
  ];
  Widget searchField(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: search,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: t(label),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: search.text.isEmpty
            ? null
            : IconButton(
                tooltip: t('Очистить'),
                onPressed: () {
                  search.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
      ),
    ),
  );
  List<Widget> socialPage(BuildContext c) => [
    heading(c, 'Люди и встречи', action: refresh),
    tabs(
      c,
      ['Люди', 'Сообщества', 'Встречи'],
      ['people', 'communities', 'meetups'].indexOf(social),
      (i) => setState(() => social = ['people', 'communities', 'meetups'][i]),
    ),
    searchField(
      social == 'people'
          ? 'Поиск людей'
          : social == 'communities'
          ? 'Поиск сообществ'
          : 'Поиск встреч',
    ),
    row(c, city, '', icon: Icons.location_city_outlined, onTap: citySheet),
    Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => filters(social),
          icon: const Icon(Icons.tune, size: 18),
          label: Text(
            filtersApplied
                ? '${t('Фильтры')} · ${[period != 'any', district != 'all', size != 'any', time != 'any'].where((v) => v).length}'
                : t('Фильтры'),
          ),
        ),
        if (filtersApplied)
          TextButton(
            onPressed: () => setState(() {
              filtersApplied = false;
              period = 'any';
              district = 'all';
              size = 'any';
              time = 'any';
            }),
            child: Text(t('Сбросить')),
          ),
      ],
    ),
    if (scenario != 'populated')
      stateBlock(c, scenario)
    else if (social == 'people') ...[
      row(
        c,
        'Ульяна',
        'Центральный район · Минск',
        initials: 'УЛ',
        onTap: () => go('public-helper'),
      ),
      const Divider(height: 1),
      row(
        c,
        'Анна',
        'Советский район · Минск',
        initials: 'АН',
        onTap: () => go('owner'),
      ),
    ] else if (social == 'communities') ...[
      group(c, 'Мои сообщества', [
        if (communityJoined)
          row(
            c,
            'Собаки Минска',
            'Минск · 24 участника',
            icon: Icons.groups_outlined,
            onTap: () => go('community'),
          )
        else
          caption(c, 'Вы пока не вступили в сообщества.'),
      ]),
      group(c, 'Найти сообщество', [
        row(
          c,
          'Собаки Минска',
          'Спокойные прогулки и общение · Минск',
          icon: Icons.groups_outlined,
          onTap: () => go('community'),
        ),
        caption(c, '24 участника · Собаки, прогулки'),
        const Divider(height: 24),
        row(
          c,
          'Городские прогулки',
          'Встречи владельцев и питомцев · Минск',
          icon: Icons.groups_outlined,
          onTap: () => go('community'),
        ),
        caption(c, '12 участников · Парки, встречи'),
      ]),
    ] else ...[
      const SizedBox(height: 16),
      row(
        c,
        'Прогулка в парке',
        '18 октября · 11:00 · 60 минут',
        icon: Icons.calendar_today_outlined,
        onTap: () => go('meetup'),
      ),
      caption(c, 'Парк Победы · Анна · 8 из 12 участников'),
      caption(c, joined ? 'Вы участвуете' : 'Открыта для участия'),
      const Divider(height: 24),
      if (!helper)
        action(
          'Создать встречу',
          () => go('create-meetup'),
          primary: false,
          icon: Icons.add,
        ),
    ],
  ];
  List<Widget> community(BuildContext c) => [
    heading(c, 'Собаки Минска'),
    row(c, 'Минск', '24 участника', icon: Icons.groups_outlined),
    Text(
      'Обсуждаем спокойные прогулки, делимся общественными местами и встречаемся с питомцами.',
    ),
    const SizedBox(height: 12),
    caption(c, 'Собаки · Прогулки'),
    group(c, 'Участники', [
      row(c, 'Анна', '', initials: 'АН', onTap: () => go('owner')),
      row(c, 'Ульяна', '', initials: 'УЛ', onTap: () => go('public-helper')),
    ]),
    const SizedBox(height: 24),
    if (communityJoined) ...[
      action('Открыть чат', () => go('community-chat')),
      TextButton(
        onPressed: () => setState(() => communityJoined = false),
        child: Text(t('Выйти из сообщества')),
      ),
    ] else
      action('Вступить', () => setState(() => communityJoined = true)),
    caption(c, 'Приглашение не вступает в сообщество автоматически.'),
  ];
  List<Widget> meetup(BuildContext c) => [
    heading(c, 'Прогулка в парке'),
    row(
      c,
      '${dateLabel()} · 11:00',
      '60 минут · Время места встречи',
      icon: Icons.calendar_today_outlined,
    ),
    row(c, 'Парк Победы', 'Минск', icon: Icons.location_on_outlined),
    map(c),
    group(c, 'Организатор', [
      row(
        c,
        'Анна',
        '8 из 12 участников',
        initials: 'АН',
        onTap: () => go('owner'),
      ),
    ]),
    const SizedBox(height: 12),
    Text(
      'Встречаемся у общественного входа в парк. Пойдём спокойным маршрутом.',
    ),
    const SizedBox(height: 24),
    if (joined) ...[
      action('Открыть чат', () => go('meetup-chat')),
      TextButton(
        onPressed: () => setState(() => joined = false),
        child: Text(t('Отменить участие')),
      ),
    ] else
      action('Присоединиться', () => setState(() => joined = true)),
  ];
  List<Widget> requests(BuildContext c) => [
    heading(c, 'Запросы', action: refresh),
    cityFilter(c),
    const SizedBox(height: 16),
    if (scenario != 'populated')
      stateBlock(c, scenario)
    else ...[
      row(
        c,
        'Луна',
        '${dateLabel()} · 10:00 · ${duration(45)}',
        initials: '',
        pet: true,
        onTap: () => go('request'),
      ),
      caption(c, 'Небольшая собака · Центральный район'),
      const SizedBox(height: 8),
      Text('Нужна спокойная прогулка утром, пока я на работе.'),
      const SizedBox(height: 8),
      row(
        c,
        'Анна',
        t('Как владелец') +
            ' · 4,9 · ' +
            lookupAppLocalizations(Locale(locale)).reviewCount(3),
        initials: 'АН',
        onTap: () => go('owner'),
      ),
      caption(
        c,
        applied
            ? 'Отклик отправлен · ожидаем выбор владельца'
            : 'Можно откликнуться',
      ),
      const Divider(height: 24),
      row(
        c,
        'Арчи',
        '${dateLabel()} · 18:30 · ${duration(30)}',
        initials: '',
        pet: true,
        onTap: () => go('request'),
      ),
      caption(c, 'Средняя собака · Советский район'),
    ],
  ];
  List<Widget> request(BuildContext c) => [
    row(
      c,
      'Луна',
      'Корги · 3 года · Небольшая собака',
      initials: '',
      pet: true,
    ),
    row(
      c,
      '${dateLabel()} · 10:00',
      '45 минут · Время места встречи',
      icon: Icons.calendar_today_outlined,
    ),
    row(c, 'Центральный район', 'Минск', icon: Icons.location_on_outlined),
    row(
      c,
      'Анна',
      t('Как владелец') +
          ' · 4,9 · ' +
          lookupAppLocalizations(Locale(locale)).reviewCount(3),
      initials: 'АН',
      onTap: () => go('owner'),
    ),
    const SizedBox(height: 16),
    Text('Нужна спокойная прогулка утром. Луна любит привычный маршрут.'),
    group(c, 'Участие', [
      Text(
        t(
          selected
              ? 'Помощник выбран'
              : applied
              ? 'Отклик отправлен · ожидаем выбор владельца'
              : 'Можно откликнуться',
        ),
      ),
      const SizedBox(height: 12),
      if (selected)
        action('Открыть чат', () => go('chat'))
      else if (applied)
        action(
          'Отозвать отклик',
          () => setState(() => applied = false),
          primary: false,
        )
      else
        action('Откликнуться', () => setState(() => applied = true)),
    ]),
    if (!helper && !selected)
      group(c, 'Отклики', [
        row(
          c,
          'Ульяна',
          '4,8 · 12 отзывов',
          initials: 'УЛ',
          onTap: () => go('public-helper'),
        ),
        action('Выбрать помощника', () {
          setState(() {
            selected = true;
            walkState = 'selected';
          });
          go('chat');
        }),
      ]),
  ];
  List<Widget> walks(BuildContext c) => [
    heading(c, helper ? 'Мои прогулки' : 'Выгул', action: refresh),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: howItWorks,
        icon: const Icon(Icons.help_outline, size: 18),
        label: Text(t('Как это работает')),
      ),
    ),
    tabs(
      c,
      ['Текущие', 'История', 'Отзывы'],
      ['current', 'history', 'reviews'].indexOf(tab),
      (i) => setState(() => tab = ['current', 'history', 'reviews'][i]),
    ),
    if (tab == 'reviews')
      ...reviews(c)
    else ...[
      if (tab == 'history')
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: periodSheet,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(
              t(
                period == 'any'
                    ? 'За всё время'
                    : period == 'week'
                    ? 'За неделю'
                    : 'За месяц',
              ),
            ),
          ),
        ),
      if (scenario != 'populated')
        stateBlock(c, scenario)
      else ...[
        walkRow(c, 'Луна', tab == 'history'),
        const Divider(height: 24),
        if (tab == 'history')
          walkRow(c, 'Арчи', true, cancelled: true)
        else
          walkRow(c, 'Арчи', false),
      ],
      if (!helper && tab == 'current')
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: action(
              'Попросить о выгуле',
              () => go('create-request'),
              primary: false,
              icon: Icons.add,
            ),
          ),
        ),
    ],
  ];
  Widget walkRow(
    BuildContext c,
    String name,
    bool past, {
    bool cancelled = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      row(
        c,
        name,
        '${dateLabel()} · 10:00 · ' +
            t(helper ? 'Вы — помощник' : 'Вы — владелец'),
        initials: '',
        pet: true,
        onTap: () => go('chat'),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 60),
        child: caption(c, t(helper ? 'Владелец · Анна' : 'Помощник · Ульяна')),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Icon(
            cancelled
                ? Icons.cancel_outlined
                : past
                ? Icons.check_circle_outline
                : Icons.schedule_outlined,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t(
                cancelled
                    ? 'Отменена'
                    : past
                    ? 'Завершена'
                    : walkState == 'waiting'
                    ? 'Ждёт подтверждения'
                    : walkState == 'progress'
                    ? 'Идёт прогулка'
                    : 'Помощник выбран',
              ),
            ),
          ),
          if (past && !cancelled && !reviewed && scale <= 1.3)
            OutlinedButton(
              onPressed: reviewSheet,
              child: Text(t('Оставить отзыв')),
            ),
        ],
      ),
      if (past && !cancelled && !reviewed && scale > 1.3)
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: reviewSheet,
            child: Text(t('Оставить отзыв')),
          ),
        ),
      if (past && reviewed && !cancelled) caption(c, 'Отзыв оставлен'),
    ],
  );
  List<Widget> reviews(BuildContext c) => [
    row(c, 'Александра Ковальская', '', initials: 'АК'),
    row(
      c,
      'Условия прогулок',
      'Минск · Центральный район',
      icon: Icons.tune,
      onTap: () => go('conditions'),
    ),
    tabs(
      c,
      ['Как помощник', 'Как владелец'],
      role == 'helper' ? 0 : 1,
      (i) => setState(() => role = i == 0 ? 'helper' : 'owner'),
    ),
    if (scenario == 'empty') ...[
      Text(t('Пока нет отзывов'), style: Theme.of(c).textTheme.titleMedium),
      const SizedBox(height: 8),
      caption(c, 'Отзывы появляются после подтверждённых прогулок.'),
      const SizedBox(height: 12),
      caption(c, 'Завершённых прогулок пока нет'),
    ] else if (scenario != 'populated')
      stateBlock(c, scenario)
    else ...[
      Wrap(
        spacing: 32,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('4,8', style: Theme.of(c).textTheme.headlineSmall),
              caption(
                c,
                lookupAppLocalizations(Locale(locale)).reviewCount(12),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('24', style: Theme.of(c).textTheme.headlineSmall),
              caption(c, 'Завершённых прогулок'),
            ],
          ),
        ],
      ),
      const Divider(height: 32),
      row(
        c,
        'Екатерина Александровская-Лисовская',
        DateFormat.yMMMd(locale).format(DateTime(2026, 10, 12)),
        initials: 'ЕК',
        trailing: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.star_outline, size: 18), Text(' 5')],
        ),
      ),
      Text(
        'Спасибо за внимательное отношение к просьбе выбрать спокойный маршрут. Заранее уточнила привычки собаки и подробно рассказала, как прошла прогулка. Луна вернулась спокойной и довольной.',
        maxLines: expandedReview ? null : 4,
        overflow: expandedReview ? TextOverflow.visible : TextOverflow.ellipsis,
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => setState(() => expandedReview = !expandedReview),
          child: Text(t(expandedReview ? 'Свернуть' : 'Читать полностью')),
        ),
      ),
      if (replied)
        Container(
          padding: const EdgeInsets.all(12),
          color: StudioColors.of(c).tint,
          child: Text('Спасибо! Рада, что прогулка прошла комфортно.'),
        )
      else
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: replySheet,
            icon: const Icon(Icons.reply, size: 18),
            label: Text(t('Ответить на отзыв')),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: reportSheet,
          child: Text(t('Пожаловаться на отзыв')),
        ),
      ),
    ],
  ];
  PreferredSizeWidget chatBar(BuildContext c) => AppBar(
    leading: IconButton(
      tooltip: t('Назад'),
      onPressed: back,
      icon: const Icon(Icons.arrow_back),
    ),
    titleSpacing: 0,
    title: Row(
      children: [
        avatar(c, page == 'chat' ? 'УЛ' : 'АН', diameter: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                page == 'chat'
                    ? (helper ? 'Анна' : 'Ульяна')
                    : page == 'community-chat'
                    ? 'Собаки Минска'
                    : 'Прогулка в парке',
                style: Theme.of(c).textTheme.titleMedium,
              ),
              caption(
                c,
                page == 'chat'
                    ? (helper ? 'Владелец' : 'Помощник')
                    : 'Чат участников',
              ),
            ],
          ),
        ),
      ],
    ),
    actions: [
      IconButton(
        tooltip: t('Сообщить о проблеме'),
        onPressed: reportSheet,
        icon: const Icon(Icons.error_outline),
      ),
    ],
  );
  Widget chat(BuildContext c) => scenario != 'populated'
      ? ListView(
          padding: const EdgeInsets.all(20),
          children: [stateBlock(c, scenario)],
        )
      : Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  if (page == 'chat')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          row(
                            c,
                            'Луна',
                            '${dateLabel()} · 10:00 · Минск',
                            initials: '',
                            pet: true,
                            onTap: detailsSheet,
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: progress(c),
                          ),
                          if (walkState != 'completed')
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: action(
                                  helper
                                      ? (walkState == 'selected'
                                            ? 'Начать прогулку'
                                            : walkState == 'progress'
                                            ? 'Завершить прогулку'
                                            : 'Ждём владельца')
                                      : (walkState == 'waiting'
                                            ? 'Подтвердить завершение'
                                            : 'Написать помощнику'),
                                  helper && walkState == 'waiting'
                                      ? null
                                      : () {
                                          if (helper)
                                            setState(
                                              () => walkState =
                                                  walkState == 'selected'
                                                  ? 'progress'
                                                  : 'waiting',
                                            );
                                          else if (walkState == 'waiting')
                                            setState(
                                              () => walkState = 'completed',
                                            );
                                          else
                                            FocusScope.of(c).nextFocus();
                                        },
                                ),
                              ),
                            ),
                          if (walkState == 'completed' && !reviewed)
                            Align(
                              alignment: Alignment.centerRight,
                              child: action(
                                'Оставить отзыв',
                                reviewSheet,
                                primary: false,
                                icon: Icons.star_outline,
                              ),
                            ),
                          const Divider(height: 1),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: caption(c, dateLabel())),
                        const SizedBox(height: 16),
                        bubble(
                          c,
                          'Встречаемся у входа со стороны сквера?',
                          false,
                          '10:47',
                        ),
                        bubble(c, 'Да, буду с Луной в 10:00.', true, '10:49'),
                        for (final m in messages) bubble(c, m, true, '10:50'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: t('Прикрепить фото'),
                      onPressed: photoSheet,
                      icon: const Icon(Icons.add),
                    ),
                    Expanded(
                      child: TextField(
                        controller: message,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: t('Написать сообщение…'),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: t('Отправить'),
                      onPressed: message.text.trim().isEmpty
                          ? null
                          : () {
                              setState(() {
                                messages.add(message.text.trim());
                                message.clear();
                              });
                            },
                      icon: const Icon(Icons.arrow_upward),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
  Widget bubble(BuildContext c, String text, bool mine, String time) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(c).width * .8),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mine ? StudioColors.lime : StudioColors.of(c).tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: mine
                  ? StudioColors.onLime
                  : Theme.of(c).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${mine ? t('Вы') : 'Ульяна'} · $time',
            style: TextStyle(
              fontSize: 12,
              color: mine
                  ? StudioColors.onLime
                  : Theme.of(c).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
  Widget progress(BuildContext c) {
    final index = [
      'selected',
      'progress',
      'waiting',
      'completed',
    ].indexOf(walkState);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: t(switch (walkState) {
            'progress' => 'Идёт прогулка',
            'waiting' => 'Ждёт подтверждения',
            'completed' => 'Завершена',
            _ => 'Помощник выбран',
          }),
          child: Row(
            children: [
              for (int i = 0; i < 4; i++)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                    color: i <= index
                        ? Theme.of(c).colorScheme.onSurface
                        : StudioColors.of(c).line,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t(switch (walkState) {
            'progress' => 'Идёт прогулка',
            'waiting' => 'Ждёт подтверждения',
            'completed' => 'Завершена',
            _ => 'Помощник выбран',
          }),
        ),
        caption(c, t('Выбор → прогулка → подтверждение → завершение')),
      ],
    );
  }

  List<Widget> chats(BuildContext c) => [
    heading(c, 'Чаты'),
    if (helper)
      tabs(
        c,
        ['По прогулкам', 'Все чаты'],
        allChats ? 1 : 0,
        (i) => setState(() => allChats = i == 1),
      ),
    if (scenario != 'populated')
      stateBlock(c, scenario)
    else ...[
      row(
        c,
        'Ульяна',
        'Луна · ' + t('Помощник выбран'),
        initials: 'УЛ',
        onTap: () => go('chat'),
      ),
      const Divider(height: 1),
      if (!helper || allChats) ...[
        row(
          c,
          'Собаки Минска',
          'Анна · ' + t('Встречаемся завтра?'),
          initials: 'СМ',
          onTap: () => go('community-chat'),
        ),
        const Divider(height: 1),
        row(
          c,
          'Прогулка в парке',
          'Анна · 10:40',
          initials: 'ПП',
          onTap: () => go('meetup-chat'),
        ),
      ],
    ],
    if (helper && !allChats)
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: caption(
          c,
          'Остальные разговоры доступны во вкладке «Все чаты».',
        ),
      ),
  ];
  List<Widget> profile(BuildContext c) => [
    heading(c, 'Я'),
    row(
      c,
      'Александра Ковальская',
      helper ? 'Помощник · Минск' : 'Владелец · Минск',
      initials: 'АК',
    ),
    if (helper) ...[
      const SizedBox(height: 8),
      Text(bio.text),
      group(c, 'Условия прогулок', [
        row(
          c,
          'Минск · Центральный район',
          'Пн–Пт · 09:00–17:00',
          icon: Icons.tune,
          onTap: () => go('conditions'),
        ),
      ]),
      group(c, 'Репутация помощника', [
        caption(c, reputationSummary(4.8, 12, 24)),
      ]),
      const SizedBox(height: 24),
      action(
        'Редактировать профиль',
        () => go('edit-profile'),
        primary: false,
        icon: Icons.edit_outlined,
      ),
    ] else ...[
      group(c, 'Мои питомцы', [
        row(c, 'Луна', 'Корги · 3 года', initials: '', pet: true),
      ]),
      group(c, 'Избранные места', [
        if (favorites)
          row(
            c,
            'Парк Победы',
            'Минск · Парк',
            icon: Icons.park_outlined,
            onTap: () => go('place'),
          )
        else ...[
          Text(t('Пока нет избранных мест')),
          caption(c, 'Сохраняйте места, к которым хотите вернуться.'),
          TextButton(
            onPressed: () => go('places'),
            child: Text(t('Найти места')),
          ),
        ],
      ]),
      const SizedBox(height: 24),
      action(
        'Редактировать профиль',
        () => go('edit-profile'),
        primary: false,
        icon: Icons.edit_outlined,
      ),
    ],
  ];
  List<Widget> settings(BuildContext c) => [
    row(
      c,
      'Роль и режим',
      t(
            productRoles == 'both'
                ? 'Владелец и помощник'
                : productRoles == 'helper'
                ? 'Помощник'
                : 'Владелец',
          ) +
          ' · ' +
          t(helper ? 'Сейчас: помощник' : 'Сейчас: владелец'),
      icon: Icons.swap_horiz,
      onTap: () => go('roles'),
    ),
    const Divider(height: 1),
    row(
      c,
      'Язык приложения',
      {
        'ru': 'Русский',
        'en': 'English',
        'be': 'Беларуская',
        'pl': 'Polski',
      }[locale]!,
      icon: Icons.language,
      onTap: languageSheet,
    ),
    row(
      c,
      'Тема',
      t(dark ? 'Тёмная' : 'Светлая'),
      icon: Icons.brightness_6_outlined,
      onTap: () {
        setState(() => dark = !dark);
      },
    ),
    row(
      c,
      'Безопасность',
      '',
      icon: Icons.lock_outline,
      onTap: () => feedback('Существующий раздел остаётся без изменений.'),
    ),
    row(
      c,
      'Об аккаунте',
      '',
      icon: Icons.info_outline,
      onTap: () => feedback('Существующий раздел остаётся без изменений.'),
    ),
  ];
  List<Widget> roles(BuildContext c) => [
    Text(
      t('Один аккаунт, разные задачи.'),
      style: Theme.of(c).textTheme.titleMedium,
    ),
    const SizedBox(height: 8),
    Text(
      t(
        'Роль определяет доступные действия. Режим меняет разделы приложения, сохраняя чаты и историю.',
      ),
    ),
    group(c, 'Что вы хотите делать?', [
      for (final r in ['owner', 'helper', 'both'])
        choice(
          c,
          t(
            r == 'owner'
                ? 'Владелец'
                : r == 'helper'
                ? 'Помощник'
                : 'Владелец и помощник',
          ),
          draftRoles == r,
          () => setState(() => draftRoles = r),
        ),
    ]),
    group(c, 'Активный режим', [
      choice(
        c,
        t('Владелец'),
        !draftHelper,
        draftRoles == 'helper'
            ? null
            : () => setState(() => draftHelper = false),
      ),
      choice(
        c,
        t('Помощник'),
        draftHelper,
        draftRoles == 'owner' ? null : () => setState(() => draftHelper = true),
      ),
    ]),
    const SizedBox(height: 24),
    action('Сохранить', () {
      if (draftRoles == 'helper') draftHelper = true;
      if (draftRoles == 'owner') draftHelper = false;
      productRoles = draftRoles;
      helper = draftHelper;
      feedback('Изменения сохранены');
      back();
    }),
    caption(c, 'История, переписка и один аккаунт сохраняются.'),
  ];
  Widget choice(
    BuildContext c,
    String label,
    bool selected,
    VoidCallback? onTap,
  ) => Semantics(
    selected: selected,
    enabled: onTap != null,
    button: true,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: onTap == null ? Theme.of(c).disabledColor : null,
                ),
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: Theme.of(c).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    ),
  );
  List<Widget> conditions(BuildContext c) => [
    row(c, 'Минск · Центральный район', '', icon: Icons.location_on_outlined),
    group(c, 'С какими питомцами', [
      Text(t('Небольшие и средние собаки')),
      const SizedBox(height: 8),
      Text('Люблю спокойные прогулки. Есть опыт ухода за собаками.'),
    ]),
    group(c, 'Где могу помочь', [Text('Центральный район, Советский район')]),
    group(c, 'Когда', [
      row(c, 'Пн–Пт', '09:00–17:00', icon: Icons.schedule_outlined),
      caption(c, 'Время в Минске · UTC+3'),
    ]),
    group(c, 'Доступность', [Text(t('Готов обсуждать прогулки'))]),
    const SizedBox(height: 24),
    Align(
      alignment: Alignment.centerLeft,
      child: action(
        'Редактировать условия',
        () => go('edit-conditions'),
        primary: false,
        icon: Icons.edit_outlined,
      ),
    ),
  ];
  List<Widget> editConditions(BuildContext c) => [
    TextField(
      controller: bio,
      maxLines: 3,
      decoration: InputDecoration(labelText: t('О себе')),
    ),
    group(c, 'С какими питомцами', [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in ['Небольшие', 'Средние', 'Крупные'])
            PreviewChoiceChip(
              label: Text(t(s)),
              selected: size == s,
              onSelected: (_) => setState(() => size = s),
            ),
        ],
      ),
    ]),
    group(c, 'Где могу помочь', [
      row(c, city, '', onTap: citySheet, icon: Icons.location_city_outlined),
      TextFormField(
        initialValue: 'Центральный район',
        decoration: InputDecoration(labelText: t('Публичный район')),
      ),
    ]),
    group(c, 'Когда', [
      TextFormField(
        initialValue: 'Пн–Пт · 09:00–17:00',
        decoration: InputDecoration(labelText: t('Доступность')),
      ),
    ]),
    const SizedBox(height: 24),
    if (scenario == 'error')
      Text(
        t('Не удалось сохранить. Введённые данные остаются здесь.'),
        style: TextStyle(color: Theme.of(c).colorScheme.error),
      ),
    action(busy ? 'Сохраняем…' : 'Сохранить', busy ? null : save),
    TextButton(onPressed: back, child: Text(t('Отмена'))),
  ];
  Future<void> save() async {
    setState(() => busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => busy = false);
    if (failSave) {
      setState(() => scenario = 'error');
      feedback('Не удалось сохранить. Введённые данные остаются здесь.');
    } else {
      feedback('Изменения сохранены');
      back();
    }
  }

  List<Widget> publicHelper(BuildContext c) => [
    row(c, 'Ульяна', 'Минск · Центральный район', initials: 'УЛ'),
    Text('Люблю спокойные прогулки. Есть опыт ухода за собаками.'),
    group(c, 'Репутация помощника', [Text(reputationSummary(4.8, 12, 24))]),
    group(c, 'Условия прогулок', [
      Text(t('Небольшие и средние собаки')),
      caption(c, 'Пн–Пт · 09:00–17:00'),
    ]),
    const SizedBox(height: 24),
    action('Обсудить прогулку', () => go('chat')),
    TextButton(onPressed: reportSheet, child: Text(t('Сообщить о проблеме'))),
    TextButton(
      onPressed: () => feedback('Демонстрация · действие не отправляется'),
      child: Text(t('Заблокировать')),
    ),
    group(c, 'Отзывы', [
      row(c, 'Анна', '12 октября · 5', initials: 'АН'),
      Text('Спасибо за спокойную прогулку и внимательность к питомцу.'),
    ]),
  ];
  List<Widget> owner(BuildContext c) => [
    row(c, 'Анна', 'Минск · Советский район', initials: 'АН'),
    group(c, 'Как владелец', [
      Text(reputationSummary(4.9, 3, 0)),
      caption(c, 'Опубликованные отзывы участников прогулок'),
    ]),
    group(c, 'Отзывы', [
      Text(
        'Всё было понятно: время, публичное место и привычки собаки обсудили заранее.',
      ),
    ]),
    const SizedBox(height: 24),
    action('Обсудить прогулку', () => go('chat')),
  ];
  List<Widget> createRequest(BuildContext c) => [
    TextFormField(
      initialValue: 'Луна',
      decoration: InputDecoration(labelText: t('Питомец')),
    ),
    const SizedBox(height: 16),
    row(
      c,
      '${dateLabel()} · 10:00',
      '45 минут',
      icon: Icons.calendar_today_outlined,
      onTap: periodSheet,
    ),
    TextField(
      controller: review,
      maxLines: 3,
      decoration: InputDecoration(labelText: t('Публичное описание')),
    ),
    const SizedBox(height: 16),
    TextFormField(
      initialValue: '',
      maxLines: 2,
      decoration: InputDecoration(labelText: t('Передача и уход')),
    ),
    caption(c, 'Только для участников этой прогулки'),
    const SizedBox(height: 24),
    action('Опубликовать', () {
      feedback('Демонстрационный запрос создан');
      root('walks');
    }),
  ];
  List<Widget> createMeetup(BuildContext c) => [
    TextFormField(
      initialValue: 'Прогулка в парке',
      decoration: InputDecoration(labelText: t('Название')),
    ),
    const SizedBox(height: 16),
    row(
      c,
      '${dateLabel()} · 11:00',
      'Минск · Время места встречи',
      icon: Icons.calendar_today_outlined,
      onTap: periodSheet,
    ),
    row(
      c,
      'Парк Победы',
      'Публичное место',
      icon: Icons.location_on_outlined,
      onTap: () => go('place'),
    ),
    TextField(
      controller: review,
      maxLines: 3,
      decoration: InputDecoration(labelText: t('Описание')),
    ),
    const SizedBox(height: 24),
    action('Создать встречу', () {
      feedback('Демонстрационная встреча создана');
      root('social');
    }),
  ];
  int onboardingStep = 0;
  List<Widget> onboarding(BuildContext c) => [
    caption(c, '${onboardingStep + 1} / 3'),
    heading(
      c,
      onboardingStep == 0
          ? 'Профиль помощника'
          : onboardingStep == 1
          ? 'Где и с кем гулять'
          : 'Ваша доступность',
    ),
    if (onboardingStep == 0) ...[
      row(c, 'Александра Ковальская', '', initials: 'АК'),
      TextField(
        controller: bio,
        maxLines: 3,
        decoration: InputDecoration(labelText: t('О себе')),
      ),
    ] else if (onboardingStep == 1) ...[
      row(c, city, '', onTap: citySheet, icon: Icons.location_city_outlined),
      Text(t('Питомец не нужен, чтобы стать помощником.')),
      Wrap(
        spacing: 8,
        children: [
          for (final s in ['Небольшие', 'Средние', 'Крупные'])
            PreviewChoiceChip(
              label: Text(t(s)),
              selected: size == s,
              onSelected: (_) => setState(() => size = s),
            ),
        ],
      ),
    ] else ...[
      TextFormField(
        initialValue: 'Пн–Пт · 09:00–17:00',
        decoration: InputDecoration(labelText: t('Доступность')),
      ),
    ],
    const SizedBox(height: 24),
    action(onboardingStep < 2 ? 'Продолжить' : 'Готово', () {
      if (onboardingStep < 2)
        setState(() => onboardingStep++);
      else {
        helper = true;
        root('requests');
      }
    }),
  ];
  Future<void> sheet(
    String title,
    Widget Function(BuildContext, StateSetter) body,
  ) => showModalBottomSheet<void>(
    context: currentContext!,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: false,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(currentContext!)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 250),
            reverseDuration: Duration(milliseconds: 220),
          ),
    backgroundColor: Theme.of(currentContext!).colorScheme.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (c) => StatefulBuilder(
      builder: (c, update) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(c).height * .86,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t(title),
                          style: Theme.of(c).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: t('Закрыть'),
                        onPressed: () => Navigator.pop(c),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: body(c, update),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  void citySheet() => sheet(
    'Город поиска',
    (c, u) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: t('Поиск города'),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        for (final name in ['Минск', 'Гродно', 'Варшава'])
          row(
            c,
            name,
            name == 'Варшава' ? 'Polska' : 'Беларусь',
            icon: Icons.location_city_outlined,
            onTap: () {
              setState(() => city = name);
              Navigator.pop(c);
            },
          ),
      ],
    ),
  );
  void filters(String kind) {
    String nextDate = period,
        nextDistrict = district,
        nextSize = size,
        nextTime = time;
    sheet(
      'Фильтры',
      (c, u) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          caption(c, city),
          const SizedBox(height: 16),
          Text(t('Дата'), style: Theme.of(c).textTheme.titleSmall),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in {
                'any': 'Любая дата',
                'week': 'На неделе',
                'month': 'В этом месяце',
              }.entries)
                PreviewChoiceChip(
                  label: Text(t(e.value)),
                  selected: nextDate == e.key,
                  onSelected: (_) => u(() => nextDate = e.key),
                ),
            ],
          ),
          if (kind == 'requests') ...[
            const SizedBox(height: 16),
            Text(t('Время'), style: Theme.of(c).textTheme.titleSmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in {
                  'any': 'Любое время',
                  'morning': 'Утро',
                  'evening': 'Вечер',
                }.entries)
                  PreviewChoiceChip(
                    label: Text(t(e.value)),
                    selected: nextTime == e.key,
                    onSelected: (_) => u(() => nextTime = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(t('Размер собаки'), style: Theme.of(c).textTheme.titleSmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in {
                  'any': 'Любой размер',
                  'small': 'Небольшие',
                  'medium': 'Средние',
                  'large': 'Крупные',
                }.entries)
                  PreviewChoiceChip(
                    label: Text(t(e.value)),
                    selected: nextSize == e.key,
                    onSelected: (_) => u(() => nextSize = e.key),
                  ),
              ],
            ),
          ],
          if (kind == 'meetups') ...[
            const SizedBox(height: 16),
            Text(t('Участие'), style: Theme.of(c).textTheme.titleSmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in ['Все встречи', 'Участвую', 'Организую'])
                  PreviewChoiceChip(
                    label: Text(t(name)),
                    selected: nextTime == name,
                    onSelected: (_) => u(() => nextTime = name),
                  ),
              ],
            ),
          ],
          if (kind == 'places') ...[
            const SizedBox(height: 16),
            Text(t('Категория'), style: Theme.of(c).textTheme.titleSmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in [
                  'Все',
                  'Парки',
                  'Ветклиники',
                  'Зоомагазины',
                ])
                  PreviewChoiceChip(
                    label: Text(t(name)),
                    selected: nextSize == name,
                    onSelected: (_) => u(() => nextSize = name),
                  ),
              ],
            ),
          ],
          if (kind == 'communities') ...[
            const SizedBox(height: 16),
            Text(t('Интересы'), style: Theme.of(c).textTheme.titleSmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in ['Все', 'Собаки', 'Кошки', 'Прогулки'])
                  PreviewChoiceChip(
                    label: Text(t(name)),
                    selected: nextSize == name,
                    onSelected: (_) => u(() => nextSize = name),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            t('Район · необязательно'),
            style: Theme.of(c).textTheme.titleSmall,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in [
                'all',
                'Центральный район',
                'Советский район',
              ])
                PreviewChoiceChip(
                  label: Text(name == 'all' ? t('Все районы') : name),
                  selected: nextDistrict == name,
                  onSelected: (_) => u(() => nextDistrict = name),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              action('Показать результаты', () {
                setState(() {
                  period = nextDate;
                  district = nextDistrict;
                  size = nextSize;
                  time = nextTime;
                  filtersApplied =
                      nextDate != 'any' ||
                      nextDistrict != 'all' ||
                      nextSize != 'any' ||
                      nextTime != 'any';
                  scenario = filtersApplied && nextDistrict == 'Советский район'
                      ? 'empty'
                      : 'populated';
                });
                Navigator.pop(c);
              }),
              TextButton(
                onPressed: () => u(() {
                  nextDate = 'any';
                  nextDistrict = 'all';
                  nextSize = 'any';
                  nextTime = 'any';
                }),
                child: Text(t('Сбросить')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void periodSheet() {
    String next = period;
    sheet(
      'Период',
      (c, u) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in {
            'any': 'За всё время',
            'week': 'За неделю',
            'month': 'За месяц',
          }.entries)
            choice(c, t(e.value), next == e.key, () => u(() => next = e.key)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: action('Применить', () {
              setState(() => period = next);
              Navigator.pop(c);
            }),
          ),
          const SizedBox(height: 8),
          caption(c, 'Дата прогулки определяется временем её города.'),
        ],
      ),
    );
  }

  void howItWorks() => sheet(
    'Как это работает',
    (c, u) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('Запрос и выбор'), style: Theme.of(c).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          t(
            'Владелец выбирает помощника из откликов. Отклик ещё не означает назначения.',
          ),
        ),
        const Divider(height: 32),
        Text(
          t('Прогулка и подтверждение'),
          style: Theme.of(c).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          t(
            'Участники договариваются в чате. Помощник начинает и завершает прогулку, владелец подтверждает.',
          ),
        ),
        const Divider(height: 32),
        Text(t('Отзывы'), style: Theme.of(c).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          t(
            'После подтверждения каждый участник может оставить один отзыв о другом. Рейтинги владельца и помощника считаются отдельно.',
          ),
        ),
      ],
    ),
  );
  void detailsSheet() => sheet(
    'Детали прогулки',
    (c, u) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Луна', style: Theme.of(c).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('${dateLabel()} · 10:00 · ${duration(45)}'),
        caption(c, 'Время места встречи · Минск'),
        caption(c, 'Центральный район'),
        const Divider(height: 32),
        Text(t('Участники'), style: Theme.of(c).textTheme.titleMedium),
        row(c, 'Анна', 'Владелец', initials: 'АН'),
        row(c, 'Ульяна', 'Помощник', initials: 'УЛ'),
        const Divider(height: 32),
        Text(t('Передача и уход'), style: Theme.of(c).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Встречаемся у общественного входа со стороны сквера. Привычный поводок и вода — в сумке.',
        ),
        const SizedBox(height: 4),
        caption(c, 'Только для участников этой прогулки'),
        const SizedBox(height: 16),
        Text(t('Что важно знать'), style: Theme.of(c).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Луна любит спокойный маршрут. Избегайте близкого контакта с незнакомыми собаками.',
        ),
      ],
    ),
  );
  int rating = 0;
  void reviewSheet() => sheet(
    'Оставить отзыв',
    (c, u) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(
          c,
          helper ? 'Анна' : 'Ульяна',
          helper ? 'Как владелец' : 'Как помощник',
          initials: helper ? 'АН' : 'УЛ',
        ),
        Wrap(
          children: [
            for (int i = 1; i <= 5; i++)
              IconButton(
                tooltip: '$i / 5',
                onPressed: () => u(() => rating = i),
                icon: Icon(
                  i <= rating ? Icons.star : Icons.star_outline,
                  color: Theme.of(c).colorScheme.onSurface,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: review,
          maxLines: 4,
          decoration: InputDecoration(labelText: t('Как прошла прогулка?')),
        ),
        const SizedBox(height: 16),
        if (failSave && scenario == 'error')
          Text(
            t('Не удалось сохранить. Введённые данные остаются здесь.'),
            style: TextStyle(color: Theme.of(c).colorScheme.error),
          ),
        action(
          busy ? 'Сохраняем…' : 'Опубликовать отзыв',
          rating == 0 || busy
              ? null
              : () async {
                  u(() => busy = true);
                  await Future<void>.delayed(const Duration(milliseconds: 650));
                  if (!c.mounted) return;
                  if (failSave) {
                    setState(() => scenario = 'error');
                    u(() => busy = false);
                  } else {
                    setState(() {
                      reviewed = true;
                      busy = false;
                    });
                    Navigator.pop(c);
                    feedback('Отзыв опубликован');
                  }
                },
        ),
      ],
    ),
  );
  void replySheet() => sheet(
    'Ответить на отзыв',
    (c, u) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: review,
          maxLines: 3,
          decoration: InputDecoration(labelText: t('Ваш ответ')),
        ),
        const SizedBox(height: 16),
        action('Отправить', () {
          if (review.text.trim().isEmpty) return;
          setState(() => replied = true);
          Navigator.pop(c);
        }),
      ],
    ),
  );
  void reportSheet() => sheet(
    'Сообщить о проблеме',
    (c, u) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t('Опишите, что произошло. Не публикуйте личные адреса.')),
        const SizedBox(height: 16),
        TextField(
          controller: report,
          maxLines: 4,
          decoration: InputDecoration(labelText: t('Описание проблемы')),
        ),
        const SizedBox(height: 16),
        action('Отправить', () {
          if (report.text.trim().isEmpty) return;
          Navigator.pop(c);
          feedback('Демонстрация · действие не отправляется');
        }),
      ],
    ),
  );
  void photoSheet() => sheet(
    'Прикрепить фото',
    (c, u) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        caption(c, 'Фото · до 5 МиБ'),
        const SizedBox(height: 12),
        action(
          'Выбрать фото',
          () {
            Navigator.pop(c);
            feedback('Демонстрация · действие не отправляется');
          },
          primary: false,
          icon: Icons.photo_outlined,
        ),
      ],
    ),
  );
  void languageSheet() => sheet(
    'Язык приложения',
    (c, u) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final e in {
          'ru': 'Русский',
          'en': 'English',
          'be': 'Беларуская',
          'pl': 'Polski',
        }.entries)
          choice(c, e.value, locale == e.key, () {
            setState(() => locale = e.key);
            Navigator.pop(c);
          }),
      ],
    ),
  );
  void lab() => sheet(
    'Настройки макета',
    (c, u) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t('Синтетические данные. Ничего не отправляется.')),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t('Тёмная тема')),
          value: dark,
          onChanged: (v) {
            setState(() => dark = v);
            u(() {});
          },
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final l in ['ru', 'en', 'be', 'pl'])
              PreviewChoiceChip(
                label: Text(l.toUpperCase()),
                selected: locale == l,
                onSelected: (_) {
                  setState(() => locale = l);
                  u(() {});
                },
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final s in [1.0, 1.5, 2.0])
              PreviewChoiceChip(
                label: Text('${(s * 100).toInt()}%'),
                selected: scale == s,
                onSelected: (_) {
                  setState(() => scale = s);
                  u(() {});
                },
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t('Режим помощника')),
          value: helper,
          onChanged: (v) {
            setState(() => helper = v);
            u(() {});
          },
        ),
        Text(t('Состояние')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in [
              'populated',
              'loading',
              'empty',
              'error',
              'offline',
              'unavailable',
              'permission',
            ])
              PreviewChoiceChip(
                label: Text(s),
                selected: scenario == s,
                onSelected: (_) {
                  setState(() => scenario = s);
                  u(() {});
                },
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t('Ошибка сохранения')),
          value: failSave,
          onChanged: (v) {
            setState(() => failSave = v);
            u(() {});
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t('Избранные места')),
          value: favorites,
          onChanged: (v) {
            setState(() => favorites = v);
            u(() {});
          },
        ),
        const Divider(),
        Text(t('Этап прогулки')),
        Wrap(
          spacing: 8,
          children: [
            for (final s in ['selected', 'progress', 'waiting', 'completed'])
              PreviewChoiceChip(
                label: Text(s),
                selected: walkState == s,
                onSelected: (_) {
                  setState(() => walkState = s);
                  u(() {});
                },
              ),
          ],
        ),
        const Divider(),
        Text(t('Все экраны')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in [
              'nearby',
              'places',
              'place',
              'social',
              'community',
              'meetup',
              'requests',
              'request',
              'walks',
              'chat',
              'chats',
              'profile',
              'settings',
              'roles',
              'conditions',
              'edit-conditions',
              'public-helper',
              'owner',
              'create-request',
              'create-meetup',
              'onboarding',
            ])
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(c);
                  go(s);
                },
                child: Text(s),
              ),
          ],
        ),
      ],
    ),
  );
}

ThemeData reviewTheme(Brightness brightness) {
  final theme = studioTheme(brightness);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: theme.colorScheme.onSurface, width: 1.5),
  );
  return theme.copyWith(
    chipTheme: theme.chipTheme.copyWith(
      labelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Golos Text',
          fontSize: 14,
          color: states.contains(WidgetState.selected)
              ? theme.scaffoldBackgroundColor
              : theme.colorScheme.onSurface,
        ),
      ),
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      focusedBorder: border,
      errorBorder: border.copyWith(
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
    ),
  );
}

class PreviewChoiceChip extends StatelessWidget {
  const PreviewChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: label,
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      labelStyle: TextStyle(
        fontFamily: 'Golos Text',
        fontSize: 14,
        color: selected
            ? theme.scaffoldBackgroundColor
            : theme.colorScheme.onSurface,
      ),
      selectedColor: theme.colorScheme.onSurface,
      backgroundColor: StudioColors.of(context).tint,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
