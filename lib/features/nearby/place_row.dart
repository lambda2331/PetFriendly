import '../../core/display_numbers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/components.dart';
import 'place_repository.dart';
import 'place_details_sheet.dart';
import 'place_filters.dart';
import 'location_service.dart';
import 'place_rating.dart';
import 'pet_access_repository.dart';
import 'pet_access_widgets.dart';

class PlaceRow extends ConsumerWidget {
  const PlaceRow({required this.place, super.key});
  final Place place;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = ref.watch(placeRatingProvider(place));
    final access = ref.watch(petAccessByCityProvider(place.city));
    final evidence = place.pending
        ? null
        : access.hasValue
        ? (access.value?[place.id])
        : place.accessEvidence;
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showPlace(context, place),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                InitialAvatar('', accent: place.id == 'park', icon: place.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (place.pending)
                        Text(
                          'На проверке · видно только вам',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 4),
                      MetadataLine(
                        items: [
                          distanceLabel(
                                placeDistance(
                                  place,
                                  ref
                                      .read(locationServiceProvider)
                                      .lastPosition,
                                ),
                              ) ??
                              place.distance,
                          place.category,
                        ],
                      ),
                      const SizedBox(height: 6),
                      PetAccessStatus(
                        evidence: evidence,
                        loading:
                            !place.pending &&
                            evidence == null &&
                            access.isLoading,
                        unavailable:
                            !place.pending &&
                            evidence == null &&
                            access.hasError,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (rating != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(displayDecimal(rating.average)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, size: 16),
                    ],
                  ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

String? distanceLabel(double? meters) => meters == null
    ? null
    : meters < 1000
    ? '~${(meters / 10).round() * 10} м по прямой'
    : '~${displayDecimal(meters / 1000)} км по прямой';
