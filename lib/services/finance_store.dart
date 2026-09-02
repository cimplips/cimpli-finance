import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/recurring_transaction.dart';
import '../models/transaction.dart';

class FinanceStore extends ChangeNotifier {
  Database? _db;

  final List<String> _accounts = <String>[];
  String? _activeAccount;
  bool _loading = false;
  String? _error;

  List<String> get accounts => List.unmodifiable(_accounts);

  String? get activeAccount => _activeAccount;

  bool get loading => _loading;

  bool get isLoading => _loading;

  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final dbPath = join(
        await getDatabasesPath(),
        'keuangan_prima.db',
      );

      _db = await openDatabase(
        dbPath,
        version: 3,
        onCreate: (db, version) async {
          await _createBaseTables(db);
          await _createCategoriesTable(db);
          await _createRecurringTransactionsTable(db);
          await _seedDefaultAccounts(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createCategoriesTable(db);
            await _migrateTransactionCategories(db);
          }

          if (oldVersion < 3) {
            await _createRecurringTransactionsTable(db);
          }
        },
        onOpen: (db) async {
          await _createCategoriesTable(db);
          await _createRecurringTransactionsTable(db);
        },
      );

      await _loadAccounts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _createBaseTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts(
        name TEXT PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        account TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_account_date
      ON transactions(account, date)
    ''');
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        account TEXT NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY(account, name)
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_categories_account
      ON categories(account)
    ''');
  }

  Future<void> _createRecurringTransactionsTable(
    Database db,
  ) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        account TEXT NOT NULL,
        category TEXT NOT NULL,
        start_date TEXT NOT NULL,
        frequency TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        last_generated_date TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_recurring_account
      ON recurring_transactions(account)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_recurring_active
      ON recurring_transactions(is_active)
    ''');
  }

  Future<void> _seedDefaultAccounts(Database db) async {
    final defaultAccounts = <String>[
      'Keuangan Pribadi',
      'Keuangan Kantor',
      'Keuangan Rumah',
    ];

    for (final name in defaultAccounts) {
      await db.insert(
        'accounts',
        {'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _migrateTransactionCategories(
    Database db,
  ) async {
    final rows = await db.query(
      'transactions',
      columns: <String>[
        'account',
        'category',
      ],
      distinct: true,
    );

    final now = DateTime.now().toIso8601String();

    for (final row in rows) {
      final account = row['account'] as String?;
      final category = row['category'] as String?;

      if (account == null ||
          category == null ||
          account.trim().isEmpty ||
          category.trim().isEmpty) {
        continue;
      }

      await db.insert(
        'categories',
        {
          'account': account,
          'name': category,
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _loadAccounts() async {
    final db = _db;

    if (db == null) {
      return;
    }

    final rows = await db.query(
      'accounts',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    _accounts
      ..clear()
      ..addAll(
        rows.map(
          (row) => row['name'] as String,
        ),
      );

    if (_accounts.isEmpty) {
      _activeAccount = null;
      return;
    }

    if (!_accounts.contains(_activeAccount)) {
      _activeAccount = _accounts.first;
    }
  }

  Future<bool> addAccount(String name) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    final cleaned = name.trim();

    if (cleaned.isEmpty) {
      return false;
    }

    try {
      final result = await db.insert(
        'accounts',
        {'name': cleaned},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      if (result <= 0) {
        return false;
      }

      if (_activeAccount == null) {
        _activeAccount = _accounts.first;
      } else if (!_accounts.contains(_activeAccount)) {
        _activeAccount = _accounts.first;
      }

      await _loadAccounts();
      notifyListeners();

      return true;
    } on DatabaseException {
      return false;
    }
  }

  Future<bool> renameAccount(
    String oldName,
    String newName,
  ) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    final cleanedOldName = oldName.trim();
    final cleanedNewName = newName.trim();

    if (cleanedOldName.isEmpty ||
        cleanedNewName.isEmpty ||
        cleanedOldName == cleanedNewName) {
      return false;
    }

    if (_accounts.contains(cleanedNewName)) {
      return false;
    }

    try {
      await db.transaction(
        (txn) async {
          await txn.update(
            'accounts',
            {'name': cleanedNewName},
            where: 'name = ?',
            whereArgs: [cleanedOldName],
          );

          await txn.update(
            'transactions',
            {'account': cleanedNewName},
            where: 'account = ?',
            whereArgs: [cleanedOldName],
          );

          await txn.update(
            'categories',
            {'account': cleanedNewName},
            where: 'account = ?',
            whereArgs: [cleanedOldName],
          );

          await txn.update(
            'recurring_transactions',
            {'account': cleanedNewName},
            where: 'account = ?',
            whereArgs: [cleanedOldName],
          );
        },
      );
    } on DatabaseException {
      return false;
    }

    if (_activeAccount == cleanedOldName) {
      _activeAccount = cleanedNewName;
    }

    await _loadAccounts();
    notifyListeners();

    return true;
  }

  Future<bool> deleteAccount(String name) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    if (_accounts.length <= 1) {
      return false;
    }

    final cleaned = name.trim();

    if (cleaned.isEmpty ||
        !_accounts.contains(cleaned)) {
      return false;
    }

    try {
      await db.transaction(
        (txn) async {
          await txn.delete(
            'transactions',
            where: 'account = ?',
            whereArgs: [cleaned],
          );

          await txn.delete(
            'categories',
            where: 'account = ?',
            whereArgs: [cleaned],
          );

          await txn.delete(
            'recurring_transactions',
            where: 'account = ?',
            whereArgs: [cleaned],
          );

          await txn.delete(
            'accounts',
            where: 'name = ?',
            whereArgs: [cleaned],
          );
        },
      );
    } on DatabaseException {
      return false;
    }

    if (_activeAccount == cleaned) {
      final remaining = _accounts
          .where((account) => account != cleaned)
          .toList();

      _activeAccount =
          remaining.isEmpty ? null : remaining.first;
    }

    await _loadAccounts();
    notifyListeners();

    return true;
  }

  Future<void> setActiveAccount(String name) async {
    if (!_accounts.contains(name)) {
      return;
    }

    _activeAccount = name;
    notifyListeners();
  }

  Future<bool> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required DateTime date,
    required String account,
    required String category,
  }) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    final cleanedTitle = title.trim();
    final cleanedAccount = account.trim();
    final cleanedCategory = category.trim();

    if (cleanedTitle.isEmpty ||
        cleanedAccount.isEmpty ||
        cleanedCategory.isEmpty ||
        amount <= 0) {
      return false;
    }

    try {
      await _ensureCategoryExists(
        account: cleanedAccount,
        category: cleanedCategory,
      );

      final result = await db.insert(
        'transactions',
        {
          'title': cleanedTitle,
          'amount': amount,
          'type': type.name,
          'date': date.toIso8601String(),
          'account': cleanedAccount,
          'category': cleanedCategory,
        },
      );

      if (result <= 0) {
        return false;
      }

      await _refreshCurrentAccount();

      return true;
    } on DatabaseException {
      return false;
    }
  }

  Future<bool> updateTransaction({
    required int id,
    required String title,
    required double amount,
    required TransactionType type,
    required DateTime date,
    required String account,
    required String category,
  }) async {
    final db = _db;

    if (db == null || amount <= 0) {
      return false;
    }

    final cleanedTitle = title.trim();
    final cleanedAccount = account.trim();
    final cleanedCategory = category.trim();

    if (cleanedTitle.isEmpty ||
        cleanedAccount.isEmpty ||
        cleanedCategory.isEmpty) {
      return false;
    }

    try {
      await _ensureCategoryExists(
        account: cleanedAccount,
        category: cleanedCategory,
      );

      final result = await db.update(
        'transactions',
        {
          'title': cleanedTitle,
          'amount': amount,
          'type': type.name,
          'date': date.toIso8601String(),
          'account': cleanedAccount,
          'category': cleanedCategory,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result <= 0) {
        return false;
      }

      await _refreshCurrentAccount();

      return true;
    } on DatabaseException {
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    final result = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result <= 0) {
      return false;
    }

    await _refreshCurrentAccount();

    return true;
  }

  Future<List<Tx>> getTransactions({
    String? account,
    String? category,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = _db;

    if (db == null) {
      return <Tx>[];
    }

    final where = <String>[];
    final args = <Object?>[];

    final targetAccount = account ?? _activeAccount;

    if (targetAccount != null) {
      where.add('account = ?');
      args.add(targetAccount);
    }

    if (category != null &&
        category.trim().isNotEmpty) {
      where.add('category = ?');
      args.add(category.trim());
    }

    if (type != null) {
      where.add('type = ?');
      args.add(type.name);
    }

    if (startDate != null) {
      where.add('date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where.add('date < ?');
      args.add(endDate.toIso8601String());
    }

    final rows = await db.query(
      'transactions',
      where: where.isEmpty
          ? null
          : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, id DESC',
    );

    return rows.map(_transactionFromRow).toList();
  }

  Tx _transactionFromRow(
    Map<String, Object?> row,
  ) {
    return Tx(
      id: row['id'] as int,
      title: row['title'] as String,
      amount: (row['amount'] as num).toDouble(),
      type: TransactionType.values.byName(
        row['type'] as String,
      ),
      date: DateTime.parse(
        row['date'] as String,
      ),
      account: row['account'] as String,
      category: row['category'] as String,
    );
  }

  Future<List<String>> getCategories({
    String? account,
  }) async {
    final db = _db;

    if (db == null) {
      return <String>[];
    }

    final targetAccount = account ?? _activeAccount;

    if (targetAccount == null ||
        targetAccount.trim().isEmpty) {
      return <String>[];
    }

    final categoryRows = await db.query(
      'categories',
      columns: ['name'],
      where: 'account = ?',
      whereArgs: [targetAccount],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    final result = <String>{
      for (final row in categoryRows)
        row['name'] as String,
    };

    final transactionRows = await db.query(
      'transactions',
      columns: ['category'],
      where: 'account = ?',
      whereArgs: [targetAccount],
      distinct: true,
      orderBy: 'category COLLATE NOCASE ASC',
    );

    for (final row in transactionRows) {
      final category = row['category'] as String?;

      if (category != null &&
          category.trim().isNotEmpty) {
        result.add(category);
      }
    }

    final categories = result.toList();

    categories.sort(
      (a, b) => a.toLowerCase().compareTo(
            b.toLowerCase(),
          ),
    );

    return categories;
  }

  Future<bool> addCategory({
    required String account,
    required String name,
  }) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    final cleanedAccount = account.trim();
    final cleanedName = name.trim();

    if (cleanedAccount.isEmpty ||
        cleanedName.isEmpty) {
      return false;
    }

    try {
      final result = await db.insert(
        'categories',
        {
          'account': cleanedAccount,
          'name': cleanedName,
          'created_at':
              DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      if (result <= 0) {
        return false;
      }

      notifyListeners();

      return true;
    } on DatabaseException {
      return false;
    }
  }

  Future<bool> renameCategory({
    required String account,
    required String oldName,
    required String newName,
  }) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    final cleanedAccount = account.trim();
    final cleanedOldName = oldName.trim();
    final cleanedNewName = newName.trim();

    if (cleanedAccount.isEmpty ||
        cleanedOldName.isEmpty ||
        cleanedNewName.isEmpty ||
        cleanedOldName == cleanedNewName) {
      return false;
    }

    final existing = await db.query(
      'categories',
      where: 'account = ? AND name = ?',
      whereArgs: [
        cleanedAccount,
        cleanedNewName,
      ],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return false;
    }

    try {
      await db.transaction(
        (txn) async {
          final categoryResult = await txn.update(
            'categories',
            {'name': cleanedNewName},
            where: 'account = ? AND name = ?',
            whereArgs: [
              cleanedAccount,
              cleanedOldName,
            ],
          );

          if (categoryResult == 0) {
            throw StateError(
              'Kategori tidak ditemukan.',
            );
          }

          await txn.update(
            'transactions',
            {'category': cleanedNewName},
            where: 'account = ? AND category = ?',
            whereArgs: [
              cleanedAccount,
              cleanedOldName,
            ],
          );

          await txn.update(
            'recurring_transactions',
            {'category': cleanedNewName},
            where: 'account = ? AND category = ?',
            whereArgs: [
              cleanedAccount,
              cleanedOldName,
            ],
          );
        },
      );
    } on DatabaseException {
      return false;
    } on StateError {
      return false;
    }

    notifyListeners();

    return true;
  }

  Future<bool> isCategoryUsed({
    required String account,
    required String name,
  }) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    final rows = await db.query(
      'transactions',
      columns: ['id'],
      where: 'account = ? AND category = ?',
      whereArgs: [
        account,
        name,
      ],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<bool> deleteCategory({
    required String account,
    required String name,
  }) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    if (await isCategoryUsed(
      account: account,
      name: name,
    )) {
      return false;
    }

    final result = await db.delete(
      'categories',
      where: 'account = ? AND name = ?',
      whereArgs: [
        account,
        name,
      ],
    );

    if (result <= 0) {
      return false;
    }

    notifyListeners();

    return true;
  }

  Future<double> getBalance({
    String? account,
  }) async {
    final income = await getTotalIncome(
      account: account,
    );

    final expense = await getTotalExpense(
      account: account,
    );

    return income - expense;
  }

  Future<double> getTotalIncome({
    String? account,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _getTotalByType(
      account: account,
      type: TransactionType.income,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<double> getTotalExpense({
    String? account,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _getTotalByType(
      account: account,
      type: TransactionType.expense,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<double> _getTotalByType({
    String? account,
    required TransactionType type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = _db;

    if (db == null) {
      return 0;
    }

    final where = <String>[];
    final args = <Object?>[];

    final targetAccount = account ?? _activeAccount;

    if (targetAccount != null) {
      where.add('account = ?');
      args.add(targetAccount);
    }

    where.add('type = ?');
    args.add(type.name);

    if (startDate != null) {
      where.add('date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where.add('date < ?');
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0)
      FROM transactions
      WHERE ${where.join(' AND ')}
      ''',
      args,
    );

    final value = result.first.values.first;

    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }

  Future<List<RecurringTransaction>>
      getRecurringTransactions({
    String? account,
    bool activeOnly = false,
  }) async {
    final db = _db;

    if (db == null) {
      return <RecurringTransaction>[];
    }

    final targetAccount = account ?? _activeAccount;

    final where = <String>[];
    final args = <Object?>[];

    if (targetAccount != null) {
      where.add('account = ?');
      args.add(targetAccount);
    }

    if (activeOnly) {
      where.add('is_active = 1');
    }

    final rows = await db.query(
      'recurring_transactions',
      where: where.isEmpty
          ? null
          : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'start_date ASC, id ASC',
    );

    return rows
        .map(
          RecurringTransaction.fromMap,
        )
        .toList();
  }

  Future<RecurringTransaction?>
      getRecurringTransaction(
    int id,
  ) async {
    final db = _db;

    if (db == null) {
      return null;
    }

    final rows = await db.query(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return RecurringTransaction.fromMap(
      rows.first,
    );
  }

  Future<bool> addRecurringTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String account,
    required String category,
    required DateTime startDate,
    required RecurringFrequency frequency,
  }) async {
    final db = _db;

    if (db == null || amount <= 0) {
      return false;
    }

    final cleanedTitle = title.trim();
    final cleanedAccount = account.trim();
    final cleanedCategory = category.trim();

    if (cleanedTitle.isEmpty ||
        cleanedAccount.isEmpty ||
        cleanedCategory.isEmpty) {
      return false;
    }

    try {
      await _ensureCategoryExists(
        account: cleanedAccount,
        category: cleanedCategory,
      );

      final result = await db.insert(
        'recurring_transactions',
        {
          'title': cleanedTitle,
          'amount': amount,
          'type': type.name,
          'account': cleanedAccount,
          'category': cleanedCategory,
          'start_date':
              startDate.toIso8601String(),
          'frequency': frequency.name,
          'is_active': 1,
          'last_generated_date': null,
        },
      );

      if (result <= 0) {
        return false;
      }

      notifyListeners();

      return true;
    } on DatabaseException {
      return false;
    }
  }

  Future<bool> updateRecurringTransaction({
    required int id,
    required String title,
    required double amount,
    required TransactionType type,
    required String account,
    required String category,
    required DateTime startDate,
    required RecurringFrequency frequency,
  }) async {
    final db = _db;

    if (db == null || amount <= 0) {
      return false;
    }

    final cleanedTitle = title.trim();
    final cleanedAccount = account.trim();
    final cleanedCategory = category.trim();

    if (cleanedTitle.isEmpty ||
        cleanedAccount.isEmpty ||
        cleanedCategory.isEmpty) {
      return false;
    }

    try {
      await _ensureCategoryExists(
        account: cleanedAccount,
        category: cleanedCategory,
      );

      final result = await db.update(
        'recurring_transactions',
        {
          'title': cleanedTitle,
          'amount': amount,
          'type': type.name,
          'account': cleanedAccount,
          'category': cleanedCategory,
          'start_date':
              startDate.toIso8601String(),
          'frequency': frequency.name,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result <= 0) {
        return false;
      }

      notifyListeners();

      return true;
    } on DatabaseException {
      return false;
    }
  }

  Future<bool> setRecurringTransactionActive({
    required int id,
    required bool active,
  }) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    final result = await db.update(
      'recurring_transactions',
      {
        'is_active': active ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result <= 0) {
      return false;
    }

    notifyListeners();

    return true;
  }

  Future<bool> deleteRecurringTransaction(
    int id,
  ) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    final result = await db.delete(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result <= 0) {
      return false;
    }

    notifyListeners();

    return true;
  }

  Future<int> generateDueRecurringTransactions({
    DateTime? until,
  }) async {
    final db = _db;

    if (db == null) {
      return 0;
    }

    final targetDate = until ?? DateTime.now();

    final recurringRows = await db.query(
      'recurring_transactions',
      where: 'is_active = 1',
      orderBy: 'start_date ASC, id ASC',
    );

    var generatedCount = 0;

    for (final row in recurringRows) {
      final recurring =
          RecurringTransaction.fromMap(row);

      final dates = _getDueDates(
        recurring: recurring,
        until: targetDate,
      );

      for (final date in dates) {
        await _ensureCategoryExists(
          account: recurring.account,
          category: recurring.category,
        );

        await db.insert(
          'transactions',
          {
            'title': recurring.title,
            'amount': recurring.amount,
            'type': recurring.type,
            'date': date.toIso8601String(),
            'account': recurring.account,
            'category': recurring.category,
          },
        );

        generatedCount++;

        await db.update(
          'recurring_transactions',
          {
            'last_generated_date':
                date.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [recurring.id],
        );
      }
    }

    if (generatedCount > 0) {
      await _refreshCurrentAccount();
    }

    return generatedCount;
  }

  List<DateTime> _getDueDates({
    required RecurringTransaction recurring,
    required DateTime until,
  }) {
    final dates = <DateTime>[];

    DateTime? nextDate = _nextRecurringDate(
      recurring: recurring,
    );

    while (nextDate != null &&
        !nextDate.isAfter(until)) {
      final dueDate = nextDate;
      dates.add(dueDate);

      nextDate = _nextRecurringDate(
        recurring: recurring,
        after: dueDate,
      );

      if (dates.length >= 120) {
        break;
      }
    }

    return dates;
  }

  DateTime? _nextRecurringDate({
    required RecurringTransaction recurring,
    DateTime? after,
  }) {
    final baseDate = after ??
        recurring.lastGeneratedDate ??
        _dateBeforeStart(recurring.startDate);

    DateTime next;

    switch (recurring.frequency) {
      case RecurringFrequency.weekly:
        next = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day + 7,
        );
        break;

      case RecurringFrequency.monthly:
        next = DateTime(
          baseDate.year,
          baseDate.month + 1,
          _safeDayOfMonth(
            baseDate.year,
            baseDate.month + 1,
            recurring.startDate.day,
          ),
        );
        break;

      case RecurringFrequency.yearly:
        next = DateTime(
          baseDate.year + 1,
          recurring.startDate.month,
          _safeDayOfMonth(
            baseDate.year + 1,
            recurring.startDate.month,
            recurring.startDate.day,
          ),
        );
        break;
    }

    if (recurring.lastGeneratedDate == null &&
        next.isBefore(recurring.startDate)) {
      return recurring.startDate;
    }

    return next;
  }

  DateTime _dateBeforeStart(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day - 1,
    );
  }

  int _safeDayOfMonth(
    int year,
    int month,
    int requestedDay,
  ) {
    final lastDay = DateTime(
      year,
      month + 1,
      0,
    ).day;

    if (requestedDay > lastDay) {
      return lastDay;
    }

    return requestedDay;
  }

  Future<void> _ensureCategoryExists({
    required String account,
    required String category,
  }) async {
    final db = _db;

    if (db == null) {
      return;
    }

    final cleanedAccount = account.trim();
    final cleanedCategory = category.trim();

    if (cleanedAccount.isEmpty ||
        cleanedCategory.isEmpty) {
      return;
    }

    await db.insert(
      'categories',
      {
        'account': cleanedAccount,
        'name': cleanedCategory,
        'created_at':
            DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _refreshCurrentAccount() async {
    await _loadAccounts();
    notifyListeners();
  }

  Future<void> close() async {
    final db = _db;

    if (db == null) {
      return;
    }

    await db.close();
    _db = null;
  }
}
