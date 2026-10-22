import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/prototype_store.dart';
import 'generated/app_localizations.dart';
import 'message_bridge.dart';
export 'generated/app_localizations.dart';

const appLanguages = {
  'ru': 'Русский',
  'en': 'English',
  'be': 'Беларуская',
  'pl': 'Polski',
};

class LanguageController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final language = ref.read(preferencesProvider).read('language');
    return appLanguages.containsKey(language) ? Locale(language!) : null;
  }

  Future<void> select(String? language) async {
    if (language != null && !appLanguages.containsKey(language)) {
      throw ArgumentError.value(language, 'language');
    }
    await ref.read(preferencesProvider).write('language', language ?? 'system');
    state = language == null ? null : Locale(language);
  }
}

final languageProvider = NotifierProvider<LanguageController, Locale?>(
  LanguageController.new,
);

Locale resolveAppLocale(
  List<Locale>? deviceLocales,
  Iterable<Locale> supported,
) {
  for (final device in deviceLocales ?? const <Locale>[]) {
    for (final locale in supported) {
      if (locale.languageCode == device.languageCode) return locale;
    }
  }
  return const Locale('ru');
}

extension AppTranslation on String {
  /// Only call for application copy. User messages/names are never translated.
  String tr(BuildContext context, {Map<String, Object?> arguments = const {}}) {
    final l = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (l == null) {
      return replaceAllMapped(
        RegExp(r'\{(p\d+)\}'),
        (m) => (arguments[m[1]] ?? '').toString(),
      );
    }
    return translateMessage(l, this, arguments);
  }
}

extension AppLanguageContext on BuildContext {
  String get languageCode =>
      Localizations.of<AppLocalizations>(this, AppLocalizations)?.localeName ??
      'ru';
}

/// Locale-aware formatting for services/pure helpers, with no global mutable locale.
String translateForLanguage(
  String source, {
  String locale = 'ru',
  Map<String, Object?> arguments = const {},
}) => translateMessage(
  lookupAppLocalizations(
    Locale(appLanguages.containsKey(locale) ? locale : 'ru'),
  ),
  source,
  arguments,
);
AppLocalizations stringsFor(String locale) => lookupAppLocalizations(
  Locale(appLanguages.containsKey(locale) ? locale : 'ru'),
);
