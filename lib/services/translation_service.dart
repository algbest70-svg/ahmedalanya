import 'dart:developer';
import 'package:translator/translator.dart';

class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();

  Future<String> translate(String sourceText, String targetLang) async {
    if (targetLang == 'ar' || sourceText.isEmpty) {
      return sourceText;
    }
    
    // Normalize language codes
    String lang = targetLang;
    if (lang == 'zh-CN') lang = 'zh-cn'; // Library might prefer lowercase

    try {
      // Add a tiny jitter/delay to avoid being flagged by Google Translate for rapid parallel requests
      await Future.delayed(const Duration(milliseconds: 100));
      
      final translation = await _translator.translate(
        sourceText,
        from: 'ar',
        to: lang,
      );
      return translation.text;
    } catch (e) {
      log('Translation Error ($lang) for text: "${sourceText.substring(0, sourceText.length > 20 ? 20 : sourceText.length)}...": $e');
      return sourceText; // Fallback to Arabic so the app doesn't crash
    }
  }
}
