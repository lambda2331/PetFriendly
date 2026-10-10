import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:petfriendly/core/backend/backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Changing backend does not read or revoke sessions and PKCE belonging to another project',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const local = SecureSessionStorage(project: 'http://127.0.0.1:54321');
      const stage = SecureSessionStorage(
        project: 'https://example-staging.supabase.co',
      );
      await local.persistSession('synthetic-local-session');
      expect(await stage.accessToken(), isNull);
      await stage.persistSession('synthetic-staging-session');
      await local.removePersistedSession();
      expect(await stage.accessToken(), 'synthetic-staging-session');
      final localPkce = SecurePkceStorage(project: 'http://127.0.0.1:54321');
      final stagePkce = SecurePkceStorage(
        project: 'https://example-staging.supabase.co',
      );
      await localPkce.setItem(
        key: 'verifier',
        value: 'synthetic-local-verifier',
      );
      expect(await stagePkce.getItem(key: 'verifier'), isNull);
      await stagePkce.setItem(
        key: 'verifier',
        value: 'synthetic-staging-verifier',
      );
      await localPkce.removeItem(key: 'verifier');
      expect(
        await stagePkce.getItem(key: 'verifier'),
        'synthetic-staging-verifier',
      );
      FlutterSecureStorage.setMockInitialValues({});
    },
  );
}
