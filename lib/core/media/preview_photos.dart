import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/studio_theme.dart';
import '../backend/backend.dart';

// Demo photos stay in memory; backend photos use authenticated private Storage.
class PreviewPhotos extends Notifier<Map<String, Uint8List>> {
  @override
  Map<String, Uint8List> build() => {};
  void put(String id, Uint8List bytes) => state = {...state, id: bytes};
}

final savedPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>((ref, id) async {
      ref.watch(authStateProvider);
      final client = ref.watch(backendProvider);
      if (client == null || client.auth.currentUser == null) return null;
      final parts = id.split(':');
      if (parts.length != 2) return null;
      final row = await client
          .from('entity_photos')
          .select('object_path')
          .eq('kind', parts[0])
          .eq('target_id', parts[1])
          .maybeSingle();
      if (row == null) return null;
      final response = await client.functions.invoke(
        'read-photo',
        body: {'kind': parts[0], 'target': parts[1]},
      );
      return response.data as Uint8List;
    });

Future<bool> savePhoto(WidgetRef ref, String id, Uint8List bytes) async {
  final client = ref.read(backendProvider);
  if (client != null) {
    final parts = id.split(':');
    await client.functions.invoke(
      'upload-photo',
      body: bytes,
      headers: {'Content-Type': 'image/png'},
      queryParameters: {'kind': parts[0], 'target': parts[1]},
    );
    ref.invalidate(savedPhotoProvider(id));
  }
  ref.read(previewPhotosProvider.notifier).put(id, bytes);
  return client != null;
}

final previewPhotosProvider =
    NotifierProvider<PreviewPhotos, Map<String, Uint8List>>(PreviewPhotos.new);
Future<Uint8List?> pickPreviewPhoto({
  int maxInputBytes = 8 * 1024 * 1024,
}) async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    requestFullMetadata: false,
  );
  if (file == null) return null;
  if (await file.length() > maxInputBytes) {
    throw FormatException(
      'Выберите фото до ${maxInputBytes ~/ (1024 * 1024)} МБ',
    );
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(
    await file.readAsBytes(),
  );
  late ui.Codec codec;
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    try {
      if (descriptor.width * descriptor.height > 40000000) {
        throw const FormatException('Слишком большое разрешение фото');
      }
      final scale = math.min(
        1.0,
        1200 / math.max(descriptor.width, descriptor.height),
      );
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (descriptor.width * scale).round()),
        targetHeight: math.max(1, (descriptor.height * scale).round()),
      );
    } finally {
      descriptor.dispose();
    }
  } finally {
    buffer.dispose();
  }
  try {
    final frame = await codec.getNextFrame();
    try {
      final encoded = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return encoded?.buffer.asUint8List();
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

class IdentityPicture extends ConsumerWidget {
  const IdentityPicture({
    required this.id,
    required this.icon,
    this.size = 56,
    this.name,
    super.key,
  });
  final String id;
  final String? name;
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedPhotoProvider(id));
    final bytes = ref.watch(previewPhotosProvider)[id] ?? saved.value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .3),
      child: Container(
        width: size,
        height: size,
        color: StudioColors.of(context).tint,
        child: bytes == null
            ? name == null || name!.trim().isEmpty
                  ? Icon(icon, size: size * .46)
                  : ExcludeSemantics(
                      child: Center(
                        child: Text(
                          name!
                              .trim()
                              .split(RegExp(r'\s+'))
                              .take(2)
                              .map((part) => part.characters.first)
                              .join()
                              .toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontSize: size * .34),
                        ),
                      ),
                    )
            : Image.memory(
                bytes,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                gaplessPlayback: true,
              ),
      ),
    );
  }
}

class CommunityCover extends ConsumerWidget {
  const CommunityCover({
    required this.id,
    this.previewBytes,
    this.title,
    this.prominent = false,
    super.key,
  });
  final String id;
  final Uint8List? previewBytes;
  final String? title;
  final bool prominent;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedPhotoProvider(id));
    final bytes =
        previewBytes ?? ref.watch(previewPhotosProvider)[id] ?? saved.value;
    final heading = Text(
      title ?? 'Фото сообщества не добавлено',
      style: prominent
          ? Theme.of(context).textTheme.headlineSmall
          : Theme.of(context).textTheme.titleMedium,
    );
    if (bytes == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: StudioColors.of(context).tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.people_outline, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(header: title != null, child: heading),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Semantics(header: true, child: heading),
          const SizedBox(height: 12),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 2,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              gaplessPlayback: true,
            ),
          ),
        ),
      ],
    );
  }
}
