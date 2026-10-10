import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backend/backend.dart';
import 'pet_access.dart';
import 'city_catalog.dart';
import 'place_pages.dart';

/// Lists share a single public city query instead of fetching evidence per row.
final petAccessByCityProvider = FutureProvider.autoDispose
    .family<Map<String, PetAccessEvidence>, String>((ref, city) async {
      ref.watch(authStateProvider.select((state) => state.value?.id));
      final client = ref.watch(backendProvider);
      if (client == null) return {};
      final response = await client.rpc(
        'city_place_pet_access',
        params: {'city_in': city},
      );
      final rows = (response as List).map(
        (row) => Map<String, dynamic>.from(row),
      );
      final result = <String, PetAccessEvidence>{};
      for (final row in rows) {
        final evidence = PetAccessEvidence.fromJson(row);
        if (evidence != null) result[row['place_id'] as String] = evidence;
      }
      return result;
    }, retry: (_, _) => null);

final petAccessEvidenceProvider = FutureProvider.autoDispose
    .family<PetAccessEvidence?, String>((ref, placeId) async {
      ref.watch(authStateProvider.select((state) => state.value?.id));
      final client = ref.watch(backendProvider);
      if (client == null) return null;
      final row = await client
          .from('place_pet_access_evidence')
          .select()
          .eq('place_id', placeId)
          .maybeSingle();
      return row == null ? null : PetAccessEvidence.fromJson(row);
    }, retry: (_, _) => null);

final petAccessModeratorProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  ref.watch(authStateProvider.select((state) => state.value?.id));
  final client = ref.watch(backendProvider);
  if (client == null) return false;
  return await client.rpc('moderation_available') == true;
}, retry: (_, _) => null);

class PetAccessPublication {
  const PetAccessPublication({
    required this.confirmation,
    required this.policy,
    required this.observedAt,
    required this.basis,
    this.conditions = '',
    this.referenceUrl = '',
  });
  final String confirmation, policy, basis, conditions, referenceUrl;
  final DateTime observedAt;
  Map<String, dynamic> parameters(String placeId) => {
    'place_in': placeId,
    'confirmation_in': confirmation,
    'policy_in': policy,
    'observed_in': observedAt.toUtc().toIso8601String(),
    'basis_in': basis.trim(),
    'conditions_in': conditions.trim(),
    'reference_in': referenceUrl.trim(),
  };
}

final petAccessPublisherProvider = Provider(
  (ref) => (String placeId, PetAccessPublication evidence) async {
    final client = ref.read(backendProvider);
    if (client == null) throw StateError('Publication requires a backend');
    await client.rpc(
      'publish_place_pet_access',
      params: evidence.parameters(placeId),
    );
    ref.invalidate(petAccessEvidenceProvider(placeId));
    ref.invalidate(petAccessByCityProvider);
    ref.invalidate(cityCatalogProvider);
    ref.invalidate(placePagesProvider);
  },
);

final petAccessWithdrawalProvider = Provider(
  (ref) => (String placeId) async {
    final client = ref.read(backendProvider);
    if (client == null) throw StateError('Withdrawal requires a backend');
    await client.rpc(
      'withdraw_place_pet_access',
      params: {'place_in': placeId},
    );
    ref.invalidate(petAccessEvidenceProvider(placeId));
    ref.invalidate(petAccessByCityProvider);
    ref.invalidate(cityCatalogProvider);
    ref.invalidate(placePagesProvider);
  },
);
