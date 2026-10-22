import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/prototype_store.dart';
import '../../core/ui/components.dart';
import 'location_service.dart';
import 'fullscreen_map_screen.dart';
import 'city_sheet.dart';
import 'city_catalog.dart';
import 'place_filters.dart';
import 'nearby_event_banner.dart';
import 'nearby_studio_layout.dart';

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});
  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  final mapActions = EmbeddedMapActions();
  bool locating = false;
  int locationRequest = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prefs = ref.read(preferencesProvider);
      if (!ref.read(prototypeProvider).manualCity &&
          prefs.read('locationPrompted') != 'yes') {
        prefs.write('locationPrompted', 'yes');
        locate();
      }
    });
  }

  Future<void> locate() async {
    final request = ++locationRequest;
    setState(() => locating = true);
    try {
      final city = await ref.read(locationServiceProvider).nearbyCity();
      if (!mounted || request != locationRequest) return;
      await ref.read(prototypeProvider.notifier).setCity(city, manual: false);
    } on LocationIssue catch (e) {
      if (mounted) {
        notice(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        notice(
          context,
          "Местоположение недоступно. Выберите город вручную.".tr(context),
        );
      }
    } finally {
      if (mounted) {
        setState(() => locating = false);
      }
    }
  }

  void chooseCity() {
    showStudioSelectionSheet<void>(
      context: context,
      builder: (ctx) => CitySheet(
        city: ref.read(prototypeProvider).city,
        onSelected: (city) {
          locationRequest++;
          ref.read(prototypeProvider.notifier).setCity(city);
          Navigator.pop(ctx);
        },
        onLocate: () {
          Navigator.pop(ctx);
          locate();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prototypeProvider);
    return NearbyStudioLayout(
      greeting: 'Хороший день для прогулки.'.tr(context),
      subtitle: 'И новой компании для вас двоих.'.tr(context),
      meetups: NearbyEventBanner(city: state.city),
      placesTitle: 'Места рядом'.tr(context),
      city: state.city.split(',').first.trim(),
      cityDetails: state.city.contains(',')
          ? state.city.split(',').skip(1).join(',').trim()
          : '',
      listLabel: 'Список мест'.tr(context),
      mapLabel: stringsFor(context.languageCode).nearbyMapView,
      onCity: chooseCity,
      onList: () => mapActions.openList(),
      onMap: () => mapActions.expand(),
      catalogStatus: const CityCatalogStatus(inset: false, linearLoading: true),
      map: FullscreenMapScreen(
        embedded: true,
        showEmbeddedControls: false,
        embeddedHeight: 180,
        actions: mapActions,
        onList: () {
          ref.invalidate(filteredPlacesProvider);
          return context.push<void>('/places');
        },
        onExpand: (camera) => context.push<void>(
          '/map',
          extra: FullscreenMapArgs(
            places: ref.read(filteredPlacesProvider),
            city: state.city,
            camera: camera,
            initialPosition: state.manualCity
                ? null
                : ref.read(locationServiceProvider).lastPosition,
          ),
        ),
        args: FullscreenMapArgs(
          places: ref.watch(filteredPlacesProvider),
          city: state.city,
          initialPosition: state.manualCity
              ? null
              : ref.read(locationServiceProvider).lastPosition,
        ),
      ),
    );
  }
}
