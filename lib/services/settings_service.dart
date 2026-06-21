import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const String _key = 'app_settings';

  static final SettingsService instance = SettingsService._init();
  SettingsService._init();

  /// حفظ الإعدادات
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(settings.toMap());
      await prefs.setString(_key, json);
    } catch (e) {
      // لا تفعل شيئاً إذا فشل الحفظ
    }
  }

  /// تحميل الإعدادات
  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json == null) return AppSettings();
      
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) {
        return AppSettings.fromMap(decoded);
      }
      return AppSettings();
    } catch (_) {
      return AppSettings(); // الإعدادات الافتراضية عند أي خطأ
    }
  }
}