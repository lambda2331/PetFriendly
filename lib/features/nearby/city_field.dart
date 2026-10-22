import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/components.dart';
import '../../l10n/localization.dart';
import 'city_sheet.dart';
import 'location_service.dart';

/// All city selectors return the same canonical, country-qualified key.
/// Public city data and the user's exact location remain separate.
class CityField extends ConsumerWidget {
  const CityField({
    required this.controller,
    required this.onChanged,
    this.enabled = true,
    this.showLabel = true,
    this.fieldKey,
    super.key,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled, showLabel;
  final Key? fieldKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
    label: showLabel ? null : 'Город'.tr(context),
    child: TextFormField(
      key: fieldKey,
      controller: controller,
      readOnly: true,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: showLabel ? 'Город'.tr(context) : null,
        suffixIcon: const Icon(Icons.expand_more),
      ),
      validator: (value) => value?.trim().isNotEmpty == true
          ? null
          : 'Выберите город'.tr(context),
      onTap: () async {
        final city = await showStudioSelectionSheet<String>(
          context: context,
          builder: (sheetContext) => CitySheet(
            city: controller.text,
            onSelected: (value) => Navigator.of(sheetContext).pop(value),
            onLocate: () async {
              try {
                final detected = await ref
                    .read(locationServiceProvider)
                    .nearbyCity();
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop(detected);
                }
              } catch (_) {
                if (sheetContext.mounted) {
                  notice(
                    sheetContext,
                    'Местоположение недоступно. Выберите город вручную.'.tr(
                      sheetContext,
                    ),
                  );
                }
              }
            },
          ),
        );
        if (city != null && context.mounted) {
          controller.text = city;
          onChanged(city);
        }
      },
    ),
  );
}
