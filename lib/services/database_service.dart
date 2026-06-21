import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/contact.dart';
import '../models/inventory_item.dart';
import '../models/invoice.dart';
import '../models/journal_entry.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    // تحقق آمن من أن قاعدة البيانات مفتوحة وجاهزة
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDB('theeqah_accounting.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');

    await db.execute('''
      CREATE TABLE accounts (
        account_code TEXT PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_en TEXT,
        account_type TEXT NOT NULL,
        is_debit_normal INTEGER NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        parent_code TEXT,
        level_depth INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (parent_code) REFERENCES accounts (account_code)
      )
    ''');

    await db.execute('''
      CREATE TABLE warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT,
        location TEXT,
        code TEXT UNIQUE NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        sale_price REAL NOT NULL,
        purchase_price REAL NOT NULL,
        quantity_in_stock REAL NOT NULL DEFAULT 0.0,
        warehouse_id INTEGER,
        FOREIGN KEY (warehouse_id) REFERENCES warehouses (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT NOT NULL,
        movement_type TEXT NOT NULL,
        quantity REAL NOT NULL,
        source_warehouse_id INTEGER,
        destination_warehouse_id INTEGER,
        movement_date TEXT NOT NULL,
        reference_doc TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        tax_number TEXT,
        opening_balance REAL NOT NULL DEFAULT 0.0,
        current_balance REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        contact_id INTEGER,
        invoice_date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount_amount REAL NOT NULL DEFAULT 0.0,
        tax_amount REAL NOT NULL,
        total_amount REAL NOT NULL,
        payment_type TEXT NOT NULL,
        warehouse_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        sku TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        tax_rate REAL NOT NULL DEFAULT 0.15,
        tax_amount REAL NOT NULL,
        total_amount REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_date TEXT NOT NULL,
        description TEXT NOT NULL,
        source_document TEXT,
        reference_no TEXT,
        created_at TEXT NOT NULL,
        cost_center_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE journal_entry_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        journal_entry_id INTEGER NOT NULL,
        account_code TEXT NOT NULL,
        debit REAL NOT NULL DEFAULT 0.0,
        credit REAL NOT NULL DEFAULT 0.0,
        description TEXT,
        FOREIGN KEY (journal_entry_id) REFERENCES journal_entries (id) ON DELETE CASCADE
      )
    ''');

    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // فارغة تماماً ليبدأ التطبيق بدون بيانات
  }

  // --- دليل الحسابات ---
  Future<List<Account>> getAllAccounts() async {
    final db = await database;
    final result = await db.query('accounts', orderBy: 'account_code ASC');
    if (result.isEmpty) return [];
    return result.map((e) => Account.fromMap(e)).toList();
  }

  Future<void> insertAccount(Account account) async {
    final db = await database;
    await db.insert('accounts', account.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- جهات الاتصال ---
  Future<List<Contact>> getAllContacts() async {
    final db = await database;
    final result = await db.query('contacts', orderBy: 'name ASC');
    if (result.isEmpty) return [];
    return result.map((e) => Contact.fromMap(e)).toList();
  }

  Future<void> insertContact(Contact contact) async {
    final db = await database;
    await db.insert('contacts', contact.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- الأصناف ---
  Future<List<InventoryItem>> getAllInventoryItems() async {
    final db = await database;
    final result = await db.query('inventory_items', orderBy: 'name ASC');
    if (result.isEmpty) return [];
    return result.map((e) => InventoryItem.fromMap(e)).toList();
  }

  Future<void> insertInventoryItem(InventoryItem item) async {
    final db = await database;
    await db.insert('inventory_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- الفواتير ---
  Future<List<Invoice>> getAllInvoices() async {
    final db = await database;
    final result = await db.query('invoices', orderBy: 'invoice_date DESC, id DESC');
    if (result.isEmpty) return [];

    List<Invoice> invoices = [];
    for (final json in result) {
      final int? id = json['id'] as int?;
      final linesResult = id == null
          ? <Map<String, dynamic>>[]
          : await db.query('invoice_lines', where: 'invoice_id = ?', whereArgs: [id]);
      final lines = linesResult.map((e) => InvoiceLine.fromMap(e)).toList();
      invoices.add(Invoice.fromMap(json, lines: lines));
    }
    return invoices;
  }

  Future<List<Invoice>> getLastInvoices({int limit = 5}) async {
    final db = await database;
    final result = await db.query('invoices', orderBy: 'invoice_date DESC, id DESC', limit: limit);
    if (result.isEmpty) return [];

    List<Invoice> invoices = [];
    for (final json in result) {
      final int? id = json['id'] as int?;
      final linesResult = id == null
          ? <Map<String, dynamic>>[]
          : await db.query('invoice_lines', where: 'invoice_id = ?', whereArgs: [id]);
      final lines = linesResult.map((e) => InvoiceLine.fromMap(e)).toList();
      invoices.add(Invoice.fromMap(json, lines: lines));
    }
    return invoices;
  }

  Future<void> insertInvoice(Invoice invoice) async {
    final db = await database;
    await db.transaction((txn) async {
      final invoiceId = await txn.insert('invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      if (invoice.lines.isNotEmpty) {
        for (final line in invoice.lines) {
          await txn.insert('invoice_lines', line.toMap(parentInvoiceId: invoiceId));
        }
      }
    });
  }

  // --- القيود اليومية ---
  Future<List<JournalEntry>> getAllJournalEntries() async {
    final db = await database;
    final result = await db.query('journal_entries', orderBy: 'entry_date DESC, id DESC');
    if (result.isEmpty) return [];

    List<JournalEntry> entries = [];
    for (final json in result) {
      final int? id = json['id'] as int?;
      final linesResult = id == null
          ? <Map<String, dynamic>>[]
          : await db.query('journal_entry_lines', where: 'journal_entry_id = ?', whereArgs: [id]);
      final lines = linesResult.map((e) => JournalEntryLine.fromMap(e)).toList();
      entries.add(JournalEntry.fromMap(json, lines: lines));
    }
    return entries;
  }

  Future<void> insertJournalEntry(JournalEntry entry) async {
    final db = await database;
    await db.transaction((txn) async {
      final entryId = await txn.insert('journal_entries', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      if (entry.lines.isNotEmpty) {
        for (final line in entry.lines) {
          await txn.insert('journal_entry_lines', line.toMap(entryId: entryId));
        }
      }
    });
  }

  // إغلاق آمن
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}