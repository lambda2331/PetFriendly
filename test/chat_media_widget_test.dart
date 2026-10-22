import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/chat/chat_screen.dart';
import 'package:petfriendly/features/chat/chat_media.dart';
import 'package:petfriendly/features/chat/chat_media_widgets.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'widget_test.dart' show MemoryPreferences;

class FixtureMedia extends ChatMediaService {
  final draft = MediaDraft(
    bytes: File('assets/branding/app-icon.png').readAsBytesSync(),
    kind: 'image',
    mime: 'image/png',
  );
  @override
  Future<MediaDraft?> pickImage() async => draft;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'Media composition / send / gallery preview works in $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(() async {
          for (final font in ['Manrope', 'Golos Text', 'MaterialIcons']) {
            final loader = FontLoader(font)
              ..addFont(
                rootBundle.load(
                  font == 'MaterialIcons'
                      ? 'fonts/MaterialIcons-Regular.otf'
                      : 'assets/fonts/${font == 'Manrope' ? 'Manrope' : 'GolosText'}.ttf',
                ),
              );
            await loader.load();
          }
        });
        final key = GlobalKey();
        final service = FixtureMedia();
        final repository = DemoCommunityRepository(seedSamples: false);
        repository.data['conversations'] = [
          {'id': 'fixture', 'kind': 'direct', 'target': demoAnna},
        ];
        repository.data['conversation_members'] = [
          {'conversation_id': 'fixture', 'user_id': repository.userId},
          {'conversation_id': 'fixture', 'user_id': demoAnna},
        ];
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesProvider.overrideWithValue(MemoryPreferences()),
              communityRepositoryProvider.overrideWithValue(repository),
              chatMediaServiceProvider.overrideWithValue(service),
            ],
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: studioTheme(brightness),
                home: const ChatScreen(id: 'fixture'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final context = tester.element(find.byType(ChatScreen));
          await precacheImage(MemoryImage(service.draft.bytes), context);
          if (context.mounted) {
            await precacheImage(
              ResizeImage(MemoryImage(service.draft.bytes), width: 600),
              context,
            );
          }
        });
        await tester.tap(find.byKey(const Key('attach-media')));
        await tester.pumpAndSettle();
        expect(find.text('Видео'), findsNothing);
        expect(find.byIcon(Icons.videocam_outlined), findsNothing);
        expect(find.byTooltip('Убрать вложение'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('message-input')),
          'Тестовое фото',
        );
        await tester.tap(find.byKey(const Key('send-message')));
        await tester.pumpAndSettle();
        expect(find.byType(ChatMediaTile), findsOneWidget);
        expect(find.text('Тестовое фото'), findsOneWidget);
        expect(find.byTooltip('Убрать вложение'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'docs/screenshots/chat-media-${brightness.name}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
