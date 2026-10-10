import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/auth/email_confirmation_panel.dart';

class PendingEmailService extends EmailConfirmationService {
  PendingEmailService() : super(null);
  final completion = Completer<void>();
  int calls = 0;
  @override
  Future<void> resend(String email) {
    calls++;
    return completion.future;
  }
}

void main() {
  testWidgets(
    'Confirmation resend has cooldown and rejects overlapping requests',
    (tester) async {
      final service = PendingEmailService();
      var login = false, changeEmail = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emailConfirmationServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: EmailConfirmationPanel(
                email: 'fixture@example.test',
                onLogin: () => login = true,
                onChangeEmail: () => changeEmail = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Отправить повторно через 60 с'),
            )
            .onPressed,
        isNull,
      );
      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.text('Отправить письмо повторно'));
      await tester.tap(find.text('Отправить письмо повторно'));
      expect(service.calls, 1);
      service.completion.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Отправить повторно через'), findsOneWidget);
      await tester.tap(find.text('Адрес подтверждён — войти'));
      await tester.tap(find.text('Изменить email'));
      expect(login, isTrue);
      expect(changeEmail, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
