import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/ui/studio_review.dart';
import '../../core/media/preview_photos.dart';
import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/components.dart';
import '../community/data/community_repository.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({
    this.embedded = false,
    this.initialQuery = '',
    this.onQueryChanged,
    super.key,
  });
  final bool embedded;
  final String initialQuery;
  final ValueChanged<String>? onQueryChanged;
  @override
  ConsumerState<NewChatScreen> createState() => _NewChatState();
}

class _NewChatState extends ConsumerState<NewChatScreen> {
  late final TextEditingController search;
  late String query;
  @override
  void initState() {
    super.initState();
    query = widget.initialQuery;
    search = TextEditingController(text: query);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  String? opening;
  Future<void> open(String id) async {
    if (opening != null) return;
    setState(() => opening = id);
    final repository = ref.read(communityRepositoryProvider);
    final uid = repository.userId;
    try {
      final chat = await ref.read(communityProvider.notifier).command(
        'direct',
        {'target': id},
      );
      if (mounted &&
          chat != null &&
          identical(repository, ref.read(communityRepositoryProvider)) &&
          uid == repository.userId) {
        final router = GoRouter.of(context);
        if (widget.embedded) {
          Navigator.pop(context, chat);
        } else {
          await router.push('/chat/$chat');
        }
      }
    } catch (_) {
      if (mounted) {
        notice(
          context,
          "Не удалось открыть переписку. Повторите попытку.".tr(context),
        );
      }
    } finally {
      if (mounted) setState(() => opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = ref
        .watch(communityProvider)
        .when(
          loading: () => StudioReviewState(
            title: 'Загружаем профиль…'.tr(context),
            loading: true,
          ),
          error: (_, _) => StudioReviewState(
            title: 'Не удалось загрузить'.tr(context),
            action: OutlinedButton(
              onPressed: () => ref.invalidate(communityProvider),
              child: Text('Повторить загрузку'.tr(context)),
            ),
          ),
          data: (data) {
            final repository = ref.read(communityRepositoryProvider);
            final blocked = rows(data, 'blocks')
                .where((b) => b['user_id'] == repository.userId)
                .map((b) => b['target_id'])
                .toSet();
            final people = rows(data, 'profiles')
                .where(
                  (p) =>
                      p['id'] != repository.userId &&
                      !blocked.contains(p['id']) &&
                      (p['display_name'] as String? ?? '')
                          .toLowerCase()
                          .contains(query.trim().toLowerCase()),
                )
                .toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: search,
                  onChanged: (value) {
                    setState(() => query = value);
                    widget.onQueryChanged?.call(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Поиск по имени'.tr(context),
                    prefixIcon: const Icon(LucideIcons.search),
                  ),
                ),
                const SizedBox(height: 12),
                if (people.isEmpty)
                  StudioReviewState(
                    title: 'Ничего не найдено'.tr(context),
                    message: 'Попробуйте другое имя.'.tr(context),
                  ),
                for (var i = 0; i < people.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 12, endIndent: 12),
                  StudioReviewRow(
                    key: ValueKey('new-chat-${people[i]['id']}'),
                    title:
                        people[i]['display_name'] as String? ??
                        'Участник'.tr(context),
                    subtitle: (people[i]['district'] as String? ?? '').isEmpty
                        ? null
                        : people[i]['district'] as String,
                    leading: IdentityPicture(
                      id: 'profile:${people[i]['id']}',
                      name: people[i]['display_name'],
                      icon: LucideIcons.user,
                      size: 56,
                    ),
                    trailing: opening == people[i]['id']
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.messageSquare),
                    onTap: opening == null
                        ? () => open(people[i]['id'] as String)
                        : null,
                  ),
                ],
              ],
            );
          },
        );
    if (widget.embedded) {
      return StudioReviewSheet(
        title: 'Новая переписка'.tr(context),
        child: body,
      );
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('Новая переписка'.tr(context), style: studioSheetText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: body,
      ),
    );
  }
}

Future<void> showNewChatSheet(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final repository = container.read(communityRepositoryProvider);
  final uid = repository.userId;
  final router = GoRouter.of(context);
  final bucket = PageStorageBucket();
  var query = '';
  bool sameAccount() =>
      identical(repository, container.read(communityRepositoryProvider)) &&
      uid == repository.userId;
  while (true) {
    if (!context.mounted) return;
    if (!sameAccount()) return;
    final chat = await showStudioSelectionSheet<String>(
      context: context,
      builder: (ctx) => PageStorage(
        bucket: bucket,
        child: NewChatScreen(
          embedded: true,
          initialQuery: query,
          onQueryChanged: (value) => query = value,
        ),
      ),
    );
    if (chat == null || !context.mounted || !sameAccount()) return;
    await router.push('/chat/$chat');
  }
}
