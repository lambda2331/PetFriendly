import '../ui/studio_review.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'display_time.dart';
import '../ui/components.dart';

Future<String?> chooseVenueTimeZone(
  BuildContext context,
  String? selected, {
  bool onboarding = false,
}) => showStudioSelectionSheet<String>(
  context: context,
  builder: (_) => _TimeZonePicker(selected: selected, onboarding: onboarding),
);

class _TimeZonePicker extends StatefulWidget {
  const _TimeZonePicker({this.selected, this.onboarding = false});
  final bool onboarding;
  final String? selected;
  @override
  State<_TimeZonePicker> createState() => _TimeZonePickerState();
}

class _TimeZonePickerState extends State<_TimeZonePicker> {
  String query = '';
  final zones = <String>{
    'Europe/Minsk',
    'Europe/Warsaw',
    'Europe/Vilnius',
    'Europe/Riga',
    'Europe/Moscow',
    'Europe/Kyiv',
    ...venueTimeZones,
  }.toList();
  @override
  Widget build(BuildContext context) {
    final matches = zones
        .where(
          (zone) => '$zone ${timeZoneLabel(zone, locale: context.languageCode)}'
              .toLowerCase()
              .contains(query.toLowerCase().trim()),
        )
        .toList();
    if (widget.onboarding) {
      return StudioReviewSheet(
        title: 'Часовой пояс'.tr(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('onboarding-zone-search'),
              decoration: InputDecoration(
                hintText: 'Поиск города или часового пояса'.tr(context),
                prefixIcon: const Icon(LucideIcons.search, size: 22),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                contentPadding: const EdgeInsets.all(12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: 12),
            if (matches.isEmpty)
              StudioReviewState(
                title: 'Ничего не найдено'.tr(context),
                message: 'Не нашли. Попробуйте название на английском.'.tr(
                  context,
                ),
                icon: LucideIcons.search,
              ),
            for (final zone in matches.take(80))
              StudioReviewRow(
                title: timeZoneLabel(zone, locale: context.languageCode),
                subtitle: zone,
                trailing: zone == widget.selected
                    ? const Icon(LucideIcons.check, size: 22)
                    : const SizedBox(width: 22),
                onTap: () => Navigator.pop(context, zone),
              ),
          ],
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        "Часовой пояс места".tr(context),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Выберите город в том же часовом поясе, что и место прогулки."
                          .tr(context),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: "Поиск города или часового пояса".tr(
                          context,
                        ),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => query = value),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: matches.isEmpty
                    ? Center(
                        child: Text(
                          "Не нашли. Попробуйте название на английском.".tr(
                            context,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final zone = matches[index];
                          return ListTile(
                            title: Text(
                              timeZoneLabel(zone, locale: context.languageCode),
                            ),
                            subtitle: Text(zone),
                            selected: zone == widget.selected,
                            trailing: zone == widget.selected
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () => Navigator.pop(context, zone),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
