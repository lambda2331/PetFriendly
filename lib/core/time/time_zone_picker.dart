import 'package:flutter/material.dart';
import 'display_time.dart';
import '../ui/components.dart';

Future<String?> chooseVenueTimeZone(BuildContext context, String? selected) =>
    showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      sheetAnimationStyle: studioSheetAnimation(context),
      isScrollControlled: true,
      builder: (_) => _TimeZonePicker(selected: selected),
    );

class _TimeZonePicker extends StatefulWidget {
  const _TimeZonePicker({this.selected});
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
          (zone) => '$zone ${timeZoneLabel(zone)}'.toLowerCase().contains(
            query.toLowerCase().trim(),
          ),
        )
        .toList();
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
                        'Часовой пояс места',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Выберите город в том же часовом поясе, что и место прогулки.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Поиск города или часового пояса',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => query = value),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: matches.isEmpty
                    ? const Center(
                        child: Text(
                          'Не нашли. Попробуйте название на английском.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final zone = matches[index];
                          return ListTile(
                            title: Text(timeZoneLabel(zone)),
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
