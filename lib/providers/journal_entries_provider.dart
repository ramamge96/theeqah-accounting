import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/journal_entry.dart';
import '../services/database_service.dart';

class JournalEntriesProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<JournalEntry> _journalEntries = [];
  List<Account> _accounts = [];
  Map<String, Account> _accountsMap = {};
  bool _isLoading = false;

  List<JournalEntry> get journalEntries => List.unmodifiable(_journalEntries);
  List<Account> get accounts => List.unmodifiable(_accounts);
  Map<String, Account> get accountsMap => Map.unmodifiable(_accountsMap);
  bool get isLoading => _isLoading;

  JournalEntriesProvider() {
    _loadAllDataSafely();
  }

  Future<void> _loadAllDataSafely() async {
    _isLoading = true;
    try { notifyListeners(); } catch (_) {}
    try {
      final loadedEntries = await _dbService.getAllJournalEntries();
      final loadedAccounts = await _dbService.getAllAccounts();
      _journalEntries = loadedEntries;
      _accounts = loadedAccounts;
      _accountsMap = {};
      for (final acc in _accounts) {
        if (acc.accountCode.isNotEmpty) {
          _accountsMap[acc.accountCode] = acc;
        }
      }
    } catch (e) {
      debugPrint("خطأ تحميل بيانات القيود: $e");
      _journalEntries = [];
      _accounts = [];
      _accountsMap = {};
    } finally {
      _isLoading = false;
      try { notifyListeners(); } catch (_) {}
    }
  }

  Future<void> loadAllData() async => await _loadAllDataSafely();

  Future<bool> createManualJournalEntry(
    String date, String description, String? reference, List<JournalEntryLine> lines,
  ) async {
    _isLoading = true;
    try { notifyListeners(); } catch (_) {}
    try {
      if (lines.isEmpty) return false;
      for (final line in lines) {
        if (line.accountCode.isEmpty) return false;
      }
      final now = DateTime.now().toIso8601String();
      final newEntry = JournalEntry(
        entryDate: date.isEmpty ? DateTime.now().toIso8601String() : date,
        description: description.isEmpty ? 'قيد يومية' : description,
        referenceNo: reference, sourceDocument: 'قيد يدوي عام', createdAt: now, lines: lines,
      );
      await _dbService.insertJournalEntry(newEntry);
      await _loadAllDataSafely();
      return true;
    } catch (e) {
      debugPrint("خطأ إنشاء القيد اليدوي: $e");
      return false;
    } finally {
      _isLoading = false;
      try { notifyListeners(); } catch (_) {}
    }
  }

  String getAccountName(String code) {
    if (code.isEmpty) return 'حساب غير معروف';
    return _accountsMap[code]?.nameAr ?? 'حساب غير موجود';
  }

  Account? getAccountByCode(String code) {
    if (code.isEmpty) return null;
    return _accountsMap[code];
  }

  bool accountExists(String code) {
    if (code.isEmpty) return false;
    return _accountsMap.containsKey(code);
  }

  Future<void> refresh() async => await _loadAllDataSafely();

  void clearState() {
    _journalEntries = []; _accounts = []; _accountsMap = {};
    try { notifyListeners(); } catch (_) {}
  }
}