import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../core/ui/studio_review.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/media/preview_photos.dart';
import '../../core/time/display_time.dart';
import '../../core/ui/components.dart';
import '../../l10n/localization.dart';
import '../community/data/community_repository.dart';
import 'walking_chat_controller.dart';
import 'walking_studio_components.dart';
import 'walks_screen.dart' show walkStatus, showWalkingReviewSheet;

String walkingChatTime(BuildContext context, Json item) {
  final parsed = DateTime.tryParse('${item['starts_at']}');
  final zone =
      item['time_zone'] as String? ?? cityTimeZone(item['city'] as String?);
  if (parsed == null || !validTimeZone(zone)) {
    // Keep the existing honest unavailable/unknown-zone response.
    return venueTime(
      item['starts_at'],
      city: item['city'],
      timeZone: item['time_zone'] as String?,
      locale: context.languageCode,
    );
  }
  final local = venueDateTime(parsed, zone!);
  return '${DateFormat.yMMMMd(context.languageCode).format(local)} · ${DateFormat.Hm(context.languageCode).format(local)}';
}

class WalkingChatContext extends ConsumerWidget {
  const WalkingChatContext({required this.id, this.maximumHeight, super.key});
  final String id;
  final double? maximumHeight;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(walkingChatProvider).records[id];
    final item = record?.item;
    final maximum =
        maximumHeight ??
        (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom) *
            (MediaQuery.viewInsetsOf(context).bottom > 0 ? .18 : .30);
    return Container(
      key: const Key('walking-chat-context'),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      constraints: BoxConstraints(maxHeight: maximum),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: item == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (record == null || record.loading)
                    const LinearProgressIndicator()
                  else
                    Text(
                      (record.error != null
                              ? 'Не удалось загрузить прогулку'
                              : 'Прогулка недоступна')
                          .tr(context),
                    ),
                  if (record != null && !record.loading)
                    TextButton(
                      onPressed: () =>
                          ref.read(walkingChatProvider.notifier).load(id),
                      child: Text('Повторить'.tr(context)),
                    ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    key: const Key('walking-chat-details'),
                    onTap: () {
                      ref.read(walkingChatProvider.notifier).load(id);
                      showWalkingChatDetails(context, id);
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: [
                          IdentityPicture(
                            id: 'pet:${(item['pet'] as Map?)?['id'] ?? item['pet_id']}',
                            name: '${(item['pet'] as Map?)?['name'] ?? ''}',
                            icon: LucideIcons.pawPrint,
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${(item['pet'] as Map?)?['name'] ?? 'Питомец'.tr(context)}',
                                  style: walkingBodyStyle.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  walkingShortTime(context, item),
                                  style: walkingMetaStyle(context, size: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.info, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    key: const Key('walking-chat-status'),
                    onTap: () => showStudioSelectionSheet<void>(
                      context: context,
                      builder: (_) => _WalkingProgress(id: id),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: [
                          Expanded(
                            child: WalkingStatusLabel(
                              walkStatus(item['status']).tr(context),
                            ),
                          ),
                          const Icon(Icons.expand_less, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

Future<void> showWalkingChatDetails(
  BuildContext context,
  String id, {
  bool chatEntry = false,
}) async {
  while (context.mounted) {
    if (!context.mounted) return;
    final openChat = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      sheetAnimationStyle: studioSheetAnimation(context),
      builder: (context) => _WalkingDetails(id: id, chatEntry: chatEntry),
    );
    if (openChat != true || !context.mounted) return;
    await context.push('/chat/$id');
  }
}

class _WalkingDetails extends ConsumerWidget {
  const _WalkingDetails({required this.id, this.chatEntry = false});
  final String id;
  final bool chatEntry;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(walkingChatProvider).records[id];
    final item = record?.item;
    final pet = item?['pet'] as Map?;
    final uid = ref.watch(communityRepositoryProvider).userId;
    final instructions = record?.instructions?.trim() ?? '';
    final temperament = '${pet?['temperament'] ?? ''}'.trim();
    final note = '${item?['description'] ?? ''}'.trim();
    final parsed = DateTime.tryParse('${item?['starts_at']}');
    final zone =
        item?['time_zone'] as String? ?? cityTimeZone(item?['city'] as String?);
    final local = parsed != null && validTimeZone(zone)
        ? venueDateTime(parsed, zone!)
        : null;
    final participants = [
      _WalkingParticipant(
        person: item?['owner'] as Map?,
        id: '${(item?['owner'] as Map?)?['id'] ?? item?['owner_id']}',
        role: 'Владелец',
        me: item?['my_role'] == 'owner' && uid != null,
      ),
      _WalkingParticipant(
        person: item?['helper'] as Map?,
        id: '${(item?['helper'] as Map?)?['id'] ?? item?['helper_id']}',
        role: 'Помощник',
        me: item?['my_role'] == 'helper' && uid != null,
      ),
    ];
    return WalkingFormTheme(
      child: WalkingChatSheet(
        title: 'Детали'.tr(context),
        children: [
          if (chatEntry && item != null)
            OutlinedButton.icon(
              key: const Key('agreement-details-chat'),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: Text('Чат'.tr(context)),
            ),
          if (record?.loading == true)
            const WalkingLoadingState()
          else if (item == null) ...[
            Text(
              (record?.error != null
                      ? 'Не удалось загрузить прогулку'
                      : 'Прогулка недоступна')
                  .tr(context),
            ),
            TextButton(
              onPressed: () => ref.read(walkingChatProvider.notifier).load(id),
              child: Text('Повторить'.tr(context)),
            ),
          ] else ...[
            Text(
              '${pet?['name'] ?? 'Питомец'.tr(context)}',
              style: walkingIdentityStyle,
            ),
            const SizedBox(height: 8),
            Text(
              [
                local == null
                    ? walkingChatTime(context, item)
                    : '${DateFormat.MMMMd(context.languageCode).format(local)} · ${DateFormat.Hm(context.languageCode).format(local)}',
                if (item['duration'] is num)
                  stringsFor(
                    context.languageCode,
                  ).walkingDurationMinutes((item['duration'] as num).toInt()),
              ].join(' · '),
              style: walkingBodyStyle,
            ),
            const SizedBox(height: 12),
            Text(
              [
                if (validTimeZone(zone))
                  timeZoneLabel(
                    zone!,
                    at: parsed,
                    locale: context.languageCode,
                  ),
                [
                  item['city'],
                  item['district'],
                ].whereType<String>().where((v) => v.isNotEmpty).join(', '),
              ].where((v) => v.isNotEmpty).join(' · '),
              style: walkingMetaStyle(context),
            ),
            const _WalkingSectionDivider(),
            Semantics(
              label: 'Участники'.tr(context),
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    MediaQuery.textScalerOf(context).scale(16) > 24 ||
                        constraints.maxWidth < 300
                    ? Column(
                        children: [
                          participants[0],
                          const SizedBox(height: 12),
                          participants[1],
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: participants[0]),
                          const SizedBox(width: 16),
                          Expanded(child: participants[1]),
                        ],
                      ),
              ),
            ),
            if (instructions.isNotEmpty) ...[
              const _WalkingSectionDivider(),
              Text('Передача питомца'.tr(context), style: walkingIdentityStyle),
              const SizedBox(height: 8),
              Text(
                'Только для участников этой прогулки'.tr(context),
                style: walkingMetaStyle(context),
              ),
              const SizedBox(height: 8),
              Text(instructions, style: walkingBodyStyle),
            ],
            if (temperament.isNotEmpty || note.isNotEmpty) ...[
              const _WalkingSectionDivider(),
              Text('Что нужно знать'.tr(context), style: walkingIdentityStyle),
              const SizedBox(height: 8),
              Text(
                [temperament, note].where((v) => v.isNotEmpty).join('\n\n'),
                style: walkingBodyStyle,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WalkingSectionDivider extends StatelessWidget {
  const _WalkingSectionDivider();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
  );
}

class _WalkingParticipant extends StatelessWidget {
  const _WalkingParticipant({
    required this.person,
    required this.id,
    required this.role,
    required this.me,
  });
  final Map? person;
  final String id, role;
  final bool me;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      IdentityPicture(
        id: 'profile:$id',
        name: person?['display_name'] as String?,
        icon: LucideIcons.user,
        size: 40,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${person?['display_name'] ?? role.tr(context)}',
              style: walkingBodyStyle.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              [role.tr(context), if (me) 'Вы'.tr(context)].join(' · '),
              style: walkingMetaStyle(context, size: 13),
            ),
          ],
        ),
      ),
    ],
  );
}

class WalkingChatSheet extends StatelessWidget {
  const WalkingChatSheet({
    required this.title,
    required this.children,
    this.closeEnabled = true,
    this.onClose,
    super.key,
  });
  final bool closeEnabled;
  final VoidCallback? onClose;
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .86,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            key: const Key('walking-sheet-header'),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Expanded(child: Text(title, style: walkingSheetTitleStyle)),
                IconButton(
                  tooltip: 'Закрыть'.tr(context),
                  onPressed: closeEnabled
                      ? onClose ?? () => Navigator.pop(context)
                      : null,
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              key: const Key('walking-sheet-scroll'),
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _WalkingProgress extends ConsumerStatefulWidget {
  const _WalkingProgress({required this.id});
  final String id;
  @override
  ConsumerState<_WalkingProgress> createState() => _WalkingProgressState();
}

class _WalkingProgressState extends ConsumerState<_WalkingProgress> {
  Timer? tick;
  @override
  void initState() {
    super.initState();
    tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.id;
    final record = ref.watch(walkingChatProvider).records[id];
    final item = record?.item;
    if (item == null) {
      return StudioReviewSheet(
        title: 'Прогулка'.tr(context),
        child: Text('Прогулка недоступна'.tr(context)),
      );
    }
    final start = DateTime.tryParse('${item['started_at']}');
    final end = DateTime.tryParse('${item['finished_at']}') ?? DateTime.now();
    final seconds = start == null
        ? null
        : end.difference(start).inSeconds.clamp(0, 8640000);
    final elapsed = seconds == null
        ? '—'
        : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return StudioReviewSheet(
      title: '${(item['pet'] as Map?)?['name'] ?? 'Прогулка'.tr(context)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          WalkingStatusLabel(walkStatus(item['status']).tr(context)),
          const SizedBox(height: 12),
          if ([
            'in_progress',
            'awaiting_confirmation',
            'completed',
          ].contains(item['status'])) ...[
            Text(elapsed, style: Theme.of(context).textTheme.headlineLarge),
            Text(
              '${item['duration']} ${'мин'.tr(context)} · ${'По плану'.tr(context)}',
            ),
            const SizedBox(height: 20),
          ],
          if (walkingChatNextAction(item) case final String action) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                key: Key('walking-chat-action-$action'),
                onPressed: record!.pending
                    ? null
                    : () async {
                        if (action.startsWith('review_')) {
                          await showWalkingReviewSheet(
                            context,
                            id: '${item['id']}',
                            role: action == 'review_owner' ? 'owner' : 'helper',
                          );
                          if (ref.context.mounted) {
                            await ref
                                .read(walkingChatProvider.notifier)
                                .load(id);
                          }
                        } else {
                          await ref
                              .read(walkingChatProvider.notifier)
                              .advance(id, action);
                        }
                      },
                child: record.pending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        ({
                          'start': 'Начать прогулку',
                          'finish': 'Завершить прогулку',
                          'confirm': 'Подтвердить завершение',
                          'review_helper': 'Оставить отзыв',
                          'review_owner': 'Оставить отзыв',
                        }[action]!).tr(context),
                      ),
              ),
            ),
          ],
          if (record!.actionError != null) ...[
            Text(
              'Не удалось обновить статус. Обновите прогулку и попробуйте снова.'
                  .tr(context),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: () => ref.read(walkingChatProvider.notifier).load(id),
              child: Text('Обновить статус заявки'.tr(context)),
            ),
          ],
        ],
      ),
    );
  }
}
