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
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _service.loadSettings();
    } catch (e) {
      debugPrint("Error loading settings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveSettings(AppSettings newSettings) async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = newSettings;
      await _service.saveSettings(_settings);
    } catch (e) {
      debugPrint("Error saving settings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // دوال مساعدة لتحديث حقول محددة
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
    _settings.passwordHash = newPassword; // لاحقاً نضيف تشفير
    await saveSettings(_settings);
  }
}