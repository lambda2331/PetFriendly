import 'package:flutter/material.dart';
import '../../core/time/display_time.dart';
import 'pet_access.dart';

class PetAccessStatus extends StatelessWidget {
  const PetAccessStatus({
    this.evidence,
    this.includePolicy = true,
    this.loading = false,
    this.unavailable = false,
    super.key,
  });
  final PetAccessEvidence? evidence;
  final bool includePolicy;
  final bool loading, unavailable;
  @override
  Widget build(BuildContext context) {
    final known = evidence != null;
    final label = known && includePolicy
        ? '${petPolicyLabel(evidence!.policy)} · ${petAccessLabel(evidence)}'
        : unavailable
        ? 'Подтверждения сейчас недоступны'
        : loading
        ? 'Проверяем подтверждения…'
        : petAccessLabel(evidence);
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              known ? Icons.fact_check_outlined : Icons.help_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class PetAccessRules extends StatelessWidget {
  const PetAccessRules({
    required this.catalogHint,
    this.evidence,
    this.loading = false,
    this.unavailable = false,
    super.key,
  });
  final String catalogHint;
  final PetAccessEvidence? evidence;
  final bool loading, unavailable;
  @override
  Widget build(BuildContext context) {
    final info = evidence;
    final catalogPolicy = catalogPetPolicy(catalogHint);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('С питомцем', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          PetAccessStatus(
            evidence: info,
            includePolicy: false,
            loading: loading,
            unavailable: unavailable,
          ),
          const SizedBox(height: 10),
          if (info != null) ...[
            Text(petPolicyLabel(info.policy)),
            const SizedBox(height: 6),
            Text(
              'Подтверждение от ${readableDate(info.observedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (info.conditions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Условия: ${info.conditions}'),
            ],
            const SizedBox(height: 10),
            Text(info.basis, style: Theme.of(context).textTheme.bodySmall),
            if (info.referenceUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              SelectableText(
                'Публичное подтверждение: ${info.referenceUrl}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Правила могут измениться. Уточните их перед визитом.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            Text('Уточните правила у администрации места перед визитом.'),
            if (catalogPolicy != PetAccessPolicy.unknown) ...[
              const SizedBox(height: 10),
              Text(
                'Отметка каталога: ${petPolicyLabel(catalogPolicy).toLowerCase()}. Это не подтверждение сообщества или заведения.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else if (catalogHint != 'Допуск питомцев не уточнён' &&
                catalogHint.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'В каталоге есть неподтверждённое описание правил. Подтверждающих сведений пока нет.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
