/// Catalog tags are hints. Only a separately moderated evidence record can
/// establish community/venue confirmation; no category grants permission.
enum PetAccessConfirmation { unknown, community, venue }

enum PetAccessPolicy { unknown, allowed, onLeash, forbidden }

class PetAccessEvidence {
  const PetAccessEvidence({
    required this.confirmation,
    required this.policy,
    required this.observedAt,
    required this.verifiedAt,
    required this.basis,
    this.conditions = '',
    this.referenceUrl,
  });
  final PetAccessConfirmation confirmation;
  final PetAccessPolicy policy;
  final DateTime observedAt, verifiedAt;
  final String conditions, basis;
  final String? referenceUrl;

  static PetAccessEvidence? fromJson(Map<String, dynamic> value) {
    final confirmation = switch (value['confirmation']) {
      'community' => PetAccessConfirmation.community,
      'venue' => PetAccessConfirmation.venue,
      _ => PetAccessConfirmation.unknown,
    };
    final policy = switch (value['policy']) {
      'allowed' => PetAccessPolicy.allowed,
      'on_leash' => PetAccessPolicy.onLeash,
      'forbidden' => PetAccessPolicy.forbidden,
      _ => PetAccessPolicy.unknown,
    };
    final observed = DateTime.tryParse('${value['observed_at']}');
    final verified = DateTime.tryParse('${value['verified_at']}');
    final basis = (value['basis'] as String?)?.trim() ?? '';
    final reference = value['reference_url'] as String?;
    final url = Uri.tryParse(reference ?? '');
    if (confirmation == PetAccessConfirmation.unknown ||
        policy == PetAccessPolicy.unknown ||
        observed == null ||
        verified == null ||
        observed.isAfter(verified) ||
        verified.isAfter(DateTime.now().toUtc()) ||
        basis.isEmpty ||
        confirmation == PetAccessConfirmation.venue &&
            (url?.scheme != 'https' || url!.host.isEmpty)) {
      return null;
    }
    return PetAccessEvidence(
      confirmation: confirmation,
      policy: policy,
      observedAt: observed,
      verifiedAt: verified,
      basis: basis,
      conditions: (value['conditions'] as String?)?.trim() ?? '',
      referenceUrl: reference,
    );
  }
}

PetAccessPolicy catalogPetPolicy(String legacy) {
  if (!legacy.contains('OSM')) return PetAccessPolicy.unknown;
  if (legacy.startsWith('Собаки разрешены')) return PetAccessPolicy.allowed;
  if (legacy.startsWith('Собаки на поводке')) return PetAccessPolicy.onLeash;
  if (legacy.startsWith('Собаки запрещены')) return PetAccessPolicy.forbidden;
  return PetAccessPolicy.unknown;
}

String petAccessLabel(PetAccessEvidence? evidence) => evidence == null
    ? 'Допуск не подтверждён'
    : switch (evidence.confirmation) {
        PetAccessConfirmation.community => 'Подтверждено сообществом',
        PetAccessConfirmation.venue => 'Подтверждено заведением',
        PetAccessConfirmation.unknown => 'Допуск не подтверждён',
      };

String petPolicyLabel(PetAccessPolicy policy) => switch (policy) {
  PetAccessPolicy.allowed => 'С собаками можно',
  PetAccessPolicy.onLeash => 'Собаки только на поводке',
  PetAccessPolicy.forbidden => 'С собаками нельзя',
  PetAccessPolicy.unknown => 'Правила для питомцев пока неизвестны',
};
