import 'dart:typed_data';

class CleanVideo {
  const CleanVideo(this.bytes, this.duration);
  final Uint8List bytes;
  final double duration;
}

// Replace metadata atoms in place: moving moov would invalidate sample offsets.
CleanVideo sanitizeChatVideo(Uint8List input) {
  if (input.length > 20 * 1024 * 1024) {
    throw const FormatException('Видео больше 20 МБ');
  }
  final bytes = Uint8List.fromList(input),
      view = ByteData.sublistView(Uint8List.fromList(input));
  // The view only reads original atom headers and timing.
  String text(int at) => String.fromCharCodes(bytes.sublist(at, at + 4));
  const children = {
    'root': ['ftyp', 'moov', 'mdat', 'wide'],
    'moov': ['mvhd', 'trak'],
    'trak': ['tkhd', 'mdia', 'edts'],
    'mdia': ['mdhd', 'hdlr', 'minf'],
    'minf': ['vmhd', 'smhd', 'dinf', 'stbl'],
    'dinf': ['dref'],
    'edts': ['elst'],
    'stbl': [
      'stsd',
      'stts',
      'stsc',
      'stsz',
      'stco',
      'co64',
      'stss',
      'ctts',
      'sdtp',
    ],
    'sample': ['avcC', 'hvcC', 'pasp', 'colr', 'btrt', 'clap', 'fiel'],
  };
  var atoms = 0, duration = 0.0, video = false, videoSample = false;
  final roots = <String>{};
  Never invalid() => throw const FormatException(
    'Нужно видео MP4/MOV до 60 секунд с H.264 или HEVC',
  );
  void walk(int start, int end, String parent, [int depth = 0]) {
    if (depth > 12) invalid();
    var p = start;
    while (p < end) {
      if (++atoms > 50000 || p + 8 > end) invalid();
      var size = view.getUint32(p), header = 8;
      if (size == 1) {
        if (p + 16 > end || view.getUint32(p + 8) != 0) invalid();
        size = view.getUint32(p + 12);
        header = 16;
      }
      if (size == 0) size = end - p;
      if (size < header || p + size > end) invalid();
      final type = text(p + 4), finish = p + size;
      if (parent == 'root') roots.add(type);
      if (!(children[parent] ?? []).contains(type)) {
        bytes.setRange(p + 4, p + 8, [102, 114, 101, 101]);
        bytes.fillRange(p + header, finish, 0);
      } else if (children.containsKey(type)) {
        walk(p + header, finish, type, depth + 1);
      } else if (['mvhd', 'mdhd', 'tkhd'].contains(type)) {
        final v = bytes[p + header];
        if (v > 1 || size < header + (v == 1 ? 32 : 20)) invalid();
        if (type == 'mvhd') {
          final scaleAt = p + header + (v == 1 ? 20 : 12),
              ticksAt = scaleAt + 4;
          if (ticksAt + (v == 1 ? 8 : 4) > finish) invalid();
          final scale = view.getUint32(scaleAt);
          if (scale == 0 || v == 1 && view.getUint32(ticksAt) != 0) invalid();
          duration = view.getUint32(ticksAt + (v == 1 ? 4 : 0)) / scale;
          if (duration <= 0 || duration > 60) invalid();
        }
        bytes.fillRange(p + header + 4, p + header + (v == 1 ? 20 : 12), 0);
      } else if (type == 'hdlr') {
        if (size < header + 24) invalid();
        if (text(p + header + 8) == 'vide') video = true;
        bytes.fillRange(p + header + 24, finish, 0);
      } else if (type == 'dref') {
        if (size != header + 20 ||
            view.getUint32(p + header + 4) != 1 ||
            text(p + header + 12) != 'url ' ||
            view.getUint32(p + header + 16) != 1) {
          invalid();
        }
      } else if (type == 'stsd') {
        if (size < header + 8 || view.getUint32(p + header + 4) != 1) invalid();
        final sample = p + header + 8,
            codec = text(sample + 4),
            sampleSize = view.getUint32(sample);
        if (sampleSize < 8 || sample + sampleSize != finish) invalid();
        if (['avc1', 'avc3', 'hvc1', 'hev1'].contains(codec)) {
          if (sampleSize < 86) invalid();
          final width = view.getUint16(sample + 32),
              height = view.getUint16(sample + 34);
          if (width == 0 || height == 0 || width > 4096 || height > 4096) {
            invalid();
          }
          videoSample = true;
          bytes.fillRange(sample + 50, sample + 82, 0);
          walk(sample + 86, finish, 'sample', depth + 1);
        } else if (codec != 'mp4a') {
          invalid();
        }
      }
      p = finish;
    }
  }

  try {
    walk(0, bytes.length, 'root');
  } on RangeError {
    invalid();
  }
  if (!roots.containsAll(['ftyp', 'moov', 'mdat']) ||
      !video ||
      !videoSample ||
      duration == 0) {
    invalid();
  }
  return CleanVideo(bytes, duration);
}
