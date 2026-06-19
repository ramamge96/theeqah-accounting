import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/invoice.dart';
import '../services/database_service.dart';

class DashboardProvider extends ChangeNotifier {
  final _dbService = DatabaseService.instance;

  double _totalAssets = 0.0;
  double _totalLiabilities = 0.0;
  double _totalEquity = 0.0;
  double _totalRevenues = 0.0;
  double _totalExpenses = 0.0;

  List<Invoice> _lastInvoices = [];
  Map<int, String> _contactNames = {};
  bool _isLoading = false;

  double get totalAssets => _totalAssets;
  double get totalLiabilities => _totalLiabilities;
  double get totalEquity => _totalEquity;
  double get totalRevenues => _totalRevenues;
  double get totalExpenses => _totalExpenses;
  double get netProfitOrLoss => _totalRevenues - _totalExpenses;

  List<Invoice> get lastInvoices => _lastInvoices;
  Map<int, String> get contactNames => _contactNames;
  bool get isLoading => _isLoading;

  DashboardProvider() {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final accounts = await _dbService.getAllAccounts();
      _calculateTotals(accounts);

      final contacts = await _dbService.getAllContacts();
      _contactNames = {};
      for (var c in contacts) {
        if (c.id != null) {
          _contactNames[c.id!] = c.name;
        }
      }

      _lastInvoices = await _dbService.getLastInvoices(limit: 5);
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
      _totalAssets = 0;
      _totalLiabilities = 0;
      _totalEquity = 0;
      _totalRevenues = 0;
      _totalExpenses = 0;
      _lastInvoices = [];
      _contactNames = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateTotals(List<Account> accounts) {
    _totalAssets = 0.0;
    _totalLiabilities = 0.0;
    _totalEquity = 0.0;
    _totalRevenues = 0.0;
    _totalExpenses = 0.0;

    if (accounts.isEmpty) return;

    final rootAccounts = accounts.where((acc) => acc.parentCode == null).toList();

    for (var root in rootAccounts) {
      double rootBalance = _sumChildBalances(root.accountCode, accounts);

      switch (root.accountType) {
        case 'ASSET':
          _totalAssets += rootBalance;
          break;
        case 'LIABILITY':
          _totalLiabilities += rootBalance;
          break;
        case 'EQUITY':
          _totalEquity += rootBalance;
          break;
        case 'REVENUE':
          _totalRevenues += rootBalance;
          break;
        case 'EXPENSE':
          _totalExpenses += rootBalance;
          break;
      }
    }
  }

  double _sumChildBalances(String code, List<Account> allAccounts) {
    final children = allAccounts.where((acc) => acc.parentCode == code).toList();
    if (children.isEmpty) {
      final currentAcc = allAccounts.firstWhere(
        (acc) => acc.accountCode == code,
        orElse: () => Account(
          accountCode: code,
          nameAr: '',
          nameEn: '',
          accountType: 'ASSET',
          isDebitNormal: true,
          balance: 0.0,
        ),
      );
      return currentAcc.balance;
    }

    double sum = 0.0;
    for (var child in children) {
      sum += _sumChildBalances(child.accountCode, allAccounts);
    }
    return sum;
  }
}