import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/transaction.dart';

class FinanceStore extends ChangeNotifier {
  Database? _db;

  final List<String> _accounts = <String>[];
  String? _activeAccount;

  bool _loading = true;
  String? _error;

  List<String> get accounts => List.unmodifiable(_accounts);
  String? get activeAccount => _activeAccount;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final databasePath = await getDatabasesPath();

      _db = await openDatabase(
        '$databasePath/keuangan_prima.db',
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              type INTEGER NOT NULL,
              date TEXT NOT NULL,
              account TEXT NOT NULL,
              category TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE INDEX idx_transactions_account_date
            ON transactions(account, date)
          ''');

          await db.execute('''
            CREATE TABLE accounts (
              name TEXT PRIMARY KEY
            )
          ''');

          await db.insert(
            'accounts',
            <String, Object?>{
              'name': 'Pribadi',
            },
          );

          await _createCategoriesTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createCategoriesTable(db);
            await _migrateExistingCategories(db);
          }
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

  Future<void> _createCategoriesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        account TEXT NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (account, name)
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_categories_account
      ON categories(account)
    ''');
  }

  Future<void> _migrateExistingCategories(
    DatabaseExecutor db,
  ) async {
    final rows = await db.rawQuery('''
      SELECT DISTINCT account, category
      FROM transactions
      WHERE category IS NOT NULL
        AND TRIM(category) != ''
    ''');

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
        <String, Object?>{
          'account': account.trim(),
          'name': category.trim(),
          'created_at': DateTime.now().toIso8601String(),
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
        rows
            .map((row) => row['name'])
            .whereType<String>(),
      );

    if (_accounts.isEmpty) {
      await db.insert(
        'accounts',
        <String, Object?>{
          'name': 'Pribadi',
        },
      );

      _accounts.add('Pribadi');
    }

    if (_activeAccount == null ||
        !_accounts.contains(_activeAccount)) {
      _activeAccount = _accounts.first;
    }
  }

  Future<bool> addAccount(String name) async {
    final db = _db;
    final cleanName = name.trim();

    if (db == null || cleanName.isEmpty) {
      return false;
    }

    if (_accounts.any(
      (account) =>
          account.toLowerCase() == cleanName.toLowerCase(),
    )) {
      return false;
    }

    try {
      await db.insert(
        'accounts',
        <String, Object?>{
          'name': cleanName,
        },
      );

      _accounts.add(cleanName);
      _accounts.sort(
        (a, b) => a.toLowerCase().compareTo(
              b.toLowerCase(),
            ),
      );

      _activeAccount = cleanName;

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> renameAccount(
    String oldName,
    String newName,
  ) async {
    final db = _db;
    final cleanName = newName.trim();

    if (db == null ||
        oldName.trim().isEmpty ||
        cleanName.isEmpty) {
      return false;
    }

    final duplicate = _accounts.any(
      (account) =>
          account != oldName &&
          account.toLowerCase() == cleanName.toLowerCase(),
    );

    if (duplicate) {
      return false;
    }

    try {
      await db.transaction((txn) async {
        await txn.update(
          'accounts',
          <String, Object?>{
            'name': cleanName,
          },
          where: 'name = ?',
          whereArgs: <Object?>[oldName],
        );

        await txn.update(
          'transactions',
          <String, Object?>{
            'account': cleanName,
          },
          where: 'account = ?',
          whereArgs: <Object?>[oldName],
        );

        await txn.update(
          'categories',
          <String, Object?>{
            'account': cleanName,
          },
          where: 'account = ?',
          whereArgs: <Object?>[oldName],
        );
      });

      final index = _accounts.indexOf(oldName);

      if (index >= 0) {
        _accounts[index] = cleanName;
      }

      _accounts.sort(
        (a, b) => a.toLowerCase().compareTo(
              b.toLowerCase(),
            ),
      );

      if (_activeAccount == oldName) {
        _activeAccount = cleanName;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount(String name) async {
    final db = _db;

    if (db == null || _accounts.length <= 1) {
      return false;
    }

    if (!_accounts.contains(name)) {
      return false;
    }

    try {
      await db.transaction((txn) async {
        await txn.delete(
          'transactions',
          where: 'account = ?',
          whereArgs: <Object?>[name],
        );

        await txn.delete(
          'categories',
          where: 'account = ?',
          whereArgs: <Object?>[name],
        );

        await txn.delete(
          'accounts',
          where: 'name = ?',
          whereArgs: <Object?>[name],
        );
      });

      _accounts.remove(name);

      if (_activeAccount == name) {
        _activeAccount = _accounts.first;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setActiveAccount(String account) {
    if (!_accounts.contains(account)) {
      return;
    }

    if (_activeAccount == account) {
      return;
    }

    _activeAccount = account;
    notifyListeners();
  }

  Future<int?> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required DateTime date,
    required String account,
    required String category,
  }) async {
    final db = _db;

    if (db == null) {
      return null;
    }

    final cleanTitle = title.trim();
    final cleanAccount = account.trim();
    final cleanCategory = category.trim();

    if (cleanTitle.isEmpty ||
        cleanAccount.isEmpty ||
        cleanCategory.isEmpty ||
        amount <= 0) {
      return null;
    }

    try {
      await _ensureCategoryExists(
        db,
        cleanAccount,
        cleanCategory,
      );

      final id = await db.insert(
        'transactions',
        <String, Object?>{
          'title': cleanTitle,
          'amount': amount,
          'type': type == TransactionType.income ? 0 : 1,
          'date': date.toIso8601String(),
          'account': cleanAccount,
          'category': cleanCategory,
        },
      );

      notifyListeners();
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
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

    if (db == null) {
      return false;
    }

    final cleanTitle = title.trim();
    final cleanAccount = account.trim();
    final cleanCategory = category.trim();

    if (cleanTitle.isEmpty ||
        cleanAccount.isEmpty ||
        cleanCategory.isEmpty ||
        amount <= 0) {
      return false;
    }

    try {
      await _ensureCategoryExists(
        db,
        cleanAccount,
        cleanCategory,
      );

      final affected = await db.update(
        'transactions',
        <String, Object?>{
          'title': cleanTitle,
          'amount': amount,
          'type': type == TransactionType.income ? 0 : 1,
          'date': date.toIso8601String(),
          'account': cleanAccount,
          'category': cleanCategory,
        },
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );

      if (affected == 0) {
        return false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    try {
      final affected = await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );

      if (affected == 0) {
        return false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
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

    if (account != null && account.trim().isNotEmpty) {
      where.add('account = ?');
      args.add(account.trim());
    }

    if (category != null &&
        category.trim().isNotEmpty &&
        category != 'Semua') {
      where.add('category = ?');
      args.add(category.trim());
    }

    if (type != null) {
      where.add('type = ?');
      args.add(
        type == TransactionType.income ? 0 : 1,
      );
    }

    if (startDate != null) {
      where.add('date >= ?');
      args.add(
        DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        ).toIso8601String(),
      );
    }

    if (endDate != null) {
      final exclusiveEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).add(const Duration(days: 1));

      where.add('date < ?');
      args.add(exclusiveEnd.toIso8601String());
    }

    try {
      final rows = await db.query(
        'transactions',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'date DESC, id DESC',
      );

      return rows.map(_transactionFromRow).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return <Tx>[];
    }
  }

  Tx _transactionFromRow(
    Map<String, Object?> row,
  ) {
    return Tx(
      id: row['id'] as int?,
      title: row['title'] as String? ?? '',
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      type: (row['type'] as int? ?? 0) == 0
          ? TransactionType.income
          : TransactionType.expense,
      date: DateTime.tryParse(
            row['date'] as String? ?? '',
          ) ??
          DateTime.now(),
      account: row['account'] as String? ?? '',
      category: row['category'] as String? ?? '',
    );
  }

  Future<List<String>> getCategories({
    String? account,
  }) async {
    final db = _db;

    if (db == null) {
      return <String>[];
    }

    final targetAccount =
        account?.trim().isNotEmpty == true
            ? account!.trim()
            : _activeAccount;

    if (targetAccount == null || targetAccount.isEmpty) {
      return <String>[];
    }

    try {
      final rows = await db.rawQuery(
        '''
        SELECT DISTINCT name
        FROM categories
        WHERE account = ?
          AND name IS NOT NULL
          AND TRIM(name) != ''
        ORDER BY name COLLATE NOCASE ASC
        ''',
        <Object?>[targetAccount],
      );

      final categories = rows
          .map((row) => row['name'])
          .whereType<String>()
          .toList();

      final transactionRows = await db.rawQuery(
        '''
        SELECT DISTINCT category
        FROM transactions
        WHERE account = ?
          AND category IS NOT NULL
          AND TRIM(category) != ''
        ORDER BY category COLLATE NOCASE ASC
        ''',
        <Object?>[targetAccount],
      );

      final result = <String>{
        ...categories,
        ...transactionRows
            .map((row) => row['category'])
            .whereType<String>(),
      }.toList()
        ..sort(
          (a, b) => a.toLowerCase().compareTo(
                b.toLowerCase(),
              ),
        );

      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return <String>[];
    }
  }

  Future<bool> addCategory({
    String? account,
    required String name,
  }) async {
    final db = _db;

    final targetAccount =
        account?.trim().isNotEmpty == true
            ? account!.trim()
            : _activeAccount;

    final cleanName = name.trim();

    if (db == null ||
        targetAccount == null ||
        targetAccount.isEmpty ||
        cleanName.isEmpty) {
      return false;
    }

    try {
      final existing = await db.query(
        'categories',
        columns: <String>['name'],
        where: 'account = ?',
        whereArgs: <Object?>[targetAccount],
      );

      final duplicate = existing.any(
        (row) =>
            (row['name'] as String? ?? '').toLowerCase() ==
            cleanName.toLowerCase(),
      );

      if (duplicate) {
        return false;
      }

      await db.insert(
        'categories',
        <String, Object?>{
          'account': targetAccount,
          'name': cleanName,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> renameCategory({
    String? account,
    required String oldName,
    required String newName,
  }) async {
    final db = _db;

    final targetAccount =
        account?.trim().isNotEmpty == true
            ? account!.trim()
            : _activeAccount;

    final cleanOldName = oldName.trim();
    final cleanNewName = newName.trim();

    if (db == null ||
        targetAccount == null ||
        targetAccount.isEmpty ||
        cleanOldName.isEmpty ||
        cleanNewName.isEmpty) {
      return false;
    }

    if (cleanOldName.toLowerCase() ==
        cleanNewName.toLowerCase()) {
      return false;
    }

    try {
      final existing = await db.query(
        'categories',
        columns: <String>['name'],
        where: 'account = ?',
        whereArgs: <Object?>[targetAccount],
      );

      final duplicate = existing.any(
        (row) =>
            (row['name'] as String? ?? '').toLowerCase() ==
            cleanNewName.toLowerCase(),
      );

      if (duplicate) {
        return false;
      }

      final categoryExists = existing.any(
        (row) =>
            (row['name'] as String? ?? '') == cleanOldName,
      );

      if (!categoryExists) {
        return false;
      }

      await db.transaction((txn) async {
        await txn.update(
          'categories',
          <String, Object?>{
            'name': cleanNewName,
          },
          where: 'account = ? AND name = ?',
          whereArgs: <Object?>[
            targetAccount,
            cleanOldName,
          ],
        );

        await txn.update(
          'transactions',
          <String, Object?>{
            'category': cleanNewName,
          },
          where: 'account = ? AND category = ?',
          whereArgs: <Object?>[
            targetAccount,
            cleanOldName,
          ],
        );
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory({
    String? account,
    required String name,
  }) async {
    final db = _db;

    final targetAccount =
        account?.trim().isNotEmpty == true
            ? account!.trim()
            : _activeAccount;

    final cleanName = name.trim();

    if (db == null ||
        targetAccount == null ||
        targetAccount.isEmpty ||
        cleanName.isEmpty) {
      return false;
    }

    try {
      final usedRows = await db.query(
        'transactions',
        columns: <String>['id'],
        where: 'account = ? AND category = ?',
        whereArgs: <Object?>[
          targetAccount,
          cleanName,
        ],
        limit: 1,
      );

      if (usedRows.isNotEmpty) {
        return false;
      }

      final affected = await db.delete(
        'categories',
        where: 'account = ? AND name = ?',
        whereArgs: <Object?>[
          targetAccount,
          cleanName,
        ],
      );

      if (affected == 0) {
        return false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> isCategoryUsed({
    String? account,
    required String name,
  }) async {
    final db = _db;

    final targetAccount =
        account?.trim().isNotEmpty == true
            ? account!.trim()
            : _activeAccount;

    final cleanName = name.trim();

    if (db == null ||
        targetAccount == null ||
        targetAccount.isEmpty ||
        cleanName.isEmpty) {
      return false;
    }

    try {
      final rows = await db.query(
        'transactions',
        columns: <String>['id'],
        where: 'account = ? AND category = ?',
        whereArgs: <Object?>[
          targetAccount,
          cleanName,
        ],
        limit: 1,
      );

      return rows.isNotEmpty;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _ensureCategoryExists(
    DatabaseExecutor db,
    String account,
    String category,
  ) async {
    final existing = await db.query(
      'categories',
      columns: <String>['name'],
      where: 'account = ?',
      whereArgs: <Object?>[account],
      limit: 1,
    );

    final allRows = await db.query(
      'categories',
      columns: <String>['name'],
      where: 'account = ?',
      whereArgs: <Object?>[account],
    );

    final alreadyExists = allRows.any(
      (row) =>
          (row['name'] as String? ?? '').toLowerCase() ==
          category.toLowerCase(),
    );

    if (alreadyExists || existing.isEmpty) {
      if (alreadyExists) {
        return;
      }
    }

    await db.insert(
      'categories',
      <String, Object?>{
        'account': account,
        'name': category,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<double> getBalance({
    String? account,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await getTransactions(
      account: account ?? _activeAccount,
      startDate: startDate,
      endDate: endDate,
    );

    double balance = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        balance += transaction.amount;
      } else {
        balance -= transaction.amount;
      }
    }

    return balance;
  }

  Future<double> getTotalIncome({
    String? account,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await getTransactions(
      account: account ?? _activeAccount,
      type: TransactionType.income,
      startDate: startDate,
      endDate: endDate,
    );

    return transactions.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  Future<double> getTotalExpense({
    String? account,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await getTransactions(
      account: account ?? _activeAccount,
      type: TransactionType.expense,
      startDate: startDate,
      endDate: endDate,
    );

    return transactions.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  Future<void> close() async {
    final db = _db;

    if (db == null) {
      return;
    }

    await db.close();
    _db = null;
  }

  @override
  void dispose() {
    close();
    super.dispose();
  }
}
