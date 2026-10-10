import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/chat/video_sanitizer.dart';
import 'package:petfriendly/features/chat/chat_media.dart';

void main() {
  test('Only images up to 5 MiB can be queued, including retry payloads', () {
    MediaDraft draft(
      int size, {
      String kind = 'image',
      String mime = 'image/png',
    }) => MediaDraft(bytes: Uint8List(size), kind: kind, mime: mime);
    expect(
      () => validateChatUpload(draft(chatPhotoInputLimit)),
      returnsNormally,
    );
    expect(
      () => encodeMediaUpload(draft(chatPhotoInputLimit + 1), ''),
      throwsFormatException,
    );
    expect(
      () => encodeMediaUpload(draft(10, kind: 'video', mime: 'video/mp4'), ''),
      throwsFormatException,
    );
  });

  test(
    'Native H264 media strips metadata without moving samples and remains idempotent',
    () {
      final original = File('test/fixtures/chat-video.mp4').readAsBytesSync();
      expect(String.fromCharCodes(original), contains('PRIVATE_VIDEO_TEST'));
      final clean = sanitizeChatVideo(original);
      expect(clean.bytes.length, original.length);
      expect(
        String.fromCharCodes(clean.bytes),
        isNot(contains('PRIVATE_VIDEO_TEST')),
      );
      expect(clean.duration, greaterThan(0));
      expect(clean.duration, lessThan(2));
      expect(sanitizeChatVideo(clean.bytes).bytes, clean.bytes);
      expect(
        () => sanitizeChatVideo(original.sublist(0, 300)),
        throwsFormatException,
      );
      final bad = Uint8List.fromList(original),
          view = ByteData.sublistView(bad);
      final mvhd = String.fromCharCodes(bad).indexOf('mvhd') - 4;
      view.setUint32(mvhd + 24, view.getUint32(mvhd + 20) * 61);
      expect(() => sanitizeChatVideo(bad), throwsFormatException);
    },
  );
  test(
    'PostgREST to-one attachments decode; legacy array and empty messages work',
    () {
      final data = {'kind': 'video', 'mime': 'video/mp4', 'duration': 1.5};
      expect(decodeChatAttachment(data)!.duration, 1.5);
      expect(decodeChatAttachment([data])!.kind, 'video');
      expect(decodeChatAttachment(null), isNull);
      expect(decodeChatAttachment([]), isNull);
    },
  );
  test(
    'Caption is carried in the private request body, followed by immutable media bytes',
    () {
      final draft = MediaDraft(
        bytes: Uint8List.fromList([1, 2, 3]),
        kind: 'image',
        mime: 'image/png',
      );
      final body = encodeMediaUpload(draft, 'Private fixture');
      final size = ByteData.sublistView(body).getUint32(0);
      expect(
        jsonDecode(utf8.decode(body.sublist(4, 4 + size)))['caption'],
        'Private fixture',
      );
      expect(body.sublist(4 + size), [1, 2, 3]);
    },
  );
  test(
    'Temporary playback has a unique directory and can be removed completely',
    () async {
      final root = await Directory.systemTemp.createTemp('petfriendly-test-');
      try {
        final file = await createVideoPreview(
          Uint8List.fromList([1, 2, 3]),
          'mp4',
          root,
        );
        expect(await file.readAsBytes(), [1, 2, 3]);
        await file.parent.delete(recursive: true);
        expect(await root.list().toList(), isEmpty);
        await createVideoPreview(Uint8List.fromList([4]), 'mp4', root);
        final unrelated = await File(
          '${root.path}/keep.txt',
        ).writeAsString('fixture');
        await purgeTemporaryChatMedia(root);
        expect(await unrelated.exists(), isTrue);
        expect(await root.list().toList(), hasLength(1));
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
}
