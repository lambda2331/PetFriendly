import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backend/backend.dart';
import '../../core/media/preview_photos.dart';

const chatPhotoInputLimit = 5 * 1024 * 1024;

void validateChatUpload(MediaDraft draft) {
  if (draft.kind != 'image' || draft.mime != 'image/png') {
    throw const FormatException('В чаты можно загружать только фото');
  }
  if (draft.bytes.length > chatPhotoInputLimit) {
    throw const FormatException('Выберите фото до 5 МБ');
  }
}

class MediaDraft {
  const MediaDraft({
    required this.bytes,
    required this.kind,
    required this.mime,
    this.duration,
  });
  final Uint8List bytes;
  final String kind, mime;
  final double? duration;
  String get label => kind == 'image' ? 'Фото' : 'Видео';
}

class ChatAttachment {
  const ChatAttachment(this.kind, this.mime, {this.duration});
  final String kind, mime;
  final double? duration;
  factory ChatAttachment.fromJson(Map<String, dynamic> row) => ChatAttachment(
    row['kind'],
    row['mime'],
    duration: (row['duration'] as num?)?.toDouble(),
  );
}

ChatAttachment? decodeChatAttachment(dynamic value) {
  if (value is Map) {
    return ChatAttachment.fromJson(Map<String, dynamic>.from(value));
  }
  if (value is List && value.isNotEmpty) {
    return ChatAttachment.fromJson(Map<String, dynamic>.from(value.first));
  }
  return null;
}

class ChatMediaService {
  Future<MediaDraft?> pickImage() async {
    final bytes = await pickPreviewPhoto(maxInputBytes: chatPhotoInputLimit);
    if (bytes != null && bytes.length > chatPhotoInputLimit) {
      throw const FormatException(
        'Фото после обработки больше 5 МБ. Выберите другое изображение.',
      );
    }
    return bytes == null
        ? null
        : MediaDraft(bytes: bytes, kind: 'image', mime: 'image/png');
  }
}

final chatMediaServiceProvider = Provider((ref) => ChatMediaService());
final chatMediaAvailableProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  ref.watch(authStateProvider.select((state) => state.value?.id));
  final client = ref.watch(backendProvider);
  if (client == null) return true;
  try {
    await client.rpc('chat_media_capabilities');
    return true;
  } catch (_) {
    return false;
  }
});
final chatMediaBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, id) async {
      ref.watch(authStateProvider.select((state) => state.value?.id));
      final client = ref.watch(backendProvider);
      if (client == null) throw StateError('Media unavailable');
      final account = client.auth.currentUser?.id;
      final response = await client.functions.invoke(
        'chat-media',
        queryParameters: {'mode': 'read', 'message': id},
      );
      if (account == null || client.auth.currentUser?.id != account) {
        throw StateError('Session changed');
      }
      final bytes = response.data as Uint8List;
      if (bytes.length > 20 * 1024 * 1024) throw StateError('Media too large');
      return bytes;
    });
// Files created only for a live native player; no persistent chat cache.
Future<File> createVideoPreview(
  Uint8List bytes,
  String extension,
  Directory root,
) async {
  final directory = await root.createTemp('petfriendly-chat-');
  final file = File('${directory.path}/video.$extension');
  try {
    return await file.writeAsBytes(bytes, flush: true);
  } catch (_) {
    await directory.delete(recursive: true);
    rethrow;
  }
}

Uint8List encodeMediaUpload(MediaDraft draft, String caption) {
  validateChatUpload(draft);
  final metadata = utf8.encode(
    jsonEncode({'caption': caption, 'mime': draft.mime}),
  );
  final body = Uint8List(4 + metadata.length + draft.bytes.length);
  ByteData.sublistView(body).setUint32(0, metadata.length);
  body.setRange(4, 4 + metadata.length, metadata);
  body.setRange(4 + metadata.length, body.length, draft.bytes);
  return body;
}

Future<void> purgeTemporaryChatMedia(Directory root) async {
  await for (final entry in root.list(followLinks: false)) {
    if (entry is Directory &&
        entry.path
            .split(Platform.pathSeparator)
            .last
            .startsWith('petfriendly-chat-')) {
      try {
        await entry.delete(recursive: true);
      } on FileSystemException {
        /* Retry at next launch. */
      }
    }
  }
}
