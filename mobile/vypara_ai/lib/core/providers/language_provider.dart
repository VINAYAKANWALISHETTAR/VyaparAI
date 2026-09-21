import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/storage/storage_service.dart';

class LanguageModel {
  final String code; // 'EN', 'KN', 'HI'
  final String name; // 'English', 'Kannada', 'Hindi'
  final String nativeName; // 'English', 'ಕನ್ನಡ', 'हिंदी'
  final String speechLocale; // 'en_IN', 'kn_IN', 'hi_IN'
  final String localeTag; // 'en-IN', 'kn-IN', 'hi-IN'

  const LanguageModel({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.speechLocale,
    required this.localeTag,
  });

  Locale get locale => Locale(code.toLowerCase(), 'IN');
  String get langCode => code.toLowerCase();
}

const List<LanguageModel> supportedLanguages = [
  LanguageModel(
    code: 'EN',
    name: 'English',
    nativeName: 'English',
    speechLocale: 'en_IN',
    localeTag: 'en-IN',
  ),
  LanguageModel(
    code: 'KN',
    name: 'Kannada',
    nativeName: 'ಕನ್ನಡ',
    speechLocale: 'kn_IN',
    localeTag: 'kn-IN',
  ),
  LanguageModel(
    code: 'HI',
    name: 'Hindi',
    nativeName: 'हिंदी',
    speechLocale: 'hi_IN',
    localeTag: 'hi-IN',
  ),
];

class LanguageNotifier extends Notifier<LanguageModel> {
  final StorageService _storage = StorageService();

  @override
  LanguageModel build() {
    _loadSavedLanguage();
    return supportedLanguages.first; // Default to English
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final savedCode = await _storage.getLanguage();
      if (savedCode != null && savedCode.isNotEmpty) {
        final match = supportedLanguages.firstWhere(
          (l) =>
              l.code.toUpperCase() == savedCode.toUpperCase() ||
              l.name.toLowerCase() == savedCode.toLowerCase() ||
              l.langCode == savedCode.toLowerCase() ||
              l.localeTag.toLowerCase() == savedCode.toLowerCase(),
          orElse: () => supportedLanguages.first,
        );
        state = match;
      }
    } catch (_) {}
  }

  Future<void> setLanguage(LanguageModel lang) async {
    state = lang;
    try {
      await _storage.setLanguage(lang.code);
    } catch (_) {}
  }

  Future<void> setLanguageByCode(String code) async {
    final match = supportedLanguages.firstWhere(
      (l) =>
          l.code.toUpperCase() == code.toUpperCase() ||
          l.name.toLowerCase() == code.toLowerCase() ||
          l.langCode == code.toLowerCase() ||
          l.localeTag.toLowerCase() == code.toLowerCase(),
      orElse: () => supportedLanguages.first,
    );
    state = match;
    try {
      await _storage.setLanguage(match.code);
    } catch (_) {}
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, LanguageModel>(LanguageNotifier.new);
