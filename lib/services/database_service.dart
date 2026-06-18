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
    if (_database != null) return _database!;
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
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. دليل الحسابات
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

    // 2. المستودعات
    await db.execute('''
      CREATE TABLE warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT,
        location TEXT,
        code TEXT UNIQUE NOT NULL
      )
    ''');

    // 3. الأصناف
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

    // 4. حركات المخزن
    await db.execute('''
      CREATE TABLE inventory_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT NOT NULL,
        movement_type TEXT NOT NULL,
        quantity REAL NOT NULL,
        source_warehouse_id INTEGER,
        destination_warehouse_id INTEGER,
        movement_date TEXT NOT NULL,
        reference_doc TEXT,
        FOREIGN KEY (sku) REFERENCES inventory_items (sku),
        FOREIGN KEY (source_warehouse_id) REFERENCES warehouses (id),
        FOREIGN KEY (destination_warehouse_id) REFERENCES warehouses (id)
      )
    ''');

    // 5. جهات الاتصال (بالحقول المالية)
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

    // 6. الفواتير
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
        warehouse_id INTEGER,
        FOREIGN KEY (contact_id) REFERENCES contacts (id),
        FOREIGN KEY (warehouse_id) REFERENCES warehouses (id)
      )
    ''');

    // 7. سطور الفواتير
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
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (sku) REFERENCES inventory_items (sku)
      )
    ''');

    // 8. القيود اليومية
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

    // 9. سطور القيود اليومية
    await db.execute('''
      CREATE TABLE journal_entry_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        journal_entry_id INTEGER NOT NULL,
        account_code TEXT NOT NULL,
        debit REAL NOT NULL DEFAULT 0.0,
        credit REAL NOT NULL DEFAULT 0.0,
        description TEXT,
        FOREIGN KEY (journal_entry_id) REFERENCES journal_entries (id) ON DELETE CASCADE,
        FOREIGN KEY (account_code) REFERENCES accounts (account_code)
      )
    ''');

    // 10. المستخدمون والصلاحيات
    await db.execute('''
      CREATE TABLE roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role_name TEXT UNIQUE NOT NULL,
        permissions TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role_id INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (role_id) REFERENCES roles (id)
      )
    ''');

    // 11. سجل التدقيق
    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        action TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        old_values TEXT,
        new_values TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // 12. المرتجعات
    await db.execute('''
      CREATE TABLE returns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        return_number TEXT UNIQUE NOT NULL,
        invoice_id INTEGER,
        return_type TEXT NOT NULL,
        return_date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax_amount REAL NOT NULL,
        total_amount REAL NOT NULL,
        reason TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id)
      )
    ''');

    // 13. العملات وأسعار الصرف
    await db.execute('''
      CREATE TABLE currencies (
        code TEXT PRIMARY KEY,
        name_ar TEXT NOT NULL,
        symbol TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exchange_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currency_code TEXT NOT NULL,
        rate REAL NOT NULL,
        effective_date TEXT NOT NULL,
        FOREIGN KEY (currency_code) REFERENCES currencies (code)
      )
    ''');

    // 14. مراكز التكلفة
    await db.execute('''
      CREATE TABLE cost_centers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name_ar TEXT NOT NULL,
        name_en TEXT,
        parent_id INTEGER,
        FOREIGN KEY (parent_id) REFERENCES cost_centers (id)
      )
    ''');

    // 15. الأصول الثابتة
    await db.execute('''
      CREATE TABLE fixed_assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_code TEXT UNIQUE NOT NULL,
        name_ar TEXT NOT NULL,
        purchase_date TEXT NOT NULL,
        purchase_cost REAL NOT NULL,
        scrap_value REAL NOT NULL DEFAULT 0.0,
        useful_life_years INTEGER NOT NULL,
        depreciation_method TEXT NOT NULL,
        accumulated_depreciation REAL NOT NULL DEFAULT 0.0,
        current_book_value REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE asset_depreciations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_id INTEGER NOT NULL,
        depreciation_year INTEGER NOT NULL,
        depreciation_rate REAL NOT NULL,
        depreciation_amount REAL NOT NULL,
        accumulated_after REAL NOT NULL,
        book_value_after REAL NOT NULL,
        journal_entry_id INTEGER,
        FOREIGN KEY (asset_id) REFERENCES fixed_assets (id),
        FOREIGN KEY (journal_entry_id) REFERENCES journal_entries (id)
      )
    ''');

    await _seedInitialData(db);
  }Future<void> _seedInitialData(Database db) async {
    // تم حذف جميع البيانات الافتراضية ليبدأ التطبيق فارغاً
  }

  // --- دليل الحسابات ---
  Future<List<Account>> getAllAccounts() async {
    final db = await instance.database;
    final result = await db.query('accounts', orderBy: 'account_code ASC');
    return result.map((json) => Account.fromMap(json)).toList();
  }

  Future<void> insertAccount(Account account) async {
    final db = await instance.database;
    await db.insert('accounts', account.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- جهات الاتصال ---
  Future<List<Contact>> getAllContacts() async {
    final db = await instance.database;
    final result = await db.query('contacts', orderBy: 'name ASC');
    return result.map((json) => Contact.fromMap(json)).toList();
  }

  Future<void> insertContact(Contact contact) async {
    final db = await instance.database;
    await db.insert('contacts', contact.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- الأصناف ---
  Future<List<InventoryItem>> getAllInventoryItems() async {
    final db = await instance.database;
    final result = await db.query('inventory_items', orderBy: 'name ASC');
    return result.map((json) => InventoryItem.fromMap(json)).toList();
  }

  Future<void> insertInventoryItem(InventoryItem item) async {
    final db = await instance.database;
    await db.insert('inventory_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- الفواتير ---
  Future<List<Invoice>> getAllInvoices() async {
    final db = await instance.database;
    final result = await db.query('invoices', orderBy: 'invoice_date DESC, id DESC');
    List<Invoice> invoices = [];
    for (var json in result) {
      final id = json['id'] as int;
      final linesResult = await db.query('invoice_lines', where: 'invoice_id = ?', whereArgs: [id]);
      final lines = linesResult.map((l) => InvoiceLine.fromMap(l)).toList();
      invoices.add(Invoice.fromMap(json, lines: lines));
    }
    return invoices;
  }

  Future<List<Invoice>> getLastInvoices({int limit = 5}) async {
    final db = await instance.database;
    final result = await db.query('invoices', orderBy: 'invoice_date DESC, id DESC', limit: limit);
    List<Invoice> invoices = [];
    for (var json in result) {
      final id = json['id'] as int;
      final linesResult = await db.query('invoice_lines', where: 'invoice_id = ?', whereArgs: [id]);
      final lines = linesResult.map((l) => InvoiceLine.fromMap(l)).toList();
      invoices.add(Invoice.fromMap(json, lines: lines));
    }
    return invoices;
  }

  Future<void> insertInvoice(Invoice invoice) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final invoiceId = await txn.insert('invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (var line in invoice.lines) {
        await txn.insert('invoice_lines', line.toMap(parentInvoiceId: invoiceId), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // --- القيود اليومية ---
  Future<List<JournalEntry>> getAllJournalEntries() async {
    final db = await instance.database;
    final result = await db.query('journal_entries', orderBy: 'entry_date DESC, id DESC');
    List<JournalEntry> entries = [];
    for (var json in result) {
      final id = json['id'] as int;
      final linesResult = await db.query('journal_entry_lines', where: 'journal_entry_id = ?', whereArgs: [id]);
      final lines = linesResult.map((l) => JournalEntryLine.fromMap(l)).toList();
      entries.add(JournalEntry.fromMap(json, lines: lines));
    }
    return entries;
  }

  Future<void> insertJournalEntry(JournalEntry entry) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final entryId = await txn.insert('journal_entries', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (var line in entry.lines) {
        await txn.insert('journal_entry_lines', line.toMap(entryId: entryId), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}