import 'portfolio_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import '../../core/storage/prototype_store.dart';
import '../../core/ui/components.dart';
import '../../core/backend/backend.dart';
import 'place_contributions.dart';
import 'live_map.dart';
import 'location_service.dart';
import 'places_list_screen.dart';

class AddPlaceScreen extends ConsumerStatefulWidget {
  const AddPlaceScreen({super.key});
  @override
  ConsumerState<AddPlaceScreen> createState() => _AddPlaceState();
}

class _AddPlaceState extends ConsumerState<AddPlaceScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), description = TextEditingController();
  final id = newPlaceId();
  String category = 'Парк';
  (double, double)? point;
  bool saving = false;
  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> choosePoint() async {
    final next = await Navigator.of(context).push<(double, double)>(
      MaterialPageRoute(
        builder: (_) =>
            PlacePositionPicker(city: ref.read(prototypeProvider).city),
      ),
    );
    if (mounted && next != null) setState(() => point = next);
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (point == null) {
      notice(context, 'Отметьте место на карте');
      return;
    }
    setState(() => saving = true);
    try {
      await ref
          .read(placeContributionsProvider.notifier)
          .submit(
            id: id,
            name: name.text,
            category: category,
            city: ref.read(prototypeProvider).city,
            description: description.text,
            latitude: point!.$1,
            longitude: point!.$2,
          );
      if (mounted) {
        Navigator.pop(context);
        notice(
          context,
          AppConfig.backendEnabled
              ? 'Место отправлено на проверку. Отметка пока видна только вам.'
              : 'Место добавлено в демо-карту до перезапуска.',
        );
      }
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'Не удалось добавить место. Проверьте данные и соединение.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Добавить место')),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          Text(
            'Ваше открытие для других',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Добавляйте публичные места. Не отмечайте свой дом, частный адрес или положение другого человека.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          TextFormField(
            textAlignVertical: TextAlignVertical.top,
            key: const Key('new-place-name'),
            controller: name,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Название',
              counterText: '',
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Введите название' : null,
          ),
          const SizedBox(height: 16),
          PlaceSelect<String>(
            label: 'Категория',
            value: category,
            choices: const {
              'Парк': 'Парк',
              'Кафе': 'Кафе',
              'Площадка': 'Площадка',
              'Ресторан': 'Ресторан',
              'Зоомагазин': 'Зоомагазин',
              'Ветклиника': 'Ветклиника',
            },
            onChanged: (v) => setState(() => category = v),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.add_location_alt_outlined),
            title: Text(point == null ? 'Отметить на карте' : 'Точка выбрана'),
            subtitle: Text(
              point == null
                  ? ref.watch(prototypeProvider).city
                  : '${point!.$1.toStringAsFixed(5)}, ${point!.$2.toStringAsFixed(5)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: saving ? null : choosePoint,
          ),
          const SizedBox(height: 16),
          TextFormField(
            textAlignVertical: TextAlignVertical.top,
            controller: description,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Что здесь интересного?',
              hintText: 'Публичное описание, без личных сведений',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Допуск питомцев пока не уточнён. После проверки место появится в общем каталоге.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (point == null) ...[
            Text(
              'Перед отправкой отметьте место на карте.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
          ],
          FilledButton(
            onPressed: saving ? null : save,
            child: saving
                ? const _PlaceBusyLabel('Отправляем место…')
                : const Text('Добавить место'),
          ),
          if (!AppConfig.backendEnabled) const DemoCaption(),
        ],
      ),
    ),
  );
}

class PlacePositionPicker extends ConsumerStatefulWidget {
  const PlacePositionPicker({required this.city, super.key});
  final String city;
  @override
  // Select the offline adapter before native map lifecycle subscriptions start.
  ConsumerState<PlacePositionPicker> createState() =>
      // ignore: no_logic_in_create_state
      AppConfig.portfolio ? PortfolioPositionState() : _PositionState();
}

class _PositionState extends ConsumerState<PlacePositionPicker> {
  MapboxMap? map;
  bool busy = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Положение места')),
    body: Stack(
      children: [
        Positioned.fill(
          child: LiveMap(
            places: const [],
            fullscreen: true,
            onPlace: (_) {},
            onReady: (value) async {
              if (mounted) setState(() => map = value);
              if (widget.city != 'Минск') {
                try {
                  final center = await ref
                      .read(locationServiceProvider)
                      .cityCenter(widget.city);
                  if (mounted) {
                    await value.setCamera(
                      CameraOptions(
                        center: Point(
                          coordinates: Position(
                            center.longitude,
                            center.latitude,
                          ),
                        ),
                        zoom: 13,
                      ),
                    );
                  }
                } catch (_) {
                  if (mounted && context.mounted) {
                    notice(
                      context,
                      'Город не найден. Переместите карту вручную.',
                    );
                  }
                }
              }
            },
          ),
        ),
        const Center(child: IgnorePointer(child: SelectedPlacePin())),
        Positioned(
          left: 24,
          right: 24,
          bottom: 40,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Переместите карту: метка в центре — ваше место.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                if (map == null) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      AppConfig.mapboxToken.isEmpty
                          ? 'Карта не настроена. Выбор точки недоступен.'
                          : 'Выбор точки станет доступен после загрузки карты.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: map == null || busy
                      ? null
                      : () async {
                          setState(() => busy = true);
                          try {
                            final camera = await map!.getCameraState();
                            if (mounted && context.mounted) {
                              Navigator.pop(context, (
                                camera.center.coordinates.lat.toDouble(),
                                camera.center.coordinates.lng.toDouble(),
                              ));
                            }
                          } catch (_) {
                            if (mounted && context.mounted) {
                              notice(
                                context,
                                'Карта недоступна. Попробуйте ещё раз.',
                              );
                            }
                          } finally {
                            if (mounted) setState(() => busy = false);
                          }
                        },
                  child: busy
                      ? const _PlaceBusyLabel('Выбираем точку…')
                      : const Text('Выбрать эту точку'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class SelectedPlacePin extends StatelessWidget {
  const SelectedPlacePin({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Выбранная точка места',
    child: Transform.translate(
      offset: const Offset(0, -20),
      child: CustomPaint(
        size: const Size(40, 48),
        painter: _PlacePinPainter(
          Theme.of(context).colorScheme.onSurface,
          Theme.of(context).colorScheme.surface,
        ),
      ),
    ),
  );
}

class _PlacePinPainter extends CustomPainter {
  const _PlacePinPainter(this.ink, this.surface);
  final Color ink, surface;
  @override
  void paint(Canvas canvas, Size size) {
    final pin = Path()
      ..moveTo(20, 44)
      ..cubicTo(17, 38, 6, 28, 6, 18)
      ..arcToPoint(const Offset(34, 18), radius: const Radius.circular(14))
      ..cubicTo(34, 28, 23, 38, 20, 44)
      ..close();
    canvas.drawPath(pin, Paint()..color = ink);
    canvas.drawCircle(const Offset(20, 18), 5, Paint()..color = surface);
  }

  @override
  bool shouldRepaint(_PlacePinPainter old) =>
      old.ink != ink || old.surface != surface;
}

class _PlaceBusyLabel extends StatelessWidget {
  const _PlaceBusyLabel(this.label);
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
