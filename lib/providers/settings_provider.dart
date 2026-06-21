import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService.instance;

  AppSettings _settings = AppSettings();
  bool _isLoading = false;

  // ================= GETTERS =================
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  // ================= CONSTRUCTOR =================
  SettingsProvider() {
    _loadSettingsSafely();
  }

  // ================= LOAD =================
  Future<void> _loadSettingsSafely() async {
    _setLoading(true);

    try {
      final loadedSettings = await _service.loadSettings();
      _settings = loadedSettings;
    } catch (e) {
      debugPrint("خطأ تحميل الإعدادات: $e");
      _settings = AppSettings(); // fallback آمن
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSettings() async => await _loadSettingsSafely();

  // ================= SAVE =================
  Future<void> saveSettings(AppSettings newSettings) async {
    _setLoading(true);

    try {
      _settings = _sanitizeSettings(newSettings);
      await _service.saveSettings(_settings);
    } catch (e) {
      debugPrint("خطأ حفظ الإعدادات: $e");
    } finally {
      _setLoading(false);
    }
  }

  // ================= UPDATE METHODS =================
  Future<void> updateCompanyName(String? name) async {
    final updated = _copyCurrent();
    updated.companyName = (name?.trim().isNotEmpty ?? false) ? name!.trim() : 'اسم الشركة';
    await saveSettings(updated);
  }

  Future<void> updateTaxRate(double? rate) async {
    final updated = _copyCurrent();
    updated.defaultTaxRate = (rate != null && rate >= 0) ? rate : 0.0;
    await saveSettings(updated);
  }

  Future<void> updateInvoicePrefix(String? prefix) async {
    final updated = _copyCurrent();
    updated.invoicePrefix = (prefix?.trim().isNotEmpty ?? false) ? prefix!.trim() : 'INV-';
    await saveSettings(updated);
  }

  Future<void> updatePassword(String? newPassword) async {
    final updated = _copyCurrent();
    updated.passwordHash = (newPassword?.trim().isNotEmpty ?? false) ? newPassword!.trim() : null;
    await saveSettings(updated);
  }

  Future<void> updatePhoneNumber(String? phone) async {
    final updated = _copyCurrent();
    updated.phoneNumber = (phone?.trim().isNotEmpty ?? false) ? phone!.trim() : null;
    await saveSettings(updated);
  }

  // ================= HELPERS =================
  AppSettings _copyCurrent() {
    return AppSettings(
      companyName: _settings.companyName,
      logoPath: _settings.logoPath,
      phoneNumber: _settings.phoneNumber,
      defaultCurrency: _settings.defaultCurrency,
      defaultTaxRate: _settings.defaultTaxRate,
      invoicePrefix: _settings.invoicePrefix,
      paperSize: _settings.paperSize,
      exportFormat: _settings.exportFormat,
      showHeaderOnInvoice: _settings.showHeaderOnInvoice,
      showFooterOnInvoice: _settings.showFooterOnInvoice,
      passwordHash: _settings.passwordHash,
    );
  }

  AppSettings _sanitizeSettings(AppSettings input) {
    return AppSettings(
      companyName: input.companyName.trim().isEmpty ? 'اسم الشركة' : input.companyName,
      logoPath: input.logoPath,
      phoneNumber: input.phoneNumber,
      defaultCurrency: input.defaultCurrency.isEmpty ? 'SAR' : input.defaultCurrency,
      defaultTaxRate: input.defaultTaxRate < 0 ? 0.0 : input.defaultTaxRate,
      invoicePrefix: input.invoicePrefix.isEmpty ? 'INV-' : input.invoicePrefix,
      paperSize: input.paperSize.isEmpty ? 'A4' : input.paperSize,
      exportFormat: input.exportFormat.isEmpty ? 'PDF' : input.exportFormat,
      showHeaderOnInvoice: input.showHeaderOnInvoice,
      showFooterOnInvoice: input.showFooterOnInvoice,
      passwordHash: input.passwordHash,
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    try { notifyListeners(); } catch (_) {}
  }

  // ================= RESET =================
  Future<void> resetToDefault() async {
    await saveSettings(AppSettings());
  }
}