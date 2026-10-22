import '../../core/ui/studio_pickers.dart';
import '../../core/location/city_directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/media/preview_photos.dart';
import '../../core/theme/studio_theme.dart';
import '../../core/time/time_zone_picker.dart';
import '../../core/ui/components.dart';
import '../../core/ui/studio_review.dart';
import '../../l10n/localization.dart';
import '../nearby/city_sheet.dart';
import '../walks/account_mode.dart';
import 'first_action_screen.dart';
import 'onboarding_widgets.dart';
import '../../core/time/display_time.dart';
import 'onboarding_controller.dart';
import 'profile_suggestion.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final scroll = ScrollController();
  final inputs = <String, TextEditingController>{};
  final nodes = <String, FocusNode>{};
  final anchors = <String, GlobalKey>{};
  String? accountId;
  @override
  void dispose() {
    scroll.dispose();
    for (final c in inputs.values) {
      c.dispose();
    }
    for (final n in nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  OnboardingController get controller => ref.read(onboardingProvider.notifier);
  Future<void> next({bool skip = false}) async {
    FocusScope.of(context).unfocus();
    await controller.advance(
      skipPet: skip,
      writePhoto: (id, bytes) => savePhoto(ref, id, bytes),
    );
    if (!mounted) return;
    final d = ref.read(onboardingProvider).value;
    if (d?.errors.isNotEmpty == true) {
      final field = d!.errors.keys.first;
      nodes[field]?.requestFocus();
      final target = anchors[field]?.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(target, alignment: .4);
      }
    } else if (scroll.hasClients) {
      scroll.jumpTo(0);
    }
  }

  Future<void> chooseCity(OnboardingDraft d) => showStudioSelectionSheet<void>(
    context: context,
    builder: (sheetContext) => Consumer(
      builder: (sheetContext, sheetRef, _) {
        final latest = sheetRef.watch(onboardingProvider).value;
        return CitySheet(
          onboarding: true,
          locating: latest?.locating ?? false,
          locationError: latest?.errors['city'],
          city: d.text('city'),
          onSelected: (city) {
            controller.city(city);
            Navigator.pop(sheetContext);
          },
          onLocate: () async {
            final found = await controller.locateCity();
            if (found && sheetContext.mounted) Navigator.pop(sheetContext);
            if (!found && sheetContext.mounted) {
              notice(
                sheetContext,
                'Местоположение недоступно. Выберите город вручную.'.tr(
                  sheetContext,
                ),
              );
            }
          },
        );
      },
    ),
  );

  Future<void> choosePhoto(bool pet) async {
    try {
      final bytes = await pickPreviewPhoto(maxInputBytes: 5 * 1024 * 1024);
      if (mounted && bytes != null) controller.photo(bytes, pet: pet);
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'Не удалось загрузить фото. Можно выбрать своё или добавить позже.'
              .tr(context),
        );
      }
    }
  }

  Widget error(String? value) => value == null
      ? const SizedBox.shrink()
      : Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: 16,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xffffb4ab)
                    : const Color(0xffb3261e)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value.tr(context),
                  style: TextStyle(
                    fontFamily: 'Golos Text',
                    fontSize: 12,
                    height: 1.5,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xffffb4ab)
                        : const Color(0xffb3261e)),
                  ),
                ),
              ),
            ],
          ),
        );
  InputBorder? invalidBorder(String? message, {bool focused = false}) =>
      message == null
      ? null
      : OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xffffb4ab)
                : const Color(0xffb3261e),
            width: focused ? 2 : 1,
          ),
        );

  Widget field(
    OnboardingDraft d,
    String key,
    String label, {
    String? hint,
    bool optional = false,
    bool multiline = false,
    double top = 20,
  }) {
    final input = inputs.putIfAbsent(
      key,
      () => TextEditingController(text: d.text(key)),
    );
    if (input.text != d.text(key)) input.text = d.text(key);
    return Padding(
      key: anchors.putIfAbsent(key, GlobalKey.new),
      padding: EdgeInsets.only(top: top),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label.tr(context)),
          const SizedBox(height: 8),
          TextField(
            key: ValueKey('onboarding-$key'),
            controller: input,
            focusNode: nodes.putIfAbsent(key, FocusNode.new),
            enabled: !d.busy,
            minLines: multiline ? 3 : 1,
            maxLines: multiline ? 4 : 1,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) => controller.field(key, value),
            decoration: InputDecoration(
              enabledBorder: invalidBorder(d.errors[key]),
              focusedBorder: invalidBorder(d.errors[key], focused: true),
            ),
          ),
          if (d.errors[key] != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: error(d.errors[key]),
            )
          else if (optional || hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                [
                  if (optional) 'Необязательно'.tr(context),
                  if (hint != null) hint.tr(context),
                ].join(' · '),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget photo(OnboardingDraft d, {bool pet = false}) {
    final bytes = pet ? d.petPhoto : d.photo;
    final suggestion = ref.watch(profileSuggestionProvider);
    final source = ref.watch(onboardingSignInProvider);
    return Column(
      children: [
        Center(
          child: SizedBox.square(
            dimension: 112,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Semantics(
                  button: true,
                  label: 'Выбрать фото'.tr(context),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: d.busy || d.photoBusy
                        ? null
                        : () => choosePhoto(pet),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: SizedBox.square(
                        dimension: 112,
                        child: bytes != null
                            ? Image.memory(bytes, fit: BoxFit.cover)
                            : pet
                            ? ColoredBox(
                                color: StudioColors.of(context).tint,
                                child: Icon(
                                  LucideIcons.pawPrint,
                                  size: 40,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                              )
                            : IconTheme(
                                data: IconThemeData(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                                child: IdentityPicture(
                                  id: 'profile:${d.accountId}',
                                  name: '',
                                  icon: LucideIcons.userRound,
                                  size: 112,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: IgnorePointer(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: StudioColors.lime,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 3,
                        ),
                      ),
                      child: d.photoBusy
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              LucideIcons.camera,
                              size: 18,
                              color: StudioColors.onLime,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'По желанию · можно добавить позже'.tr(context),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
        ),
        if (!pet && source != null) ...[
          const SizedBox(height: 12),
          Text(
            '${'Вход через'.tr(context)} $source. ${((source == 'Apple' && d.text('name').isEmpty) ? 'Имя не передано. Укажите, как вас будут видеть в приложении.' : 'Проверьте имя и фото — их можно изменить.').tr(context)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (!pet && source == 'Telegram') ...[
          const SizedBox(height: 8),
          Text(
            'Для этого входа email необязателен.'.tr(context),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (!pet)
          for (final (uri, provider, name) in [
            (suggestion.googlePhoto, ProfilePhotoProvider.google, 'Google'),
            (
              suggestion.telegramPhoto,
              ProfilePhotoProvider.telegram,
              'Telegram',
            ),
          ])
            if (uri != null &&
                provider == ProfilePhotoProvider.google &&
                d.photo == null)
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      textStyle: const TextStyle(
                        fontFamily: 'Golos Text',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: d.busy || d.photoBusy
                        ? null
                        : () => controller.importPhoto(uri, provider),
                    child: Text(
                      'Фото из {p0}'.tr(context, arguments: {'p0': name}),
                    ),
                  ),
                ),
              ),
        if (d.errors['photo'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: error(d.errors['photo']),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(onboardingProvider);
    return async.when(
      loading: () => OnboardingFrame(
        child: StudioReviewState(
          title: 'Загружаем профиль…'.tr(context),
          loading: true,
        ),
      ),
      error: (_, _) => OnboardingFrame(
        child: StudioReviewState(
          title: 'Не удалось загрузить'.tr(context),
          message: 'Проверьте соединение и попробуйте снова.'.tr(context),
          icon: LucideIcons.cloudOff,
          action: OutlinedButton(
            onPressed: () => ref.invalidate(onboardingProvider),
            child: Text('Повторить'.tr(context)),
          ),
        ),
      ),
      data: (d) {
        if (d.alreadyComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go(d.helper ? '/requests' : '/nearby');
          });
          return OnboardingFrame(
            child: StudioReviewState(
              title: 'Загружаем профиль…'.tr(context),
              loading: true,
            ),
          );
        }
        if (d.step == OnboardingStep.ready) {
          return FirstActionScreen(onBack: controller.back);
        }
        if (accountId != d.accountId) {
          for (final input in inputs.values) {
            input.clear();
          }
          accountId = d.accountId;
        }
        final sequence = d.helper
            ? [
                OnboardingStep.role,
                OnboardingStep.profile,
                OnboardingStep.preferences,
                OnboardingStep.availability,
              ]
            : [OnboardingStep.role, OnboardingStep.profile, OnboardingStep.pet];
        final step = sequence.indexOf(d.step);
        final (title, lead) = switch (d.step) {
          OnboardingStep.role => (
            'Как вы хотите участвовать?',
            'Выберите, что вам сейчас нужно. Роль можно изменить в настройках.',
          ),
          OnboardingStep.profile => (
            'Познакомимся',
            'Имя поможет узнать вас в чатах. Остальные детали можно добавить позже.',
          ),
          OnboardingStep.pet => (
            'Кто гуляет с вами?',
            'Добавьте питомца, чтобы познакомить его с соседями. Этот шаг можно пропустить.',
          ),
          OnboardingStep.preferences => (
            'С кем вам комфортно?',
            'Эти детали помогут владельцам выбрать помощника для своего питомца.',
          ),
          _ => (
            'Когда вы свободны?',
            'Обычная доступность на неделю. О конкретной прогулке договоритесь в чате.',
          ),
        };
        return OnboardingFrame(
          step: step,
          total: sequence.length,
          scroll: scroll,
          onBack: step > 0 && !d.busy ? controller.back : null,
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: d.busy || d.photoBusy || d.locating
                    ? null
                    : () => next(),
                child: d.busy
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text('Сохраняем профиль…'.tr(context)),
                          ),
                        ],
                      )
                    : Text(
                        (d.step == OnboardingStep.pet ||
                                    d.step == OnboardingStep.availability
                                ? 'Завершить настройку'
                                : 'Продолжить')
                            .tr(context),
                      ),
              ),
              if (d.step == OnboardingStep.pet)
                TextButton(
                  onPressed: d.busy ? null : () => next(skip: true),
                  child: Text('Добавлю позже'.tr(context)),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title.tr(context), style: onboardingHeading),
              const SizedBox(height: 12),
              Text(
                lead.tr(context),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (d.failure != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: error(d.failure),
                ),
              if (d.step == OnboardingStep.role) ...roleChoices(d),
              if (d.step == OnboardingStep.profile) ...[
                photo(d),
                field(
                  d,
                  'name',
                  'Ваше имя',
                  top: ref.watch(onboardingSignInProvider) == null ? 24 : 20,
                  hint: 'Как вас будут видеть другие люди',
                ),
                Padding(
                  key: anchors.putIfAbsent('city', GlobalKey.new),
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Город'.tr(context)),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('onboarding-city'),
                        readOnly: true,
                        enabled: !d.busy,
                        controller:
                            (inputs.putIfAbsent(
                                'city',
                                () => TextEditingController(),
                              )
                              ..text = knownCity(d.text('city')) == null
                                  ? d.text('city')
                                  : '${knownCity(d.text('city'))!.displayName} · ${countryName(knownCity(d.text('city'))!.isoCountry, context.languageCode)}'),
                        focusNode: nodes.putIfAbsent('city', FocusNode.new),
                        decoration: InputDecoration(
                          hintText: 'Определить мой город'.tr(context),
                          suffixIcon: d.locating
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.chevronDown),
                          enabledBorder: invalidBorder(d.errors['city']),
                          focusedBorder: invalidBorder(
                            d.errors['city'],
                            focused: true,
                          ),
                        ),
                        onTap: () => chooseCity(d),
                      ),
                      if (d.errors['city'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: error(d.errors['city']),
                        ),
                    ],
                  ),
                ),
                field(
                  d,
                  'district',
                  'Район',
                  hint:
                      'Укажите район, а не адрес. Точное местоположение не публикуется.',
                  optional: true,
                ),
              ],
              if (d.step == OnboardingStep.pet) ...[
                photo(d, pet: true),
                field(d, 'petName', 'Имя питомца', top: 24),
                const SizedBox(height: 16),
                Text('Вид'.tr(context)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final kind in ['Кот', 'Собака'])
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: kind == 'Кот' ? 8 : 0,
                          ),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.all(12),
                              textStyle: TextStyle(
                                fontFamily: 'Golos Text',
                                fontSize: 16,
                                height: 1.5,
                                fontWeight: d.text('kind') == kind
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              side: BorderSide(
                                color: d.text('kind') == kind
                                    ? StudioColors.lime
                                    : StudioColors.of(context).line,
                              ),
                              backgroundColor: d.text('kind') == kind
                                  ? StudioColors.lime
                                  : null,
                              foregroundColor: d.text('kind') == kind
                                  ? StudioColors.onLime
                                  : null,
                            ),
                            onPressed: d.busy
                                ? null
                                : () => controller.field('kind', kind),
                            child: Text(kind.tr(context)),
                          ),
                        ),
                      ),
                  ],
                ),
                field(
                  d,
                  'habits',
                  'Характер и привычки',
                  optional: true,
                  multiline: true,
                ),
              ],
              if (d.step == OnboardingStep.preferences) ...[
                field(
                  d,
                  'experience',
                  'Опыт с животными',
                  top: 0,
                  multiline: true,
                  hint: 'Коротко о том, с кем вы гуляли или кого содержали',
                ),
                Padding(
                  key: anchors.putIfAbsent('sizes', GlobalKey.new),
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Размеры собак'.tr(context)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (size, label) in [
                            ('small', 'Небольшие'),
                            ('medium', 'Средние'),
                            ('large', 'Крупные'),
                          ])
                            OutlinedButton(
                              onPressed: d.busy
                                  ? null
                                  : () => controller.toggleSize(size),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: 'Golos Text',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                minimumSize: const Size(0, 44),
                                backgroundColor: d.sizes.contains(size)
                                    ? StudioColors.lime
                                    : null,
                                foregroundColor: d.sizes.contains(size)
                                    ? StudioColors.onLime
                                    : null,
                                side: d.errors['sizes'] != null
                                    ? BorderSide(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xffffb4ab)
                                            : const Color(0xffb3261e),
                                        width: 1,
                                      )
                                    : BorderSide(
                                        color: d.sizes.contains(size)
                                            ? StudioColors.lime
                                            : StudioColors.of(context).line,
                                      ),
                              ),
                              child: Text(label.tr(context)),
                            ),
                        ],
                      ),
                      if (d.errors['sizes'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: error(d.errors['sizes']),
                        ),
                    ],
                  ),
                ),
                field(
                  d,
                  'areas',
                  'Районы для прогулок',
                  hint: 'Публичные районы в выбранном городе',
                ),
                const SizedBox(height: 20),
                Text(
                  'Укажите район, а не адрес. Точное местоположение не публикуется.'
                      .tr(context),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.5),
                ),
              ],
              if (d.step == OnboardingStep.availability) ...availability(d),
            ],
          ),
        );
      },
    );
  }

  List<Widget> roleChoices(OnboardingDraft d) => [
    for (final (role, title, hint, icon) in [
      (
        'owner',
        'Владелец питомца',
        'Места, знакомства и помощь с прогулками',
        LucideIcons.pawPrint,
      ),
      (
        'helper',
        'Помощник по выгулу',
        'Откликайтесь на запросы и гуляйте с питомцами',
        LucideIcons.footprints,
      ),
      (
        'both',
        'Владелец и помощник',
        'Оба режима, общие чаты и история',
        LucideIcons.usersRound,
      ),
    ])
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Semantics(
          selected: d.role == role,
          button: true,
          child: Material(
            color: d.role == role
                ? StudioColors.of(context).tint
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: d.role == role
                    ? Theme.of(context).colorScheme.onSurface
                    : StudioColors.of(context).line,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: d.busy ? null : () => controller.chooseRole(role),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(icon, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.tr(context),
                            style: studioIdentityText.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hint.tr(context),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      key: ValueKey('onboarding-role-indicator-$role'),
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: d.role == role
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).textTheme.bodySmall!.color!,
                          width: d.role == role ? 6 : 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    if (d.role == 'both') ...[
      const SizedBox(height: 4),
      Text(
        'С какого режима начнём?'.tr(context),
        style: const TextStyle(
          fontFamily: 'Golos Text',
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      LayoutBuilder(
        builder: (context, constraints) {
          final stacked = MediaQuery.textScalerOf(context).scale(14) > 21;
          final width = stacked
              ? constraints.maxWidth
              : (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mode in ['owner', 'helper'])
                SizedBox(
                  width: width,
                  child: Semantics(
                    selected: d.mode == mode,
                    child: OutlinedButton(
                      key: ValueKey('onboarding-start-$mode'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: d.mode == mode
                            ? StudioColors.lime
                            : Colors.transparent,
                        foregroundColor: d.mode == mode
                            ? StudioColors.onLime
                            : Theme.of(context).colorScheme.onSurface,
                        side: BorderSide(
                          color: d.mode == mode
                              ? StudioColors.lime
                              : StudioColors.of(context).line,
                        ),
                        textStyle: TextStyle(
                          fontFamily: 'Golos Text',
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: d.mode == mode
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      onPressed: d.busy
                          ? null
                          : () => controller.chooseRole('both', mode: mode),
                      child: Text(
                        (mode == 'owner'
                                ? 'Владелец питомца'
                                : 'Помощник по выгулу')
                            .tr(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
    SizedBox(height: d.role == 'both' ? 36 : 8),
    Text(
      'Один аккаунт для всех ролей. Своего питомца помощнику иметь не обязательно.'
          .tr(context),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
    ),
  ];
  ButtonStyle scheduleStyle({bool invalid = false, bool small = false}) =>
      OutlinedButton.styleFrom(
        backgroundColor: StudioColors.of(context).tint,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        side: BorderSide(
          color: invalid
              ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xffffb4ab)
                    : const Color(0xffb3261e))
              : StudioColors.of(context).line,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: Size(0, small ? 44 : 48),
        padding: EdgeInsets.all(small ? 10 : 12),
        textStyle: TextStyle(
          fontFamily: 'Golos Text',
          fontSize: small ? 14 : 16,
          fontWeight: FontWeight.w400,
        ),
      );
  List<Widget> availability(OnboardingDraft d) => [
    Padding(
      key: anchors.putIfAbsent('zone', GlobalKey.new),
      padding: EdgeInsets.zero,
      child: Text('Часовой пояс'.tr(context)),
    ),
    const SizedBox(height: 8),
    OutlinedButton(
      key: const ValueKey('onboarding-zone'),
      style: scheduleStyle(invalid: d.errors['zone'] != null),
      onPressed: d.busy
          ? null
          : () async {
              final zone = await chooseVenueTimeZone(
                context,
                d.zone,
                onboarding: true,
              );
              if (zone != null && mounted) controller.zone(zone);
            },
      child: Row(
        children: [
          Expanded(
            child: Text(
              d.zone.isEmpty
                  ? 'Выбрать'.tr(context)
                  : timeZoneLabel(d.zone, locale: context.languageCode),
            ),
          ),
          const Icon(LucideIcons.chevronDown, size: 22),
        ],
      ),
    ),
    if (d.errors['zone'] != null)
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: error(d.errors['zone']),
      ),
    for (var day = 0; day < 7; day++) ...[
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                [
                  'Понедельник',
                  'Вторник',
                  'Среда',
                  'Четверг',
                  'Пятница',
                  'Суббота',
                  'Воскресенье',
                ][day].tr(context),
              ),
            ),
            Switch(
              value: d.slots.any((s) => s.day == day),
              onChanged: d.busy
                  ? null
                  : (enabled) => controller.availability(
                      enabled
                          ? [
                              ...d.slots,
                              WeeklyAvailability(
                                day: day,
                                start: 540,
                                end: 1020,
                              ),
                            ]
                          : d.slots.where((s) => s.day != day).toList(),
                    ),
            ),
          ],
        ),
      ),
      for (final slot in d.slots.where((s) => s.day == day))
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              for (final start in [true, false]) ...[
                if (!start)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('—'),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: OutlinedButton(
                      key: ValueKey(
                        'onboarding-time-$day-${start ? 'start' : 'end'}',
                      ),
                      style: scheduleStyle(
                        invalid:
                            !start &&
                            d.errors['availability'] != null &&
                            slot.end <= slot.start,
                        small: true,
                      ),
                      onPressed: d.busy
                          ? null
                          : () async {
                              final minutes = start ? slot.start : slot.end;
                              final picked = await showStudioTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: minutes ~/ 60,
                                  minute: minutes % 60,
                                ),
                              );
                              if (!mounted || picked == null) return;
                              controller.availability(
                                d.slots
                                    .map(
                                      (s) => s == slot
                                          ? WeeklyAvailability(
                                              day: day,
                                              start: start
                                                  ? picked.hour * 60 +
                                                        picked.minute
                                                  : slot.start,
                                              end: start
                                                  ? slot.end
                                                  : picked.hour * 60 +
                                                        picked.minute,
                                            )
                                          : s,
                                    )
                                    .toList(),
                              );
                            },
                      child: Text(
                        TimeOfDay(
                          hour: (start ? slot.start : slot.end) ~/ 60,
                          minute: (start ? slot.start : slot.end) % 60,
                        ).format(context),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      if (d.errors['availability'] != null &&
          d.slots.where((s) => s.end <= s.start).firstOrNull?.day == day)
        Padding(
          key: anchors.putIfAbsent('availability', GlobalKey.new),
          padding: const EdgeInsets.only(top: 6),
          child: error(d.errors['availability']),
        ),
      const Divider(height: 24),
    ],
    if (d.errors['availability'] != null &&
        !d.slots.any((s) => s.end <= s.start))
      Padding(
        key: anchors.putIfAbsent('availability', GlobalKey.new),
        padding: const EdgeInsets.only(top: 6),
        child: error(d.errors['availability']),
      ),
  ];
}
