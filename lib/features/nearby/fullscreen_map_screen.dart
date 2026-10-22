import '../../l10n/localization.dart';
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

/// UI-only bridge for controls placed above the embedded map.
/// Camera state is transferred in memory through the existing expand path.
class EmbeddedMapActions {
  Object? _owner;
  Future<void> Function()? _list, _expand;
  Future<void> openList() => _list?.call() ?? Future<void>.value();
  Future<void> expand() => _expand?.call() ?? Future<void>.value();
  void _clear(Object owner) {
    if (!identical(owner, _owner)) return;
    _owner = null;
    _list = null;
    _expand = null;
  }
}

class FullscreenMapScreen extends ConsumerStatefulWidget {
  const FullscreenMapScreen({
    required this.args,
    this.embedded = false,
    this.showEmbeddedControls = true,
    this.embeddedHeight = 280,
    this.actions,
    this.filtersActive = false,
    this.onCityPressed,
    this.showCitySelector = true,
    this.catalogStatus,
    this.onThemePressed,
    this.onList,
    this.onExpand,
    super.key,
  });
  final FullscreenMapArgs args;
  final bool embedded, filtersActive, showCitySelector, showEmbeddedControls;
  final double embeddedHeight;
  final EmbeddedMapActions? actions;
  final Widget? catalogStatus;
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
  late final LocationService locationService;
  bool locating = false, enabled = false;
  bool foreground = true, branchVisible = true, openingPage = false;
  bool get visible => foreground && branchVisible && !openingPage;
  int request = 0;
  bool get followsUser =>
      widget.embedded &&
      !ref.read(prototypeProvider).manualCity &&
      widget.args.focusPlace == null &&
      widget.args.camera == null;

  bool expanding = false;
  void bindActions() {
    final actions = widget.actions;
    if (actions == null) return;
    actions._owner = this;
    actions._expand = expand;
    actions._list = () async {
      if (mounted && widget.onList != null) await openPage(widget.onList!);
    };
  }

  @override
  void initState() {
    super.initState();
    bindActions();
    WidgetsBinding.instance.addObserver(this);
    locationService = ref.read(locationServiceProvider);
    position = widget.args.initialPosition ?? locationService.lastPosition;
    locationService.addListener(sharedPositionChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => refreshAllowedLocation(),
    );
  }

  void sharedPositionChanged() {
    if (!mounted) return;
    final next = locationService.lastPosition;
    if (!visible && next != null) return;
    if (position != next) setState(() => position = next);
    if (next == null) {
      enabled = false;
      if (!locating) {
        pauseLocation();
      } else {
        // Let the current request report its permission/service error rather
        // than invalidating its catch/finally callbacks through this listener.
        subscription?.cancel();
        subscription = null;
      }
    } else {
      // Permission may have been granted by Nearby while this map was already
      // mounted. Resume its foreground subscription without waiting for a
      // successful city lookup or a navigation/lifecycle change.
      if (!enabled && !locating && visible) {
        unawaited(refreshAllowedLocation());
      }
    }
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
      await locate(recenter: followsUser, silent: true);
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
      } else if (visible && !locating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && visible) {
            refreshAllowedLocation();
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(FullscreenMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actions != widget.actions) {
      oldWidget.actions?._clear(this);
      bindActions();
    }
    if (oldWidget.args.city != widget.args.city) {
      controller = null; // The city-keyed native map is recreated below.
    }
    if (oldWidget.args.initialPosition != widget.args.initialPosition &&
        widget.args.initialPosition != null) {
      position = widget.args.initialPosition;
      if (!enabled && visible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && visible) {
            refreshAllowedLocation();
          }
        });
      }
    }
  }

  Future<void> centerCity() async {
    if (widget.args.focusPlace != null ||
        widget.args.initialPosition != null ||
        widget.args.camera != null ||
        (followsUser && position != null) ||
        widget.args.city == 'Минск') {
      return;
    }
    final city = widget.args.city;
    try {
      final center = await ref.read(locationServiceProvider).cityCenter(city);
      if (mounted &&
          widget.args.city == city &&
          !(followsUser && position != null)) {
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
          "Не удалось найти город на карте. Можно переместить карту вручную."
              .tr(context),
        );
      }
    }
  }

  Future<void> openPage(Future<void> Function() action) async {
    if (openingPage || !mounted) return;
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
    if (openingPage || expanding || !mounted) return;
    expanding = true;
    final city = widget.args.city;
    try {
      CameraState? camera;
      try {
        camera = await controller?.getCameraState();
      } catch (_) {}
      if (mounted && widget.args.city == city && widget.onExpand != null) {
        await openPage(() => widget.onExpand!(camera));
      }
    } finally {
      expanding = false;
    }
  }

  @override
  void dispose() {
    widget.actions?._clear(this);
    request++;
    WidgetsBinding.instance.removeObserver(this);
    locationService.removeListener(sharedPositionChanged);
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
      if (recenter && (!widget.embedded || followsUser)) {
        await moveToUser(current, animated: !silent);
      }
      if (!mounted || !visible || generation != request) return;
      listenToPosition(service, generation);
    } on LocationIssue catch (e) {
      if (mounted && generation == request) {
        enabled = false;
        setState(() => position = null);
        if (!silent) notice(context, e.message);
      }
    } catch (_) {
      // A first GPS fix may exceed the one-shot timeout (for example indoors).
      // Keep listening in the foreground rather than giving up until restart.
      if (!mounted || !visible || generation != request) return;
      final service = ref.read(locationServiceProvider);
      var allowed = false;
      try {
        allowed = await service.hasPermission();
      } catch (_) {}
      if (mounted && visible && generation == request) {
        enabled = allowed;
        if (allowed) {
          listenToPosition(service, generation, recenterFirst: recenter);
        } else {
          setState(() => position = null);
        }
        if (!silent) {
          notice(
            context,
            allowed
                ? "Ожидаем местоположение. Картой уже можно пользоваться.".tr(
                    context,
                  )
                : "Не удалось определить местоположение. Попробуйте ещё раз."
                      .tr(context),
          );
        }
      }
    } finally {
      if (mounted && generation == request) setState(() => locating = false);
    }
  }

  void listenToPosition(
    LocationService service,
    int generation, {
    bool recenterFirst = false,
  }) {
    var waitingForFirst = recenterFirst;
    subscription = service.positions().listen(
      (next) {
        if (!mounted || !visible || generation != request) return;
        service.lastPosition = next;
        setState(() => position = next);
        if (waitingForFirst) {
          waitingForFirst = false;
          // A manual city selection made while waiting takes priority.
          if (!widget.embedded || followsUser) {
            unawaited(moveToUser(next, animated: false));
          }
        }
      },
      onError: (_) {
        subscription?.cancel();
        subscription = null;
        if (mounted && generation == request) {
          enabled = false;
          service.lastPosition = null;
          setState(() => position = null);
          notice(
            context,
            "Местоположение недоступно. Картой можно пользоваться без него.".tr(
              context,
            ),
          );
        }
      },
    );
  }

  Future<void> moveToUser(geo.Position current, {bool animated = true}) async {
    try {
      final camera = CameraOptions(
        center: Point(
          coordinates: Position(current.longitude, current.latitude),
        ),
        zoom: 15,
      );
      if (animated) {
        await move(camera);
      } else {
        // A first foreground GPS fix establishes the viewport immediately.
        // Do not compete with native map initialization through an animation.
        await controller?.setCamera(camera);
      }
    } catch (_) {
      // A native camera transition failure must not discard a valid GPS fix.
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
      if (mounted) notice(context, "Не удалось изменить масштаб.".tr(context));
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
            onCreated: (_) => controller = null,
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
              } else if (followsUser && position != null) {
                // GPS can finish before the native map exists. Apply its
                // camera again when ready instead of falling back to the city.
                await map.setCamera(
                  CameraOptions(
                    center: Point(
                      coordinates: Position(
                        position!.longitude,
                        position!.latitude,
                      ),
                    ),
                    zoom: 15,
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
                      tooltip: "Закрыть карту".tr(context),
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
                                ? "Обзор карты".tr(context)
                                : "Места · {p0}".tr(
                                    context,
                                    arguments: {'p0': widget.args.city},
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    if (widget.onList != null && !unavailable)
                      IconButton.filledTonal(
                        tooltip: "Список мест".tr(context),
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
                        tooltip: "На весь экран".tr(context),
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
                        ? "Светлая тема".tr(context)
                        : "Тёмная тема".tr(context),
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
                  tooltip: "Приблизить".tr(context),
                  onPressed: () => zoom(1),
                  icon: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                IconButton.filledTonal(
                  tooltip: "Отдалить".tr(context),
                  onPressed: () => zoom(-1),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(height: 16),
                IconButton.filled(
                  tooltip: "Моё местоположение".tr(context),
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
    final preview = unavailable
        ? const MapUnavailableState(compact: true)
        : SizedBox(
            height: widget.embeddedHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: map,
            ),
          );
    if (!widget.showEmbeddedControls) return preview;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Места рядом'.tr(context),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onList != null)
                        TextButton(
                          key: const Key('nearby-places-list'),
                          onPressed: () => openPage(widget.onList!),
                          child: Text('Список'.tr(context)),
                        ),
                      if (widget.onExpand != null && !unavailable)
                        IconButton(
                          tooltip: 'На весь экран'.tr(context),
                          onPressed: expand,
                          icon: const Icon(Icons.open_in_full, size: 20),
                        ),
                    ],
                  ),
                ],
              ),
              if (widget.showCitySelector)
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    key: const Key('choose-city'),
                    onPressed: widget.onCityPressed,
                    iconAlignment: IconAlignment.end,
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
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
                    label: Text(widget.args.city, softWrap: true),
                  ),
                ),
              if (widget.catalogStatus != null) widget.catalogStatus!,
            ],
          ),
        ),
        preview,
      ],
    );
  }
}
