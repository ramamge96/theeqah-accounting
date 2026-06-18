import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/database_service.dart';

class AccountsProvider extends ChangeNotifier {
  final _dbService = DatabaseService.instance;

  List<Account> _accounts = [];
  String? _selectedTypeFilter;
  String _searchQuery = "";
  bool _isLoading = false;

  List<Account> get accounts => _accounts;
  String? get selectedTypeFilter => _selectedTypeFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  AccountsProvider() {
    _loadAccountsSafely();
  }

  Future<void> _loadAccountsSafely() async {
    _isLoading = true;
    notifyListeners();
    try {
      _accounts = await _dbService.getAllAccounts();
    } catch (e) {
      debugPrint("خطأ في تحميل الحسابات: $e");
      _accounts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAccounts() async {
    await _loadAccountsSafely();
  }

  List<Account> get filteredAccounts {
    List<Account> temp = _accounts;
    if (_selectedTypeFilter != null) {
      temp = temp.where((acc) => acc.accountType == _selectedTypeFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      temp = temp.where((acc) =>
          acc.nameAr.contains(_searchQuery) ||
          acc.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          acc.accountCode.contains(_searchQuery)).toList();
    }
    return temp;
  }

  void setTypeFilter(String? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> addNewAccount({
    required String code,
    required String nameAr,
    required String nameEn,
    required String type,
    required bool isDebitNormal,
    required double initialBalance,
    String? parentCode,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      int computedLevel = 1;
      if (parentCode != null && parentCode.isNotEmpty) {
        final parent = _accounts.firstWhere(
          (acc) => acc.accountCode == parentCode,
          orElse: () => Account(
            accountCode: parentCode,
            nameAr: "",
            nameEn: "",
            accountType: type,
            isDebitNormal: isDebitNormal,
          ),
        );
        if (parent.nameAr.isNotEmpty) {
          computedLevel = parent.level + 1;
        }
      }
      final newAccount = Account(
        accountCode: code,
        nameAr: nameAr,
        nameEn: nameEn,
        accountType: type,
        isDebitNormal: isDebitNormal,
        balance: initialBalance,
        parentCode: parentCode == "" ? null : parentCode,
        level: computedLevel,
      );
      await _dbService.insertAccount(newAccount);
      await _loadAccountsSafely();
      return true;
    } catch (e) {
      debugPrint("خطأ في إنشاء الحساب: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}