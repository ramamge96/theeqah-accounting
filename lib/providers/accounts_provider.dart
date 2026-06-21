import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/database_service.dart';

class AccountsProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<Account> _accounts = [];
  List<Account> _filteredAccounts = [];

  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedTypeFilter;

  // ================= GETTERS =================
  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Account> get filteredAccounts => List.unmodifiable(_filteredAccounts);
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedTypeFilter => _selectedTypeFilter;

  // ================= CONSTRUCTOR =================
  AccountsProvider() {
    _loadAccountsSafely();
  }

  // ================= LOAD =================
  Future<void> _loadAccountsSafely() async {
    _isLoading = true;
    try { notifyListeners(); } catch (_) {}

    try {
      final result = await _dbService.getAllAccounts();
      _accounts = result;
      _applyFiltersSafely();
    } catch (e) {
      debugPrint("خطأ تحميل الحسابات: $e");
      _accounts = [];
      _filteredAccounts = [];
    } finally {
      _isLoading = false;
      try { notifyListeners(); } catch (_) {}
    }
  }

  Future<void> loadAccounts() async => await _loadAccountsSafely();

  // ================= FILTER =================
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _applyFiltersSafely();
    try { notifyListeners(); } catch (_) {}
  }

  void setTypeFilter(String? type) {
    _selectedTypeFilter = type;
    _applyFiltersSafely();
    try { notifyListeners(); } catch (_) {}
  }

  void _applyFiltersSafely() {
    List<Account> temp = List<Account>.from(_accounts);

    if (_selectedTypeFilter != null && _selectedTypeFilter!.isNotEmpty) {
      temp = temp.where((acc) => acc.accountType == _selectedTypeFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final search = _searchQuery.toLowerCase();
      temp = temp.where((acc) {
        final code = (acc.accountCode).toLowerCase();
        final nameAr = (acc.nameAr).toLowerCase();
        final nameEn = (acc.nameEn).toLowerCase();
        return code.contains(search) || nameAr.contains(search) || nameEn.contains(search);
      }).toList();
    }

    _filteredAccounts = temp;
  }

  // ================= ADD ACCOUNT =================
  Future<bool> addNewAccount({
    required String code,
    required String nameAr,
    String nameEn = '',
    required String type,
    required bool isDebitNormal,
    double initialBalance = 0.0,
    String? parentCode,
  }) async {
    _isLoading = true;
    try { notifyListeners(); } catch (_) {}

    try {
      int level = 1;
      if (parentCode != null && parentCode.isNotEmpty) {
        final parentList = _accounts.where((acc) => acc.accountCode == parentCode);
        if (parentList.isNotEmpty) {
          level = parentList.first.level + 1;
        }
      }

      final newAccount = Account(
        accountCode: code,
        nameAr: nameAr,
        nameEn: nameEn,
        accountType: type,
        isDebitNormal: isDebitNormal,
        balance: initialBalance,
        parentCode: parentCode,
        level: level,
      );

      await _dbService.insertAccount(newAccount);
      await _loadAccountsSafely();
      return true;
    } catch (e) {
      debugPrint("خطأ إضافة الحساب: $e");
      return false;
    } finally {
      _isLoading = false;
      try { notifyListeners(); } catch (_) {}
    }
  }

  // ================= UTILITIES =================
  Account? getAccountByCode(String code) {
    try {
      final result = _accounts.where((acc) => acc.accountCode == code);
      return result.isEmpty ? null : result.first;
    } catch (e) {
      debugPrint("خطأ البحث عن الحساب: $e");
      return null;
    }
  }

  bool accountExists(String code) {
    return _accounts.any((acc) => acc.accountCode == code);
  }

  List<Account> getChildAccounts(String parentCode) {
    return _accounts.where((acc) => acc.parentCode == parentCode).toList();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedTypeFilter = null;
    _filteredAccounts = List<Account>.from(_accounts);
    try { notifyListeners(); } catch (_) {}
  }

  Future<void> refreshAccounts() async => await _loadAccountsSafely();
}