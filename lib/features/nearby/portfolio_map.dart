import 'add_place_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'fullscreen_map_screen.dart';
import 'place_details_sheet.dart';
import 'place_repository.dart';

/// Offline demo adapter. Shared app navigation and place sheets remain native
/// Flutter widgets; only the external Mapbox surface is replaced.
class PortfolioMapState extends ConsumerState<FullscreenMapScreen> {
  final transform = TransformationController();
  bool showPosition = false;
  bool positioned = false;
  Size viewport = Size.zero;

  @override
  void initState() {
    super.initState();
    if (widget.args.focusPlace != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => focus(widget.args.focusPlace!),
      );
    }
  }

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  void zoom(double factor) {
    final current = transform.value.getMaxScaleOnAxis();
    if (current * factor < .7 || current * factor > 5) return;
    final next = transform.value.clone()..scaleByDouble(factor, factor, 1, 1);
    transform.value = next;
  }

  Offset point(Place place) {
    return Offset(
      340 + ((place.longitude ?? 27.556) - 27.556) * 14500,
      320 - ((place.latitude ?? 53.906) - 53.906) * 20000,
    );
  }

  void focus(Place place) {
    final p = point(place);
    final next = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - p.dx,
        viewport.height / 2 - p.dy,
        0,
        1,
      );
    transform.value = next;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final embedded = widget.embedded;
    final map = LayoutBuilder(
      builder: (context, constraints) {
        viewport = constraints.biggest;
        if (!positioned) {
          positioned = true;
          transform.value = Matrix4.identity()
            ..translateByDouble(
              viewport.width / 2 - 340,
              viewport.height / 2 - 320,
              0,
              1,
            );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(embedded ? 24 : 0),
                child: InteractiveViewer(
                  key: const Key('portfolio-map'),
                  transformationController: transform,
                  boundaryMargin: const EdgeInsets.all(500),
                  minScale: .7,
                  maxScale: 5,
                  constrained: false,
                  child: SizedBox(
                    width: 700,
                    height: 900,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _NeighborhoodPainter(
                              dark:
                                  Theme.of(context).brightness ==
                                  Brightness.dark,
                            ),
                          ),
                        ),
                        for (final place in widget.args.places)
                          Positioned(
                            left: point(place).dx - 24,
                            top: point(place).dy - 24,
                            child: Semantics(
                              button: true,
                              label: 'Open ${place.name}',
                              child: IconButton.filled(
                                tooltip: place.name,
                                style: IconButton.styleFrom(
                                  backgroundColor: colors.surface,
                                  foregroundColor: colors.onSurface,
                                ),
                                onPressed: () => showPlace(
                                  context,
                                  place,
                                  onShowOnMap: () => focus(place),
                                ),
                                icon: Icon(place.icon, size: 22),
                              ),
                            ),
                          ),
                        if (showPosition)
                          Positioned(
                            left: 330,
                            top: 350,
                            child: Semantics(
                              label: 'Simulated position',
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: embedded ? 12 : 28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Mock map · fictional places',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
            if (!embedded)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Close map',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                      const SizedBox(width: 12),
                      Chip(label: Text('Places · ${widget.args.city}')),
                      const Spacer(),
                      IconButton.filledTonal(
                        tooltip: 'Places list',
                        onPressed: () => context.push('/places'),
                        icon: const Icon(Icons.view_list_outlined),
                      ),
                    ],
                  ),
                ),
              ),
            if (!embedded)
              Positioned(
                right: 16,
                bottom: 72,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Zoom in',
                      onPressed: () => zoom(1.25),
                      icon: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    IconButton.filledTonal(
                      tooltip: 'Zoom out',
                      onPressed: () => zoom(.8),
                      icon: const Icon(Icons.remove),
                    ),
                    const SizedBox(height: 16),
                    IconButton.filled(
                      tooltip: 'Show simulated position',
                      onPressed: () {
                        setState(() => showPosition = true);
                        transform.value = Matrix4.identity()
                          ..translateByDouble(
                            viewport.width / 2 - 340,
                            viewport.height / 2 - 350,
                            0,
                            1,
                          );
                      },
                      icon: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
    if (!embedded) return Scaffold(body: map);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Места рядом',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton.icon(
              key: const Key('choose-city'),
              onPressed: widget.onCityPressed,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.expand_more, size: 18),
              label: Text(widget.args.city),
            ),
            IconButton(
              tooltip: 'На весь экран',
              onPressed: () => context.push(
                '/map',
                extra: FullscreenMapArgs(
                  places: widget.args.places,
                  city: widget.args.city,
                ),
              ),
              icon: const Icon(Icons.open_in_full, size: 20),
            ),
          ],
        ),
        const Divider(height: 1),
        InkWell(
          onTap: widget.onList,
          child: const SizedBox(
            height: 56,
            child: Row(
              children: [
                Icon(Icons.view_list_outlined, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Места списком')),
                Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Expanded(child: map),
      ],
    );
  }
}

class _NeighborhoodPainter extends CustomPainter {
  _NeighborhoodPainter({required this.dark});
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(
      dark ? const Color(0xFF252B28) : const Color(0xFFEEEFE9),
      BlendMode.src,
    );
    final park = Paint()
      ..color = dark ? const Color(0xFF344132) : const Color(0xFFD9E5CC);
    for (final rect in [
      const Rect.fromLTWH(190, 110, 200, 160),
      const Rect.fromLTWH(45, 410, 150, 210),
      const Rect.fromLTWH(490, 510, 160, 260),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(32)),
        park,
      );
    }
    final water = Paint()
      ..color = dark ? const Color(0xFF30484D) : const Color(0xFFC5DFE5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38;
    final river = Path()
      ..moveTo(520, -50)
      ..cubicTo(380, 220, 620, 270, 450, 480)
      ..cubicTo(290, 660, 510, 700, 420, 950);
    canvas.drawPath(river, water);
    final road = Paint()
      ..color = dark ? const Color(0xFF48514A) : Colors.white
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    for (var y = 50.0; y < 900; y += 110) {
      canvas.drawLine(Offset(0, y), Offset(700, y + 60), road);
    }
    for (var x = 20.0; x < 700; x += 135) {
      canvas.drawLine(Offset(x, 0), Offset(x + 100, 900), road);
    }
    canvas.drawPath(
      Path()
        ..moveTo(0, 700)
        ..quadraticBezierTo(350, 200, 700, 320),
      road..strokeWidth = 20,
    );
    final labelStyle = TextStyle(
      color: dark ? const Color(0xFFBBC2B4) : const Color(0xFF62695C),
      fontSize: 12,
      fontFamily: 'Golos Text',
    );
    final labels = {
      'Green Park': const Offset(225, 150),
      'Riverside': const Offset(500, 380),
      'Central district': const Offset(200, 590),
    };
    for (final entry in labels.entries) {
      final text = TextPainter(
        text: TextSpan(text: entry.key, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, entry.value);
    }
    // Small blocks provide spatial reference while dragging the synthetic map.
    final blocks = Paint()
      ..color = dark ? const Color(0xFF353C35) : const Color(0xFFDFE1D7);
    for (var i = 0; i < 28; i++) {
      final x = 30.0 + (i * 83) % 620;
      final y = 70.0 + (i * 137) % 760;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 34, 22),
          const Radius.circular(4),
        ),
        blocks,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NeighborhoodPainter oldDelegate) =>
      dark != oldDelegate.dark;
}

class PortfolioPositionState extends ConsumerState<PlacePositionPicker> {
  final transform = TransformationController();
  Size viewport = Size.zero;
  bool positioned = false;
  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Place location')),
    body: LayoutBuilder(
      builder: (context, constraints) {
        viewport = constraints.biggest;
        if (!positioned) {
          positioned = true;
          transform.value = Matrix4.identity()
            ..translateByDouble(
              viewport.width / 2 - 340,
              viewport.height / 2 - 320,
              0,
              1,
            );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: transform,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(500),
                minScale: .7,
                maxScale: 5,
                child: SizedBox(
                  width: 700,
                  height: 900,
                  child: CustomPaint(
                    painter: _NeighborhoodPainter(
                      dark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
              ),
            ),
            const Center(child: IgnorePointer(child: SelectedPlacePin())),
            Positioned(
              left: 24,
              right: 24,
              bottom: 40,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Move the mock map. The center marker is your place.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {
                        final p = transform.toScene(
                          Offset(viewport.width / 2, viewport.height / 2),
                        );
                        Navigator.pop(context, (
                          53.906 - (p.dy - 320) / 20000,
                          27.556 + (p.dx - 340) / 14500,
                        ));
                      },
                      child: const Text('Use this point'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
