import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petfriendly/features/auth/password_change.dart';

void main() {
  test(
    'An old session requests a nonce and sends it with the password update',
    () async {
      final calls = <String>[];
      var confirmed = false;
      final user = {
        'id': 'fixture',
        'aud': 'authenticated',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final session = {
        'access_token': 'synthetic-token',
        'refresh_token': 'synthetic-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': user,
      };
      final client = SupabaseClient(
        'https://fixture.example',
        'fixture-key',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/user') && request.method == 'PUT') {
            final body = jsonDecode(request.body);
            calls.add('update');
            expect(body['password'], 'synthetic-long-password');
            if (body['nonce'] == null) {
              return http.Response(
                jsonEncode({
                  'error_code': 'reauthentication_needed',
                  'msg': 'Password update requires reauthentication',
                }),
                400,
              );
            }
            expect(body['nonce'], '123456');
            confirmed = true;
            return http.Response(jsonEncode(user), 200);
          }
          if (request.url.path.endsWith('/reauthenticate')) {
            calls.add('nonce');
            return http.Response('{}', 200);
          }
          return http.Response(jsonEncode(session), 200);
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'fixture@example.test',
        password: 'fixture',
      );
      final service = PasswordChangeService(client);
      expect(
        await service.update('synthetic-long-password'),
        PasswordChangeResult.confirmationRequired,
      );
      expect(confirmed, isFalse);
      expect(calls, ['update', 'nonce']);
      expect(
        await service.update('synthetic-long-password', nonce: '123456'),
        PasswordChangeResult.completed,
      );
      expect(confirmed, isTrue);
    },
  );
}
