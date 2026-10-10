import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/auth/profile_suggestion.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/community/presentation/forms.dart';
import 'account_entry_test.dart' show fixtureId;
import 'widget_test.dart' show MemoryPreferences;

const telegramPhoto = 'https://cdn4.telesco.pe/file/fixture.jpg';
Uint8List photoBytes() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAHXRFWHREZXNjcmlwdGlvbgBQUklWQVRFX0VYSUZfVEVTVNhRoysAAAARSURBVHicY/jPwMDwH4yAGAAd8AP909B9JgAAAABJRU5ErkJggg==',
);
Map<String, dynamic> telegramUser(Map<String, dynamic> metadata) => {
  'id': fixtureId,
  'aud': 'authenticated',
  'created_at': '2026-01-01T00:00:00Z',
  'app_metadata': {'provider': 'custom:telegram'},
  'user_metadata': metadata,
  'identities': [
    <String, dynamic>{
      'id': 'telegram-fixture',
      'user_id': fixtureId,
      'provider': 'custom:telegram',
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Telegram OIDC name and picture are accepted without an email or phone',
    () {
      final user = User.fromJson(
        telegramUser({
          'name': ' Анна\u0000   Тестовая ',
          'picture': telegramPhoto,
        }),
      );
      final suggestion = ProfileSuggestion.fromUser(user);
      expect(suggestion.name, 'Анна Тестовая');
      expect(suggestion.telegramPhoto.toString(), telegramPhoto);
      expect(suggestion.googlePhoto, isNull);
      expect(user!.email, isNull);
    },
  );
  test('Telegram handles split/nested names and linked identity claims', () {
    var data = telegramUser({
      'custom_claims': {
        'given_name': 'Анна',
        'family_name': 'Тестовая',
        'picture': telegramPhoto,
      },
    });
    expect(
      ProfileSuggestion.fromUser(User.fromJson(data)).name,
      'Анна Тестовая',
    );
    expect(
      ProfileSuggestion.fromUser(User.fromJson(data)).telegramPhoto.toString(),
      telegramPhoto,
    );
    data = telegramUser({
      'name': 'Other provider',
      'picture': 'https://lh3.googleusercontent.com/a/fixture',
    });
    data['identities'][0]['identity_data'] = {
      'name': 'Telegram Name',
      'picture': telegramPhoto,
    };
    final suggestion = ProfileSuggestion.fromUser(User.fromJson(data));
    expect(suggestion.name, 'Telegram Name');
    expect(suggestion.telegramPhoto.toString(), telegramPhoto);
    expect(
      ProfileSuggestion.fromUser(
        User.fromJson(
          telegramUser({
            'preferred_username': 'username-only',
            'name': 42,
            'picture': false,
          }),
        ),
      ).name,
      isNull,
    );
  });
  test('Only approved HTTPS Telegram image endpoints are accepted', () {
    expect(allowedTelegramPhoto(Uri.parse(telegramPhoto)), isTrue);
    expect(
      allowedTelegramPhoto(Uri.parse('https://t.me/i/userpic/320/fixture.jpg')),
      isTrue,
    );
    for (final uri in [
      'http://cdn4.telesco.pe/file/fixture.jpg',
      'https://cdn4.telesco.pe.attacker.test/file/a',
      'https://attacker.test/file/a',
      'https://127.0.0.1/file/a',
      'https://cdn4.telesco.pe:8443/file/a',
      'https://user:pass@cdn4.telesco.pe/file/a',
      'https://t.me/username',
      'https://cdn4.telesco.pe/file/a#fragment',
    ]) {
      expect(allowedTelegramPhoto(Uri.parse(uri)), isFalse, reason: uri);
    }
  });
  test(
    'Telegram photo drops metadata, sends no credentials, and rejects redirects',
    () async {
      final bytes = await downloadTelegramPhoto(
        Uri.parse(telegramPhoto),
        client: MockClient((request) async {
          expect(request.followRedirects, isFalse);
          expect(request.headers.containsKey('authorization'), isFalse);
          expect(request.headers.containsKey('apikey'), isFalse);
          return http.Response.bytes(
            photoBytes(),
            200,
            headers: {'content-type': 'image/png'},
          );
        }),
      );
      expect(
        utf8.decode(bytes, allowMalformed: true),
        isNot(contains('PRIVATE_EXIF_TEST')),
      );
      await expectLater(
        downloadTelegramPhoto(
          Uri.parse(telegramPhoto),
          client: MockClient(
            (_) async => http.Response(
              '',
              302,
              headers: {'location': 'https://attacker.test/avatar'},
            ),
          ),
        ),
        throwsStateError,
      );
    },
  );
  for (final existing in [false, true]) {
    test(
      'Welcome Telegram photo preserves existing storage picture=$existing',
      () async {
        var downloads = 0;
        final user = telegramUser({'name': 'Анна', 'picture': telegramPhoto});
        final client = SupabaseClient(
          'https://fixture.example',
          'fixture-key',
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith('/entity_photos')) {
              expect(request.url.queryParameters['target_id'], 'eq.$fixtureId');
              return http.Response(
                jsonEncode(
                  existing ? {'object_path': 'own-existing-photo'} : null,
                ),
                200,
                request: request,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response(
              jsonEncode({
                'access_token': 'synthetic-token',
                'refresh_token': 'synthetic-refresh',
                'expires_in': 3600,
                'token_type': 'bearer',
                'user': user,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        await client.auth.signInWithPassword(
          email: 'fixture@example.test',
          password: 'fixture',
        );
        final container = ProviderContainer(
          overrides: [
            backendProvider.overrideWithValue(client),
            providerPhotoDownloaderProvider.overrideWithValue((
              uri,
              provider,
            ) async {
              downloads++;
              expect(provider, ProfilePhotoProvider.telegram);
              return photoBytes();
            }),
          ],
        );
        addTearDown(() async {
          container.dispose();
          await client.dispose();
        });
        container.listen(authStateProvider, (_, _) {});
        await container.read(authStateProvider.future);
        final bytes = await container.read(welcomeTelegramPhotoProvider.future);
        expect(bytes == null, existing);
        expect(downloads, existing ? 0 : 1);
      },
    );
  }
  for (final welcome in [true, false]) {
    testWidgets(
      'Telegram photo auto-previews only during onboarding=$welcome',
      (tester) async {
        final repo = DemoCommunityRepository();
        repo.data['profiles']!.first['display_name'] = welcome
            ? 'Новый пользователь'
            : 'Мой псевдоним';
        var previews = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesProvider.overrideWithValue(MemoryPreferences()),
              communityRepositoryProvider.overrideWithValue(repo),
              profileSuggestionProvider.overrideWithValue(
                ProfileSuggestion(
                  name: 'Анна Тестовая',
                  telegramPhoto: Uri.parse(telegramPhoto),
                ),
              ),
              welcomeTelegramPhotoProvider.overrideWith((ref) async {
                previews++;
                return photoBytes();
              }),
            ],
            child: MaterialApp(
              theme: studioTheme(Brightness.light),
              home: EditScreen(kind: 'profile', welcome: welcome),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final field = tester.widget<TextFormField>(
          find.byKey(const ValueKey('field.display_name')),
        );
        expect(
          field.controller!.text,
          welcome ? 'Анна Тестовая' : 'Мой псевдоним',
        );
        expect(find.text('Фото из Telegram'), findsOneWidget);
        expect(previews, welcome ? 1 : 0);
        expect(
          repo.data['profiles']!.first['display_name'],
          welcome ? 'Новый пользователь' : 'Мой псевдоним',
        );
        expect(find.byType(Image), welcome ? findsOneWidget : findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
