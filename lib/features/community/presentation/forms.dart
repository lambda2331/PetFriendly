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

class EditScreen extends ConsumerStatefulWidget {
  const EditScreen({
    required this.kind,
    this.id,
    this.welcome = false,
    super.key,
  });
  final String kind;
  final String? id;
  final bool welcome;
  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  final form = GlobalKey<FormState>();
  final inputs = <String, TextEditingController>{};
  bool saving = false, initialized = false;
  bool loadingPhoto = false;
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
    }
  }

  Future<void> leave() async {
    if (prompting || saving) return;
    prompting = true;
    final keep = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из формы?'),
        content: const Text(
          'Можно оставить черновик до закрытия приложения. Он не публикуется и не записывается на устройство.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Продолжить'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Удалить изменения'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Оставить черновик'),
          ),
        ],
      ),
    );
    prompting = false;
    if (keep == null || !mounted) return;
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
        notice(context, 'Фото недоступно. Выберите другое изображение.');
      }
    } finally {
      if (mounted) setState(() => loadingPhoto = false);
    }
  }

  Future<void> previewWelcomeTelegramPhoto() async {
    if (!mounted || cover != null || saving) return;
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
      if (mounted) setState(() => loadingPhoto = false);
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
    ValueChanged<String>? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
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
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: (text) {
        if (required && (text ?? '').trim().isEmpty) return 'Заполните поле';
        if (number) {
          final n = int.tryParse(text ?? '');
          if (n == null || n < 0) return 'Введите число';
        }
        return null;
      },
    ),
  );
  Future<void> date() async {
    final today = venueZone == null
        ? DateTime.now()
        : venueDateTime(DateTime.now(), venueZone!);
    final day = await showDatePicker(
      context: context,
      initialDate: when,
      helpText: widget.kind == 'walk' ? 'Дата прогулки' : 'Дата встречи',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
      firstDate: DateTime.utc(today.year, today.month, today.day),
      lastDate: DateTime.utc(today.year, today.month, today.day + 365),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(when),
      helpText: 'Время начала',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
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

  Future<void> save() async {
    if (saving) return;
    if (!form.currentState!.validate()) return;
    final data = ref.read(communityProvider).value ?? {};
    final uid = ref.read(communityRepositoryProvider).userId;
    String text(String key) => inputs[key]?.text.trim() ?? '';
    DateTime? starts;
    if (widget.kind == 'event' || widget.kind == 'walk') {
      if (!validTimeZone(venueZone)) {
        notice(context, 'Выберите часовой пояс места прогулки');
        return;
      }
      try {
        starts = venueWallTimeToUtc(when, venueZone!);
      } on FormatException catch (error) {
        notice(context, error.message);
        return;
      }
      if (!starts.isAfter(DateTime.now().toUtc())) {
        notice(context, 'Выберите будущее время в месте прогулки');
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
          notice(context, 'Возраст должен быть от 0 до 100');
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
        if (count == null || count < 2 || count > 100) {
          notice(context, 'От 2 до 100 участников');
          return;
        }
        values = {
          'title_in': text('title'),
          'city_in': text('city'),
          'starts_in': starts!.toIso8601String(),
          'timezone_in': venueZone,
          'capacity_in': count,
          'description_in': text('description'),
        };
        break;
      default:
        if (petId == null ||
            !rows(
              data,
              'pets',
            ).any((p) => p['id'] == petId && p['owner_id'] == uid)) {
          notice(context, 'Добавьте и выберите своего питомца');
          return;
        }
        final duration = int.tryParse(text('duration'));
        if (duration == null || duration < 15 || duration > 240) {
          notice(context, 'Продолжительность от 15 до 240 минут');
          return;
        }
        values = {
          'pet_in': petId,
          'city_in': text('city'),
          'starts_in': starts!.toIso8601String(),
          'timezone_in': venueZone,
          'duration_in': duration,
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
      if (mounted && widget.kind == 'profile' && cover != null && uid != null) {
        try {
          await savePhoto(ref, 'profile:$uid', cover!);
        } catch (_) {
          photoFailed = true;
        }
      }
      if (mounted) {
        drafts.discard(draftKey);
        setState(() => allowPop = true);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        if (widget.welcome) {
          ref.invalidate(accountEntryProvider);
          context.go('/start');
        } else {
          Navigator.pop(context);
        }
        notice(
          context,
          photoFailed
              ? 'Данные сохранены. Фото можно добавить позже.'
              : 'Сохранено',
        );
      }
    } catch (_) {
      if (mounted) {
        notice(context, 'Не удалось сохранить. Проверьте данные и соединение.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
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
    final title = switch (widget.kind) {
      'group' => 'Создать сообщество',
      'profile' =>
        widget.welcome ? 'Давайте познакомимся' : 'Редактировать профиль',
      'pet' => widget.id == null ? 'Добавить питомца' : 'Редактировать питомца',
      'event' => 'Создать встречу',
      _ => 'Попросить о выгуле',
    };
    final savingLabel = switch (widget.kind) {
      'group' => 'Создаём сообщество…',
      'event' => 'Создаём встречу…',
      'walk' => 'Публикуем заявку…',
      'pet' => widget.id == null ? 'Добавляем питомца…' : 'Сохраняем питомца…',
      _ => 'Сохраняем профиль…',
    };
    return PopScope(
      canPop: allowPop || (!changed && !saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.welcome,
          leading: widget.welcome
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
          title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        body: state.hasError
            ? Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(communityProvider),
                  child: const Text('Повторить загрузку профиля'),
                ),
              )
            : state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: form,
                child: PageBody(
                  children: [
                    if (restored != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Черновик восстановлен. До сохранения он виден только вам.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (widget.kind == 'group') ...[
                      CommunityCover(id: 'new-group', previewBytes: cover),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 18,
                        ),
                        label: const Text('Выбрать фото сообщества'),
                        onPressed: saving
                            ? null
                            : () async {
                                try {
                                  final bytes = await pickPreviewPhoto();
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
                                      'Не удалось открыть фото. Максимум 8 МБ.',
                                    );
                                  }
                                }
                              },
                      ),
                      Text(
                        'Фото — локальный предпросмотр до перезапуска, без публикации.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      field('title', 'Название сообщества'),
                      field(
                        'description',
                        'О сообществе',
                        max: 1000,
                        lines: 3,
                        required: false,
                      ),
                    ],
                    if (widget.kind == 'profile') ...[
                      if (widget.welcome) ...[
                        const Text(
                          'Как вас будут видеть другие владельцы питомцев? Имя и фото можно изменить.',
                        ),
                        const SizedBox(height: 24),
                      ],
                      Center(
                        child: cover == null
                            ? IdentityPicture(
                                id: 'profile:$uid',
                                icon: Icons.person_outline,
                                size: 88,
                              )
                            : ClipOval(
                                child: Image.memory(
                                  cover!,
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
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
                                      ? 'Загружаем…'
                                      : 'Фото из ${source.$3}',
                                ),
                                onPressed: saving || loadingPhoto
                                    ? null
                                    : () => loadProviderPhoto(
                                        source.$2!,
                                        source.$1,
                                      ),
                              ),
                          TextButton.icon(
                            icon: const Icon(
                              Icons.photo_library_outlined,
                              size: 18,
                            ),
                            label: const Text('Выбрать фото'),
                            onPressed: saving || loadingPhoto
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
                                          'Не удалось открыть фото. Максимум 8 МБ.',
                                        );
                                      }
                                    }
                                  },
                          ),
                          if (cover != null)
                            TextButton(
                              onPressed: saving
                                  ? null
                                  : () => setState(() {
                                      cover = null;
                                      changed = true;
                                    }),
                              child: const Text('Отменить выбор'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      field('display_name', 'Имя', value: initialName, max: 80),
                      field(
                        'district',
                        'Район',
                        value: profile['district'] ?? '',
                        required: false,
                      ),
                      field(
                        'about',
                        'О себе',
                        value: profile['about'] ?? '',
                        max: 1000,
                        lines: 3,
                        required: false,
                      ),
                      field(
                        'interests',
                        'Интересы',
                        value: profile['interests'] ?? '',
                        max: 300,
                        required: false,
                      ),
                    ],
                    if (widget.kind == 'pet') ...[
                      field(
                        'name',
                        'Имя питомца',
                        value: pet['name'] ?? '',
                        max: 80,
                      ),
                      field(
                        'kind',
                        'Вид животного',
                        value: pet['kind'] ?? 'Собака',
                      ),
                      field(
                        'age',
                        'Возраст в годах',
                        value: '${pet['age'] ?? 0}',
                        number: true,
                      ),
                      field(
                        'temperament',
                        'Характер и особенности',
                        value: pet['temperament'] ?? '',
                        max: 1000,
                        lines: 3,
                        required: false,
                      ),
                    ],
                    if (widget.kind == 'event') ...[
                      field('title', 'Название встречи'),
                      field(
                        'capacity',
                        'Количество участников',
                        value: '8',
                        number: true,
                      ),
                    ],
                    if (widget.kind == 'walk') ...[
                      if (myPets.isEmpty)
                        const Text('Сначала добавьте питомца в профиле.')
                      else
                        DropdownButtonFormField<String>(
                          initialValue: petId,
                          decoration: const InputDecoration(
                            labelText: 'Питомец',
                          ),
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
                      const SizedBox(height: 14),
                      field(
                        'duration',
                        'Продолжительность, минут',
                        value: '45',
                        number: true,
                      ),
                    ],
                    if (widget.kind == 'event' || widget.kind == 'walk') ...[
                      field(
                        'city',
                        'Город',
                        value: ref.read(prototypeProvider).city,
                        onChanged: (value) =>
                            setState(() => venueZone = cityTimeZone(value)),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Часовой пояс места'),
                        subtitle: Text(
                          venueZone == null
                              ? 'Выберите перед сохранением'
                              : timeZoneLabel(venueZone!),
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
                                          ref.read(prototypeProvider).city,
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
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Дата и время в месте прогулки'),
                        subtitle: Text(
                          '${when.day}.${when.month}.${when.year} · ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.edit_calendar_outlined),
                        onTap: saving ? null : date,
                      ),
                      const SizedBox(height: 14),
                      field(
                        'description',
                        'Публичное описание',
                        max: 1000,
                        lines: 3,
                        required: false,
                      ),
                      if (widget.kind == 'walk')
                        field(
                          'instructions',
                          'Приватные инструкции помощнику',
                          max: 2000,
                          lines: 3,
                          required: false,
                        ),
                    ],
                    const SizedBox(height: 16),
                    if (loadingPhoto) ...[
                      Semantics(
                        liveRegion: true,
                        child: _FormBusyLabel(
                          'Загружаем фото. Затем можно сохранить.',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    FilledButton(
                      onPressed: saving || loadingPhoto ? null : save,
                      child: saving
                          ? _FormBusyLabel(savingLabel)
                          : Text(
                              formActionLabel(
                                widget.kind,
                                editing: widget.id != null,
                                welcome: widget.welcome,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ref.read(communityRepositoryProvider).isDemo
                          ? 'Демо: изменения хранятся в памяти.'
                          : 'Личные данные доступны по правилам аккаунта.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
