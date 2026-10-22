import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/features/walks/walking_repository.dart';

void main() {
  test('Logged-out walking reads never call authorized RPCs', () async {
    var calls = 0;
    final client = SupabaseClient(
      'http://127.0.0.1:54321',
      'test-key',
      httpClient: MockClient((request) async {
        calls++;
        return http.Response('{"message":"denied"}', 403);
      }),
    );
    final scope = ProviderContainer(
      overrides: [backendProvider.overrideWithValue(client)],
    );
    addTearDown(scope.dispose);
    addTearDown(client.dispose);
    final repository = scope.read(walkingRepositoryProvider);
    expect(await repository.list(city: 'Минск'), isEmpty);
    expect(await repository.list(), isEmpty);
    expect(calls, 0);
  });

  for (final denied in [true, false]) {
    test(
      'In-flight walking ${denied ? "denial" : "data"} is discarded after logout',
      () async {
        final response = Completer<http.Response>();
        final started = Completer<void>();
        final client = SupabaseClient(
          'http://127.0.0.1:54321',
          'test-key',
          httpClient: MockClient((request) async {
            if (request.url.path.contains('/rpc/')) {
              started.complete();
              return response.future;
            }
            return http.Response('{}', 200);
          }),
        );
        await client.auth.setInitialSession(
          jsonEncode({
            'access_token': 'synthetic-access-token',
            'refresh_token': 'synthetic-refresh-token',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': '00000000-0000-0000-0000-000000000001',
              'aud': 'authenticated',
              'created_at': '2026-10-12T00:00:00Z',
              'app_metadata': {},
              'user_metadata': {},
            },
          }),
        );
        final scope = ProviderContainer(
          overrides: [backendProvider.overrideWithValue(client)],
        );
        addTearDown(scope.dispose);
        addTearDown(client.dispose);
        final pending = scope
            .read(walkingRepositoryProvider)
            .list(city: 'Минск');
        await started.future;
        await client.auth.signOut();
        response.complete(
          denied
              ? http.Response(
                  '{"message":"permission denied","code":"42501"}',
                  403,
                  request: http.Request(
                    'POST',
                    Uri.parse(
                      'http://127.0.0.1:54321/rest/v1/rpc/search_walk_requests',
                    ),
                  ),
                )
              : http.Response(
                  '{"items":[{"id":"previous-account-result"}]}',
                  200,
                  headers: {'content-type': 'application/json'},
                ),
        );
        expect(await pending, isEmpty);
      },
    );
  }
  test('Authorized walking errors remain visible to the caller', () async {
    final client = SupabaseClient(
      'http://127.0.0.1:54321',
      'test-key',
      httpClient: MockClient(
        (_) async => http.Response(
          '{"message":"permission denied","code":"42501"}',
          403,
          request: http.Request(
            'POST',
            Uri.parse(
              'http://127.0.0.1:54321/rest/v1/rpc/search_walk_requests',
            ),
          ),
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    await client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'synthetic',
        'refresh_token': 'synthetic',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': '00000000-0000-0000-0000-000000000001',
          'aud': 'authenticated',
          'created_at': '2026-10-12T00:00:00Z',
          'app_metadata': {},
          'user_metadata': {},
        },
      }),
    );
    final scope = ProviderContainer(
      overrides: [backendProvider.overrideWithValue(client)],
    );
    addTearDown(scope.dispose);
    addTearDown(client.dispose);
    await expectLater(
      scope.read(walkingRepositoryProvider).list(city: 'Минск'),
      throwsA(isA<PostgrestException>()),
    );
  });
}
