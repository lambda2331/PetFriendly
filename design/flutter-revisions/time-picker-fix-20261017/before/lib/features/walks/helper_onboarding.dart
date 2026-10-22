import '../../core/ui/studio_pickers.dart';
import 'package:intl/intl.dart';
import '../nearby/city_field.dart';
import '../../l10n/localization.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/media/preview_photos.dart';
import '../../core/time/time_zone_picker.dart';
import '../../core/time/display_time.dart';
import '../../core/ui/components.dart';
import '../auth/profile_suggestion.dart';
import '../community/data/community_repository.dart';
import 'account_mode.dart';
import 'walking_chat_widgets.dart';
import 'walking_studio_components.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionState();
}

class _RoleSelectionState extends ConsumerState<RoleSelectionScreen> {
  String? selected;
  AccountModeRepository? repository;
  bool initialized = false;
  bool saving = false;
  String? error;
  @override
  Widget build(BuildContext context) {
    final accountRepository = ref.watch(accountModeRepositoryProvider);
    if (repository != accountRepository) {
      repository = accountRepository;
      initialized = false;
      selected = null;
      error = null;
    }
    final value = ref.watch(accountModeProvider);
    if (!initialized && value.hasValue) {
      initialized = true;
      selected = value.value!.needsRoleSelection ? null : value.value!.role;
    }
    return Scaffold(
      appBar: AppBar(title: Text("Ваш PetFriendly".tr(context))),
      body: value.when(
        loading: () => const WalkingLoadingState(),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(accountModeProvider),
            child: Text("Повторить загрузку ролей".tr(context)),
          ),
        ),
        data: (mode) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ScreenIntro(
                "Ваша роль".tr(context),
                subtitle: "Один аккаунт для питомцев, прогулок и общения.".tr(
                  context,
                ),
                compact: true,
              ),
              const SizedBox(height: 24),
              ...[
                (
                  'owner',
                  "Владелец питомца".tr(context),
                  "Места, встречи и помощь с прогулками для вашего питомца.".tr(
                    context,
                  ),
                  Icons.pets_outlined,
                ),
                (
                  'helper',
                  "Помощник по выгулу".tr(context),
                  "Находите запросы и помогайте другим владельцам. Свой питомец не нужен."
                      .tr(context),
                  Icons.directions_walk_outlined,
                ),
                (
                  'both',
                  "Обе роли".tr(context),
                  "Помогайте другим и заботьтесь о своём питомце. Переключайте режим в любой момент."
                      .tr(context),
                  Icons.swap_horiz_outlined,
                ),
              ].map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    selected: selected == choice.$1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerLeft,
                        backgroundColor: selected == choice.$1
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : null,
                      ),
                      onPressed: saving
                          ? null
                          : () => setState(() {
                              selected = choice.$1;
                              error = null;
                            }),
                      child: MediaQuery.textScalerOf(context).scale(16) > 24
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(choice.$4),
                                    const Spacer(),
                                    if (selected == choice.$1)
                                      const Icon(Icons.check_circle_outline),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  choice.$2,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  choice.$3,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(choice.$4),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        choice.$2,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        choice.$3,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected == choice.$1)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(Icons.check_circle_outline),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              Text(
                "Роль можно изменить в профиле. Переписки и история останутся с вами."
                    .tr(context),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: selected == null || saving || mode.pending
                    ? null
                    : () async {
                        setState(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          await ref
                              .read(accountModeProvider.notifier)
                              .chooseRole(
                                selected!,
                                mode: selected == 'both' ? 'helper' : null,
                              );
                          if (!mounted ||
                              ref.read(accountModeRepositoryProvider) !=
                                  accountRepository) {
                            return;
                          }
                          var destination = '/helper/onboarding';
                          if (selected == 'owner') {
                            final data = await ref.read(
                              communityProvider.future,
                            );
                            if (!mounted ||
                                ref.read(accountModeRepositoryProvider) !=
                                    accountRepository) {
                              return;
                            }
                            final profile = findRow(
                              data,
                              'profiles',
                              ref.read(communityRepositoryProvider).userId,
                            );
                            final name =
                                (profile?['display_name'] as String? ?? '')
                                    .trim();
                            destination =
                                name.isEmpty || name == 'Новый пользователь'
                                ? '/edit/profile?welcome=true'
                                : '/nearby';
                          }
                          if (context.mounted) context.go(destination);
                        } catch (_) {
                          if (mounted) {
                            setState(
                              () => error =
                                  "Не удалось сохранить роль. Попробуйте снова."
                                      .tr(context),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => saving = false);
                        }
                      },
                child: Text(
                  saving ? "Сохраняем…".tr(context) : "Продолжить".tr(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final helperPreferencesDraftProvider =
    NotifierProvider<HelperDraftController, HelperDraft?>(
      HelperDraftController.new,
    );

class HelperOnboardingScreen extends ConsumerStatefulWidget {
  const HelperOnboardingScreen({
    this.preferencesOnly = false,
    this.studioSheet = false,
    super.key,
  });
  final bool preferencesOnly;
  final bool studioSheet;
  @override
  ConsumerState<HelperOnboardingScreen> createState() =>
      _HelperOnboardingState();
}

class _HelperOnboardingState extends ConsumerState<HelperOnboardingScreen> {
  NotifierProvider<HelperDraftController, HelperDraft?> get draftProvider =>
      widget.preferencesOnly
      ? helperPreferencesDraftProvider
      : helperDraftProvider;
  final form = GlobalKey<FormState>();
  final scroll = ScrollController();
  final name = TextEditingController(),
      city = TextEditingController(),
      district = TextEditingController(),
      introduction = TextEditingController(),
      experience = TextEditingController(),
      areaEntry = TextEditingController();
  List<String> serviceAreas = [];
  String? areaError;
  int step = 0;
  String zone = 'Europe/Minsk';
  List<String> sizes = [];
  List<WeeklyAvailability> slots = [];
  Uint8List? photo;
  bool accepting = true, saving = false, picking = false, initialized = false;
  bool welcomePhotoRequested = false;
  bool introductionExpanded = false;
  String? error;
  AccountModeRepository? repository;
  @override
  void dispose() {
    for (final c in [
      name,
      city,
      district,
      introduction,
      experience,
      areaEntry,
    ]) {
      c.dispose();
    }
    scroll.dispose();
    super.dispose();
  }

  HelperProfile profile() => HelperProfile(
    city: city.text.trim(),
    district: district.text.trim(),
    introduction: introduction.text.trim(),
    experience: experience.text.trim(),
    timeZone: zone,
    dogSizes: List.of(sizes),
    serviceDistricts: List.of(serviceAreas),
    availability: List.of(slots),
    accepting: accepting,
  );
  void stash() => ref
      .read(draftProvider.notifier)
      .save(
        HelperDraft(
          name: name.text,
          districtEntry: areaEntry.text,
          profile: profile(),
          photo: photo,
          step: step,
        ),
      );
  void update(VoidCallback change) {
    setState(() {
      change();
      error = null;
    });
    stash();
  }

  void initialize(HelperProfile? saved, CommunityData data) {
    final draft = ref.read(draftProvider);
    final person =
        findRow(
          data,
          'profiles',
          ref.read(communityRepositoryProvider).userId,
        ) ??
        {};
    final prefs =
        draft?.profile ??
        saved ??
        HelperProfile(
          district: person['district'] as String? ?? '',
          introduction: person['about'] as String? ?? '',
        );
    final existingName = person['display_name'] as String? ?? '';
    name.text =
        draft?.name ??
        (existingName.isEmpty || existingName == 'Новый пользователь'
            ? ref.read(profileSuggestionProvider).name ?? ''
            : existingName);
    city.text = prefs.city;
    district.text = prefs.district;
    introduction.text = prefs.introduction;
    introductionExpanded =
        prefs.introduction.isNotEmpty || prefs.experience.isNotEmpty;
    experience.text = prefs.experience;
    serviceAreas = List.of(prefs.serviceDistricts);
    areaEntry.text = draft?.districtEntry ?? '';
    areaError = null;
    zone = prefs.timeZone;
    sizes = List.of(prefs.dogSizes);
    slots = List.of(prefs.availability);
    accepting = prefs.accepting;
    step = draft?.step ?? 0;
    photo = draft?.photo;
    initialized = true;
    if (!widget.preferencesOnly &&
        saved == null &&
        draft == null &&
        !welcomePhotoRequested &&
        ref.read(profileSuggestionProvider).telegramPhoto != null) {
      welcomePhotoRequested = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => previewTelegramPhoto(),
      );
    }
  }

  Future<void> previewTelegramPhoto() async {
    if (!mounted || photo != null || saving || picking) return;
    final accountRepository = ref.read(accountModeRepositoryProvider);
    try {
      final bytes = await ref.read(welcomeTelegramPhotoProvider.future);
      if (mounted &&
          bytes != null &&
          photo == null &&
          !saving &&
          !picking &&
          ref.read(accountModeRepositoryProvider) == accountRepository) {
        update(() => photo = bytes);
      }
    } catch (_) {
      // A provider picture must never block the form; gallery/import can retry.
    }
  }

  Future<void> importPhoto(Uri uri, ProfilePhotoProvider provider) async {
    if (saving || picking) return;
    final accountRepository = ref.read(accountModeRepositoryProvider);
    setState(() => picking = true);
    try {
      final bytes = await ref.read(providerPhotoDownloaderProvider)(
        uri,
        provider,
      );
      if (mounted &&
          ref.read(accountModeRepositoryProvider) == accountRepository) {
        update(() => photo = bytes);
      }
    } catch (_) {
      if (mounted &&
          ref.read(accountModeRepositoryProvider) == accountRepository) {
        setState(
          () => error =
              "Не удалось импортировать фото. Попробуйте снова или выберите фото на устройстве."
                  .tr(context),
        );
      }
    } finally {
      if (mounted &&
          ref.read(accountModeRepositoryProvider) == accountRepository) {
        setState(() => picking = false);
      }
    }
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    if (!addArea()) return;
    final prefs = profile();
    final invalid = prefs.validate();
    if (invalid != null) {
      setState(() => error = invalid.tr(context));
      return;
    }
    final uid = ref.read(communityRepositoryProvider).userId;
    final accountRepository = ref.read(accountModeRepositoryProvider);
    stash();
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (uid == null) throw StateError('Account unavailable');
      if (!widget.preferencesOnly) {
        await ref.read(communityProvider.notifier).command('profile', {
          'display_name': name.text.trim(),
        });
      }
      if (ref.read(accountModeRepositoryProvider) != accountRepository ||
          ref.read(communityRepositoryProvider).userId != uid) {
        throw StateError('Account changed');
      }
      if (!widget.preferencesOnly && photo != null) {
        await savePhoto(ref, 'profile:$uid', photo!);
      }
      if (ref.read(accountModeRepositoryProvider) != accountRepository) {
        throw StateError('Account changed');
      }
      await ref.read(accountModeProvider.notifier).saveHelperProfile(prefs);
      if (!mounted ||
          ref.read(accountModeRepositoryProvider) != accountRepository) {
        return;
      }
      ref.read(draftProvider.notifier).clear();
      notice(context, "Профиль сохранён".tr(context));
      if (widget.studioSheet) {
        Navigator.of(context).pop();
      } else if (widget.preferencesOnly) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/my-walks?tab=profile&role=helper');
        }
      } else {
        context.go('/requests');
      }
    } catch (_) {
      if (mounted &&
          ref.read(accountModeRepositoryProvider) == accountRepository) {
        setState(
          () => error =
              "Не удалось сохранить профиль. Ваши данные остались в форме. Попробуйте снова."
                  .tr(context),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  bool addArea() {
    final value = areaEntry.text.trim();
    if (value.isEmpty) return true;
    if (value.length > 100 || serviceAreas.length >= 10) {
      setState(
        () => areaError = "Укажите до 10 районов, каждый до 100 символов".tr(
          context,
        ),
      );
      return false;
    }
    if (serviceAreas.any((area) => area.toLowerCase() == value.toLowerCase())) {
      setState(() => areaError = "Этот район уже добавлен".tr(context));
      return false;
    }
    update(() {
      serviceAreas.add(value);
      areaEntry.clear();
      areaError = null;
    });
    return true;
  }

  Widget field(
    TextEditingController controller,
    String label, {
    int max = 1000,
    int lines = 1,
    bool required = false,
  }) {
    final externalLabel = controller != name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (externalLabel) ...[
            ExcludeSemantics(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 8),
          ],
          Semantics(
            label: externalLabel ? label : null,
            child: TextFormField(
              key: ValueKey('helper-field-$label'),
              controller: controller,
              enabled: !saving,
              maxLength: max,
              minLines: lines,
              maxLines: lines == 1 ? 1 : 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: externalLabel ? null : label,
                alignLabelWithHint: true,
              ),
              onChanged: (_) => stash(),
              validator: (v) => required && (v?.trim().isEmpty ?? true)
                  ? "Заполните поле".tr(context)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget studioPreferences(BuildContext context, bool ready, bool failed) {
    Widget areaField(
      TextEditingController c,
      String title, {
      int max = 1000,
      int lines = 1,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: walkingBodyStyle),
          const SizedBox(height: 8),
          Semantics(
            label: title,
            child: TextFormField(
              key: ValueKey(
                c == experience
                    ? 'conditions-experience'
                    : c == introduction
                    ? 'conditions-introduction'
                    : c == district
                    ? 'conditions-district'
                    : 'conditions-city',
              ),
              controller: c,
              enabled: !saving,
              maxLength: max,
              minLines: lines,
              maxLines: lines == 1 ? 1 : 4,
              decoration: const InputDecoration(counterText: ''),
              onChanged: (_) => stash(),
            ),
          ),
        ],
      ),
    );
    Future<void> editAvailability() async {
      await showStudioSelectionSheet<void>(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (ctx, rebuild) => WalkingChatSheet(
            title: 'Доступность'.tr(ctx),
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Готов помогать сейчас'.tr(ctx)),
                value: accepting,
                onChanged: saving
                    ? null
                    : (v) {
                        update(() => accepting = v);
                        rebuild(() {});
                      },
              ),
            ],
          ),
        ),
      );
    }

    Future<void> editSchedule() async {
      await showStudioSelectionSheet<void>(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (ctx, rebuild) => WalkingFormTheme(
            child: WalkingChatSheet(
              title: 'Когда'.tr(ctx),
              children: [
                for (final e in slots.asMap().entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${days[e.value.day].tr(ctx)} · ${minutes(e.value.start)}–${minutes(e.value.end)}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Удалить интервал'.tr(ctx),
                      icon: const Icon(Icons.close),
                      onPressed: saving
                          ? null
                          : () {
                              update(() => slots.removeAt(e.key));
                              rebuild(() {});
                            },
                    ),
                  ),
                TextButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          await addSlot();
                          rebuild(() {});
                        },
                  icon: const Icon(Icons.add),
                  label: Text('Добавить время'.tr(ctx)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final sizeMask =
        (sizes.contains('small') ? 1 : 0) |
        (sizes.contains('medium') ? 2 : 0) |
        (sizes.contains('large') ? 4 : 0);
    final petCaption = (switch (sizeMask) {
      1 => 'Небольшие собаки',
      2 => 'Средние собаки',
      4 => 'Крупные собаки',
      3 => 'Небольшие и средние собаки',
      5 => 'Небольшие и крупные собаки',
      6 => 'Средние и крупные собаки',
      7 => 'Небольшие, средние и крупные собаки',
      _ => 'Любой размер',
    }).tr(context);
    final uniform =
        slots.isEmpty ||
        slots.every(
          (s) => s.start == slots.first.start && s.end == slots.first.end,
        );
    final start = slots.isEmpty ? 540 : slots.first.start;
    final end = slots.isEmpty ? 1020 : slots.first.end;
    Future<void> chooseHours(bool beginning) async {
      final current = beginning ? start : end;
      final picked = await showStudioTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: (current % 1440) ~/ 60,
          minute: current % 60,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (picked != null && mounted) {
        update(
          () => slots = slots
              .map(
                (s) => WeeklyAvailability(
                  day: s.day,
                  start: beginning ? picked.hour * 60 + picked.minute : s.start,
                  end: beginning
                      ? s.end
                      : (picked.hour == 0 && picked.minute == 0
                            ? 1440
                            : picked.hour * 60 + picked.minute),
                ),
              )
              .toList(),
        );
      }
    }

    return WalkingFormTheme(
      child: WalkingChatSheet(
        title: 'Условия прогулок'.tr(context),
        closeEnabled: !saving,
        onClose: () {
          stash();
          Navigator.pop(context);
        },
        children: [
          if (!ready)
            failed
                ? TextButton(
                    onPressed: () {
                      ref.invalidate(helperProfileProvider);
                      ref.invalidate(communityProvider);
                    },
                    child: Text('Повторить загрузку профиля'.tr(context)),
                  )
                : const WalkingLoadingState()
          else
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InkWell(
                      onTap: saving ? null : editAvailability,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          (accepting
                                  ? 'Готов обсуждать прогулки'
                                  : 'Сейчас не принимает новые запросы')
                              .tr(context),
                          style: walkingMetaStyle(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Где'.tr(context)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).inputDecorationTheme.fillColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            await showStudioSelectionSheet<void>(
                              context: context,
                              builder: (_) => StatefulBuilder(
                                builder: (ctx, rebuild) => WalkingFormTheme(
                                  child: WalkingChatSheet(
                                    title: 'Где'.tr(ctx),
                                    children: [
                                      CityField(
                                        controller: city,
                                        onChanged: (v) {
                                          update(
                                            () =>
                                                zone = cityTimeZone(v) ?? zone,
                                          );
                                          rebuild(() {});
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      areaField(
                                        district,
                                        'Публичный район · необязательно'.tr(
                                          ctx,
                                        ),
                                        max: 100,
                                      ),
                                      Text('Районы, где можете помочь'.tr(ctx)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final area in serviceAreas)
                                            InputChip(
                                              label: Text(area),
                                              onDeleted: () {
                                                update(
                                                  () =>
                                                      serviceAreas.remove(area),
                                                );
                                                rebuild(() {});
                                              },
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: areaEntry,
                                        maxLength: 100,
                                        decoration: InputDecoration(
                                          labelText: 'Район'.tr(ctx),
                                          errorText: areaError,
                                        ),
                                        onFieldSubmitted: (_) {
                                          addArea();
                                          rebuild(() {});
                                        },
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          addArea();
                                          rebuild(() {});
                                        },
                                        icon: const Icon(Icons.add),
                                        label: Text('Добавить район'.tr(ctx)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            [
                              city.text,
                              district.text,
                              if (district.text.isEmpty)
                                serviceAreas.join(', '),
                            ].where((s) => s.isNotEmpty).toSet().join(' · '),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Питомцы'.tr(context)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).inputDecorationTheme.fillColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            await showStudioSelectionSheet<void>(
                              context: context,
                              builder: (_) => StatefulBuilder(
                                builder: (ctx, rebuild) => WalkingChatSheet(
                                  title: 'С какими питомцами'.tr(ctx),
                                  children: [
                                    for (final pair in [
                                      ('small', 'Небольшие'),
                                      ('medium', 'Средние'),
                                      ('large', 'Крупные'),
                                    ])
                                      CheckboxListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(pair.$2.tr(ctx)),
                                        value: sizes.contains(pair.$1),
                                        onChanged: (v) {
                                          update(() {
                                            v == true
                                                ? sizes.add(pair.$1)
                                                : sizes.remove(pair.$1);
                                          });
                                          rebuild(() {});
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                    child: Row(children: [Expanded(child: Text(petCaption))]),
                  ),
                  const SizedBox(height: 16),
                  areaField(
                    experience,
                    'Опыт с собаками и кошками'.tr(context),
                    lines: 4,
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InkWell(
                      onTap: saving ? null : editSchedule,
                      child: Text('Когда'.tr(context), style: walkingBodyStyle),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (uniform) ...[
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        final large =
                            MediaQuery.textScalerOf(ctx).scale(14) > 20;
                        final children = <Widget>[
                          for (var n = 0; n < 7; n++)
                            SizedBox(
                              width: large
                                  ? 56
                                  : (constraints.maxWidth - 24) / 7,
                              child: Semantics(
                                selected: slots.any((s) => s.day == n),
                                child: OutlinedButton(
                                  key: ValueKey('conditions-day-$n'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: 8,
                                    ),
                                    backgroundColor:
                                        slots.any((s) => s.day == n)
                                        ? Theme.of(
                                            context,
                                          ).inputDecorationTheme.fillColor
                                        : Colors.transparent,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: 14,
                                          fontWeight:
                                              slots.any((s) => s.day == n)
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                  ),
                                  onPressed: saving
                                      ? null
                                      : () => update(() {
                                          if (slots.any((s) => s.day == n)) {
                                            slots.removeWhere(
                                              (s) => s.day == n,
                                            );
                                          } else {
                                            slots.add(
                                              WeeklyAvailability(
                                                day: n,
                                                start: start,
                                                end: end,
                                              ),
                                            );
                                          }
                                        }),
                                  child: Text(
                                    toBeginningOfSentenceCase(
                                      DateFormat.E(
                                        context.languageCode,
                                      ).format(DateTime(2026, 10, 12 + n)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ];
                        return Wrap(
                          spacing: 4,
                          runSpacing: 8,
                          children: children,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).inputDecorationTheme.fillColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: saving || slots.isEmpty
                                ? null
                                : () => chooseHours(true),
                            child: Row(
                              children: [
                                Expanded(child: Text(minutes(start))),
                                const Icon(Icons.schedule_outlined, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('–'),
                        ),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).inputDecorationTheme.fillColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: saving || slots.isEmpty
                                ? null
                                : () => chooseHours(false),
                            child: Row(
                              children: [
                                Expanded(child: Text(minutes(end))),
                                const Icon(Icons.schedule_outlined, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    for (final e in slots.asMap().entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${days[e.value.day].tr(context)} · ${minutes(e.value.start)}–${minutes(e.value.end)}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Удалить интервал'.tr(context),
                          onPressed: saving
                              ? null
                              : () => update(() => slots.removeAt(e.key)),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final z = await chooseVenueTimeZone(
                                context,
                                zone,
                              );
                              if (z != null && mounted) update(() => zone = z);
                            },
                      child: Text(
                        zone == 'Europe/Minsk'
                            ? 'Время Минска · UTC+3'.tr(context)
                            : timeZoneLabel(zone, locale: context.languageCode),
                        style: walkingMetaStyle(context),
                      ),
                    ),
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('helper-onboarding-action'),
                    style: FilledButton.styleFrom(
                      textStyle: walkingBodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: saving ? null : save,
                    child: Text(
                      (saving ? 'Сохраняем…' : 'Сохранить').tr(context),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountRepository = ref.watch(accountModeRepositoryProvider);
    if (repository != accountRepository) {
      repository = accountRepository;
      initialized = false;
      photo = null;
      welcomePhotoRequested = false;
      saving = false;
      error = null;
    }
    final suggestion = ref.watch(profileSuggestionProvider);
    final saved = ref.watch(helperProfileProvider);
    final community = ref.watch(communityProvider);
    final mode = ref.watch(accountModeProvider).value;
    if (!initialized && saved.hasValue && community.hasValue) {
      initialize(saved.value, community.value!);
    }
    if (mode != null && !mode.canHelp) {
      return Scaffold(
        appBar: AppBar(title: Text("Профиль помощника".tr(context))),
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/roles'),
            child: Text("Выбрать роль помощника".tr(context)),
          ),
        ),
      );
    }
    if (widget.studioSheet) {
      return studioPreferences(
        context,
        initialized,
        saved.hasError || community.hasError,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.preferencesOnly
              ? "Редактировать условия".tr(context)
              : step == 0
              ? "Знакомство".tr(context)
              : "Предпочтения".tr(context),
        ),
        leading: BackButton(
          onPressed: saving
              ? null
              : () {
                  stash();
                  if (step == 1 && !widget.preferencesOnly) {
                    update(() => step = 0);
                    scroll.jumpTo(0);
                  } else if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/roles');
                  }
                },
        ),
      ),
      body: !initialized
          ? saved.hasError || community.hasError
                ? Center(
                    child: TextButton(
                      onPressed: () {
                        ref.invalidate(helperProfileProvider);
                        ref.invalidate(communityProvider);
                      },
                      child: Text("Повторить загрузку профиля".tr(context)),
                    ),
                  )
                : const WalkingLoadingState()
          : SafeArea(
              child: Form(
                key: form,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: scroll,
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        children: [
                          if (!widget.preferencesOnly)
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                step == 0
                                    ? "Шаг 1 из 2".tr(context)
                                    : "Шаг 2 из 2".tr(context),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          const SizedBox(height: 8),
                          ScreenIntro(
                            widget.preferencesOnly
                                ? "Условия для прогулок".tr(context)
                                : step == 0
                                ? "О вас".tr(context)
                                : "Для прогулок".tr(context),
                            subtitle: widget.preferencesOnly
                                ? null
                                : step == 0
                                ? "Свой питомец не нужен.".tr(context)
                                : "Предпочтения можно изменить позже.".tr(
                                    context,
                                  ),
                            compact: true,
                          ),
                          const SizedBox(height: 20),
                          if (step == 0 || widget.preferencesOnly) ...[
                            if (!widget.preferencesOnly) ...[
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                runSpacing: 12,
                                children: [
                                  if (photo != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.memory(
                                        photo!,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    IdentityPicture(
                                      id: 'profile:${ref.read(communityRepositoryProvider).userId}',
                                      name: name.text,
                                      icon: Icons.person_outline,
                                      size: 64,
                                    ),
                                  OutlinedButton.icon(
                                    onPressed: saving || picking
                                        ? null
                                        : () async {
                                            final uid = ref
                                                .read(
                                                  communityRepositoryProvider,
                                                )
                                                .userId;
                                            setState(() => picking = true);
                                            try {
                                              final bytes =
                                                  await pickPreviewPhoto();
                                              if (mounted &&
                                                  bytes != null &&
                                                  uid ==
                                                      ref
                                                          .read(
                                                            communityRepositoryProvider,
                                                          )
                                                          .userId) {
                                                update(() => photo = bytes);
                                              }
                                            } catch (_) {
                                              if (mounted) {
                                                setState(
                                                  () => error =
                                                      "Не удалось выбрать фото. Выберите изображение до 8 МБ."
                                                          .tr(context),
                                                );
                                              }
                                            } finally {
                                              if (mounted) {
                                                setState(() => picking = false);
                                              }
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.add_photo_alternate_outlined,
                                    ),
                                    label: Text(
                                      picking
                                          ? "Открываем…".tr(context)
                                          : "Выбрать фото".tr(context),
                                    ),
                                  ),
                                  if (suggestion.googlePhoto != null)
                                    TextButton(
                                      onPressed: saving || picking
                                          ? null
                                          : () => importPhoto(
                                              suggestion.googlePhoto!,
                                              ProfilePhotoProvider.google,
                                            ),
                                      child: Text("Фото из Google".tr(context)),
                                    ),
                                  if (suggestion.telegramPhoto != null)
                                    TextButton(
                                      onPressed: saving || picking
                                          ? null
                                          : () => importPhoto(
                                              suggestion.telegramPhoto!,
                                              ProfilePhotoProvider.telegram,
                                            ),
                                      child: Text(
                                        "Фото из Telegram".tr(context),
                                      ),
                                    ),
                                  if (photo != null)
                                    TextButton(
                                      onPressed: saving
                                          ? null
                                          : () => update(() => photo = null),
                                      child: Text("Отменить выбор".tr(context)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              field(
                                name,
                                "Имя".tr(context),
                                max: 80,
                                required: true,
                              ),
                            ],
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: CityField(
                                controller: city,
                                enabled: !saving,
                                onChanged: (value) => update(() {
                                  zone = cityTimeZone(value) ?? '';
                                }),
                              ),
                            ),
                            field(
                              district,
                              "Публичный район · необязательно".tr(context),
                              max: 100,
                            ),
                            if (widget.preferencesOnly) ...[
                              field(
                                introduction,
                                "Коротко о себе · необязательно".tr(context),
                                lines: 3,
                              ),
                              field(
                                experience,
                                "Опыт с животными · необязательно".tr(context),
                                lines: 3,
                              ),
                            ] else
                              ExpansionTile(
                                key: const ValueKey('helper-introduction'),
                                tilePadding: EdgeInsets.zero,
                                childrenPadding: EdgeInsets.zero,
                                maintainState: true,
                                initiallyExpanded: introductionExpanded,
                                onExpansionChanged: (value) =>
                                    introductionExpanded = value,
                                title: Text(
                                  "О себе и опыте · необязательно".tr(context),
                                ),
                                subtitle: Text(
                                  "Можно заполнить позже в профиле.".tr(
                                    context,
                                  ),
                                ),
                                children: [
                                  field(
                                    introduction,
                                    "Коротко о себе · необязательно".tr(
                                      context,
                                    ),
                                    lines: 3,
                                  ),
                                  field(
                                    experience,
                                    "Опыт с животными · необязательно".tr(
                                      context,
                                    ),
                                    lines: 3,
                                  ),
                                ],
                              ),
                          ],
                          if (step == 1 || widget.preferencesOnly) ...[
                            Text(
                              "Размер собак".tr(context),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ...[
                              ('small', "Небольшие".tr(context)),
                              ('medium', "Средние".tr(context)),
                              ('large', "Крупные".tr(context)),
                            ].map(
                              (size) => CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(size.$2),
                                value: sizes.contains(size.$1),
                                onChanged: saving
                                    ? null
                                    : (value) => update(() {
                                        value == true
                                            ? sizes.add(size.$1)
                                            : sizes.remove(size.$1);
                                      }),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Районы, где можете помочь".tr(context),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Районы: {p0} из 10".tr(
                                context,
                                arguments: {'p0': serviceAreas.length},
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (serviceAreas.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: serviceAreas
                                    .map(
                                      (area) => InputChip(
                                        label: Text(area),
                                        deleteButtonTooltipMessage:
                                            "Удалить район".tr(context),
                                        onDeleted: saving
                                            ? null
                                            : () => update(
                                                () => serviceAreas.remove(area),
                                              ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              "Район".tr(context),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Semantics(
                                    label: "Район".tr(context),
                                    child: TextFormField(
                                      key: const Key('helper-district-input'),
                                      controller: areaEntry,
                                      enabled:
                                          !saving && serviceAreas.length < 10,
                                      maxLength: 100,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      textInputAction: TextInputAction.done,
                                      decoration: InputDecoration(
                                        errorText: areaError,
                                      ),
                                      onChanged: (_) {
                                        if (areaError != null) {
                                          setState(() => areaError = null);
                                        }
                                        stash();
                                      },
                                      onFieldSubmitted: (_) => addArea(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  key: const Key('helper-add-district'),
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  tooltip: "Добавить район".tr(context),
                                  onPressed: saving || serviceAreas.length >= 10
                                      ? null
                                      : addArea,
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                            Text(
                              "Указывайте публичные районы, без точного адреса."
                                  .tr(context),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text("Часовой пояс".tr(context)),
                              subtitle: Text(
                                timeZoneLabel(
                                  zone,
                                  locale: context.languageCode,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: saving
                                  ? null
                                  : () async {
                                      final value = await chooseVenueTimeZone(
                                        context,
                                        zone,
                                      );
                                      if (value != null && mounted) {
                                        update(() => zone = value);
                                      }
                                    },
                            ),
                            const Divider(),
                            Text(
                              "Когда вам удобно".tr(context),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Недельные интервалы в выбранном часовом поясе. Можно оставить пустым."
                                  .tr(context),
                            ),
                            ...slots.asMap().entries.map(
                              (e) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '${days[e.value.day].tr(context)} · ${minutes(e.value.start)}–${minutes(e.value.end)}',
                                ),
                                trailing: IconButton(
                                  tooltip: "Удалить интервал".tr(context),
                                  onPressed: saving
                                      ? null
                                      : () =>
                                            update(() => slots.removeAt(e.key)),
                                  icon: const Icon(Icons.close, size: 20),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: saving || slots.length >= 28
                                  ? null
                                  : addSlot,
                              icon: const Icon(Icons.add),
                              label: Text("Добавить время".tr(context)),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text("Готов помогать сейчас".tr(context)),
                              subtitle: Text(
                                "Покажем это в публичном профиле".tr(context),
                              ),
                              value: accepting,
                              onChanged: saving
                                  ? null
                                  : (value) => update(() => accepting = value),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            "Эти данные будут видны другим пользователям. Указывайте только город и район, без точного адреса и личных инструкций."
                                .tr(context),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          FilledButton(
                            key: const Key('helper-onboarding-action'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: saving || picking
                                ? null
                                : step == 0 && !widget.preferencesOnly
                                ? () {
                                    if (form.currentState!.validate()) {
                                      update(() => step = 1);
                                      FocusScope.of(context).unfocus();
                                      scroll.jumpTo(0);
                                    }
                                  }
                                : save,
                            child: Text(
                              saving
                                  ? "Сохраняем…".tr(context)
                                  : step == 0 && !widget.preferencesOnly
                                  ? "Продолжить".tr(context)
                                  : "Сохранить".tr(context),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  static const days = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];
  static String minutes(int n) =>
      '${(n ~/ 60).toString().padLeft(2, '0')}:${(n % 60).toString().padLeft(2, '0')}';
  Future<void> addSlot() async {
    final slot = await showDialog<WeeklyAvailability>(
      context: context,
      builder: (_) => _AvailabilityDialog(existing: List.of(slots)),
    );
    if (slot == null || !mounted) return;
    final problem = WeeklyAvailability.validate([...slots, slot]);
    if (problem != null) {
      setState(() => error = problem.tr(context));
      return;
    }
    update(() => slots.add(slot));
  }
}

class _AvailabilityDialog extends StatefulWidget {
  const _AvailabilityDialog({required this.existing});
  final List<WeeklyAvailability> existing;
  @override
  State<_AvailabilityDialog> createState() => _AvailabilityState();
}

class _AvailabilityState extends State<_AvailabilityDialog> {
  int day = 0;
  TimeOfDay start = const TimeOfDay(hour: 9, minute: 0),
      end = const TimeOfDay(hour: 17, minute: 0);
  String? error;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text("Время для прогулок".tr(context)),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int>(
            initialValue: day,
            isExpanded: true,
            decoration: InputDecoration(labelText: "День недели".tr(context)),
            items: List.generate(
              7,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(_HelperOnboardingState.days[i].tr(context)),
              ),
            ),
            onChanged: (v) => setState(() => day = v!),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              final v = await showStudioTimePicker(
                context: context,
                initialTime: start,
              );
              if (v != null && mounted) setState(() => start = v);
            },
            child: Text(
              "Начало: {p0}".tr(
                context,
                arguments: {'p0': start.format(context)},
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final v = await showStudioTimePicker(
                context: context,
                initialTime: end,
              );
              if (v != null && mounted) setState(() => end = v);
            },
            child: Text(
              "Окончание: {p0}".tr(
                context,
                arguments: {'p0': end.format(context)},
              ),
            ),
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text("Отмена".tr(context)),
      ),
      FilledButton(
        onPressed: () {
          final slot = WeeklyAvailability(
            day: day,
            start: start.hour * 60 + start.minute,
            end: end.hour * 60 + end.minute,
          );
          final invalid = WeeklyAvailability.validate([
            ...widget.existing,
            slot,
          ]);
          if (invalid != null) {
            setState(() => error = invalid.tr(context));
            return;
          }
          Navigator.pop(context, slot);
        },
        child: Text("Добавить".tr(context)),
      ),
    ],
  );
}
