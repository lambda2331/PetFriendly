import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const mapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  static const demo = bool.fromEnvironment('USE_DEMO_DATA', defaultValue: true);
  static const googleEnabled = bool.fromEnvironment('AUTH_GOOGLE_ENABLED');
  static const appleEnabled = bool.fromEnvironment('AUTH_APPLE_ENABLED');
  static const telegramEnabled = bool.fromEnvironment('AUTH_TELEGRAM_ENABLED');
  static const callback = 'petfriendly://auth/callback';
  static bool get backendEnabled =>
      !demo && supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
  static void validate() {
    if (!demo && !backendEnabled) {
      throw StateError('Supabase configuration is missing');
    }
    if (backendEnabled) {
      final uri = Uri.parse(supabaseUrl);
      final local = ['localhost', '127.0.0.1', '10.0.2.2'].contains(uri.host);
      if (uri.scheme != 'https' && !(kDebugMode && local)) {
        throw StateError('HTTPS is required');
      }
    }
    bool serverKey = supabaseKey.startsWith('sb_secret_');
    try {
      final parts = supabaseKey.split('.');
      if (parts.length == 3) {
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        serverKey = serverKey || payload['role'] == 'service_role';
      }
    } catch (_) {}
    if (serverKey) {
      throw StateError('Server keys must not be bundled in the client');
    }
  }
}

const secureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
  aOptions: AndroidOptions(),
);

class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage({this.project = AppConfig.supabaseUrl});
  final String project;
  static String get key => const SecureSessionStorage().sessionKey;
  String get sessionKey =>
      'petfriendly.auth.${storageNamespace(project)}.session';
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async =>
      await secureStorage.read(key: sessionKey) != null;
  @override
  Future<String?> accessToken() => secureStorage.read(key: sessionKey);
  @override
  Future<void> removePersistedSession() =>
      secureStorage.delete(key: sessionKey);
  @override
  Future<void> persistSession(String value) =>
      secureStorage.write(key: sessionKey, value: value);
}

String storageNamespace(String project) => project.isEmpty
    ? 'demo'
    : base64Url.encode(utf8.encode(Uri.parse(project).origin));

class SecurePkceStorage extends GotrueAsyncStorage {
  SecurePkceStorage({this.project = AppConfig.supabaseUrl});
  final String project;
  @override
  Future<String?> getItem({required String key}) => secureStorage.read(
    key: 'petfriendly.pkce.${storageNamespace(project)}.$key',
  );
  @override
  Future<void> removeItem({required String key}) => secureStorage.delete(
    key: 'petfriendly.pkce.${storageNamespace(project)}.$key',
  );
  @override
  Future<void> setItem({required String key, required String value}) =>
      secureStorage.write(
        key: 'petfriendly.pkce.${storageNamespace(project)}.$key',
        value: value,
      );
}

final backendProvider = Provider<SupabaseClient?>((ref) => null);
final authSessionProvider = StreamProvider<Session?>((ref) async* {
  final client = ref.watch(backendProvider);
  if (client == null) {
    yield null;
    return;
  }
  yield client.auth.currentSession;
  yield* client.auth.onAuthStateChange.map((event) => event.session);
});
final authStateProvider = StreamProvider<User?>((ref) async* {
  final client = ref.watch(backendProvider);
  if (client == null) {
    yield null;
    return;
  }
  yield client.auth.currentUser;
  yield* client.auth.onAuthStateChange.map((event) => event.session?.user);
});
