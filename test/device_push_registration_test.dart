import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petfriendly/features/notifications/device_push_registration.dart';

class FakePushDevice implements PushDevice {
  final changes = StreamController<String>.broadcast();
  final messages = StreamController<void>.broadcast();
  String? token = 'fixture-token';
  bool auto = false;
  int deletions = 0;
  @override
  bool get available => true;
  @override
  Future<bool> authorize() async => true;
  @override
  Future<void> autoInit(bool enabled) async => auto = enabled;
  @override
  Future<String?> currentToken() async => token;
  @override
  Future<void> deleteToken() async {
    token = null;
    deletions++;
  }

  @override
  Stream<String> get tokenChanges => changes.stream;
  @override
  Stream<void> get foregroundMessages => messages.stream;
  Future<void> dispose() async {
    await changes.close();
    await messages.close();
  }
}

void main() {
  test(
    'Logout waits for a token write, removes it, and ignores later refreshes',
    () async {
      final device = FakePushDevice(),
          pending = Completer<void>(),
          started = Completer<void>();
      final events = <String>[];
      final client = SupabaseClient(
        'https://fixture.example',
        'fixture-key',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/device_tokens')) {
            if (request.method == 'POST') {
              events.add('save');
              started.complete();
              await pending.future;
            } else {
              expect(request.url.queryParameters['user_id'], 'eq.fixture');
              expect(request.url.queryParameters['token'], 'eq.fixture-token');
              events.add('remove');
            }
            return http.Response('', 204, request: request);
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
          );
        }),
      );
      final registration = DevicePushRegistration(device);
      addTearDown(() async {
        await registration.dispose();
        await device.dispose();
        await client.dispose();
      });
      await client.auth.signInWithPassword(
        email: 'fixture@example.test',
        password: 'fixture',
      );
      final enabling = registration.enable(client, () => events.add('message'));
      await started.future;
      var detached = false;
      final logout = registration
          .unregister(client)
          .then((_) => detached = true);
      await Future<void>.delayed(Duration.zero);
      expect(detached, isFalse);
      pending.complete();
      await enabling;
      await logout;
      device.changes.add('late-token');
      device.messages.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(events, ['save', 'remove']);
      expect(device.auto, isFalse);
      expect(device.deletions, 1);
      await registration.unregister(client);
      expect(device.deletions, 1);
    },
  );

  test(
    'Removal failure retains the token and session for a safe retry',
    () async {
      final device = FakePushDevice();
      var fail = true;
      final client = SupabaseClient(
        'https://fixture.example',
        'fixture-key',
        httpClient: MockClient((request) async {
          if (request.method == 'DELETE') {
            return fail
                ? http.Response(
                    '{"message":"unavailable","code":"42501"}',
                    403,
                    request: request,
                  )
                : http.Response('', 204, request: request);
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
          );
        }),
      );
      final registration = DevicePushRegistration(device);
      addTearDown(() async {
        await registration.dispose();
        await device.dispose();
        await client.dispose();
      });
      await client.auth.signInWithPassword(
        email: 'fixture@example.test',
        password: 'fixture',
      );
      await expectLater(
        registration.unregister(client),
        throwsA(isA<PostgrestException>()),
      );
      expect(client.auth.currentUser, isNotNull);
      expect(device.deletions, 0);
      fail = false;
      await registration.unregister(client);
      expect(device.deletions, 1);
    },
  );
}
