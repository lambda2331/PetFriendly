import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/auth/reauthentication_screen.dart';
import 'package:petfriendly/features/auth/reauthentication.dart';

class TestReauthenticationFlow implements ReauthenticationFlow {
  ReauthStatus current = ReauthStatus.waiting;
  @override
  ReauthStatus get status => current;
  @override
  Future<void> begin() async {}
  @override
  Future<void> verifyMfa(String code) async {}
}

void main() {
  testWidgets(
    'Same user with a new session updates the reauthentication screen',
    (tester) async {
      final sessions = StreamController<Session?>.broadcast();
      final flow = TestReauthenticationFlow();
      const user = User(
        id: 'fixture',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith((ref) => sessions.stream),
            providerReauthenticationProvider.overrideWith(
              (ref, provider) => flow,
            ),
          ],
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: const ProviderReauthenticationScreen(
              provider: ReauthProvider.telegram,
            ),
          ),
        ),
      );
      sessions.add(
        Session(accessToken: 'old-fixture', tokenType: 'bearer', user: user),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Войти через Telegram'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Завершите вход'), findsOneWidget);
      flow.current = ReauthStatus.ready;
      sessions.add(
        Session(accessToken: 'new-fixture', tokenType: 'bearer', user: user),
      );
      await tester.pumpAndSettle();
      expect(find.text('Продолжить действие'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await sessions.close();
    },
  );
  final start = DateTime.utc(2026, 10, 9, 12);
  final now = start.add(const Duration(seconds: 20));
  final claims = <String, dynamic>{
    'sub': 'owner',
    'session_id': 'new-session',
    'exp': now.millisecondsSinceEpoch ~/ 1000 + 3600,
    'aal': 'aal1',
    'amr': [
      {
        'method': 'oauth',
        'timestamp': start.millisecondsSinceEpoch ~/ 1000 + 5,
      },
    ],
  };
  ReauthStatus evaluate(
    Map<String, dynamic> value, {
    String user = 'owner',
    bool mfa = false,
    DateTime? time,
  }) => evaluateReauthentication(
    expectedUser: 'owner',
    currentUser: user,
    previousSession: 'old-session',
    startedAt: start,
    now: time ?? now,
    claims: value,
    hasMfa: mfa,
  );
  test(
    'Fresh same-account OAuth session permits confirmation',
    () => expect(evaluate(claims), ReauthStatus.ready),
  );
  test(
    'Choosing another Google account cannot confirm original action',
    () => expect(evaluate(claims, user: 'other'), ReauthStatus.wrongAccount),
  );
  test(
    'Token refresh of original session is not reauthentication',
    () => expect(
      evaluate({...claims, 'session_id': 'old-session'}),
      ReauthStatus.waiting,
    ),
  );
  test(
    'Old OAuth event in a new session is insufficient',
    () => expect(
      evaluate({
        ...claims,
        'amr': [
          {
            'method': 'oauth',
            'timestamp': start.millisecondsSinceEpoch ~/ 1000 - 300,
          },
        ],
      }),
      ReauthStatus.waiting,
    ),
  );
  test('MFA must be completed after fresh OAuth', () {
    expect(evaluate(claims, mfa: true), ReauthStatus.needsMfa);
    expect(evaluate({...claims, 'aal': 'aal2'}, mfa: true), ReauthStatus.ready);
  });
  test('Expired proof and JWT cannot confirm an action', () {
    expect(
      evaluate(claims, time: start.add(const Duration(minutes: 4))),
      ReauthStatus.expired,
    );
    expect(evaluate({...claims, 'exp': 1}), ReauthStatus.expired);
  });
  test('Missing or mismatched identity claims fail closed', () {
    expect(evaluate({}), ReauthStatus.waiting);
    expect(evaluate({...claims, 'sub': 'other'}), ReauthStatus.waiting);
    expect(authClaims('malformed'), isEmpty);
  });
}
