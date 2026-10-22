import '../../l10n/localization.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/backend/backend.dart';
import '../../core/ui/components.dart';
import 'chat_media.dart';

Future<void> showChatMedia(
  BuildContext context,
  WidgetRef ref,
  String id,
  ChatAttachment attachment,
  MediaDraft? local,
) async {
  try {
    final Uint8List bytes = local != null
        ? local.bytes
        : await ref.read(chatMediaBytesProvider(id).future);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _MediaViewer(bytes: bytes, attachment: attachment),
    );
  } catch (_) {
    if (context.mounted) {
      notice(
        context,
        "Не удалось открыть вложение. Повторите попытку.".tr(context),
      );
    }
  }
}

class ChatMediaTile extends ConsumerWidget {
  const ChatMediaTile({
    required this.messageId,
    required this.attachment,
    this.local,
    this.foreground,
    super.key,
  });
  final String messageId;
  final ChatAttachment attachment;
  final MediaDraft? local;
  final Color? foreground;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attachment.kind == 'video') {
      return TextButton.icon(
        onPressed: () =>
            showChatMedia(context, ref, messageId, attachment, local),
        icon: const Icon(Icons.play_circle_outline),
        label: Text(
          "Видео · {p0} с".tr(
            context,
            arguments: {'p0': attachment.duration?.round() ?? 0},
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor:
              foreground ?? Theme.of(context).colorScheme.onSurface,
        ),
      );
    }
    final bytes = local?.bytes;
    final remote = bytes == null
        ? ref.watch(chatMediaBytesProvider(messageId))
        : null;
    final photo = bytes ?? remote?.value;
    return InkWell(
      onTap: () => showChatMedia(context, ref, messageId, attachment, local),
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: photo == null
              ? Center(
                  child: remote?.hasError == true
                      ? Text(
                          "Фото · повторить".tr(context),
                          style: TextStyle(color: foreground),
                        )
                      : const CircularProgressIndicator(),
                )
              : Image.memory(
                  photo,
                  fit: BoxFit.cover,
                  cacheWidth: 600,
                  semanticLabel: "Фото в переписке".tr(context),
                ),
        ),
      ),
    );
  }
}

class _MediaViewer extends ConsumerStatefulWidget {
  const _MediaViewer({required this.bytes, required this.attachment});
  final Uint8List bytes;
  final ChatAttachment attachment;
  @override
  ConsumerState<_MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends ConsumerState<_MediaViewer>
    with WidgetsBindingObserver {
  VideoPlayerController? player;
  File? temporary;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.attachment.kind == 'video') prepare();
  }

  Future<void> prepare() async {
    VideoPlayerController? current;
    try {
      final file = await createVideoPreview(
        widget.bytes,
        widget.attachment.mime == 'video/quicktime' ? 'mov' : 'mp4',
        await getTemporaryDirectory(),
      );
      if (!mounted) {
        await file.parent.delete(recursive: true);
        return;
      }
      temporary = file;
      current = VideoPlayerController.file(file);
      await current.initialize();
      await current.setVolume(0);
      if (!mounted) {
        await current.dispose();
        return;
      }
      setState(() => player = current);
    } catch (_) {
      await current?.dispose();
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) player?.pause();
  }

  Future<void> cleanup() async {
    await player?.dispose();
    try {
      await temporary?.parent.delete(recursive: true);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider.select((state) => state.value?.id), (
      old,
      next,
    ) {
      if (old != next && mounted) Navigator.of(context).pop();
    });
    final current = player;
    return Dialog.fullscreen(
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.attachment.kind == 'image'
                        ? "Фото".tr(context)
                        : "Видео".tr(context),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: "Закрыть".tr(context),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: widget.attachment.kind == 'image'
                    ? InteractiveViewer(
                        child: Image.memory(widget.bytes, fit: BoxFit.contain),
                      )
                    : failed
                    ? Text(
                        "Формат видео не поддерживается на устройстве.".tr(
                          context,
                        ),
                      )
                    : current == null
                    ? const CircularProgressIndicator()
                    : AspectRatio(
                        aspectRatio: current.value.aspectRatio,
                        child: VideoPlayer(current),
                      ),
              ),
            ),
            if (current != null)
              ValueListenableBuilder(
                valueListenable: current,
                builder: (context, value, _) => Column(
                  children: [
                    VideoProgressIndicator(current, allowScrubbing: true),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: value.isPlaying
                              ? "Пауза".tr(context)
                              : "Воспроизвести".tr(context),
                          onPressed: () => value.isPlaying
                              ? current.pause()
                              : current.play(),
                          icon: Icon(
                            value.isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                        ),
                        IconButton(
                          tooltip: value.volume == 0
                              ? "Включить звук".tr(context)
                              : "Выключить звук".tr(context),
                          onPressed: () =>
                              current.setVolume(value.volume == 0 ? 1 : 0),
                          icon: Icon(
                            value.volume == 0
                                ? Icons.volume_off_outlined
                                : Icons.volume_up_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
