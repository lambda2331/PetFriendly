import '../../../core/ui/studio_pickers.dart';
import '../../../core/ui/studio_review.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../nearby/city_field.dart';
import '../../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/profile_suggestion.dart';
import '../../auth/account_entry_screen.dart';
import '../../../core/storage/prototype_store.dart';
import '../../../core/ui/components.dart';
import '../../../core/time/display_time.dart';
import '../../../core/time/time_zone_picker.dart';
import '../../../core/media/preview_photos.dart';
import '../data/community_repository.dart';
import '../data/form_drafts.dart';
import '../data/event_location.dart';
import 'event_location_widgets.dart';
import '../../walks/walking_studio_components.dart';

class EditScreen extends ConsumerStatefulWidget {
  const EditScreen({
    required this.kind,
    this.id,
    this.initialCommunity,
    this.welcome = false,
    this.embedded = false,
    super.key,
  });
  final String kind;
  final String? id, initialCommunity;
  final bool welcome;
  final bool embedded;
  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  final form = GlobalKey<FormState>();
  final inputs = <String, TextEditingController>{};
  bool saving = false, initialized = false;
  bool loadingPhoto = false;
  bool walkLocationExpanded = false;
  bool welcomePhotoRequested = false;
  bool changed = false, allowPop = false, prompting = false;
  late final FormDrafts drafts;
  FormDraft? restored;
  String get draftKey =>
      '${widget.kind}:${widget.id ?? "new"}:${widget.welcome}';
  DateTime when = DateTime.now().add(const Duration(days: 1));
  String? petId;
  String? venueZone;
  Uint8List? cover;
  EventLocation? eventLocation;
  @override
  void initState() {
    super.initState();
    drafts = ref.read(formDraftsProvider);
    restored = drafts.read(draftKey);
    changed = restored != null;
    venueZone = cityTimeZone(ref.read(prototypeProvider).city);
    final initial = venueZone == null
        ? DateTime.now()
        : venueDateTime(DateTime.now(), venueZone!);
    when = DateTime.utc(
      initial.year,
      initial.month,
      initial.day + 1,
      initial.hour,
      initial.minute,
    );
    if (restored case final draft?) {
      when = draft.when;
      venueZone = draft.zone;
      petId = draft.petId;
      cover = draft.photo;
      eventLocation = draft.eventLocation;
    }
  }

  Future<void> leave() async {
    if (prompting || saving) {
      return;
    }
    prompting = true;
    final keep = await showStudioSelectionSheet<bool>(
      context: context,
      builder: (ctx) => StudioReviewSheet(
        title: 'Выйти из формы?'.tr(ctx),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Можно оставить черновик до закрытия приложения. Он не публикуется и не записывается на устройство.'
                  .tr(ctx),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Удалить изменения'.tr(ctx)),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Оставить черновик'.tr(ctx)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Продолжить'.tr(ctx)),
            ),
          ],
        ),
      ),
    );
    prompting = false;
    if (keep == null || !mounted) {
      return;
    }
    if (keep) {
      drafts.keep(
        draftKey,
        FormDraft(
          Map.unmodifiable(
            inputs.map((key, value) => MapEntry(key, value.text)),
          ),
          when,
          venueZone,
          petId,
          cover,
          eventLocation: eventLocation,
        ),
      );
    } else {
      drafts.discard(draftKey);
    }
    setState(() => allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      } else {
        await SystemNavigator.pop();
      }
    }
  }

  Future<void> chooseEventPoint() async {
    final currentCity = input('city', ref.read(prototypeProvider).city);
    final result = await Navigator.push<EventVenueSelection>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EventVenuePicker(city: currentCity.text, initial: eventLocation),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (currentCity.text != result.city ||
          eventLocation?.latitude != result.location?.latitude ||
          eventLocation?.longitude != result.location?.longitude) {
        input('location_label').text = result.location?.label ?? '';
      }
      currentCity.text = result.city;
      venueZone = cityTimeZone(result.city);
      eventLocation = result.location;
      if (result.location == null) inputs['location_label']?.clear();
      changed = true;
    });
  }

  Future<void> loadProviderPhoto(Uri uri, ProfilePhotoProvider provider) async {
    final uid = ref.read(communityRepositoryProvider).userId;
    setState(() => loadingPhoto = true);
    try {
      final bytes = await ref.read(providerPhotoDownloaderProvider)(
        uri,
        provider,
      );
      if (mounted && uid == ref.read(communityRepositoryProvider).userId) {
        setState(() {
          cover = bytes;
          changed = true;
        });
      }
    } catch (_) {
      if (mounted) {
        notice(
          context,
          "Фото недоступно. Выберите другое изображение.".tr(context),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loadingPhoto = false);
      }
    }
  }

  Future<void> previewWelcomeTelegramPhoto() async {
    if (!mounted || cover != null || saving) {
      return;
    }
    final uid = ref.read(communityRepositoryProvider).userId;
    setState(() => loadingPhoto = true);
    try {
      final bytes = await ref.read(welcomeTelegramPhotoProvider.future);
      if (mounted &&
          !saving &&
          cover == null &&
          bytes != null &&
          uid == ref.read(communityRepositoryProvider).userId) {
        setState(() {
          cover = bytes;
          changed = true;
        });
      }
    } catch (_) {
      // A missing/unavailable provider picture must never block onboarding.
      // The explicit import button and gallery picker remain available.
    } finally {
      if (mounted) {
        setState(() => loadingPhoto = false);
      }
    }
  }

  @override
  void dispose() {
    for (final input in inputs.values) {
      input.dispose();
    }
    super.dispose();
  }

  TextEditingController input(String name, [String value = '']) =>
      inputs.putIfAbsent(
        name,
        () => TextEditingController(text: restored?.values[name] ?? value),
      );
  Widget field(
    String key,
    String label, {
    String value = '',
    int max = 120,
    int lines = 1,
    bool required = true,
    bool number = false,
    double? gapAfter,
    ValueChanged<String>? onChanged,
  }) => Padding(
    padding: EdgeInsets.only(
      bottom: gapAfter ?? (widget.kind == 'walk' ? 16 : 14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ['walk', 'profile', 'pet'].contains(widget.kind)
              ? walkingBodyStyle
              : Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          child: TextFormField(
            textAlignVertical: TextAlignVertical.top,
            key: ValueKey('field.$key'),
            controller: input(key, value),
            enabled: !saving,
            onChanged: (value) {
              setState(() => changed = true);
              onChanged?.call(value);
            },
            maxLength: max,
            maxLines: lines,
            keyboardType: number ? TextInputType.number : TextInputType.text,
            decoration: const InputDecoration(counterText: ''),
            validator: (text) {
              if (required && (text ?? '').trim().isEmpty) {
                return "Заполните поле".tr(context);
              }
              if (!required && (text ?? '').trim().isEmpty) return null;
              if (widget.kind == 'event' && key == 'duration') {
                final n = int.tryParse(text ?? '');
                if (n == null || n < 15 || n > 480 || n % 15 != 0) {
                  return 'От 15 до 480 минут с шагом 15 минут'.tr(context);
                }
              }
              if (number) {
                final n = int.tryParse(text ?? '');
                if (n == null || n < 0) {
                  return "Введите число".tr(context);
                }
              }
              return null;
            },
          ),
        ),
      ],
    ),
  );
  Future<void> date() async {
    final today = venueZone == null
        ? DateTime.now()
        : venueDateTime(DateTime.now(), venueZone!);
    final day = await showStudioDatePicker(
      context: context,
      initialDate: when,
      helpText: widget.kind == 'walk'
          ? "Дата прогулки".tr(context)
          : "Дата встречи".tr(context),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      cancelText: "Отмена".tr(context),
      confirmText: "Выбрать".tr(context),
      firstDate: DateTime.utc(today.year, today.month, today.day),
      lastDate: DateTime.utc(today.year, today.month, today.day + 365),
    );
    if (day == null || !mounted) {
      return;
    }
    final time = await showStudioTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(when),
      helpText: "Время начала".tr(context),
      cancelText: "Отмена".tr(context),
      confirmText: "Выбрать".tr(context),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      setState(() {
        changed = true;
        when = DateTime.utc(
          day.year,
          day.month,
          day.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Widget petPhoto(BuildContext context, Json pet) => Center(
    child: Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: saving
              ? null
              : () async {
                  try {
                    final bytes = await pickPreviewPhoto();
                    if (mounted && bytes != null) {
                      setState(() {
                        cover = bytes;
                        changed = true;
                      });
                    }
                  } catch (_) {
                    if (context.mounted) {
                      notice(
                        context,
                        'Не удалось открыть фото. Максимум 8 МБ.'.tr(context),
                      );
                    }
                  }
                },
          child: SizedBox.square(
            dimension: 112,
            child: Stack(
              children: [
                if (cover == null)
                  IdentityPicture(
                    id: widget.kind == 'profile'
                        ? 'profile:${pet['id']}'
                        : 'pet:${pet['id']}',
                    icon: widget.kind == 'profile'
                        ? LucideIcons.user
                        : LucideIcons.pawPrint,
                    size: 112,
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.memory(
                      cover!,
                      width: 112,
                      height: 112,
                      fit: BoxFit.cover,
                    ),
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 18,
                    child: const Icon(LucideIcons.camera, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Выбрать фото'.tr(context),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );

  Future<void> save() async {
    if (saving) {
      return;
    }
    final invalid = form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      await WidgetsBinding.instance.endOfFrame;
      if (mounted && invalid.first.mounted) {
        await Scrollable.ensureVisible(invalid.first.context, alignment: .1);
      }
      return;
    }
    final data = ref.read(communityProvider).value ?? {};
    final uid = ref.read(communityRepositoryProvider).userId;
    String text(String key) => inputs[key]?.text.trim() ?? '';
    DateTime? starts;
    if (widget.kind == 'event' || widget.kind == 'walk') {
      if (!validTimeZone(venueZone)) {
        notice(context, "Выберите часовой пояс места прогулки".tr(context));
        return;
      }
      try {
        starts = venueWallTimeToUtc(when, venueZone!);
      } on FormatException catch (error) {
        notice(context, error.message);
        return;
      }
      if (!starts.isAfter(DateTime.now().toUtc())) {
        notice(context, "Выберите будущее время в месте прогулки".tr(context));
        return;
      }
    }
    Json values;
    switch (widget.kind) {
      case 'group':
        values = {
          'title_in': text('title'),
          'description_in': text('description'),
        };
        break;
      case 'profile':
        values = {
          'display_name': text('display_name'),
          'district': text('district'),
          'about': text('about'),
          'interests': text('interests'),
        };
        break;
      case 'pet':
        final age = int.tryParse(text('age'));
        if (age == null || age > 100) {
          notice(context, "Возраст должен быть от 0 до 100".tr(context));
          return;
        }
        values = {
          'name': text('name'),
          'kind': text('kind'),
          'age': age,
          'temperament': text('temperament'),
          if (widget.id != null) 'id': widget.id,
        };
        break;
      case 'event':
        final count = int.tryParse(text('capacity'));
        final duration = int.tryParse(text('duration'));
        if (duration == null ||
            duration < 15 ||
            duration > 480 ||
            duration % 15 != 0) {
          notice(context, 'От 15 до 480 минут с шагом 15 минут'.tr(context));
          return;
        }
        if (text('capacity').isNotEmpty &&
            (count == null || count < 2 || count > 100)) {
          notice(context, "От 2 до 100 участников".tr(context));
          return;
        }
        values = {
          'title_in': text('title'),
          'city_in': text('city'),
          'starts_in': starts!.toIso8601String(),
          'timezone_in': venueZone,
          'capacity_in': count,
          'duration_in': duration,
          'group_in': text('group_id').isEmpty ? null : text('group_id'),
          'description_in': text('description'),
          if (eventLocation != null) ...{
            'latitude_in': eventLocation!.latitude,
            'longitude_in': eventLocation!.longitude,
            'location_label_in': text('location_label'),
          },
        };
        break;
      default:
        if (petId == null ||
            !rows(
              data,
              'pets',
            ).any((p) => p['id'] == petId && p['owner_id'] == uid)) {
          notice(context, "Добавьте и выберите своего питомца".tr(context));
          return;
        }
        final duration = int.tryParse(text('duration'));
        if (duration == null || duration < 15 || duration > 240) {
          notice(context, "Продолжительность от 15 до 240 минут".tr(context));
          return;
        }
        values = {
          'pet_in': petId,
          'city_in': text('city'),
          'starts_in': starts!.toIso8601String(),
          'timezone_in': venueZone,
          'duration_in': duration,
          'district_in': text('walk_district'),
          'description_in': text('description'),
          'instructions_in': text('instructions'),
        };
    }
    setState(() => saving = true);
    try {
      var photoFailed = false;
      final created = await ref
          .read(communityProvider.notifier)
          .command(widget.kind, values);
      if (mounted &&
          created != null &&
          cover != null &&
          widget.kind == 'group') {
        try {
          await savePhoto(ref, 'group:$created', cover!);
        } catch (_) {
          photoFailed = true;
        }
      }
      if (mounted &&
          widget.kind == 'pet' &&
          cover != null &&
          (widget.id ?? created) != null) {
        try {
          await savePhoto(ref, 'pet:${widget.id ?? created}', cover!);
        } catch (_) {
          photoFailed = true;
        }
      }
      if (mounted && widget.kind == 'profile' && cover != null && uid != null) {
        try {
          await savePhoto(ref, 'profile:$uid', cover!);
        } catch (_) {
          photoFailed = true;
        }
      }
      if (mounted) {
        if (widget.kind == 'profile' && text('profile_city').isNotEmpty) {
          await ref
              .read(prototypeProvider.notifier)
              .setCity(text('profile_city'));
        }
        drafts.discard(draftKey);
        setState(() => allowPop = true);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) {
          return;
        }
        if (widget.welcome) {
          ref.invalidate(accountEntryProvider);
          context.go('/start');
        } else if (widget.kind == 'event' &&
            created != null &&
            GoRouter.maybeOf(context) != null) {
          context.pushReplacement('/event/$created');
        } else {
          Navigator.pop(context);
        }
        notice(
          context,
          photoFailed
              ? "Данные сохранены. Фото можно добавить позже.".tr(context)
              : "Сохранено".tr(context),
        );
      }
    } catch (_) {
      if (mounted) {
        notice(
          context,
          "Не удалось сохранить. Проверьте данные и соединение.".tr(context),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);
    final data = state.value ?? {};
    final uid = ref.read(communityRepositoryProvider).userId;
    final profile = findRow(data, 'profiles', uid) ?? {};
    final suggestion = ref.watch(profileSuggestionProvider);
    final currentName = (profile['display_name'] as String?) ?? '';
    final initialName =
        currentName.isEmpty || currentName == 'Новый пользователь'
        ? suggestion.name ?? ''
        : currentName;
    if (widget.kind == 'profile' &&
        widget.welcome &&
        restored == null &&
        state.hasValue &&
        suggestion.telegramPhoto != null &&
        !welcomePhotoRequested) {
      welcomePhotoRequested = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => previewWelcomeTelegramPhoto(),
      );
    }
    final pet = findRow(data, 'pets', widget.id) ?? {};
    final myPets = rows(
      data,
      'pets',
    ).where((p) => p['owner_id'] == uid).toList();
    if (!initialized && state.hasValue) {
      petId ??= myPets.firstOrNull?['id'];
      initialized = true;
    }
    if (widget.kind == 'walk' || widget.kind == 'event') {
      input('city', ref.read(prototypeProvider).city);
    }
    final title = switch (widget.kind) {
      'group' => "Создать сообщество".tr(context),
      'profile' =>
        widget.welcome
            ? "Давайте познакомимся".tr(context)
            : "Редактировать профиль".tr(context),
      'pet' =>
        widget.id == null
            ? "Добавить питомца".tr(context)
            : "Редактировать питомца".tr(context),
      'event' => "Создать встречу".tr(context),
      _ => "Попросить о выгуле".tr(context),
    };
    final savingLabel = switch (widget.kind) {
      'group' => "Создаём сообщество…".tr(context),
      'event' => "Создаём встречу…".tr(context),
      'walk' => "Публикуем заявку…".tr(context),
      'pet' =>
        widget.id == null
            ? "Добавляем питомца…".tr(context)
            : "Сохраняем питомца…".tr(context),
      _ => "Сохраняем профиль…".tr(context),
    };
    final saveButton = FilledButton(
      key: const ValueKey('form-save'),
      onPressed: saving || loadingPhoto || !state.hasValue ? null : save,
      child: saving
          ? _FormBusyLabel(savingLabel)
          : Text(
              (widget.kind == 'walk'
                      ? 'Опубликовать запрос'
                      : ['profile', 'pet'].contains(widget.kind) &&
                            !widget.welcome
                      ? 'Сохранить'
                      : formActionLabel(
                          widget.kind,
                          editing: widget.id != null,
                          welcome: widget.welcome,
                        ))
                  .tr(context),
            ),
    );
    return PopScope(
      canPop: allowPop || (!changed && !saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          leave();
        }
      },
      child: WalkingFormTheme(
        enabled: ['walk', 'profile', 'pet'].contains(widget.kind),
        child: Scaffold(
          appBar:
              ['walk', 'profile', 'pet'].contains(widget.kind) &&
                  widget.embedded
              ? PreferredSize(
                  preferredSize: Size.fromHeight(
                    studioSheetHeaderHeight(context, title),
                  ),
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: StudioReviewSheetHeader(
                      title: title,
                      onClose: () =>
                          changed || saving ? leave() : Navigator.pop(context),
                    ),
                  ),
                )
              : AppBar(
                  centerTitle: widget.kind == 'event'
                      ? true
                      : widget.embedded
                      ? false
                      : null,
                  titleSpacing: widget.embedded ? 20 : null,
                  automaticallyImplyLeading:
                      !widget.welcome && !widget.embedded,
                  actions: widget.embedded
                      ? [
                          IconButton(
                            tooltip: 'Закрыть'.tr(context),
                            icon: const Icon(LucideIcons.x),
                            onPressed: () => changed || saving
                                ? leave()
                                : Navigator.pop(context),
                          ),
                        ]
                      : null,
                  leading: widget.welcome || widget.embedded
                      ? null
                      : BackButton(
                          onPressed: () {
                            if (changed || saving) {
                              leave();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                  title: Text(
                    title,
                    style: ['walk', 'profile', 'pet'].contains(widget.kind)
                        ? walkingSheetTitleStyle
                        : Theme.of(context).textTheme.titleLarge,
                  ),
                ),
          bottomNavigationBar: widget.kind == 'event' && state.hasValue
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: saveButton,
                  ),
                )
              : null,
          body: state.hasError
              ? Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(communityProvider),
                    child: Text("Повторить загрузку профиля".tr(context)),
                  ),
                )
              : state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: form,
                  child: SingleChildScrollView(
                    padding:
                        ['walk', 'profile', 'pet'].contains(widget.kind) &&
                            widget.embedded
                        ? EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            20 + MediaQuery.paddingOf(context).bottom,
                          )
                        : const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (restored != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              "Черновик восстановлен. До сохранения он виден только вам."
                                  .tr(context),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        if (widget.kind == 'group') ...[
                          Row(
                            children: [
                              Tooltip(
                                message: 'Выбрать фото сообщества'.tr(context),
                                child: InkWell(
                                  key: const ValueKey('new-community-photo'),
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: saving
                                      ? null
                                      : () async {
                                          try {
                                            final bytes =
                                                await pickPreviewPhoto();
                                            if (mounted &&
                                                context.mounted &&
                                                bytes != null) {
                                              setState(() {
                                                cover = bytes;
                                                changed = true;
                                              });
                                            }
                                          } catch (_) {
                                            if (mounted && context.mounted) {
                                              notice(
                                                context,
                                                "Не удалось открыть фото. Максимум 8 МБ."
                                                    .tr(context),
                                              );
                                            }
                                          }
                                        },
                                  child: SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: cover == null
                                              ? Container(
                                                  width: 56,
                                                  height: 56,
                                                  color: Theme.of(context)
                                                      .inputDecorationTheme
                                                      .fillColor,
                                                  child: const Icon(
                                                    LucideIcons.users,
                                                  ),
                                                )
                                              : Image.memory(
                                                  cover!,
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.photo_camera_outlined,
                                              size: 16,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  (cover == null
                                          ? 'Выбрать фото сообщества'
                                          : 'Фото сообщества')
                                      .tr(context),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Фото — локальный предпросмотр до перезапуска, без публикации."
                                .tr(context),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          field('title', "Название сообщества".tr(context)),
                          field(
                            'description',
                            "О сообществе".tr(context),
                            max: 1000,
                            lines: 3,
                            required: false,
                          ),
                        ],
                        if (widget.kind == 'profile') ...[
                          if (widget.welcome) ...[
                            Text(
                              "Как вас будут видеть другие владельцы питомцев? Имя и фото можно изменить."
                                  .tr(context),
                            ),
                            const SizedBox(height: 24),
                          ],
                          petPhoto(context, {'id': uid}),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            children: [
                              for (final source in [
                                (
                                  ProfilePhotoProvider.google,
                                  suggestion.googlePhoto,
                                  'Google',
                                ),
                                (
                                  ProfilePhotoProvider.telegram,
                                  suggestion.telegramPhoto,
                                  'Telegram',
                                ),
                              ])
                                if (source.$2 != null)
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.account_circle_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      loadingPhoto
                                          ? "Загружаем…".tr(context)
                                          : "Фото из {p0}".tr(
                                              context,
                                              arguments: {'p0': source.$3},
                                            ),
                                    ),
                                    onPressed: saving || loadingPhoto
                                        ? null
                                        : () => loadProviderPhoto(
                                            source.$2!,
                                            source.$1,
                                          ),
                                  ),
                              if (cover != null)
                                TextButton(
                                  onPressed: saving
                                      ? null
                                      : () => setState(() {
                                          cover = null;
                                          changed = true;
                                        }),
                                  child: Text("Отменить выбор".tr(context)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          field(
                            'display_name',
                            "Имя".tr(context),
                            value: initialName,
                            max: 80,
                          ),
                          Text('Город'.tr(context)),
                          const SizedBox(height: 8),
                          CityField(
                            showLabel: false,
                            controller: input(
                              'profile_city',
                              ref.read(prototypeProvider).city,
                            ),
                            enabled: !saving,
                            onChanged: (city) => setState(() {
                              input('district').clear();
                              changed = true;
                            }),
                          ),
                          const SizedBox(height: 16),
                          field(
                            'district',
                            "Район".tr(context),
                            value: profile['district'] ?? '',
                            required: false,
                          ),
                          Text(
                            'В профиле виден район, а не точный адрес.'.tr(
                              context,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          field(
                            'about',
                            "О себе".tr(context),
                            value: profile['about'] ?? '',
                            max: 1000,
                            lines: 3,
                            required: false,
                          ),
                          field(
                            'interests',
                            "Интересы".tr(context),
                            value: profile['interests'] ?? '',
                            max: 300,
                            required: false,
                          ),
                        ],
                        if (widget.kind == 'pet') ...[
                          petPhoto(context, pet),
                          const SizedBox(height: 20),
                          field(
                            'name',
                            "Имя питомца".tr(context),
                            value: pet['name'] ?? '',
                            max: 80,
                          ),
                          Text('Вид'.tr(context)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (final (index, kind) in [
                                'Кот',
                                'Собака',
                              ].indexed) ...[
                                if (index > 0) const SizedBox(width: 8),
                                Expanded(
                                  child: Semantics(
                                    selected:
                                        input(
                                          'kind',
                                          pet['kind'] ?? 'Собака',
                                        ).text ==
                                        kind,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        backgroundColor:
                                            input(
                                                  'kind',
                                                  pet['kind'] ?? 'Собака',
                                                ).text ==
                                                kind
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : null,
                                        foregroundColor:
                                            input('kind').text == kind
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimary
                                            : null,
                                      ),
                                      onPressed: saving
                                          ? null
                                          : () => setState(() {
                                              input('kind').text = kind;
                                              changed = true;
                                            }),
                                      icon: Icon(
                                        index == 0
                                            ? LucideIcons.cat
                                            : LucideIcons.dog,
                                      ),
                                      label: Text(kind.tr(context)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          field(
                            'age',
                            "Возраст в годах".tr(context),
                            value: '${pet['age'] ?? 0}',
                            number: true,
                          ),
                          field(
                            'temperament',
                            "Характер и особенности".tr(context),
                            value: pet['temperament'] ?? '',
                            max: 1000,
                            lines: 3,
                            required: false,
                          ),
                        ],
                        if (widget.kind == 'event') ...[
                          Container(
                            key: const Key('event-public-callout'),
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.globe, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Открытая встреча. Любой пользователь может присоединиться, даже без участия в сообществе.'
                                        .tr(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          field('title', "Название встречи".tr(context)),
                        ],
                        if (widget.kind == 'walk') ...[
                          if (myPets.isEmpty)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add),
                              onPressed: saving
                                  ? null
                                  : () async {
                                      await context.push('/edit/pet');
                                      if (mounted) {
                                        setState(() {
                                          initialized = false;
                                        });
                                      }
                                    },
                              label: Text('Добавить питомца'.tr(context)),
                            )
                          else ...[
                            Text(
                              'Питомец'.tr(context),
                              style: walkingBodyStyle,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: petId,
                              style: walkingBodyStyle.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(counterText: ""),
                              items: myPets
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p['id'] as String,
                                      child: Text(p['name']),
                                    ),
                                  )
                                  .toList(),
                              onChanged: saving
                                  ? null
                                  : (v) => setState(() {
                                      petId = v;
                                      changed = true;
                                    }),
                            ),
                          ],
                          const SizedBox(height: 16),
                          WalkingDateField(
                            value: when,
                            firstDate: venueZone == null
                                ? DateTime.now()
                                : venueDateTime(DateTime.now(), venueZone!),
                            enabled: !saving,
                            onChanged: (value) => setState(() {
                              when = value;
                              changed = true;
                            }),
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: InkWell(
                              onTap: saving
                                  ? null
                                  : () => setState(
                                      () => walkLocationExpanded =
                                          !walkLocationExpanded,
                                    ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  bottom: 8,
                                ),
                                child: Text(
                                  venueZone == null
                                      ? 'Выберите часовой пояс места прогулки'
                                            .tr(context)
                                      : timeZoneLabel(
                                          venueZone!,
                                          locale: context.languageCode,
                                        ),
                                  style: walkingMetaStyle(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          field(
                            'duration',
                            'Длительность, минут'.tr(context),
                            value: '45',
                            number: true,
                          ),
                        ],
                        if (widget.kind == 'event' ||
                            widget.kind == 'walk') ...[
                          if (widget.kind == 'walk' && walkLocationExpanded)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: CityField(
                                fieldKey: const ValueKey('field.city'),
                                controller: input(
                                  'city',
                                  ref.read(prototypeProvider).city,
                                ),
                                enabled: !saving,
                                onChanged: (value) => setState(() {
                                  changed = true;
                                  if (widget.kind == 'walk') {
                                    input('walk_district').clear();
                                  }
                                  venueZone = cityTimeZone(value);
                                  eventLocation = null;
                                  inputs['location_label']?.clear();
                                }),
                              ),
                            ),
                          if (widget.kind == 'walk') ...[
                            field(
                              'walk_district',
                              'Район'.tr(context),
                              value: '${profile['district'] ?? ''}',
                              max: 100,
                              gapAfter: 4,
                              required: false,
                            ),
                            Text(
                              'Виден всем в запросе'.tr(context),
                              style: walkingMetaStyle(context),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (widget.kind == 'event') ...[
                            Text('Место'.tr(context)),
                            const SizedBox(height: 8),
                            Text(
                              '${'Необязательно'.tr(context)} · ${input('city').text}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Material(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: ListTile(
                                key: const ValueKey('event.choose-location'),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                leading: const Icon(
                                  LucideIcons.mapPin,
                                  size: 20,
                                ),
                                title: Text(
                                  eventLocation == null
                                      ? 'Выбрать публичную точку'.tr(context)
                                      : eventLocation!.displayLabel,
                                ),
                                trailing: eventLocation == null
                                    ? const Icon(
                                        LucideIcons.chevronRight,
                                        size: 20,
                                      )
                                    : IconButton(
                                        tooltip: 'Убрать точку встречи'.tr(
                                          context,
                                        ),
                                        onPressed: saving
                                            ? null
                                            : () => setState(() {
                                                eventLocation = null;
                                                inputs['location_label']
                                                    ?.clear();
                                                changed = true;
                                              }),
                                        icon: const Icon(
                                          LucideIcons.x,
                                          size: 20,
                                        ),
                                      ),
                                onTap: saving ? null : chooseEventPoint,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (eventLocation != null) ...[
                              field(
                                'location_label',
                                "Где собираемся".tr(context),
                                max: 160,
                                required: false,
                              ),
                              Text(
                                "Точку и описание увидят другие пользователи. Выбирайте публичное место."
                                    .tr(context),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 14),
                            ],
                          ],
                          if (widget.kind == 'event' || walkLocationExpanded)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text("Часовой пояс места".tr(context)),
                              subtitle: Text(
                                venueZone == null
                                    ? "Выберите перед сохранением".tr(context)
                                    : timeZoneLabel(
                                        venueZone!,
                                        locale: context.languageCode,
                                      ),
                              ),
                              trailing:
                                  cityTimeZone(
                                        inputs['city']?.text ??
                                            ref.read(prototypeProvider).city,
                                      ) ==
                                      null
                                  ? const Icon(Icons.expand_more)
                                  : null,
                              onTap:
                                  saving ||
                                      cityTimeZone(
                                            inputs['city']?.text ??
                                                ref
                                                    .read(prototypeProvider)
                                                    .city,
                                          ) !=
                                          null
                                  ? null
                                  : () async {
                                      final zone = await chooseVenueTimeZone(
                                        context,
                                        venueZone,
                                      );
                                      if (zone != null && mounted) {
                                        setState(() {
                                          venueZone = zone;
                                          changed = true;
                                        });
                                      }
                                    },
                            ),
                          if (widget.kind == 'event')
                            StudioTemporalFields(
                              value: when,
                              firstDate: venueZone == null
                                  ? DateTime.now()
                                  : venueDateTime(DateTime.now(), venueZone!),
                              enabled: !saving,
                              onChanged: (value) => setState(() {
                                when = value;
                                changed = true;
                              }),
                            ),
                          if (widget.kind != 'walk') const SizedBox(height: 14),
                          if (widget.kind == 'event') ...[
                            field(
                              'duration',
                              'Длительность, минут'.tr(context),
                              value: '60',
                              number: true,
                            ),
                            Text('От сообщества'.tr(context)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              isDense: false,
                              itemHeight: null,
                              initialValue: input(
                                'group_id',
                                widget.initialCommunity ?? '',
                              ).text,
                              validator: (value) =>
                                  value == null ||
                                      value.isEmpty ||
                                      rows(data, 'group_members').any(
                                        (m) =>
                                            m['group_id'] == value &&
                                            m['user_id'] == uid,
                                      )
                                  ? null
                                  : 'Сообщество недоступно'.tr(context),
                              items: [
                                if (input(
                                      'group_id',
                                      widget.initialCommunity ?? '',
                                    ).text.isNotEmpty &&
                                    !rows(data, 'groups').any(
                                      (g) =>
                                          g['id'] == input('group_id').text &&
                                          rows(data, 'group_members').any(
                                            (m) =>
                                                m['group_id'] == g['id'] &&
                                                m['user_id'] == uid,
                                          ),
                                    ))
                                  DropdownMenuItem(
                                    value: input('group_id').text,
                                    enabled: false,
                                    child: Text(
                                      'Сообщество недоступно'.tr(context),
                                    ),
                                  ),

                                DropdownMenuItem(
                                  value: '',
                                  child: Text('Личная встреча'.tr(context)),
                                ),
                                for (final g in rows(data, 'groups').where(
                                  (g) => rows(data, 'group_members').any(
                                    (m) =>
                                        m['group_id'] == g['id'] &&
                                        m['user_id'] == uid,
                                  ),
                                ))
                                  DropdownMenuItem(
                                    value: '${g['id']}',
                                    child: Text('${g['title']}'),
                                  ),
                              ],
                              onChanged: saving
                                  ? null
                                  : (v) => setState(() {
                                      input('group_id').text = v ?? '';
                                      changed = true;
                                    }),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Необязательно'.tr(context),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 20),
                            field(
                              'capacity',
                              "Количество участников".tr(context),
                              value: '8',
                              required: false,
                              number: true,
                            ),
                          ],
                          field(
                            'description',
                            (widget.kind == 'walk'
                                    ? 'Что нужно знать'
                                    : 'Публичное описание')
                                .tr(context),
                            max: 1000,
                            lines: widget.kind == 'walk' ? 4 : 3,
                            required: false,
                          ),
                          if (widget.kind == 'walk')
                            field(
                              'instructions',
                              'Передача питомца'.tr(context),
                              max: 2000,
                              lines: 4,
                              gapAfter: 4,
                              required: false,
                            ),
                          if (widget.kind == 'walk')
                            Text(
                              'Только участникам прогулки'.tr(context),
                              style: walkingMetaStyle(context),
                            ),
                        ],
                        SizedBox(height: widget.kind == 'walk' ? 20 : 16),
                        if (loadingPhoto) ...[
                          Semantics(
                            liveRegion: true,
                            child: _FormBusyLabel(
                              "Загружаем фото. Затем можно сохранить.".tr(
                                context,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (widget.kind != 'event') saveButton,
                        if (ref.read(communityRepositoryProvider).isDemo)
                          Text(
                            'Демо: изменения хранятся в памяти.'.tr(context),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _FormBusyLabel extends StatelessWidget {
  const _FormBusyLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ExcludeSemantics(
        child: SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: .38),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Flexible(child: Text(label)),
    ],
  );
}

void showStudioEditSheet(
  BuildContext context, {
  required String kind,
  String? id,
}) => showStudioSelectionSheet<void>(
  context: context,
  builder: (ctx) => SizedBox(
    height: MediaQuery.sizeOf(ctx).height * .88,
    child: EditScreen(kind: kind, id: id, embedded: true),
  ),
);
