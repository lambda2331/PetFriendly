import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backend/backend.dart';

enum ProfilePhotoProvider { google, telegram }

typedef ProviderPhotoDownloader =
    Future<Uint8List> Function(Uri uri, ProfilePhotoProvider provider);

final providerPhotoDownloaderProvider = Provider<ProviderPhotoDownloader>(
  (ref) =>
      (uri, provider) => downloadProviderPhoto(uri, provider: provider),
);

final profileSuggestionProvider = Provider<ProfileSuggestion>((ref) {
  ref.watch(authStateProvider);
  return ProfileSuggestion.fromUser(
    ref.watch(backendProvider)?.auth.currentUser,
  );
});

class ProfileSuggestion {
  const ProfileSuggestion({this.name, this.googlePhoto, this.telegramPhoto});
  final String? name;
  final Uri? googlePhoto, telegramPhoto;

  factory ProfileSuggestion.fromUser(User? user) {
    final data = user?.userMetadata ?? {};
    Map<String, dynamic>? identityData(String provider) => user?.identities
        ?.where((i) => i.provider == provider)
        .firstOrNull
        ?.identityData;
    bool hasProvider(String provider) =>
        identityData(provider) != null ||
        (user?.identities?.any((i) => i.provider == provider) ?? false) ||
        user?.appMetadata['provider'] == provider;
    final telegram = hasProvider('custom:telegram');
    final telegramData = identityData('custom:telegram');
    final googleData = identityData('google');
    // Identity-scoped claims win over merged account metadata for linked users.
    // These values only suggest public display fields; never use them as identity.
    List<Map<String, dynamic>> sources(Map<String, dynamic>? identity) => [
      ?identity,
      if (identity?['custom_claims'] is Map)
        Map<String, dynamic>.from(identity!['custom_claims']),
      data,
      if (data['custom_claims'] is Map)
        Map<String, dynamic>.from(data['custom_claims']),
    ];
    final nameSources = sources(telegram ? telegramData : googleData);
    String? name;
    for (final source in nameSources) {
      for (final value in [
        source['full_name'],
        source['name'],
        [
          source['given_name'] ?? source['first_name'],
          source['family_name'] ?? source['last_name'],
        ].whereType<String>().join(' '),
      ]) {
        name = cleanProviderName(value);
        if (name != null) break;
      }
      if (name != null) break;
    }
    Uri? photoFor(String provider, bool Function(Uri) allowed) {
      if (!hasProvider(provider)) return null;
      for (final source in sources(identityData(provider))) {
        for (final key in ['avatar_url', 'picture']) {
          final raw = source[key];
          if (raw is String && raw.length <= 2048) {
            final uri = Uri.tryParse(raw);
            if (uri != null && allowed(uri)) return uri;
          }
        }
      }
      return null;
    }

    return ProfileSuggestion(
      name: name,
      googlePhoto: photoFor('google', allowedGooglePhoto),
      telegramPhoto: photoFor('custom:telegram', allowedTelegramPhoto),
    );
  }
}

String? cleanProviderName(Object? value) {
  if (value is! String) return null;
  final clean = value
      .replaceAll(RegExp(r'[\x00-\x1f\x7f-\x9f]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return clean.isEmpty ? null : String.fromCharCodes(clean.runes.take(80));
}

bool allowedGooglePhoto(Uri uri) =>
    uri.scheme == 'https' &&
    uri.userInfo.isEmpty &&
    uri.port == 443 &&
    uri.fragment.isEmpty &&
    RegExp(r'^lh[0-9]+\.googleusercontent\.com$').hasMatch(uri.host) &&
    (uri.path.startsWith('/a/') || uri.path.startsWith('/a-/'));

bool allowedTelegramPhoto(Uri uri) =>
    uri.scheme == 'https' &&
    uri.userInfo.isEmpty &&
    uri.port == 443 &&
    uri.fragment.isEmpty &&
    ((RegExp(r'^cdn[0-9]+\.telesco\.pe$').hasMatch(uri.host) &&
            uri.path.startsWith('/file/')) ||
        (uri.host == 't.me' && uri.path.startsWith('/i/userpic/')));

final welcomeTelegramPhotoProvider = FutureProvider.autoDispose<Uint8List?>((
  ref,
) async {
  // Reading .future from a one-shot form action must retain this provider until
  // the download completes. Release it afterward so private bytes stay ephemeral.
  final hold = ref.keepAlive();
  try {
    final uid = ref.watch(authStateProvider.select((state) => state.value?.id));
    final client = ref.watch(backendProvider);
    final uri = ref.watch(
      profileSuggestionProvider.select((s) => s.telegramPhoto),
    );
    final download = ref.read(providerPhotoDownloaderProvider);
    if (uid == null || client == null || uri == null) return null;
    final existing = await client
        .from('entity_photos')
        .select('object_path')
        .eq('kind', 'profile')
        .eq('target_id', uid)
        .maybeSingle();
    if (existing != null || client.auth.currentUser?.id != uid) return null;
    final bytes = await download(uri, ProfilePhotoProvider.telegram);
    return client.auth.currentUser?.id == uid ? bytes : null;
  } finally {
    hold.close();
  }
});

// Provider photos are previews until profile save. No provider/Supabase tokens
// are sent to the image host; redirects cannot change the approved destination.
Future<Uint8List> downloadGooglePhoto(Uri uri, {http.Client? client}) =>
    downloadProviderPhoto(
      uri,
      provider: ProfilePhotoProvider.google,
      client: client,
    );

Future<Uint8List> downloadTelegramPhoto(Uri uri, {http.Client? client}) =>
    downloadProviderPhoto(
      uri,
      provider: ProfilePhotoProvider.telegram,
      client: client,
    );

Future<Uint8List> downloadProviderPhoto(
  Uri uri, {
  required ProfilePhotoProvider provider,
  http.Client? client,
}) async {
  final allowed = switch (provider) {
    ProfilePhotoProvider.google => allowedGooglePhoto(uri),
    ProfilePhotoProvider.telegram => allowedTelegramPhoto(uri),
  };
  if (!allowed) throw StateError('Unsupported photo source');
  final transport = client ?? http.Client();
  try {
    final request = http.Request('GET', uri)..followRedirects = false;
    final response = await transport
        .send(request)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200 ||
        !(response.headers['content-type'] ?? '').startsWith('image/')) {
      throw StateError('Photo unavailable');
    }
    const limit = 8 * 1024 * 1024;
    if ((response.contentLength ?? 0) > limit) {
      throw StateError('Photo too large');
    }
    Future<Uint8List> read() async {
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.stream) {
        if (bytes.length + chunk.length > limit) {
          throw StateError('Photo too large');
        }
        bytes.add(chunk);
      }
      return bytes.takeBytes();
    }

    final bytes = await read().timeout(const Duration(seconds: 12));
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        if (descriptor.width * descriptor.height > 40000000) {
          throw StateError('Photo dimensions too large');
        }
        final scale = math.min(
          1.0,
          1200 / math.max(descriptor.width, descriptor.height),
        );
        final codec = await descriptor.instantiateCodec(
          targetWidth: math.max(1, (descriptor.width * scale).round()),
          targetHeight: math.max(1, (descriptor.height * scale).round()),
        );
        try {
          final frame = await codec.getNextFrame();
          try {
            final png = await frame.image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (png == null) throw StateError('Photo unavailable');
            return png.buffer.asUint8List();
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  } finally {
    transport.close();
  }
}
