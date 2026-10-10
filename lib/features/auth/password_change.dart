import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend/backend.dart';

enum PasswordChangeResult { completed, confirmationRequired, mfaRequired }

final passwordChangeServiceProvider = Provider((ref) {
  final client = ref.read(backendProvider);
  if (client == null) throw StateError('Account unavailable');
  return PasswordChangeService(client);
});

class PasswordChangeService {
  PasswordChangeService(this.client);
  final SupabaseClient client;

  Future<PasswordChangeResult> update(String password, {String? nonce}) async {
    final owner = client.auth.currentUser?.id;
    if (owner == null) throw StateError('Account unavailable');
    final factors = await client.auth.mfa.listFactors();
    if (factors.totp.isNotEmpty &&
        client.auth.mfa.getAuthenticatorAssuranceLevel().currentLevel !=
            AuthenticatorAssuranceLevels.aal2) {
      return PasswordChangeResult.mfaRequired;
    }
    if (client.auth.currentUser?.id != owner) {
      throw StateError('Account changed');
    }
    try {
      await client.auth.updateUser(
        UserAttributes(password: password, nonce: nonce),
      );
      return PasswordChangeResult.completed;
    } on AuthException catch (error) {
      if (error.code != 'reauthentication_needed') rethrow;
      await client.auth.reauthenticate();
      return PasswordChangeResult.confirmationRequired;
    }
  }

  Future<void> resendConfirmation() => client.auth.reauthenticate();
}
