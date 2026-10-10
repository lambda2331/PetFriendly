import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/media/preview_photos.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/auth/account_actions.dart';
import 'package:petfriendly/features/community/data/form_drafts.dart';
import 'widget_test.dart' show MemoryPreferences;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Local logout clears session and private drafts while preserving theme/city',
    () async {
      var logouts = 0;
      final client = SupabaseClient(
        'https://fixture.example',
        'fixture-key',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/logout')) {
            expect(request.url.queryParameters['scope'], 'local');
            logouts++;
            return http.Response('', 204);
          }
          return http.Response(
            jsonEncode({
              'access_token': 'synthetic-token',
              'refresh_token': 'synthetic-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': 'fixture',
                'aud': 'authenticated',
                'created_at': '2026-01-01T00:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      await client.auth.signInWithPassword(
        email: 'logout@example.test',
        password: 'fixture-only',
      );
      final prefs = MemoryPreferences();
      final container = ProviderContainer(
        overrides: [
          backendProvider.overrideWithValue(client),
          preferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await client.dispose();
      });
      await container.read(prototypeProvider.notifier).setCity('Гродно');
      await container
          .read(prototypeProvider.notifier)
          .favorite('private-favorite');
      container
          .read(formDraftsProvider)
          .keep(
            'profile',
            FormDraft(
              {'about': 'private draft'},
              DateTime(2026),
              null,
              null,
              null,
            ),
          );
      container
          .read(previewPhotosProvider.notifier)
          .put('fixture', Uint8List.fromList([1, 2, 3]));
      await container.read(accountActionsProvider.notifier).signOut();
      expect(logouts, 1);
      expect(client.auth.currentSession, isNull);
      expect(container.read(formDraftsProvider).read('profile'), isNull);
      expect(container.read(previewPhotosProvider), isEmpty);
      expect(container.read(prototypeProvider).favorites, isEmpty);
      expect(container.read(prototypeProvider).city, 'Гродно');
      expect(container.read(prototypeProvider).manualCity, isTrue);
    },
  );
}
