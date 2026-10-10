import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/components.dart';
import '../community/data/community_repository.dart';

class PlaceFeedbackScreen extends ConsumerStatefulWidget {
  const PlaceFeedbackScreen({
    required this.id,
    this.correction = false,
    super.key,
  });
  final String id;
  final bool correction;
  @override
  ConsumerState<PlaceFeedbackScreen> createState() => _FeedbackState();
}

class _FeedbackState extends ConsumerState<PlaceFeedbackScreen> {
  final input = TextEditingController();
  int rating = 5;
  bool busy = false;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.correction ? 'Предложить исправление' : 'Отзыв о месте',
      ),
    ),
    body: PageBody(
      children: [
        ScreenIntro(
          widget.correction
              ? 'Что стоит\nуточнить?'
              : 'Поделитесь\nвпечатлением.',
          compact: true,
        ),
        const SizedBox(height: 20),
        if (!widget.correction) ...[
          DropdownButtonFormField<int>(
            initialValue: rating,
            decoration: const InputDecoration(labelText: 'Оценка'),
            items: [1, 2, 3, 4, 5]
                .map((i) => DropdownMenuItem(value: i, child: Text('$i ★')))
                .toList(),
            onChanged: busy ? null : (value) => rating = value ?? 5,
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          textAlignVertical: TextAlignVertical.top,
          controller: input,
          enabled: !busy,
          maxLines: 4,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: widget.correction
                ? 'Например, правила входа с собакой'
                : 'Ваш отзыв',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.correction
              ? 'Исправление будет проверено.'
              : 'Комментарий будет публичным. Не указывайте личные сведения.',
        ),
        const SizedBox(height: 20),
        if (busy) ...[
          Semantics(
            liveRegion: true,
            child: Text('Отправляем. Поля временно недоступны.'),
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  if (widget.correction && input.text.trim().isEmpty) {
                    notice(context, 'Опишите исправление');
                    return;
                  }
                  setState(() => busy = true);
                  try {
                    await ref.read(communityProvider.notifier).command(
                      widget.correction ? 'place_correction' : 'place_review',
                      {
                        'place_id': widget.id,
                        'body': input.text.trim(),
                        if (!widget.correction) 'rating': rating,
                      },
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      notice(context, 'Отправлено');
                    }
                  } catch (_) {
                    if (context.mounted) {
                      notice(
                        context,
                        'Не удалось отправить. Возможно, отзыв уже опубликован.',
                      );
                    }
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: Text(busy ? 'Отправляем…' : 'Отправить'),
        ),
      ],
    ),
  );
}
