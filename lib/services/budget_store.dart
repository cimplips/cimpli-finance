import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Budget {
  const Budget({
    required this.id,
    required this.account,
    required this.category,
    required this.month,
    required this.limit,
    this.spent = 0,
  });

  final int? id;
  final String account;
  final String category;
  final DateTime month;
  final double limit;
  final double spent;

  double get remaining => limit - spent;

  double get percentage {
    if (limit <= 0) {
      return 0;
    }

    return (spent / limit).clamp(0.0, 1.0);
  }

  bool get isOverBudget => spent > limit;

  Budget copyWith({
    int? id,
    String? account,
    String? category,
    DateTime? month,
    double? limit,
    double? spent,
  }) {
    return Budget(
      id: id ?? this.id,
      account: account ?? this.account,
      category: category ?? this.category,
      month: month ?? this.month,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
    );
  }
}

class BudgetStore extends ChangeNotifier {
  Database? _db;

  Future<void> load() async {
    final dbPath = join(
      await getDatabasesPath(),
      'keuangan_prima.db',
    );

    _db = await openDatabase(
      dbPath,
      version: 3,
      singleInstance: false,
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS budgets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account TEXT NOT NULL,
            category TEXT NOT NULL,
            month TEXT NOT NULL,
            amount REAL NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE(account, category, month)
          )
        ''');

        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_budgets_account_month
          ON budgets(account, month)
        ''');
      },
    );
  }

  Future<List<Budget>> getBudgets({
    required String account,
    DateTime? month,
  }) async {
    final db = _db;

    if (db == null) {
      return <Budget>[];
    }

    final targetMonth = _monthStart(
      month ?? DateTime.now(),
    );

    final rows = await db.query(
      'budgets',
      where: 'account = ? AND month = ?',
      whereArgs: [
        account,
        _monthKey(targetMonth),
      ],
      orderBy: 'category COLLATE NOCASE ASC',
    );

    final budgets = <Budget>[];

    for (final row in rows) {
      final category = row['category'] as String;
      final limit = (row['amount'] as num).toDouble();

      final spent = await _getSpent(
        db: db,
        account: account,
        category: category,
        month: targetMonth,
      );

      budgets.add(
        Budget(
          id: row['id'] as int,
          account: account,
          category: category,
          month: targetMonth,
          limit: limit,
          spent: spent,
        ),
      );
    }

    return budgets;
  }

  Future<Budget?> getBudget({
    required String account,
    required String category,
    DateTime? month,
  }) async {
    final db = _db;

    if (db == null) {
      return null;
    }

    final targetMonth = _monthStart(
      month ?? DateTime.now(),
    );

    final rows = await db.query(
      'budgets',
      where: 'account = ? AND category = ? AND month = ?',
      whereArgs: [
        account,
        category,
        _monthKey(targetMonth),
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;

    final spent = await _getSpent(
      db: db,
      account: account,
      category: category,
      month: targetMonth,
    );

    return Budget(
      id: row['id'] as int,
      account: account,
      category: category,
      month: targetMonth,
      limit: (row['amount'] as num).toDouble(),
      spent: spent,
    );
  }

  Future<bool> saveBudget({
    required String account,
    required String category,
    required double amount,
    DateTime? month,
  }) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    final cleanedAccount = account.trim();
    final cleanedCategory = category.trim();

    if (cleanedAccount.isEmpty ||
        cleanedCategory.isEmpty ||
        amount <= 0) {
      return false;
    }

    final targetMonth = _monthStart(
      month ?? DateTime.now(),
    );

    final now = DateTime.now().toIso8601String();

    try {
      await db.insert(
        'budgets',
        {
          'account': cleanedAccount,
          'category': cleanedCategory,
          'month': _monthKey(targetMonth),
          'amount': amount,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      notifyListeners();

      return true;
    } on DatabaseException {
      return false;
    }
  }

  Future<bool> updateBudget({
    required int id,
    required double amount,
  }) async {
    final db = _db;

    if (db == null || amount <= 0) {
      return false;
    }

    final result = await db.update(
      'budgets',
      {
        'amount': amount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result > 0) {
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<bool> deleteBudget(int id) async {
    final db = _db;

    if (db == null) {
      return false;
    }

    final result = await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result > 0) {
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<double> getSpent({
    required String account,
    required String category,
    DateTime? month,
  }) async {
    final db = _db;

    if (db == null) {
      return 0;
    }

    return _getSpent(
      db: db,
      account: account,
      category: category,
      month: _monthStart(
        month ?? DateTime.now(),
      ),
    );
  }

  Future<double> getTotalBudget({
    required String account,
    DateTime? month,
  }) async {
    final db = _db;

    if (db == null) {
      return 0;
    }

    final targetMonth = _monthStart(
      month ?? DateTime.now(),
    );

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0)
      FROM budgets
      WHERE account = ?
        AND month = ?
      ''',
      [
        account,
        _monthKey(targetMonth),
      ],
    );

    final value = result.first.values.first;

    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }

  Future<double> getTotalSpent({
    required String account,
    DateTime? month,
  }) async {
    final db = _db;

    if (db == null) {
      return 0;
    }

    final targetMonth = _monthStart(
      month ?? DateTime.now(),
    );

    final start = targetMonth;
    final end = DateTime(
      targetMonth.year,
      targetMonth.month + 1,
    );

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0)
      FROM transactions
      WHERE account = ?
        AND type = ?
        AND date >= ?
        AND date < ?
      ''',
      [
        account,
        'expense',
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );

    final value = result.first.values.first;

    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }

  Future<void> refresh() async {
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

  Future<double> _getSpent({
    required Database db,
    required String account,
    required String category,
    required DateTime month,
  }) async {
    final start = _monthStart(month);
    final end = DateTime(
      start.year,
      start.month + 1,
    );

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0)
      FROM transactions
      WHERE account = ?
        AND category = ?
        AND type = ?
        AND date >= ?
        AND date < ?
      ''',
      [
        account,
        category,
        'expense',
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );

    final value = result.first.values.first;

    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }

  DateTime _monthStart(DateTime date) {
    return DateTime(
      date.year,
      date.month,
    );
  }

  String _monthKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$year-$month';
  }
}
