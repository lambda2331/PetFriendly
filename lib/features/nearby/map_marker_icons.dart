import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MapMarkerIcons {
  static final _user = <double, Future<Uint8List>>{};
  static Future<Uint8List> userLocation(double ratio) =>
      _user.putIfAbsent(ratio, () async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)..scale(ratio);
        canvas.drawCircle(
          const Offset(24, 24),
          23,
          Paint()..color = const Color(0x303687FF),
        );
        canvas.drawCircle(
          const Offset(24, 24),
          16,
          Paint()..color = const Color(0xFFFFFFFF),
        );
        canvas.drawCircle(
          const Offset(24, 24),
          13,
          Paint()..color = const Color(0xFF2468D7),
        );
        final arrow = Path()
          ..moveTo(24, 15)
          ..lineTo(31, 31)
          ..lineTo(24, 27)
          ..lineTo(17, 31)
          ..close();
        canvas.drawPath(arrow, Paint()..color = const Color(0xFFFFFFFF));
        final picture = recorder.endRecording();
        final image = await picture.toImage(
          (48 * ratio).round(),
          (48 * ratio).round(),
        );
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        picture.dispose();
        return bytes!.buffer.asUint8List();
      });
  static final _cached = <double, Future<Map<String, Uint8List>>>{};
  static Future<Map<String, Uint8List>> load(double pixelRatio) =>
      _cached.putIfAbsent(pixelRatio, () => _render(pixelRatio));
  static Future<Map<String, Uint8List>> _render(double pixelRatio) async {
    final result = <String, Uint8List>{};
    for (final entry in <String, IconData>{
      'Парк': Icons.park_outlined,
      'Кафе': Icons.local_cafe_outlined,
      'Площадка': Icons.pets_outlined,
      'Зоомагазин': Icons.storefront_outlined,
      'Ветклиника': Icons.local_hospital_outlined,
      'Ресторан': Icons.restaurant_outlined,
      'Место встречи': Icons.groups_outlined,
    }.entries) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(pixelRatio);
      canvas.drawCircle(
        const Offset(32, 32),
        29,
        Paint()..color = const Color(0xFFD6ED8A),
      );
      canvas.drawCircle(
        const Offset(32, 32),
        29,
        Paint()
          ..color = const Color(0xFF253314)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      final glyph = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(entry.value.codePoint),
          style: TextStyle(
            fontFamily: entry.value.fontFamily,
            package: entry.value.fontPackage,
            fontSize: 33,
            color: const Color(0xFF253314),
          ),
        ),
      )..layout();
      glyph.paint(
        canvas,
        Offset((64 - glyph.width) / 2, (64 - glyph.height) / 2),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (64 * pixelRatio).round(),
        (64 * pixelRatio).round(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) result[entry.key] = bytes.buffer.asUint8List();
      image.dispose();
      picture.dispose();
    }
    return result;
  }
}
