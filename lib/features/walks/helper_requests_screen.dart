import '../../core/ui/studio_pickers.dart';
import '../../core/ui/studio_review.dart';
import 'package:intl/intl.dart';
import '../nearby/city_field.dart';
import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/components.dart';
import '../../core/time/display_time.dart';
import '../community/data/community_repository.dart';
import 'walking_repository.dart';
import 'walks_screen.dart';
import 'account_mode.dart';
import '../../core/media/preview_photos.dart';
import '../../core/time/time_zone_picker.dart';
import '../../core/theme/studio_theme.dart';
import 'walking_studio_components.dart';
import 'walking_chat_widgets.dart';
import 'walking_chat_controller.dart';
import '../community/presentation/social_components.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});
  @override
  ConsumerState<RequestsScreen> createState() => _RequestsState();
}

class _RequestsState extends ConsumerState<RequestsScreen> {
  final city = TextEditingController(text: 'Минск'),
      district = TextEditingController();
  String search = "";
  String? size;
  DateTime? date;
  String timePeriod = 'any';
  String? explicitZone;
  bool cityEdited = false;
  late Future<List<Json>> future;
  int page = 0;
  bool hasMore = false;
  String appliedCity = 'Минск', appliedDistrict = '';
  String? appliedSize, appliedZone;
  DateTime? appliedDate;
  String appliedPeriod = 'any';
  List<Json> loadedItems = [];
  int queryGeneration = 0;
  final Set<String> districtSuggestions = {};
  bool get dirty =>
      city.text.trim() != appliedCity ||
      district.text.trim() != appliedDistrict ||
      size != appliedSize ||
      date != appliedDate ||
      timePeriod != appliedPeriod ||
      explicitZone != appliedZone;
  bool get filtered =>
      appliedDistrict.isNotEmpty || appliedSize != null || appliedDate != null;
  bool get needsZone =>
      date != null &&
      cityTimeZone(city.text.trim()) == null &&
      explicitZone == null;

  void resetFilters() {
    setState(() {
      district.clear();
      size = null;
      date = null;
      timePeriod = 'any';
      load();
    });
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  void load({bool apply = true}) {
    page = 0;
    loadedItems = [];
    if (apply) {
      appliedCity = city.text.trim();
      appliedDistrict = district.text.trim();
      appliedSize = size;
      appliedDate = date;
      appliedPeriod = timePeriod;
      appliedZone = explicitZone;
    }
    queryGeneration++;
    future = query();
    // A hidden shell branch may replace this Future before FutureBuilder listens.
    // Keep errors observable by FutureBuilder without leaking an unhandled error.
    future.ignore();
  }

  Future<List<Json>> query() async {
    final generation = queryGeneration;
    final requestedPage = page;
    final searchCity = appliedCity;
    final zone = cityTimeZone(appliedCity) ?? appliedZone;
    if (appliedDate != null && zone == null) {
      throw StateError("Выберите часовой пояс города".tr(context));
    }
    final hours = switch (appliedPeriod) {
      'morning' => (6, 12),
      'evening' => (17, 24),
      _ => (0, 24),
    };
    final from = appliedDate == null
        ? null
        : venueWallTimeToUtc(
            DateTime.utc(
              appliedDate!.year,
              appliedDate!.month,
              appliedDate!.day,
              hours.$1,
            ),
            zone!,
          );
    final until = appliedDate == null
        ? null
        : venueWallTimeToUtc(
            DateTime.utc(
              appliedDate!.year,
              appliedDate!.month,
              appliedDate!.day,
              hours.$2,
            ),
            zone!,
          );
    final results = await ref
        .read(walkingRepositoryProvider)
        .list(
          city: appliedCity,
          district: appliedDistrict.isEmpty ? null : appliedDistrict,
          size: appliedSize,
          from: from,
          until: until,
          offset: page * 40,
        );
    if (mounted && generation == queryGeneration && searchCity == appliedCity) {
      hasMore = results.length == 40;
      if (requestedPage == 0) loadedItems = results;
      districtSuggestions.addAll(
        results
            .map((item) => '${item['district'] ?? ''}')
            .where((value) => value.isNotEmpty),
      );
    }
    return results;
  }

  void more({bool retry = false}) {
    setState(() {
      if (!retry) page++;
      final previous = List<Json>.of(loadedItems);
      final generation = queryGeneration;
      future = query().then((items) {
        final combined = [...previous, ...items];
        if (generation == queryGeneration) loadedItems = combined;
        return combined;
      });
      future.ignore();
    });
  }

  @override
  void dispose() {
    city.dispose();
    district.dispose();
    super.dispose();
  }

  Future<void> showFilters() => showStudioSelectionSheet<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (sheetContext, rebuild) {
        void change(VoidCallback fn) {
          setState(fn);
          rebuild(() {});
        }

        return WalkingChatSheet(
          title: 'Фильтры'.tr(sheetContext),
          children: filterFields(sheetContext, change),
        );
      },
    ),
  );

  List<Widget> filterFields(BuildContext context, StateSetter change) => [
    CityField(
      controller: city,
      onChanged: (_) => change(() {
        cityEdited = true;
        explicitZone = null;
        date = null;
        timePeriod = 'any';
        district.clear();
        districtSuggestions.clear();
        load();
      }),
    ),
    const SizedBox(height: 12),
    ExcludeSemantics(
      child: Text(
        "Район · необязательно".tr(context),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
    const SizedBox(height: 8),
    Semantics(
      label: "Район · необязательно".tr(context),
      child: TextField(
        controller: district,
        textInputAction: TextInputAction.done,
        onChanged: (_) => change(() {}),
        onSubmitted: (_) {
          if (!needsZone) change(load);
        },
        decoration: InputDecoration(
          suffixIcon: IconButton(
            tooltip: "Выбрать район".tr(context),
            icon: const Icon(Icons.expand_more),
            onPressed: () async {
              final options = districtSuggestions.toList()..sort();
              final value = await showStudioSelectionSheet<String>(
                context: context,
                builder: (sheetContext) => SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionTitle("Район".tr(context), compact: true),
                          ListTile(
                            title: Text("Любой район".tr(context)),
                            onTap: () => Navigator.pop(sheetContext, ''),
                          ),
                          for (final option in options)
                            ListTile(
                              title: Text(option),
                              onTap: () => Navigator.pop(sheetContext, option),
                            ),
                          if (options.isEmpty)
                            Text(
                              "Районы появятся после загрузки запросов. Можно ввести район вручную."
                                  .tr(context),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              if (value != null && mounted) {
                change(() {
                  district.text = value;
                  if (!needsZone) load();
                });
              }
            },
          ),
        ),
      ),
    ),
    const SizedBox(height: 8),
    Text(
      "Введите район или выберите из найденных.".tr(context),
      style: Theme.of(context).textTheme.bodySmall,
    ),
    const SizedBox(height: 12),
    if (dirty) ...[
      Text(
        "Фильтры изменены. Примените их, чтобы обновить результаты.".tr(
          context,
        ),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: city.text.trim().isEmpty || needsZone
            ? null
            : () {
                FocusScope.of(context).unfocus();
                change(load);
              },
        child: Text("Показать запросы".tr(context)),
      ),
    ],
    if (needsZone)
      Text("Для поиска по дате выберите часовой пояс города.".tr(context)),
    ExpansionTile(
      key: const ValueKey('helper-extra-filters'),
      title: Text("Дата, время и размер собаки".tr(context)),
      subtitle: appliedSize == null && appliedDate == null
          ? null
          : Text(
              [
                if (appliedDate != null)
                  DateFormat.yMMMd(context.languageCode).format(appliedDate!),
                if (appliedDate != null && appliedPeriod != 'any')
                  (appliedPeriod == 'morning' ? "Утро" : "Вечер").tr(context),
                if (appliedSize != null)
                  switch (appliedSize) {
                    'small' => "Небольшая".tr(context),
                    'medium' => "Средняя".tr(context),
                    _ => "Крупная".tr(context),
                  },
              ].join(' · '),
            ),
      tilePadding: EdgeInsets.zero,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(size),
          isExpanded: true,
          isDense: false,
          itemHeight: null,
          initialValue: size,
          decoration: InputDecoration(labelText: "Размер собаки".tr(context)),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text("Любой размер".tr(context)),
            ),
            DropdownMenuItem(
              value: 'small',
              child: Text("Небольшая".tr(context)),
            ),
            DropdownMenuItem(
              value: 'medium',
              child: Text("Средняя".tr(context)),
            ),
            DropdownMenuItem(
              value: 'large',
              child: Text("Крупная".tr(context)),
            ),
          ],
          onChanged: (v) => change(() => size = v),
        ),
        TextButton.icon(
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(
            date == null
                ? "Выбрать день".tr(context)
                : '${date!.day}.${date!.month}.${date!.year}',
          ),
          onPressed: () async {
            final zone = cityTimeZone(city.text.trim()) ?? explicitZone;
            final now = zone == null
                ? DateTime.now()
                : venueDateTime(DateTime.now(), zone);
            final today = DateTime(now.year, now.month, now.day);
            final d = await showStudioDatePicker(
              context: context,
              initialDate: date ?? today,
              firstDate: today,
              lastDate: today.add(const Duration(days: 365)),
            );
            if (d != null) change(() => date = d);
          },
        ),
        DropdownButtonFormField<String>(
          key: ValueKey(timePeriod),
          isExpanded: true,
          isDense: false,
          itemHeight: null,
          initialValue: timePeriod,
          decoration: InputDecoration(
            labelText: "Время в выбранный день".tr(context),
          ),
          items: [
            DropdownMenuItem(
              value: 'any',
              child: Text("Весь день".tr(context)),
            ),
            DropdownMenuItem(
              value: 'morning',
              child: Text("Утро · 06:00–12:00".tr(context)),
            ),
            DropdownMenuItem(
              value: 'evening',
              child: Text("Вечер · 17:00–24:00".tr(context)),
            ),
          ],
          onChanged: date == null
              ? null
              : (v) => change(() => timePeriod = v ?? 'any'),
        ),
        if (date == null)
          Text("Выберите день, чтобы уточнить время.".tr(context)),
        if (cityTimeZone(city.text.trim()) == null)
          TextButton(
            onPressed: () async {
              final zone = await chooseVenueTimeZone(context, explicitZone);
              if (zone != null && mounted) {
                change(() => explicitZone = zone);
              }
            },
            child: Text(
              explicitZone ?? "Выбрать часовой пояс города".tr(context),
            ),
          ),
      ],
    ),
    Text(
      [
        "Поиск: {p0}".tr(context, arguments: {'p0': appliedCity}),
        if (appliedDistrict.isNotEmpty) appliedDistrict,
      ].join(' · '),
      style: Theme.of(context).textTheme.bodySmall,
    ),
    if (filtered)
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () {
            resetFilters();
            change(() {});
          },
          child: Text("Сбросить фильтры".tr(context)),
        ),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen(communityProvider, (_, next) {
      if (next.hasValue) setState(() => load(apply: false));
    });
    ref.listen(accountModeProvider, (_, next) {
      if (next.hasValue) setState(() => load(apply: false));
    });
    ref.listen(helperProfileProvider, (_, next) {
      final profile = next.value;
      if (profile != null && !cityEdited) {
        setState(() {
          city.text = profile.city.isEmpty ? 'Минск' : profile.city;
          load();
        });
      }
    });
    ref.watch(helperProfileProvider);
    return PageBody(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Запросы'.tr(context),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              tooltip: 'Как это работает'.tr(context),
              icon: const Icon(Icons.info_outline),
              onPressed: () => showStudioSelectionSheet<void>(
                context: context,
                builder: (_) => const WalkingHowItWorksSheet(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('walking-request-search'),
                onChanged: (value) => setState(() => search = value),
                decoration: InputDecoration(
                  hintText: 'Питомец, участник'.tr(context),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: StudioColors.of(context).tint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Фильтры'.tr(context),
              onPressed: showFilters,
              style: IconButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              icon: const Icon(Icons.filter_list),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          [
            appliedCity,
            if (appliedDistrict.isNotEmpty) appliedDistrict,
          ].join(' · '),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        FutureBuilder<List<Json>>(
          future: future,
          builder: (context, s) => WalkingListResult(
            snapshot: s,
            search: search,
            onRetry: () => setState(() => load(apply: false)),
            onEmptyAction: filtered ? resetFilters : null,
            emptyAction: "Сбросить фильтры".tr(context),
            empty:
                "Подходящих запросов пока нет. Попробуйте другой день или район."
                    .tr(context),
            retainedItems: page > 0 ? loadedItems : const [],
            onPageRetry: page > 0 ? () => more(retry: true) : null,
            onMore: hasMore ? more : null,
          ),
        ),
      ],
    );
  }
}

class WalkingHowItWorksSheet extends StatelessWidget {
  const WalkingHowItWorksSheet({super.key});
  @override
  Widget build(BuildContext context) => StudioReviewSheet(
    title: 'Выгул и рейтинг'.tr(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Как проходит прогулка".tr(context),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        for (final (index, step) in [
          ('Запрос и выбор', 'Владелец выбирает помощника из откликов.'),
          (
            'Договоритесь в чате',
            'Обсудите детали в личном чате после назначения.',
          ),
          (
            'Прогулка и подтверждение',
            'Помощник отмечает начало и конец, владелец подтверждает завершение.',
          ),
        ].indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.$1.tr(context),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(step.$2.tr(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 24),
        Text(
          "Что означает рейтинг".tr(context),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text("Рейтинг основан на отзывах о завершённых прогулках.".tr(context)),
        const SizedBox(height: 8),
        Text(
          "Рейтинг помогает выбрать, но не гарантирует безопасность. У мест — отдельный рейтинг."
              .tr(context),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Text("Кто может оставить отзыв".tr(context)),
          children: [
            Text('Отклик ещё не означает назначение.'.tr(context)),
            const SizedBox(height: 8),
            Text(
              'Опыт владельца и помощника учитывается отдельно — по опубликованным допустимым отзывам.'
                  .tr(context),
            ),
            const SizedBox(height: 8),
            Text(
              "После подтверждённого завершения каждый назначенный участник может оставить один отзыв о другом. Нельзя оценивать себя или человека вне этой договорённости."
                  .tr(context),
            ),
          ],
        ),
      ],
    ),
  );
}

class MyWalksScreen extends ConsumerStatefulWidget {
  const MyWalksScreen({super.key});
  @override
  ConsumerState<MyWalksScreen> createState() => _MyWalksState();
}

class _MyWalksState extends ConsumerState<MyWalksScreen> {
  String view = 'active';
  int page = 0;
  bool hasMore = false;
  int generation = 0;
  List<Json> loadedItems = [];
  late Future<List<Json>> future;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    page = 0;
    loadedItems = [];
    final requestGeneration = ++generation;
    future = ref.read(walkingRepositoryProvider).list(view: view).then((items) {
      if (requestGeneration == generation) {
        hasMore = items.length == 40;
        loadedItems = items;
      }
      return items;
    });
  }

  void more({bool retry = false}) {
    setState(() {
      if (!retry) page++;
      final previous = List<Json>.of(loadedItems);
      final requestGeneration = generation;
      future = ref
          .read(walkingRepositoryProvider)
          .list(view: view, offset: page * 40)
          .then((items) {
            final combined = [...previous, ...items];
            if (requestGeneration == generation) {
              hasMore = items.length == 40;
              loadedItems = combined;
            }
            return combined;
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(communityProvider, (_, next) {
      if (next.hasValue) setState(load);
    });
    ref.listen(accountModeProvider, (_, next) {
      if (next.hasValue) setState(load);
    });
    return PageBody(
      children: [
        ScreenIntro(
          "Мои прогулки".tr(context),
          compact: true,
          subtitle: "Договорённости, которым вы уделяете время.".tr(context),
        ),
        const SizedBox(height: 16),
        if (view == 'history') ...[
          TextButton.icon(
            onPressed: () => setState(() {
              view = 'active';
              load();
            }),
            icon: const Icon(Icons.arrow_back),
            label: Text("К предстоящим прогулкам".tr(context)),
          ),
          SectionTitle("История прогулок".tr(context), compact: true),
          Text("Завершённые и отменённые договорённости.".tr(context)),
        ] else ...[
          WalkingViewTabs(
            value: view,
            onChanged: (value) => setState(() {
              view = value;
              load();
            }),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() {
                view = 'history';
                load();
              }),
              child: Text("История прогулок".tr(context)),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (view == 'applications')
          Text(
            "Отклик ещё не означает, что вас выбрали. Владелец подтвердит договорённость."
                .tr(context),
          ),
        FutureBuilder<List<Json>>(
          future: future,
          builder: (context, s) => WalkingListResult(
            snapshot: s,
            onRetry: () => setState(load),
            agreementsOnly: view == 'active',
            error: "Прогулки не загрузились. Попробуйте ещё раз.".tr(context),
            moreLabel: "Следующие прогулки".tr(context),
            onEmptyAction: view == 'history'
                ? null
                : () => context.go('/requests'),
            emptyAction: "Посмотреть запросы".tr(context),
            empty: view == 'applications'
                ? "Вы пока не откликнулись на запросы.".tr(context)
                : view == 'history'
                ? "Завершённые и отменённые прогулки появятся здесь.".tr(
                    context,
                  )
                : "Отправьте отклик. Прогулка появится здесь, когда владелец выберет вас."
                      .tr(context),
            retainedItems: page > 0 ? loadedItems : const [],
            onPageRetry: page > 0 ? () => more(retry: true) : null,
            onMore: hasMore ? more : null,
          ),
        ),
      ],
    );
  }
}

/// Full-width controls become a vertical group when text needs more room.
class WalkingViewTabs extends StatelessWidget {
  const WalkingViewTabs({
    required this.value,
    required this.onChanged,
    super.key,
  });
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final entries = {
        'active': "Предстоящие".tr(context),
        'applications': "Отклики".tr(context),
      };
      final style = Theme.of(context).textTheme.bodyLarge!;
      final stack = entries.values.any((label) {
        final painter = TextPainter(
          text: TextSpan(text: label, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        return painter.width + 24 > constraints.maxWidth / 2;
      });
      Widget tab(MapEntry<String, String> entry) => Semantics(
        selected: value == entry.key,
        button: true,
        child: InkWell(
          onTap: () => onChanged(entry.key),
          child: Container(
            width: stack ? double.infinity : null,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: value == entry.key ? 2 : 1,
                  color: value == entry.key
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Text(entry.value, style: style, textAlign: TextAlign.center),
          ),
        ),
      );
      return stack
          ? Column(children: entries.entries.map(tab).toList())
          : Row(
              children: entries.entries
                  .map((entry) => Expanded(child: tab(entry)))
                  .toList(),
            );
    },
  );
}

class WalkingListResult extends StatelessWidget {
  const WalkingListResult({
    required this.snapshot,
    required this.onRetry,
    required this.empty,
    this.onMore,
    this.onPageRetry,
    this.retainedItems = const [],
    this.onEmptyAction,
    this.emptyAction,
    this.error,
    this.moreLabel,
    this.agreementsOnly = false,
    this.search = "",
    super.key,
  });
  final AsyncSnapshot<List<Json>> snapshot;
  final VoidCallback onRetry;
  final VoidCallback? onMore, onEmptyAction, onPageRetry;
  final List<Json> retainedItems;
  final String? emptyAction, error, moreLabel;
  final String empty;
  final bool agreementsOnly;
  final String search;
  @override
  Widget build(BuildContext context) {
    final loading = snapshot.connectionState != ConnectionState.done;
    if (loading && retainedItems.isEmpty) {
      return const WalkingLoadingState();
    }
    if (snapshot.hasError && retainedItems.isEmpty) {
      return Column(
        children: [
          Text(
            error ??
                "Запросы не загрузились. Данные сейчас недоступны.".tr(context),
          ),
          TextButton(onPressed: onRetry, child: Text("Повторить".tr(context))),
        ],
      );
    }
    final items =
        (loading || snapshot.hasError ? retainedItems : snapshot.data ?? [])
            .where(
              (w) =>
                  (!agreementsOnly ||
                      ['helper', 'owner'].contains(w['my_role'])) &&
                  [w['pet'], w['owner'], w['district']]
                      .join(' ')
                      .toLowerCase()
                      .contains(search.trim().toLowerCase()),
            )
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty)
          SocialContentState(
            centered: true,
            icon: Icons.pets_outlined,
            title: 'Пока нет запросов'.tr(context),
            message: empty,
            actionLabel: emptyAction,
            onAction: onEmptyAction,
          ),
        for (final w in items) WalkingRequestRow(item: w, onReturn: onRetry),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (snapshot.hasError) ...[
          Text(
            "Следующая страница не загрузилась. Уже найденные прогулки сохранены."
                .tr(context),
          ),
          TextButton(
            onPressed: onPageRetry,
            child: Text("Повторить".tr(context)),
          ),
        ] else if (onMore != null)
          TextButton(
            onPressed: onMore,
            child: Text(moreLabel ?? "Следующие запросы".tr(context)),
          ),
        TextButton(onPressed: onRetry, child: Text("Обновить".tr(context))),
      ],
    );
  }
}

class WalkingRequestRow extends StatelessWidget {
  const WalkingRequestRow({required this.item, this.onReturn, super.key});
  final VoidCallback? onReturn;
  final Json item;
  @override
  Widget build(BuildContext context) {
    final pet = item['pet'] as Map?;
    final owner = item['owner'] as Map?;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IdentityPicture(
                id: 'pet:${pet?['id'] ?? item['pet_id']}',
                name: '${pet?['name'] ?? ''}',
                icon: Icons.pets_outlined,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pet?['name'] ?? 'Питомец'.tr(context)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      walkingShortTime(context, item),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        item['district'],
                      ].where((v) => v != null && '$v'.isNotEmpty).join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ('${item['description'] ?? ''}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${item['description']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (owner != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${'Владелец'.tr(context)} · ${owner['display_name'] ?? ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 12),
          WalkingStatusLabel(
            item['applied'] == true && item['my_role'] == 'applicant'
                ? 'Отклик отправлен · ждём решения'.tr(context)
                : walkStatus('${item['status']}').tr(context),
          ),
          WalkingRowActions(
            trailing: OutlinedButton(
              onPressed: () async {
                final chat = item['conversation_id'] as String?;
                if (chat != null &&
                    ['owner', 'helper'].contains(item['my_role'])) {
                  final container = ProviderScope.containerOf(context);
                  container.read(walkingChatProvider.notifier).load(chat);
                  await showWalkingChatDetails(context, chat, chatEntry: true);
                } else {
                  await showWalkRequestSheet(context, id: '${item['id']}');
                }
                onReturn?.call();
              },
              child: Text('Детали'.tr(context)),
            ),
          ),
          const Divider(height: 32),
        ],
      ),
    );
  }
}
