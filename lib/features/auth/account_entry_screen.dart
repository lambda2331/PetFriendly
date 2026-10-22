import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend/backend.dart';
import '../walks/account_mode.dart';
import 'onboarding_replay.dart';

final accountEntryProvider = FutureProvider<String>((ref) async {
  // listFactors refreshes the SDK session. Watching every refresh event here
  // would recursively restart entry checks; only an account change restarts it.
  ref.watch(authStateProvider.select((state) => state.value?.id));
  final client = ref.read(backendProvider);
  final user = client?.auth.currentUser;
  if (client == null) return '/nearby';
  if (user == null) return '/login';
  final factors = await client.auth.mfa.listFactors();
  final assurance = client.auth.mfa.getAuthenticatorAssuranceLevel();
  if (factors.totp.any((f) => f.status == FactorStatus.verified) &&
      assurance.currentLevel != AuthenticatorAssuranceLevels.aal2) {
    return '/mfa';
  }
  if (ref.watch(onboardingReplayProvider)) return '/onboarding';
  final mode = await ref.read(accountModeProvider.future);
  if (mode.needsRoleSelection) return '/onboarding';
  final profile = await client
      .from('profiles')
      .select('display_name')
      .eq('id', user.id)
      .maybeSingle();
  if (profile == null) throw StateError('Profile unavailable');
  final name = (profile['display_name'] as String).trim();
  if (name.isEmpty || name == 'Новый пользователь') return '/onboarding';
  if (mode.isHelper && await ref.read(helperProfileProvider.future) == null) {
    return '/onboarding';
  }
  return mode.isHelper ? '/requests' : '/nearby';
}, retry: (_, _) => null);

class AccountEntryScreen extends ConsumerWidget {
  const AccountEntryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountEntryProvider);
    final destination = state.value;
    if (destination != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final router = GoRouter.of(context);
        if (router.routeInformationProvider.value.uri.path ==
            '/auth/complete') {
          router.go(destination);
        }
      });
    }
    return Scaffold(
      body: Center(
        child: state.hasError
            ? TextButton(
                onPressed: () => ref.invalidate(accountEntryProvider),
                child: Text("Повторить вход в аккаунт".tr(context)),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
