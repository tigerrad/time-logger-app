import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.dart';

class LanguageProvider extends ChangeNotifier {
  static const _kLang = 'app_language_v3';

  AppLanguage _lang = AppLanguage.fa;
  AppLanguage get lang => _lang;

  Locale get locale {
    switch (_lang) {
      case AppLanguage.fa:
        return const Locale('fa', 'IR');
      case AppLanguage.en:
        return const Locale('en', 'US');
      case AppLanguage.ar:
        return const Locale('ar', 'SA');
    }
  }

  TextDirection get direction => _lang == AppLanguage.en ? TextDirection.ltr : TextDirection.rtl;

  LanguageProvider() {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_kLang);
    if (v == 'en') _lang = AppLanguage.en;
    if (v == 'ar') _lang = AppLanguage.ar;
    if (v == 'fa') _lang = AppLanguage.fa;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage l) async {
    _lang = l;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, l.name);
    notifyListeners();
  }
}