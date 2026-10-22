import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/media/preview_photos.dart';
import '../../core/theme/studio_theme.dart';
import '../community/data/community_repository.dart';
import 'helper_reputation.dart';

/// The section's action styling comes from the shared Studio button themes.
class WalkingActionTheme extends StatelessWidget {
  const WalkingActionTheme({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

String _reviews(int count, String locale) =>
    stringsFor(locale).reviewCount(count);

class WalkingExperienceSummary extends StatelessWidget {
  const WalkingExperienceSummary({
    required this.reputation,
    this.onRetry,
    this.compactEmpty = false,
    super.key,
  });
  final HelperReputation reputation;
  final VoidCallback? onRetry;
  final bool compactEmpty;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = reputation.reviewCount;
    if (compactEmpty && count == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Пока нет отзывов".tr(context),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              reputation.completed == null
                  ? "Опыт недоступен".tr(context)
                  : reputation.completed == 0
                  ? "Завершённых прогулок пока нет".tr(context)
                  : reputation.localizedCompletedLabel(context.languageCode),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (reputation.completed == null && onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text("Повторить загрузку опыта".tr(context)),
              ),
          ],
        ),
      );
    }
    final facts = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (count != null && count > 0 && reputation.rating != null)
            Semantics(
              label: "Средняя оценка {p0} из 5".tr(
                context,
                arguments: {
                  'p0': NumberFormat(
                    '0.0',
                    context.languageCode,
                  ).format(reputation.rating),
                },
              ),
              excludeSemantics: true,
              child: Row(
                children: [
                  const Icon(Icons.star_outline_rounded, size: 24),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      NumberFormat(
                        '0.0',
                        context.languageCode,
                      ).format(reputation.rating),
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              count == null
                  ? "Отзывы недоступны".tr(context)
                  : count > 0
                  ? "Оценка недоступна".tr(context)
                  : "Пока нет отзывов".tr(context),
              style: theme.textTheme.titleMedium,
            ),
          if (count != null && count > 0)
            Text(
              "{p0} · опубликовано".tr(
                context,
                arguments: {'p0': _reviews(count, context.languageCode)},
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reputation.completed != null) ...[
            Text(
              '${reputation.completed}',
              style: theme.textTheme.headlineMedium,
            ),
            Text(
              stringsFor(
                context.languageCode,
              ).completedWalkNoun(reputation.completed!),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else
            Text(
              "Опыт недоступен".tr(context),
              style: theme.textTheme.titleMedium,
            ),
        ],
      ),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: StudioColors.of(context).line),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stack =
                  constraints.maxWidth < 290 ||
                  MediaQuery.textScalerOf(context).scale(16) > 21;
              return stack
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        facts[0],
                        const SizedBox(height: 18),
                        facts[1],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: facts[0]),
                        const SizedBox(width: 20),
                        Expanded(child: facts[1]),
                      ],
                    );
            },
          ),
          if ((count == null || reputation.completed == null) &&
              onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text("Повторить загрузку опыта".tr(context)),
            ),
        ],
      ),
    );
  }
}

class WalkingEmptyState extends StatelessWidget {
  const WalkingEmptyState({
    required this.reputation,
    required this.isSelf,
    super.key,
  });
  final HelperReputation reputation;
  final bool isSelf;
  @override
  Widget build(BuildContext context) {
    if (reputation.reviewCount == null || reputation.completed == null) {
      return Text(
        "Отзывы или опыт сейчас недоступны. Повторите загрузку.".tr(context),
      );
    }
    if (reputation.reviewCount != 0) {
      return Text("Отзывы сейчас недоступны.".tr(context));
    }
    final started = (reputation.completed ?? 0) > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudioColors.of(context).tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            started
                ? "Отзывы ещё впереди".tr(context)
                : isSelf
                ? "Первый выгул впереди".tr(context)
                : "Новый помощник".tr(context),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            started
                ? "Завершённые выгулы уже есть. Владельцы пока не оставили отзывов."
                      .tr(context)
                : isSelf
                ? "Помогите владельцу с прогулкой. После завершения он сможет оставить отзыв."
                      .tr(context)
                : "Пока нет завершённых выгулов и отзывов. Обсудите опыт и потребности питомца в переписке."
                      .tr(context),
          ),
        ],
      ),
    );
  }
}

class WalkingExperienceExplanation extends StatefulWidget {
  const WalkingExperienceExplanation({this.isSelf = true, super.key});
  final bool isSelf;
  @override
  State<WalkingExperienceExplanation> createState() =>
      _WalkingExperienceExplanationState();
}

class _WalkingExperienceExplanationState
    extends State<WalkingExperienceExplanation> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        expanded: expanded,
        child: TextButton.icon(
          onPressed: () => setState(() => expanded = !expanded),
          icon: Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
          ),
          label: Text("Как считается опыт".tr(context)),
        ),
      ),
      if (expanded)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            widget.isSelf
                ? "Здесь учитываются прогулки, в которых вы были помощником. На рейтинг влияют только опубликованные отзывы владельцев после завершённого выгула. Ваши запросы для собственного питомца не учитываются."
                      .tr(context)
                : "Здесь учитываются прогулки, в которых этот человек помогал другим владельцам. На рейтинг влияют только опубликованные отзывы после завершённого выгула. Запросы для собственного питомца не учитываются."
                      .tr(context),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
    ],
  );
}

class WalkingReviewTile extends StatefulWidget {
  const WalkingReviewTile({
    required this.review,
    this.author,
    this.isSelf = false,
    this.preview = false,
    this.ownerReview = false,
    this.replyEditor,
    super.key,
  });
  final Json review;
  final Json? author;
  final bool isSelf, preview, ownerReview;
  final Widget? replyEditor;
  @override
  State<WalkingReviewTile> createState() => _WalkingReviewTileState();
}

class _WalkingReviewTileState extends State<WalkingReviewTile> {
  bool expanded = false;
  String date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null
        ? ''
        : MaterialLocalizations.of(context).formatMediumDate(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.author?['display_name']?.toString().trim();
    final body = widget.review['body']?.toString().trim() ?? '';
    final reply =
        widget.review[widget.ownerReview ? 'owner_reply' : 'helper_reply']
            ?.toString()
            .trim() ??
        '';
    final created = date(widget.review['created_at']);
    final identity = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IdentityPicture(
          id: 'profile:${widget.review['author_id']}',
          icon: Icons.person_outline,
          name: name,
          size: 40,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name?.isNotEmpty == true
                    ? name!
                    : "Владелец питомца".tr(context),
                style: theme.textTheme.titleSmall,
              ),
              Text(
                [
                  (widget.ownerReview ? "Помощник" : "Владелец").tr(context),
                  if (created.isNotEmpty) created,
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final rating = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ExcludeSemantics(
          child: Icon(Icons.star_outline_rounded, size: 18),
        ),
        const SizedBox(width: 4),
        Text(
          "{p0} из 5".tr(context, arguments: {'p0': widget.review['rating']}),
          style: theme.textTheme.labelLarge,
        ),
        if (!widget.preview)
          PopupMenuButton<String>(
            tooltip: "Действия с отзывом".tr(context),
            icon: const Icon(Icons.more_horiz, size: 20),
            onSelected: (_) =>
                context.push('/report/review/${widget.review['id']}'),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'report',
                child: Text("Пожаловаться на отзыв".tr(context)),
              ),
            ],
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth < 340 ||
                    MediaQuery.textScalerOf(context).scale(16) > 21
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [identity, const SizedBox(height: 8), rating],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: identity),
                      const SizedBox(width: 8),
                      rating,
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxLines = widget.preview ? 3 : 6;
              final painter = TextPainter(
                text: TextSpan(
                  text: body,
                  style: DefaultTextStyle.of(context).style,
                ),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: maxLines,
              )..layout(maxWidth: constraints.maxWidth);
              final needsExpansion = painter.didExceedMaxLines;
              painter.dispose();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    body,
                    maxLines: expanded ? null : maxLines,
                    overflow: expanded ? null : TextOverflow.ellipsis,
                  ),
                  if (needsExpansion)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () => setState(() => expanded = !expanded),
                      child: Text(
                        expanded
                            ? "Свернуть отзыв".tr(context)
                            : "Читать полностью".tr(context),
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (reply.isNotEmpty && !widget.preview)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: StudioColors.of(context).tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isSelf
                        ? "Ваш ответ".tr(context)
                        : (widget.ownerReview
                                  ? "Ответ владельца"
                                  : "Ответ помощника")
                              .tr(context),
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(reply),
                  if (date(widget.review['replied_at']).isNotEmpty)
                    Text(
                      date(widget.review['replied_at']),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          if (widget.replyEditor != null) widget.replyEditor!,
        ],
      ),
    );
  }
}
