import 'features/nearby/location_service.dart';
import 'core/diagnostics/crash_reporting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/storage/prototype_store.dart';
import 'core/backend/backend.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/community/data/community_repository.dart';
import 'features/nearby/place_repository.dart';
import 'features/chat/chat_media.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate();
  if (AppConfig.portfolio) WidgetsBinding.instance.ensureSemantics();
  try {
    await purgeTemporaryChatMedia(await getTemporaryDirectory());
  } catch (_) {
    /* No private chat cache is required for startup. */
  }
  SupabaseClient? client;
  if (AppConfig.backendEnabled) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseKey,
      debug: false,
      authOptions: FlutterAuthClientOptions(
        localStorage: const SecureSessionStorage(),
        pkceAsyncStorage: SecurePkceStorage(),
        detectSessionInUriPredicate: (uri) =>
            uri.scheme == 'petfriendly' &&
            uri.host == 'auth' &&
            uri.path == '/callback',
      ),
    );
    client = Supabase.instance.client;
  }
  const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  const firebaseSender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const firebaseProject = String.fromEnvironment('FIREBASE_PROJECT_ID');
  if (!AppConfig.portfolio &&
      [
        firebaseApiKey,
        firebaseAppId,
        firebaseSender,
        firebaseProject,
      ].every((v) => v.isNotEmpty)) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: firebaseApiKey,
        appId: firebaseAppId,
        messagingSenderId: firebaseSender,
        projectId: firebaseProject,
        iosBundleId: 'com.petfriendly.petfriendly',
      ),
    );
  }
  final catalog = AppConfig.portfolio
      ? DemoPlaceRepository()
      : await OsmPlaceRepository.load();
  if (!AppConfig.portfolio && AppConfig.mapboxToken.isNotEmpty) {
    MapboxOptions.setAccessToken(AppConfig.mapboxToken);
  }
  final preferences = await SharedPreferences.getInstance();
  try {
    await initializeCrashReporting(preferences);
  } catch (_) {
    /* A monitoring failure must not prevent sign-in. */
  }
  runApp(
    ProviderScope(
      overrides: [
        diagnosticsPreferencesProvider.overrideWithValue(preferences),
        preferencesProvider.overrideWithValue(DevicePreferences(preferences)),
        backendProvider.overrideWithValue(client),
        placesProvider.overrideWithValue(catalog),
        if (AppConfig.portfolio)
          locationServiceProvider.overrideWithValue(PortfolioLocationService()),
        communityRepositoryProvider.overrideWithValue(
          client != null
              ? SupabaseCommunityRepository(client)
              : DemoCommunityRepository(seedSamples: AppConfig.portfolio),
        ),
      ],
      child: const PetFriendlyApp(),
    ),
  );
}
