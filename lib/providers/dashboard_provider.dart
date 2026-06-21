import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../models/contact.dart';
import '../models/invoice.dart';
import '../services/database_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  bool _isLoading = false;
  List<Account> _accounts = [];
  List<Invoice> _lastInvoices = [];
  List<Contact> _contacts = [];

  double _totalAssets = 0.0;
  double _totalLiabilities = 0.0;
  double _totalEquity = 0.0;
  double _netProfitOrLoss = 0.0;

  Map<int, String> _contactNames = {};

  // ===== Getters آمنة =====
  bool get isLoading => _isLoading;
  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Invoice> get lastInvoices => List.unmodifiable(_lastInvoices);
  Map<int, String> get contactNames => Map.unmodifiable(_contactNames);
  double get totalAssets => _totalAssets;
  double get totalLiabilities => _totalLiabilities;
  double get totalEquity => _totalEquity;
  double get netProfitOrLoss => _netProfitOrLoss;

  DashboardProvider() {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    _setLoading(true);
    try {
      await _loadDataSafely();
      _calculateFinancialIndicators();
      _buildContactMapSafely();
    } catch (e, stack) {
      debugPrint("DashboardProvider Error: $e");
      debugPrint(stack.toString());
      _resetToDefaults();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadDataSafely() async {
    try { _accounts = await _dbService.getAllAccounts(); } catch (e) { debugPrint("خطأ تحميل الحسابات: $e"); _accounts = []; }
    try { _lastInvoices = await _dbService.getLastInvoices(limit: 5); } catch (e) { debugPrint("خطأ تحميل الفواتير: $e"); _lastInvoices = []; }
    try { _contacts = await _dbService.getAllContacts(); } catch (e) { debugPrint("خطأ تحميل جهات الاتصال: $e"); _contacts = []; }
  }

  void _calculateFinancialIndicators() {
    _totalAssets = 0.0;
    _totalLiabilities = 0.0;
    _totalEquity = 0.0;
    _netProfitOrLoss = 0.0;

    for (final account in _accounts) {
      final balance = account.balance;
      switch (account.accountType) {
        case 'ASSET': _totalAssets += balance;
        case 'LIABILITY': _totalLiabilities += balance;
        case 'EQUITY': _totalEquity += balance;
        case 'REVENUE': _netProfitOrLoss += balance;
        case 'EXPENSE': _netProfitOrLoss -= balance;
      }
    }
  }

  void _buildContactMapSafely() {
    _contactNames = {};
    for (final contact in _contacts) {
      if (contact.id != null) {
        _contactNames[contact.id!] = contact.name;
      }
    }
  }

  void _resetToDefaults() {
    _accounts = [];
    _lastInvoices = [];
    _contacts = [];
    _totalAssets = 0.0;
    _totalLiabilities = 0.0;
    _totalEquity = 0.0;
    _netProfitOrLoss = 0.0;
    _contactNames = {};
  }

  void _setLoading(bool value) {
    _isLoading = value;
    try { notifyListeners(); } catch (_) {}
  }

  Future<void> refresh() async => await loadDashboardData();

  void clearData() {
    _resetToDefaults();
    try { notifyListeners(); } catch (_) {}
  }
}