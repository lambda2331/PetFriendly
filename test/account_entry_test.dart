import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/features/auth/account_entry_screen.dart';
import 'package:petfriendly/features/auth/profile_suggestion.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/community/presentation/forms.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'widget_test.dart' show MemoryPreferences;

const photo = 'https://lh3.googleusercontent.com/a-/fixture=s96-c';
const fixtureId = '12345678-1234-1234-1234-123456789012';
Map<String, dynamic> userData({bool mfa = false}) => {
  'id': fixtureId,
  'aud': 'authenticated',
  'created_at': '2026-01-01T00:00:00Z',
  'app_metadata': {'provider': 'google'},
  'user_metadata': {'full_name': '  Анна   Тестовая ', 'avatar_url': photo},
  'identities': [
    {'id': 'google-fixture', 'user_id': fixtureId, 'provider': 'google'},
  ],
  'factors': mfa
      ? [
          {
            'id': '11111111-1234-1234-1234-123456789012',
            'factor_type': 'totp',
            'status': 'verified',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
          },
        ]
      : [],
};
Map<String, dynamic> sessionData({bool mfa = false}) {
  String part(Map<String, dynamic> data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  return {
    'access_token':
        '${part({'alg': 'HS256'})}.${part({'sub': fixtureId, 'aal': 'aal1', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.fixture',
    'refresh_token': 'fixture-refresh',
    'token_type': 'bearer',
    'user': userData(mfa: mfa),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final initial in ['Новый пользователь', 'Псевдоним']) {
    testWidgets('Profile draft prefills only an unset name: $initial', (
      tester,
    ) async {
      final repo = DemoCommunityRepository();
      repo.data['profiles']!.first['display_name'] = initial;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileSuggestionProvider.overrideWithValue(
              ProfileSuggestion(
                name: 'Анна Тестовая',
                googlePhoto: Uri.parse(photo),
              ),
            ),
            communityRepositoryProvider.overrideWithValue(repo),
            preferencesProvider.overrideWithValue(MemoryPreferences()),
          ],
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: const EditScreen(kind: 'profile', welcome: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = tester.widget<TextFormField>(
        find.byKey(const ValueKey('field.display_name')),
      );
      expect(
        field.controller!.text,
        initial == 'Новый пользователь' ? 'Анна Тестовая' : initial,
      );
      expect(find.text('Фото из Google'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('field.display_name')),
        'Выбранное имя',
      );
      expect(repo.data['profiles']!.first['display_name'], initial);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  test('Optional provider fields tolerate missing or malformed metadata', () {
    expect(ProfileSuggestion.fromUser(null).name, isNull);
    final data = userData();
    data['user_metadata'] = {'full_name': 42, 'name': ' Анна\u0000  Тестовая '};
    final suggestion = ProfileSuggestion.fromUser(User.fromJson(data));
    expect(suggestion.name, 'Анна Тестовая');
    expect(suggestion.googlePhoto, isNull);
  });
  test(
    'Google profile data remains a suggestion; only approved photo hosts pass',
    () {
      final suggestion = ProfileSuggestion.fromUser(User.fromJson(userData()));
      expect(suggestion.name, 'Анна Тестовая');
      expect(suggestion.googlePhoto.toString(), photo);
      for (final url in [
        'http://lh3.googleusercontent.com/a/test',
        'https://lh3.googleusercontent.com.attacker.test/a/test',
        'https://user:pass@lh3.googleusercontent.com/a/test',
        'https://lh3.googleusercontent.com:8443/a/test',
        'https://127.0.0.1/a/test',
      ]) {
        expect(allowedGooglePhoto(Uri.parse(url)), isFalse);
      }
    },
  );
  test(
    'Provider photo request carries no auth tokens and rejects redirects',
    () async {
      var calls = 0;
      await expectLater(
        downloadGooglePhoto(
          Uri.parse(photo),
          client: MockClient((request) async {
            calls++;
            expect(request.followRedirects, isFalse);
            expect(request.headers.containsKey('authorization'), isFalse);
            expect(request.headers.containsKey('apikey'), isFalse);
            return http.Response(
              '',
              302,
              headers: {'location': 'http://127.0.0.1/private'},
            );
          }),
        ),
        throwsStateError,
      );
      expect(calls, 1);
    },
  );
  test('Provider image is re-encoded without copied textual metadata', () async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAHXRFWHREZXNjcmlwdGlvbgBQUklWQVRFX0VYSUZfVEVTVNhRoysAAAARSURBVHicY/jPwMDwH4yAGAAd8AP909B9JgAAAABJRU5ErkJggg==',
    );
    final png = await downloadGooglePhoto(
      Uri.parse(photo),
      client: MockClient(
        (_) async => http.Response.bytes(
          bytes,
          200,
          headers: {'content-type': 'image/png'},
        ),
      ),
    );
    expect(png.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(
      utf8.decode(png, allowMalformed: true),
      isNot(contains('PRIVATE_EXIF_TEST')),
    );
  });
  for (final scenario in [
    ('Новый пользователь', false, '/edit/profile?welcome=true'),
    ('Моё выбранное имя', false, '/nearby'),
    ('Новый пользователь', true, '/mfa'),
  ]) {
    test(
      'Account entry routes ${scenario.$1} with MFA=${scenario.$2}',
      () async {
        var refreshes = 0, profileReads = 0;
        final client = SupabaseClient(
          'https://fixture.example',
          'fixture-key',
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith('/token')) {
              refreshes++;
              return http.Response(
                jsonEncode(sessionData(mfa: scenario.$2)),
                200,
                request: request,
                headers: {'content-type': 'application/json'},
              );
            }
            profileReads++;
            return http.Response(
              jsonEncode({'display_name': scenario.$1}),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        await client.auth.recoverSession(
          jsonEncode(sessionData(mfa: scenario.$2)),
        );
        final container = ProviderContainer(
          overrides: [backendProvider.overrideWithValue(client)],
          retry: (_, _) => null,
        );
        addTearDown(() async {
          container.dispose();
          await client.dispose();
        });
        expect(await container.read(accountEntryProvider.future), scenario.$3);
        expect(refreshes, lessThanOrEqualTo(2));
        if (scenario.$2) expect(profileReads, 0);
      },
    );
  }
}
