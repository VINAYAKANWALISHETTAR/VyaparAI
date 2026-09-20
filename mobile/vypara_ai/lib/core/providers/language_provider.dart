import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/storage/storage_service.dart';

class LanguageModel {
  final String code;
  final String name;
  final String nativeName;
  final String speechLocale;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.speechLocale,
  });
}

const List<LanguageModel> supportedLanguages = [
  LanguageModel(code: 'EN', name: 'English', nativeName: 'English', speechLocale: 'en_IN'),
  LanguageModel(code: 'HI', name: 'Hindi', nativeName: 'हिंदी', speechLocale: 'hi_IN'),
  LanguageModel(code: 'KN', name: 'Kannada', nativeName: 'ಕನ್ನಡ', speechLocale: 'kn_IN'),
  LanguageModel(code: 'TA', name: 'Tamil', nativeName: 'தமிழ்', speechLocale: 'ta_IN'),
  LanguageModel(code: 'TE', name: 'Telugu', nativeName: 'తెలుగు', speechLocale: 'te_IN'),
  LanguageModel(code: 'ML', name: 'Malayalam', nativeName: 'മലയാളം', speechLocale: 'ml_IN'),
  LanguageModel(code: 'MR', name: 'Marathi', nativeName: 'मराठी', speechLocale: 'mr_IN'),
  LanguageModel(code: 'GU', name: 'Gujarati', nativeName: 'ગુજરાતી', speechLocale: 'gu_IN'),
  LanguageModel(code: 'BN', name: 'Bengali', nativeName: 'বাংলা', speechLocale: 'bn_IN'),
];

class LanguageNotifier extends Notifier<LanguageModel> {
  final StorageService _storage = StorageService();

  @override
  LanguageModel build() {
    _loadSavedLanguage();
    return supportedLanguages.first; // Default to English
  }

  Future<void> _loadSavedLanguage() async {
    final savedCode = await _storage.getLanguage();
    if (savedCode != null) {
      final match = supportedLanguages.firstWhere(
        (l) => l.code == savedCode || l.name == savedCode,
        orElse: () => supportedLanguages.first,
      );
      state = match;
    }
  }

  Future<void> setLanguage(LanguageModel lang) async {
    state = lang;
    await _storage.setLanguage(lang.code);
  }

  Future<void> setLanguageByCode(String code) async {
    final match = supportedLanguages.firstWhere(
      (l) => l.code == code || l.name.toLowerCase() == code.toLowerCase(),
      orElse: () => supportedLanguages.first,
    );
    state = match;
    await _storage.setLanguage(match.code);
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, LanguageModel>(LanguageNotifier.new);
