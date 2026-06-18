import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/journal_entry.dart';
import '../services/database_service.dart';

class JournalEntriesProvider extends ChangeNotifier {
  final _dbService = DatabaseService.instance;

  List<JournalEntry> _journalEntries = [];
  List<Account> _accounts = [];
  Map<String, Account> _accountsMap = {};
  bool _isLoading = false;

  List<JournalEntry> get journalEntries => _journalEntries;
  List<Account> get accounts => _accounts;
  Map<String, Account> get accountsMap => _accountsMap;
  bool get isLoading => _isLoading;

  JournalEntriesProvider() {
    _loadAllDataSafely();
  }

  Future<void> _loadAllDataSafely() async {
    _isLoading = true;
    notifyListeners();
    try {
      _journalEntries = await _dbService.getAllJournalEntries();
      _accounts = await _dbService.getAllAccounts();
      _accountsMap = {for (var acc in _accounts) acc.accountCode: acc};
    } catch (e) {
      debugPrint("خطأ في تحميل بيانات القيود: $e");
      _journalEntries = [];
      _accounts = [];
      _accountsMap = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllData() async {
    await _loadAllDataSafely();
  }

  Future<bool> createManualJournalEntry(
    String date,
    String description,
    String? reference,
    List<JournalEntryLine> lines,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final now = DateTime.now().toIso8601String();
      final newEntry = JournalEntry(
        entryDate: date,
        description: description,
        referenceNo: reference,
        sourceDocument: 'قيد يدوي عام',
        createdAt: now,
        lines: lines,
      );
      await _dbService.insertJournalEntry(newEntry);
      await _loadAllDataSafely();
      return true;
    } catch (e) {
      debugPrint("خطأ في إنشاء القيد اليدوي: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getAccountName(String code) {
    return _accountsMap[code]?.nameAr ?? code;
  }
}