import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = Locale('en'); // 默认语言为英文
  static const String _languageKey = 'selected_language';

  Locale get locale => _locale;

  // 从SharedPreferences加载保存的语言设置
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    if (_locale.languageCode != languageCode) {
      print('Language changing from ${_locale.languageCode} to $languageCode');
      
      // 先更新语言设置
      _locale = Locale(languageCode);
      
      // 保存到SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      print('Language changed to: $languageCode and saved to preferences');
      
      // 通知界面更新
      notifyListeners();
    }
  }
}
// flutter pub run intl_utils:generate
