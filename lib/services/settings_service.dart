import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const String _key = 'app_settings';

  static final SettingsService instance = SettingsService._init();
  SettingsService._init();

  /// حفظ الإعدادات
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(settings.toMap());
    await prefs.setString(_key, json);
  }

  /// تحميل الإعدادات
  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return AppSettings.fromMap(map);
    }
    return AppSettings(); // الإعدادات الافتراضية
  }
}