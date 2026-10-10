import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend/backend.dart';

enum ReauthStatus { waiting, wrongAccount, expired, needsMfa, ready }

enum ReauthProvider {
  google,
  telegram;

  String get label => this == google ? 'Google' : 'Telegram';
  String get identity => this == google ? 'google' : 'custom:telegram';
  bool get enabled =>
      this == google ? AppConfig.googleEnabled : AppConfig.telegramEnabled;
  OAuthProvider get oauth => this == google
      ? OAuthProvider.google
      : const OAuthProvider('custom:telegram');
}

String? sessionIdentifier(String token) {
  final value = authClaims(token)['session_id'];
  return value is String ? value : null;
}

Map<String, dynamic> authClaims(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    return Map<String, dynamic>.from(
      jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
          as Map,
    );
  } catch (_) {
    return {};
  }
}

// These checks guide the UI. Privileged RPCs independently validate the signed
// JWT, current session, MFA and recent_auth; client claims never grant access.
ReauthStatus evaluateReauthentication({
  required String expectedUser,
  required String? currentUser,
  required String previousSession,
  required DateTime startedAt,
  required DateTime now,
  required Map<String, dynamic> claims,
  required bool hasMfa,
}) {
  if (currentUser == null) return ReauthStatus.waiting;
  if (currentUser != expectedUser) return ReauthStatus.wrongAccount;
  if (now.difference(startedAt) > const Duration(minutes: 3)) {
    return ReauthStatus.expired;
  }
  final sid = claims['session_id'];
  if (sid is! String ||
      sid.isEmpty ||
      sid == previousSession ||
      claims['sub'] != expectedUser) {
    return ReauthStatus.waiting;
  }
  final expiry = claims['exp'];
  if (expiry is! num || expiry <= now.millisecondsSinceEpoch ~/ 1000) {
    return ReauthStatus.expired;
  }
  final methods = claims['amr'];
  if (methods is! List ||
      !methods.any(
        (method) =>
            method is Map &&
            method['method'] == 'oauth' &&
            method['timestamp'] is num &&
            method['timestamp'] >=
                startedAt.millisecondsSinceEpoch ~/ 1000 - 2 &&
            method['timestamp'] <= now.millisecondsSinceEpoch ~/ 1000 + 2,
      )) {
    return ReauthStatus.waiting;
  }
  if (hasMfa && claims['aal'] != 'aal2') return ReauthStatus.needsMfa;
  return ReauthStatus.ready;
}

abstract class ReauthenticationFlow {
  Future<void> begin();
  ReauthStatus get status;
  Future<void> verifyMfa(String code);
}

class ProviderReauthentication implements ReauthenticationFlow {
  ProviderReauthentication(this.client, this.provider)
    : userId = client.auth.currentUser?.id,
      previousSession = sessionIdentifier(
        client.auth.currentSession?.accessToken ?? '',
      );
  final SupabaseClient client;
  final ReauthProvider provider;
  final String? userId, previousSession;
  DateTime? startedAt;

  @override
  Future<void> begin() async {
    if (!provider.enabled ||
        userId == null ||
        previousSession == null ||
        client.auth.currentUser?.id != userId ||
        !(client.auth.currentUser?.identities?.any(
              (i) => i.provider == provider.identity,
            ) ??
            false)) {
      throw StateError('Reauthentication unavailable');
    }
    startedAt = DateTime.now().toUtc();
    try {
      final opened = await client.auth.signInWithOAuth(
        provider.oauth,
        redirectTo: AppConfig.callback,
        queryParams: provider == ReauthProvider.google
            ? {'prompt': 'select_account'}
            : null,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (!opened) throw StateError('Provider unavailable');
    } catch (_) {
      startedAt = null;
      rethrow;
    }
  }

  @override
  ReauthStatus get status {
    final start = startedAt;
    if (start == null || userId == null || previousSession == null) {
      return ReauthStatus.waiting;
    }
    return evaluateReauthentication(
      expectedUser: userId!,
      currentUser: client.auth.currentUser?.id,
      previousSession: previousSession!,
      startedAt: start,
      now: DateTime.now().toUtc(),
      claims: authClaims(client.auth.currentSession?.accessToken ?? ''),
      hasMfa:
          client.auth.currentUser?.factors?.any(
            (f) => f.status == FactorStatus.verified,
          ) ??
          false,
    );
  }

  @override
  Future<void> verifyMfa(String code) async {
    if (status != ReauthStatus.needsMfa) {
      throw StateError('Reauthentication required');
    }
    final factors = await client.auth.mfa.listFactors();
    if (status != ReauthStatus.needsMfa || factors.totp.isEmpty) {
      throw StateError('Factor unavailable');
    }
    await client.auth.mfa.challengeAndVerify(
      factorId: factors.totp.first.id,
      code: code,
    );
  }
}

final providerReauthenticationProvider = Provider.autoDispose
    .family<ReauthenticationFlow, ReauthProvider>((ref, provider) {
      final client = ref.read(backendProvider);
      if (client == null) throw StateError('Account unavailable');
      return ProviderReauthentication(client, provider);
    });
