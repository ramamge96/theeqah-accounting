import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final _service = SettingsService.instance;
  AppSettings _settings = AppSettings();
  bool _isLoading = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    // تحميل الإعدادات بشكل آمن بدون انتظار
    _loadSettingsSafely();
  }

  Future<void> _loadSettingsSafely() async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _service.loadSettings();
    } catch (e) {
      debugPrint("خطأ في تحميل الإعدادات: $e");
      _settings = AppSettings(); // استخدام الإعدادات الافتراضية
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    await _loadSettingsSafely();
  }

  Future<void> saveSettings(AppSettings newSettings) async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = newSettings;
      await _service.saveSettings(_settings);
    } catch (e) {
      debugPrint("خطأ في حفظ الإعدادات: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCompanyName(String name) async {
    _settings.companyName = name;
    await saveSettings(_settings);
  }

  Future<void> updateTaxRate(double rate) async {
    _settings.defaultTaxRate = rate;
    await saveSettings(_settings);
  }

  Future<void> updateInvoicePrefix(String prefix) async {
    _settings.invoicePrefix = prefix;
    await saveSettings(_settings);
  }

  Future<void> updatePassword(String newPassword) async {
    _settings.passwordHash = newPassword;
    await saveSettings(_settings);
  }
}