import 'package:flutter/material.dart';
import '../../core/backend/backend.dart';
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

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});
  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
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
        notice(context, 'Местоположение недоступно. Выберите город вручную.');
      }
    } finally {
      if (mounted) {
        setState(() => locating = false);
      }
    }
  }

  void chooseCity() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      sheetAnimationStyle: studioSheetAnimation(context),
      isScrollControlled: true,
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
    final compact =
        MediaQuery.sizeOf(context).height < 780 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final intro = Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            const ScreenIntro(
              'Хороший день\nдля прогулки.',
              subtitle: 'И новой компании для вас двоих.',
            ),
            const SizedBox(height: 12),
          ] else ...[
            Semantics(
              header: true,
              child: Text(
                'Хороший день для прогулки.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 12),
          ],
          NearbyEventBanner(city: state.city),
        ],
      ),
    );
    final map = Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: FullscreenMapScreen(
        embedded: true,
        filtersActive: ref.watch(placeFiltersProvider).active,
        args: FullscreenMapArgs(
          places: ref.watch(filteredPlacesProvider),
          city: state.city,
          initialPosition: state.manualCity
              ? null
              : ref.read(locationServiceProvider).lastPosition,
        ),
        onCityPressed: chooseCity,
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
      ),
    );
    final mapConfigured = AppConfig.mapboxToken.isNotEmpty;
    if (compact || !mapConfigured) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: Column(
            children: [
              intro,
              const CityCatalogStatus(),
              if (mapConfigured)
                SizedBox(
                  height: constraints.maxHeight * .55 < 320
                      ? 320
                      : constraints.maxHeight * .55,
                  child: map,
                )
              else
                map,
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        intro,
        const CityCatalogStatus(),
        Expanded(child: map),
      ],
    );
  }
}
