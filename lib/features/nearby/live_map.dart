import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../core/backend/backend.dart';
import '../../core/ui/components.dart';
import 'place_repository.dart';
import 'map_clusters.dart';
import 'map_marker_icons.dart';

class LiveMap extends StatefulWidget {
  const LiveMap({
    required this.places,
    required this.onPlace,
    this.position,
    this.userPosition,
    this.initialCamera,
    this.cityCenter,
    this.fullscreen = false,
    this.onExpand,
    this.onCreated,
    this.onReady,
    this.focusPlace,
    this.onOpenList,
    super.key,
  });
  final List<Place> places;
  final ValueChanged<Place> onPlace;
  final geo.Position? position, userPosition;
  final CameraState? initialCamera;
  final Point? cityCenter;
  final bool fullscreen;
  final ValueChanged<CameraState?>? onExpand;
  final ValueChanged<MapboxMap>? onCreated, onReady;
  final Place? focusPlace;
  final VoidCallback? onOpenList;
  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  late final ViewportState initialViewport = CameraViewportState(
    center:
        widget.focusPlace?.longitude != null &&
            widget.focusPlace?.latitude != null
        ? Point(
            coordinates: Position(
              widget.focusPlace!.longitude!,
              widget.focusPlace!.latitude!,
            ),
          )
        : widget.initialCamera?.center ??
              widget.cityCenter ??
              Point(
                coordinates: Position.named(
                  lng: widget.position?.longitude ?? 27.5619,
                  lat: widget.position?.latitude ?? 53.9023,
                ),
              ),
    zoom: widget.focusPlace != null ? 16 : widget.initialCamera?.zoom ?? 12,
    bearing: widget.initialCamera?.bearing ?? 0,
    pitch: widget.initialCamera?.pitch ?? 0,
  );
  MapboxMap? map;
  CircleAnnotationManager? manager;
  PointAnnotationManager? userManager;
  Cancelable? taps, labelTaps;
  PointAnnotationManager? labels;
  Timer? cameraDebounce;
  int markerRevision = 0;
  final byAnnotation = <String, MapCluster>{};
  final byLabel = <String, MapCluster>{};
  bool failed = false;
  Brightness? loadedBrightness;
  int mapGeneration = 0;
  Future<void> markers() async {
    final current = map;
    final generation = mapGeneration;
    final revision = ++markerRevision;
    if (current == null || !mounted) return;
    final markerPixelRatio = defaultTargetPlatform == TargetPlatform.iOS
        ? MediaQuery.devicePixelRatioOf(context)
        : 1.0;
    try {
      final annotationsManager =
          manager ?? await current.annotations.createCircleAnnotationManager();
      if (!mounted || generation != mapGeneration) return;
      manager = annotationsManager;
      await annotationsManager.deleteAll();
      final places = widget.places
          .where((p) => p.latitude != null && p.longitude != null)
          .toList();
      final zoom = (await current.getCameraState()).zoom;
      final groups = widget.fullscreen
          ? clusterPlaces(places, zoom)
          : places.map((p) => MapCluster([p])).toList();
      final clustered = groups.where((g) => g.places.length > 1).toList();
      final annotations = clustered.isEmpty
          ? <CircleAnnotation?>[]
          : await annotationsManager.createMulti(
              clustered
                  .map(
                    (group) => CircleAnnotationOptions(
                      geometry: Point(
                        coordinates: Position.named(
                          lng: group.longitude,
                          lat: group.latitude,
                        ),
                      ),
                      circleRadius: group.places.length > 1 ? 14 : 6,
                      circleColor: 0xFFD6ED8A,
                      circleStrokeWidth: 2,
                      circleStrokeColor: 0xFF253314,
                    ),
                  )
                  .toList(),
            );
      if (!mounted || generation != mapGeneration) return;
      if (revision != markerRevision) return;
      byAnnotation.clear();
      for (var i = 0; i < annotations.length; i++) {
        if (annotations[i] != null) {
          byAnnotation[annotations[i]!.id] = clustered[i];
        }
      }
      taps?.cancel();
      taps = annotationsManager.tapEvents(
        onTap: (annotation) {
          final group = byAnnotation[annotation.id];
          if (group != null && mounted) openGroup(group);
        },
      );
      final labelManager =
          labels ?? await current.annotations.createPointAnnotationManager();
      if (!mounted ||
          generation != mapGeneration ||
          revision != markerRevision) {
        return;
      }
      labels = labelManager;
      await labelManager.setIconAllowOverlap(true);
      await labelManager.setIconIgnorePlacement(true);
      await labelManager.setTextAllowOverlap(true);
      await labelManager.setTextIgnorePlacement(true);
      await labelManager.deleteAll();
      final icons = await MapMarkerIcons.load(markerPixelRatio);
      final textAnnotations = groups.isEmpty
          ? <PointAnnotation?>[]
          : await labelManager.createMulti(
              groups
                  .map(
                    (g) => PointAnnotationOptions(
                      geometry: Point(
                        coordinates: Position.named(
                          lng: g.longitude,
                          lat: g.latitude,
                        ),
                      ),
                      image: g.places.length == 1
                          ? icons[g.places.first.category] ?? icons['Парк']
                          : null,
                      iconSize: .55,
                      textField: g.places.length > 1
                          ? '${g.places.length}'
                          : null,
                      textSize: 12,
                      textColor: 0xFF253314,
                    ),
                  )
                  .toList(),
            );
      if (!mounted ||
          generation != mapGeneration ||
          revision != markerRevision) {
        return;
      }
      byLabel.clear();
      for (var i = 0; i < textAnnotations.length; i++) {
        if (textAnnotations[i] != null) {
          byLabel[textAnnotations[i]!.id] = groups[i];
        }
      }
      labelTaps?.cancel();
      labelTaps = labelManager.tapEvents(
        onTap: (annotation) {
          final group = byLabel[annotation.id];
          if (mounted && group != null) openGroup(group);
        },
      );
      await userMarker();
      setState(() {});
    } catch (_) {
      if (mounted && generation == mapGeneration) setState(() => failed = true);
    }
  }

  Future<void> openGroup(MapCluster group) async {
    if (group.places.length == 1) {
      widget.onPlace(group.places.first);
      return;
    }
    try {
      final current = map;
      if (current == null) return;
      final camera = await current.getCameraState();
      if (!mounted) return;
      if (camera.zoom >= 18) {
        final selected = await showModalBottomSheet<Place>(
          context: context,
          useRootNavigator: true,
          sheetAnimationStyle: studioSheetAnimation(context),
          builder: (ctx) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height * .6,
              child: ListView(
                children: group.places
                    .map(
                      (p) => ListTile(
                        title: Text(p.name),
                        subtitle: Text(p.category),
                        onTap: () => Navigator.pop(ctx, p),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
        if (mounted && selected != null) widget.onPlace(selected);
        return;
      }
      await current.easeTo(
        CameraOptions(
          center: Point(
            coordinates: Position.named(
              lng: group.longitude,
              lat: group.latitude,
            ),
          ),
          zoom: (camera.zoom + 2).clamp(2, 19),
        ),
        MapAnimationOptions(
          duration: MediaQuery.disableAnimationsOf(context) ? 0 : 220,
        ),
      );
    } catch (_) {}
  }

  Future<void> userMarker() async {
    final current = map;
    final generation = mapGeneration;
    if (current == null) return;
    final position = widget.userPosition;
    try {
      final next =
          userManager ??
          await current.annotations.createPointAnnotationManager();
      if (!mounted || generation != mapGeneration) return;
      userManager = next;
      await next.setIconAllowOverlap(true);
      await next.setIconIgnorePlacement(true);
      await next.deleteAll();
      if (!mounted || generation != mapGeneration) return;
      if (position != null) {
        final ratio = defaultTargetPlatform == TargetPlatform.iOS
            ? MediaQuery.devicePixelRatioOf(context)
            : 1.0;
        final image = await MapMarkerIcons.userLocation(ratio);
        if (!mounted || generation != mapGeneration) return;
        await next.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position.named(
                lng: position.longitude,
                lat: position.latitude,
              ),
            ),
            image: image,
            iconSize: 1,
          ),
        );
      }
    } catch (_) {
      /* A location marker failure must not hide the place map. */
    }
  }

  @override
  void didUpdateWidget(LiveMap old) {
    super.didUpdateWidget(old);
    if (old.places != widget.places) markers();
    if (old.userPosition != widget.userPosition) userMarker();
  }

  @override
  void dispose() {
    taps?.cancel();
    labelTaps?.cancel();
    cameraDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.mapboxToken.isEmpty || failed) {
      return Align(
        alignment: Alignment.topCenter,
        child: MapUnavailableState(onOpenList: widget.onOpenList),
      );
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.fullscreen ? 0 : 24),
      child: SizedBox(
        height: widget.fullscreen ? null : 360,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              key: const ValueKey('live-map'),
              identifier:
                  loadedBrightness == Theme.of(context).brightness &&
                      (byLabel.isNotEmpty ||
                          byAnnotation.isNotEmpty ||
                          widget.places.isEmpty)
                  ? (dark ? 'map-ready-dark' : 'map-ready-light')
                  : 'map-loading',
              label: 'Карта мест рядом',
              value: loadedBrightness == Theme.of(context).brightness
                  ? 'Мест на карте: ${widget.places.length}'
                  : 'Загрузка карты',
              child: MapWidget(
                key: ValueKey(dark),
                gestureRecognizers: widget.fullscreen
                    ? {
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      }
                    : null,
                styleUri: dark ? MapboxStyles.DARK : MapboxStyles.LIGHT,
                viewport: initialViewport,
                onMapCreated: (value) {
                  map = value;
                  mapGeneration++;
                  taps?.cancel();
                  manager = null;
                  userManager = null;
                  labels = null;
                  labelTaps?.cancel();
                  cameraDebounce?.cancel();
                  widget.onCreated?.call(value);
                  byAnnotation.clear();
                  loadedBrightness = null;
                },
                onCameraChangeListener: (_) {
                  if (widget.fullscreen && loadedBrightness != null) {
                    cameraDebounce?.cancel();
                    cameraDebounce = Timer(
                      const Duration(milliseconds: 160),
                      () {
                        if (mounted) markers();
                      },
                    );
                  }
                },
                onStyleLoadedListener: (_) => markers(),
                onMapLoadedListener: (_) {
                  if (mounted) {
                    setState(
                      () => loadedBrightness = dark
                          ? Brightness.dark
                          : Brightness.light,
                    );
                    final current = map;
                    if (current != null) widget.onReady?.call(current);
                  }
                },
                onMapLoadErrorListener: (_) {
                  if (mounted) setState(() => failed = true);
                },
              ),
            ),
            if (widget.userPosition != null)
              Positioned(
                left: 12,
                top: 12,
                child: Semantics(
                  key: ValueKey('user-location-visible'),
                  label: 'Ваше положение отмечено синим',
                  child: SizedBox.shrink(),
                ),
              ),
            if (widget.onExpand != null)
              Positioned(
                right: 12,
                top: 12,
                child: IconButton.filledTonal(
                  tooltip: 'На весь экран',
                  onPressed: () async {
                    CameraState? camera;
                    try {
                      camera = await map?.getCameraState();
                    } catch (_) {}
                    if (mounted) widget.onExpand?.call(camera);
                  },
                  icon: const Icon(Icons.open_in_full),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MapUnavailableState extends StatelessWidget {
  const MapUnavailableState({this.onOpenList, this.compact = false, super.key});
  final bool compact;
  final VoidCallback? onOpenList;

  @override
  Widget build(BuildContext context) => compact
      ? Text(
          'Карта пока недоступна',
          style: Theme.of(context).textTheme.bodySmall,
        )
      : StudioCard(
          padding: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Карта пока недоступна',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Места можно посмотреть списком.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (onOpenList != null) ...[
                const SizedBox(height: 12),
                Tooltip(
                  message: 'Список мест',
                  child: OutlinedButton.icon(
                    onPressed: onOpenList,
                    icon: const Icon(Icons.view_list_outlined, size: 18),
                    label: const Text('Открыть список мест'),
                  ),
                ),
              ],
            ],
          ),
        );
}
