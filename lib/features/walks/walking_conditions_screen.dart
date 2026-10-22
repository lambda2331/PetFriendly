import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/time/display_time.dart';
import '../../l10n/localization.dart';
import 'account_mode.dart';
import 'personal_walking_controller.dart';
import 'helper_onboarding.dart';

/// Account-scoped helper conditions. Editing uses the existing preference form.
class WalkingConditionsScreen extends ConsumerWidget {
  const WalkingConditionsScreen({this.embedded = false, super.key});
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) => embedded
      ? const HelperOnboardingScreen(preferencesOnly: true, studioSheet: true)
      : Scaffold(
          appBar: AppBar(
            centerTitle: embedded ? false : null,
            titleSpacing: embedded ? 20 : null,
            title: Text('Условия прогулок'.tr(context)),
            automaticallyImplyLeading: !embedded,
            actions: embedded
                ? [
                    IconButton(
                      tooltip: 'Закрыть'.tr(context),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ]
                : null,
          ),
          body: ref
              .watch(helperProfileProvider)
              .when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Загружаем предпочтения помощника'.tr(
                      context,
                    ),
                  ),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextButton(
                    onPressed: () => ref.invalidate(helperProfileProvider),
                    child: Text(
                      'Предпочтения недоступны · повторить'.tr(context),
                    ),
                  ),
                ),
                data: (profile) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    if (profile == null)
                      Text('Предпочтения пока не указаны'.tr(context))
                    else ...[
                      _ConditionsGroup(
                        title: 'Где'.tr(context),
                        children: [
                          Text(
                            _distinct([
                              profile.city,
                              profile.district,
                            ]).join(' · '),
                          ),
                          if (profile.serviceDistricts.isEmpty)
                            Text('Районы пока не указаны'.tr(context))
                          else if (_distinct(profile.serviceDistricts)
                              .where(
                                (district) =>
                                    district.toLowerCase() !=
                                    profile.district.trim().toLowerCase(),
                              )
                              .isNotEmpty)
                            Text(
                              'Районы: {p0}'.tr(
                                context,
                                arguments: {
                                  'p0': _distinct(profile.serviceDistricts)
                                      .where(
                                        (district) =>
                                            district.toLowerCase() !=
                                            profile.district
                                                .trim()
                                                .toLowerCase(),
                                      )
                                      .join(', '),
                                },
                              ),
                            ),
                        ],
                      ),
                      _ConditionsGroup(
                        title: 'С какими питомцами'.tr(context),
                        children: [
                          Text(
                            profile.dogSizes.isEmpty
                                ? 'Предпочтения пока не указаны'.tr(context)
                                : 'Размер собак: {p0}'.tr(
                                    context,
                                    arguments: {
                                      'p0':
                                          [
                                                for (final size in [
                                                  'small',
                                                  'medium',
                                                  'large',
                                                ])
                                                  if (profile.dogSizes.contains(
                                                    size,
                                                  ))
                                                    size,
                                                ...profile.dogSizes.where(
                                                  (size) => ![
                                                    'small',
                                                    'medium',
                                                    'large',
                                                  ].contains(size),
                                                ),
                                              ]
                                              .map(
                                                (size) => switch (size) {
                                                  'small' => 'Небольшие'.tr(
                                                    context,
                                                  ),
                                                  'medium' => 'Средние'.tr(
                                                    context,
                                                  ),
                                                  'large' => 'Крупные'.tr(
                                                    context,
                                                  ),
                                                  _ => size,
                                                },
                                              )
                                              .join(', '),
                                    },
                                  ),
                          ),
                          if (profile.introduction.isNotEmpty)
                            Text(profile.introduction),
                          if (profile.experience.isNotEmpty &&
                              profile.experience.trim() !=
                                  profile.introduction.trim())
                            Text(profile.experience),
                        ],
                      ),
                      _ConditionsGroup(
                        title: 'Когда'.tr(context),
                        children: [
                          if (profile.availability.isEmpty)
                            Text('Время обсудим в переписке'.tr(context))
                          else ...[
                            for (final slot in compactWalkingSchedule(
                              profile.availability,
                            ))
                              Text(_schedule(context, slot)),
                            Text(
                              'Время в {p0}'.tr(
                                context,
                                arguments: {
                                  'p0': timeZoneLabel(
                                    profile.timeZone,
                                    locale: context.languageCode,
                                  ),
                                },
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                      _ConditionsGroup(
                        title: 'Доступность'.tr(context),
                        children: [
                          Text(
                            (profile.accepting
                                    ? 'Готов обсуждать прогулки'
                                    : 'Сейчас не принимает новые запросы')
                                .tr(context),
                          ),
                        ],
                      ),
                    ],
                    if (ref.watch(accountModeProvider).value?.canHelp == true)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text('Редактировать условия'.tr(context)),
                          onPressed: () async {
                            if (embedded) {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const HelperOnboardingScreen(
                                    preferencesOnly: true,
                                  ),
                                ),
                              );
                            } else {
                              await context.push('/helper/preferences');
                            }
                            ref.invalidate(helperProfileProvider);
                          },
                        ),
                      ),
                  ],
                ),
              ),
        );
}

List<String> _distinct(Iterable<String> source) {
  final seen = <String>{};
  return source
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty && seen.add(value.toLowerCase()))
      .toList();
}

String _schedule(BuildContext context, WalkingScheduleRange slot) {
  String day(int value) => DateFormat.E(
    context.languageCode,
  ).format(DateTime.utc(2026, 10, 5 + value));
  String clock(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
  return '${day(slot.firstDay)}${slot.lastDay == slot.firstDay ? '' : '–${day(slot.lastDay)}'} · ${clock(slot.start)}–${clock(slot.end)}';
}

class _ConditionsGroup extends StatelessWidget {
  const _ConditionsGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0) const SizedBox(height: 8),
        children[index],
      ],
      const Divider(height: 32),
    ],
  );
}
