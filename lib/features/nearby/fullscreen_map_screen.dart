import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../core/backend/backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import '../../core/ui/components.dart';
import '../../core/storage/prototype_store.dart';
import 'live_map.dart';
import 'location_service.dart';
import 'place_repository.dart';
import 'place_details_sheet.dart';

class FullscreenMapArgs {
  const FullscreenMapArgs({
    required this.places,
    required this.city,
    this.camera,
    this.initialPosition,
    this.focusPlace,
  });
  final List<Place> places;
  final String city;
  final CameraState? camera;
  final Place? focusPlace;
  final geo.Position? initialPosition;
}

class FullscreenMapScreen extends ConsumerStatefulWidget {
  const FullscreenMapScreen({
    required this.args,
    this.embedded = false,
    this.filtersActive = false,
    this.onCityPressed,
    this.onThemePressed,
    this.onList,
    this.onExpand,
    super.key,
  });
  final FullscreenMapArgs args;
  final bool embedded, filtersActive;
  final VoidCallback? onCityPressed, onThemePressed;
  final Future<void> Function()? onList;
  final Future<void> Function(CameraState?)? onExpand;
  @override
  ConsumerState<FullscreenMapScreen> createState() => _FullscreenMapState();
}

class _FullscreenMapState extends ConsumerState<FullscreenMapScreen>
    with WidgetsBindingObserver {
  MapboxMap? controller;
  StreamSubscription<geo.Position>? subscription;
  geo.Position? position;
  bool locating = false, enabled = false;
  bool foreground = true, branchVisible = true, openingPage = false;
  bool get visible => foreground && branchVisible && !openingPage;
  int request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    position =
        widget.args.initialPosition ??
        ref.read(locationServiceProvider).lastPosition;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => refreshAllowedLocation(),
    );
  }

  Future<void> refreshAllowedLocation() async {
    try {
      final allowed = await ref.read(locationServiceProvider).hasPermission();
      if (!mounted || !visible) return;
      if (!allowed) {
        pauseLocation();
        enabled = false;
        ref.read(locationServiceProvider).lastPosition = null;
        setState(() => position = null);
        return;
      }
      await locate(
        recenter:
            widget.embedded &&
            !ref.read(prototypeProvider).manualCity &&
            widget.args.focusPlace == null &&
            widget.args.camera == null,
        silent: true,
      );
    } catch (_) {
      /* No automatic permission prompt. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      foreground = false;
      pauseLocation();
    } else if (state == AppLifecycleState.inactive &&
        Theme.of(context).platform == TargetPlatform.iOS) {
      subscription?.cancel();
      subscription = null;
    } else if (state == AppLifecycleState.resumed) {
      foreground = true;
      if (visible && !locating) refreshAllowedLocation();
    }
  }

  void pauseLocation() {
    request++;
    subscription?.cancel();
    subscription = null;
    if (mounted) setState(() => locating = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (active != branchVisible) {
      branchVisible = active;
      if (!active) {
        pauseLocation();
      } else if (visible && enabled && !locating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && visible) {
            locate(
              recenter:
                  widget.embedded && !ref.read(prototypeProvider).manualCity,
            );
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(FullscreenMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.args.city != widget.args.city) centerCity();
    if (oldWidget.args.initialPosition != widget.args.initialPosition &&
        widget.args.initialPosition != null) {
      position = widget.args.initialPosition;
      if (!enabled && visible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && visible) {
            locate(
              recenter:
                  widget.embedded && !ref.read(prototypeProvider).manualCity,
            );
          }
        });
      }
    }
  }

  Future<void> centerCity() async {
    if (widget.args.focusPlace != null ||
        widget.args.initialPosition != null ||
        widget.args.camera != null ||
        widget.args.city == 'Минск') {
      return;
    }
    final city = widget.args.city;
    try {
      final center = await ref.read(locationServiceProvider).cityCenter(city);
      if (mounted && widget.args.city == city) {
        await move(
          CameraOptions(
            center: Point(
              coordinates: Position.named(
                lng: center.longitude,
                lat: center.latitude,
              ),
            ),
            zoom: 12,
          ),
        );
      }
    } catch (_) {
      if (mounted && widget.args.city == city) {
        notice(
          context,
          'Не удалось найти город на карте. Можно переместить карту вручную.',
        );
      }
    }
  }

  Future<void> openPage(Future<void> Function() action) async {
    openingPage = true;
    pauseLocation();
    try {
      await action();
    } finally {
      if (mounted) {
        openingPage = false;
        if (visible && enabled) locate(recenter: false);
      }
    }
  }

  Future<void> expand() async {
    CameraState? camera;
    try {
      camera = await controller?.getCameraState();
    } catch (_) {}
    if (mounted && widget.onExpand != null) {
      await openPage(() => widget.onExpand!(camera));
    }
  }

  @override
  void dispose() {
    request++;
    WidgetsBinding.instance.removeObserver(this);
    subscription?.cancel();
    super.dispose();
  }

  Future<void> locate({bool recenter = true, bool silent = false}) async {
    final generation = ++request;
    setState(() => locating = true);
    await subscription?.cancel();
    subscription = null;
    try {
      final service = ref.read(locationServiceProvider);
      final current = await service.currentPosition();
      if (!mounted || !visible || generation != request) return;
      enabled = true;
      setState(() => position = current);
      if (recenter) {
        await move(
          CameraOptions(
            center: Point(
              coordinates: Position.named(
                lng: current.longitude,
                lat: current.latitude,
              ),
            ),
            zoom: 15,
          ),
        );
      }
      await subscription?.cancel();
      if (!mounted || !visible || generation != request) return;
      subscription = service.positions().listen(
        (next) {
          if (mounted && visible && generation == request) {
            service.lastPosition = next;
            setState(() => position = next);
          }
        },
        onError: (_) {
          subscription?.cancel();
          subscription = null;
          if (mounted) {
            enabled = false;
            setState(() => position = null);
            notice(
              context,
              'Местоположение недоступно. Картой можно пользоваться без него.',
            );
          }
        },
      );
    } on LocationIssue catch (e) {
      if (mounted && generation == request) {
        enabled = false;
        setState(() => position = null);
        if (!silent) notice(context, e.message);
      }
    } catch (_) {
      if (mounted && generation == request) {
        enabled = false;
        setState(() => position = null);
        if (!silent) {
          notice(
            context,
            'Не удалось определить местоположение. Попробуйте ещё раз.',
          );
        }
      }
    } finally {
      if (mounted && generation == request) setState(() => locating = false);
    }
  }

  Future<void> move(CameraOptions camera) async {
    final current = controller;
    if (current == null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      await current.setCamera(camera);
    } else {
      await current.easeTo(camera, MapAnimationOptions(duration: 220));
    }
  }

  Future<void> zoom(double step) async {
    try {
      final camera = await controller?.getCameraState();
      if (camera != null && mounted) {
        await move(CameraOptions(zoom: (camera.zoom + step).clamp(2, 19)));
      }
    } catch (_) {
      if (mounted) notice(context, 'Не удалось изменить масштаб.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unavailable = AppConfig.mapboxToken.isEmpty;
    final publicCenter =
        widget.args.initialPosition == null &&
            widget.args.camera == null &&
            widget.args.focusPlace == null
        ? ref.watch(cityCenterProvider(widget.args.city)).value
        : null;
    final map = Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: LiveMap(
            key: ValueKey(widget.args.city),
            places: widget.args.places,
            fullscreen: true,
            initialCamera: widget.args.camera,
            cityCenter: publicCenter == null
                ? null
                : Point(
                    coordinates: Position(
                      publicCenter.longitude,
                      publicCenter.latitude,
                    ),
                  ),
            position: widget.args.initialPosition,
            focusPlace: widget.args.focusPlace,
            userPosition: position,
            onReady: (map) async {
              controller = map;
              if (widget.args.focusPlace != null) {
                final place = widget.args.focusPlace!;
                await map.setCamera(
                  CameraOptions(
                    center: Point(
                      coordinates: Position(place.longitude!, place.latitude!),
                    ),
                    zoom: 16,
                  ),
                );
              } else {
                centerCity();
              }
              try {
                await map.compass.updateSettings(
                  CompassSettings(enabled: !widget.embedded),
                );
                await map.scaleBar.updateSettings(
                  ScaleBarSettings(
                    position: OrnamentPosition.BOTTOM_LEFT,
                    marginLeft: 16,
                    marginBottom: widget.embedded ? 32 : 72,
                    isMetricUnits: true,
                  ),
                );
              } catch (_) {}
            },
            onOpenList: () => context.push('/places'),
            onPlace: (place) => showPlace(
              context,
              place,
              onShowOnMap: widget.embedded
                  ? null
                  : () => move(
                      CameraOptions(
                        center: Point(
                          coordinates: Position(
                            place.longitude!,
                            place.latitude!,
                          ),
                        ),
                        zoom: 16,
                      ),
                    ),
            ),
          ),
        ),
        if (!widget.embedded)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Закрыть карту',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          label: Text(
                            widget.args.places.isEmpty
                                ? 'Обзор карты'
                                : 'Места · ${widget.args.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    if (widget.onList != null && !unavailable)
                      IconButton.filledTonal(
                        tooltip: 'Список мест',
                        onPressed: () => openPage(widget.onList!),
                        icon: Badge(
                          isLabelVisible: widget.filtersActive,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: const Icon(Icons.view_list_outlined),
                        ),
                      ),
                    if (widget.onExpand != null) ...[
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'На весь экран',
                        onPressed: expand,
                        icon: const Icon(Icons.open_in_full),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (!widget.embedded)
          Positioned(
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onThemePressed != null) ...[
                  IconButton.filledTonal(
                    tooltip: Theme.of(context).brightness == Brightness.dark
                        ? 'Светлая тема'
                        : 'Тёмная тема',
                    onPressed: widget.onThemePressed,
                    icon: Icon(
                      Theme.of(context).brightness == Brightness.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                IconButton.filledTonal(
                  tooltip: 'Приблизить',
                  onPressed: () => zoom(1),
                  icon: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                IconButton.filledTonal(
                  tooltip: 'Отдалить',
                  onPressed: () => zoom(-1),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(height: 16),
                IconButton.filled(
                  tooltip: 'Моё местоположение',
                  onPressed: locating ? null : () => locate(),
                  icon: locating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
      ],
    );
    if (!widget.embedded) return Scaffold(body: map);
    return Column(
      mainAxisSize: unavailable ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
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
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Golos Text',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: Text(
                      widget.args.city,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onExpand != null && !unavailable)
                    IconButton(
                      tooltip: 'На весь экран',
                      onPressed: expand,
                      icon: const Icon(Icons.open_in_full, size: 20),
                    ),
                ],
              ),
              if (widget.onList != null) ...[
                const Divider(height: 1),
                Semantics(
                  button: true,
                  child: Tooltip(
                    excludeFromSemantics: true,
                    message: 'Список мест',
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () => openPage(widget.onList!),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Badge(
                                  isLabelVisible: widget.filtersActive,
                                  child: const Icon(
                                    Icons.view_list_outlined,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Места списком',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
            ],
          ),
        ),
        if (unavailable)
          const MapUnavailableState(compact: true)
        else
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: map,
            ),
          ),
      ],
    );
  }
}
