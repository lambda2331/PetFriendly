import '../../l10n/localization.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/prototype_store.dart';
import '../../core/ui/components.dart';
import '../../core/time/display_time.dart';
import '../community/data/community_repository.dart';
import 'place_repository.dart';
import 'place_contributions.dart';
import 'city_catalog.dart';
import 'place_rating.dart';
import 'pet_access_repository.dart';
import 'pet_access_widgets.dart';
import 'pet_access_review_sheet.dart';
import 'fullscreen_map_screen.dart';

final _openingPlaces = Expando<bool>();

Future<void> showPlace(
  BuildContext context,
  Place place, {
  VoidCallback? onShowOnMap,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (_openingPlaces[navigator] == true) return;
  _openingPlaces[navigator] = true;
  final container = ProviderScope.containerOf(context, listen: false);
  final route = ModalRoute.of(context);
  final feedback = placeFeedbackProvider(place.id);
  final evidence = petAccessEvidenceProvider(place.id);
  // Keep auto-disposed data alive from preparation through sheet dismissal.
  final subscriptions = [
    container.listen(feedback, (_, _) {}),
    container.listen(evidence, (_, _) {}),
    container.listen(petAccessModeratorProvider, (_, _) {}),
  ];
  final cancelled = Completer<void>();
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? loadingNotice;
  final loadingTimer = Timer(const Duration(milliseconds: 300), () {
    if (!context.mounted || route?.isCurrent == false) return;
    loadingNotice = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Открываем место…".tr(context)),
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: "Отмена".tr(context),
          onPressed: () {
            if (!cancelled.isCompleted) cancelled.complete();
          },
        ),
      ),
    );
  });
  final navigationWatch = Timer.periodic(const Duration(milliseconds: 100), (
    _,
  ) {
    if ((!context.mounted || route?.isCurrent == false) &&
        !cancelled.isCompleted) {
      cancelled.complete();
    }
  });
  try {
    // Resolve the initial content before sizing: short sheets fit naturally,
    // and late reviews cannot resize an already visible sheet.
    await Future.any([
      Future.wait([
        container.read(feedback.future).then<void>((_) {}, onError: (_, _) {}),
        container.read(evidence.future).then<void>((_) {}, onError: (_, _) {}),
        container
            .read(petAccessModeratorProvider.future)
            .then<void>((_) {}, onError: (_, _) {}),
      ]),
      cancelled.future,
    ]);
    loadingTimer.cancel();
    navigationWatch.cancel();
    loadingNotice?.close();
    if (cancelled.isCompleted ||
        !context.mounted ||
        route?.isCurrent == false) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: Duration(milliseconds: 250),
              reverseDuration: Duration(milliseconds: 220),
            ),
      builder: (_) => PlaceDetailsSheet(place: place, onShowOnMap: onShowOnMap),
    );
  } finally {
    loadingTimer.cancel();
    navigationWatch.cancel();
    loadingNotice?.close();
    for (final subscription in subscriptions) {
      subscription.close();
    }
    _openingPlaces[navigator] = false;
  }
}

class PlaceDetailsSheet extends ConsumerStatefulWidget {
  const PlaceDetailsSheet({required this.place, this.onShowOnMap, super.key});
  final Place place;
  final VoidCallback? onShowOnMap;
  @override
  ConsumerState<PlaceDetailsSheet> createState() => _PlaceDetailsState();
}

class _PlaceDetailsState extends ConsumerState<PlaceDetailsSheet> {
  final comment = TextEditingController();
  int stars = 0;
  bool sending = false, expanded = false, reviewing = false;
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (stars == 0 || sending || widget.place.pending) return;
    setState(() => sending = true);
    try {
      await ref.read(communityProvider.notifier).command('place_review', {
        'place_id': widget.place.id,
        'rating': stars,
        'body': comment.text.trim(),
      });
      ref.invalidate(placeFeedbackProvider(widget.place.id));
      if (mounted) {
        comment.clear();
        notice(
          context,
          ref.read(communityRepositoryProvider).isDemo
              ? "Отзыв добавлен в демо · до перезапуска.".tr(context)
              : "Спасибо! Отзыв опубликован.".tr(context),
        );
      }
    } catch (_) {
      if (mounted) {
        notice(
          context,
          "Не удалось отправить. Возможно, вы уже оценили это место.".tr(
            context,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void showMap() {
    final place = widget.place;
    final router = GoRouter.of(context);
    final catalog = <String, Place>{
      for (final p in [
        ...ref.read(cityCatalogProvider(place.city)).value ?? [],
        ...ref.read(placeContributionsProvider).value ?? [],
        place,
      ])
        if (p.city == place.city) p.id: p,
    };
    Navigator.pop(context);
    if (widget.onShowOnMap != null) {
      widget.onShowOnMap!();
      return;
    }
    router.push(
      '/map',
      extra: FullscreenMapArgs(
        places: catalog.values.toList(),
        city: place.city,
        focusPlace: place,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final favorite = ref.watch(prototypeProvider).favorites.contains(place.id);
    final rating = ref.watch(placeRatingProvider(place));
    final evidence = ref.watch(petAccessEvidenceProvider(place.id));
    final moderator = ref.watch(petAccessModeratorProvider).value == true;
    final feedback = ref.watch(placeFeedbackProvider(place.id));
    final data = ref.watch(communityProvider).value ?? {};
    final uid = ref.watch(communityRepositoryProvider).userId;
    final hasMap = place.latitude != null && place.longitude != null;
    final hasCorrection = place.sourceId?.trim().isNotEmpty == true;
    final hasDescription =
        place.description.trim().isNotEmpty &&
        place.description !=
            'Правила посещения могут измениться. Уточните допуск животных перед визитом.';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        key: const Key('place-sheet-frame'),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .86,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            16 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              StudioSheetHeader(
                title: place.name,
                actions: [
                  IconButton(
                    isSelected: favorite,
                    tooltip: favorite
                        ? "Убрать из избранного".tr(context)
                        : "В избранное".tr(context),
                    onPressed: () =>
                        ref.read(prototypeProvider.notifier).favorite(place.id),
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                    ),
                  ),
                ],
              ),
              if (place.category.trim().isNotEmpty ||
                  place.city.trim().isNotEmpty ||
                  rating != null) ...[
                const SizedBox(height: 8),
                Row(
                  key: const Key('place-metadata'),
                  children: [
                    if (place.category.trim().isNotEmpty) ...[
                      Icon(place.icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: MetadataLine(
                        items: [place.category.tr(context), place.city],
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.star_rounded, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.average.toStringAsFixed(1).replaceAll('.', ','),
                      ),
                    ],
                  ],
                ),
              ],
              if (place.pending) ...[
                const SizedBox(height: 12),
                Text(
                  "На проверке · пока видно только вам".tr(context),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (hasDescription) ...[
                const SizedBox(height: 16),
                Text(place.description.trim()),
              ],
              const SizedBox(height: 8),
              PetAccessRules(
                catalogHint: place.petAccess,
                evidence: place.pending
                    ? null
                    : evidence.hasValue
                    ? evidence.value
                    : place.accessEvidence,
                loading: !place.pending && evidence.isLoading,
                unavailable: !place.pending && evidence.hasError,
              ),
              if (evidence.isLoading)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text("Загружаем подтверждения правил…".tr(context)),
                ),
              if (evidence.hasError)
                TextButton(
                  onPressed: () =>
                      ref.invalidate(petAccessEvidenceProvider(place.id)),
                  child: Text(
                    "Подтверждения не загрузились · повторить".tr(context),
                  ),
                ),
              if (moderator && !place.pending)
                TextButton.icon(
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text("Проверить сведения о допуске".tr(context)),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    sheetAnimationStyle: studioSheetAnimation(context),
                    builder: (_) => PetAccessReviewSheet(place: place),
                  ),
                ),
              if (hasMap || hasCorrection) ...[
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final actions = <Widget>[
                      if (hasMap)
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          onPressed: showMap,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: Text("Показать на карте".tr(context)),
                        ),
                      if (hasCorrection)
                        OutlinedButton.icon(
                          onPressed: () {
                            final router = GoRouter.of(context);
                            Navigator.pop(context);
                            router.push(
                              '/place-feedback/${place.id}?correction=true',
                            );
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text("Уточнить данные".tr(context)),
                        ),
                    ];
                    // Keep complete labels at normal size; stack at narrow
                    // widths or increased text sizes rather than squeeze them.
                    final stack =
                        constraints.maxWidth <
                        480 * MediaQuery.textScalerOf(context).scale(14) / 14;
                    if (stack) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (index, action) in actions.indexed) ...[
                            if (index > 0) const SizedBox(height: 8),
                            action,
                          ],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        for (final (index, action) in actions.indexed) ...[
                          if (index > 0) const SizedBox(width: 8),
                          Expanded(child: action),
                        ],
                      ],
                    );
                  },
                ),
              ],
              feedback.when(
                loading: () => Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle("Отзывы".tr(context), compact: true),
                      LinearProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Загружаем отзывы…".tr(context)),
                    ],
                  ),
                ),
                error: (_, _) => TextButton(
                  onPressed: () =>
                      ref.invalidate(placeFeedbackProvider(place.id)),
                  child: Text("Отзывы не загрузились · повторить".tr(context)),
                ),
                data: (value) {
                  final reviews = [...value.reviews];
                  if (value.own != null &&
                      !reviews.any((r) => r['id'] == value.own!['id'])) {
                    reviews.insert(0, value.own!);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (value.own != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            "Вы уже оценили это место".tr(context),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (reviews.isNotEmpty)
                        SectionTitle(
                          "Отзывы".tr(context),
                          compact: true,
                          trailing: rating == null
                              ? null
                              : Text(
                                  '${rating.count}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                        ),
                      if (reviews.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: !place.pending && value.own == null ? 16 : 0,
                          ),
                          child: Text(
                            place.pending
                                ? "Отзывы станут доступны после публикации места."
                                      .tr(context)
                                : "Пока нет отзывов.".tr(context),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ...(expanded ? reviews : reviews.take(3)).indexed.map((
                        entry,
                      ) {
                        final (index, r) = entry;
                        final author = r['author_id'] == uid
                            ? "Вы".tr(context)
                            : findRow(
                                    data,
                                    'profiles',
                                    r['author_id'],
                                  )?['display_name'] ??
                                  "Участник".tr(context);
                        final date = DateTime.tryParse(
                          r['created_at'] ?? '',
                        )?.toLocal();
                        return Padding(
                          padding: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        author,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    const Icon(Icons.star_rounded, size: 15),
                                    const SizedBox(width: 4),
                                    MetadataLine(items: ['${r['rating']}']),
                                  ],
                                ),
                                if ((r['body'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(r['body']),
                                ],
                                if (date != null) ...[
                                  const SizedBox(height: 8),
                                  MetadataLine(
                                    items: [
                                      readableDate(
                                        date,
                                        locale: context.languageCode,
                                      ),
                                    ],
                                  ),
                                ],
                                if (index <
                                    (expanded
                                            ? reviews.length
                                            : reviews.take(3).length) -
                                        1) ...[
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                      if (!expanded && reviews.length > 3)
                        TextButton(
                          onPressed: () => setState(() => expanded = true),
                          child: Text("Показать ещё отзывы".tr(context)),
                        ),
                      if (expanded && (rating?.count ?? 0) > 50)
                        Text(
                          "Показаны последние отзывы.".tr(context),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (!place.pending &&
                          value.own == null &&
                          !reviewing) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          key: const Key('open-place-review'),
                          onPressed: () => setState(() => reviewing = true),
                          icon: const Icon(
                            Icons.rate_review_outlined,
                            size: 18,
                          ),
                          label: Text("Оставить отзыв".tr(context)),
                        ),
                      ],
                      if (!place.pending && value.own == null && reviewing) ...[
                        SectionTitle(
                          "Ваше впечатление".tr(context),
                          compact: true,
                        ),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            stars == 0
                                ? "Выберите оценку для публикации.".tr(context)
                                : "Оценка: {p0} из 5. Можно публиковать.".tr(
                                    context,
                                    arguments: {'p0': stars},
                                  ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 2,
                          children: List.generate(
                            5,
                            (i) => IconButton(
                              isSelected: stars == i + 1,
                              tooltip: "{p0} из 5".tr(
                                context,
                                arguments: {'p0': i + 1},
                              ),
                              onPressed: sending
                                  ? null
                                  : () => setState(() => stars = i + 1),
                              icon: Icon(
                                i < stars
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          textAlignVertical: TextAlignVertical.top,
                          key: const Key('inline-place-review'),
                          controller: comment,
                          enabled: !sending,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            hintText: "Комментарий (необязательно)".tr(context),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Отзыв публичный. Не указывайте личные сведения.".tr(
                            context,
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: stars == 0 || sending ? null : submit,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (sending) ...[
                                  const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Text(
                                    sending
                                        ? "Публикуем…".tr(context)
                                        : "Опубликовать отзыв".tr(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
