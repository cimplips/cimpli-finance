import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction.dart';

class FinanceStore extends ChangeNotifier {
  Database? _db;

  final accounts = <String>[];
  final transactions = <Tx>[];

  String activeAccount = 'Keuangan Pribadi';

  Future<void> load() async {
    final dbPath = join(
      await getDatabasesPath(),
      'keuangan_prima.db',
    );

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE accounts(name TEXT PRIMARY KEY)',
        );

        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            date TEXT NOT NULL,
            account TEXT NOT NULL,
            category TEXT NOT NULL
          )
        ''');

        final defaultAccounts = [
          'Keuangan Pribadi',
          'Keuangan Kantor',
          'Keuangan Rumah',
        ];

        for (final name in defaultAccounts) {
          await db.insert(
            'accounts',
            {'name': name},
          );
        }
      },
    );

    await refresh();
  }

  Future<void> refresh() async {
    final db = _db;

    if (db == null) {
      return;
    }

    accounts
      ..clear()
      ..addAll(
        (await db.query('accounts'))
            .map((row) => row['name'] as String),
      );

    if (accounts.isNotEmpty &&
        !accounts.contains(activeAccount)) {
      activeAccount = accounts.first;
    }

    if (accounts.isEmpty) {
      transactions.clear();
      notifyListeners();
      return;
    }

    final rows = await db.query(
      'transactions',
      where: 'account = ?',
      whereArgs: [activeAccount],
      orderBy: 'date DESC, id DESC',
    );

    transactions
      ..clear()
      ..addAll(
        rows.map(
          (row) => Tx(
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
          ),
        ),
      );

    notifyListeners();
  }

  Future<void> selectAccount(String name) async {
    if (!accounts.contains(name)) {
      return;
    }

    activeAccount = name;
    await refresh();
  }

  Future<bool> addAccount(String name) async {
    final cleaned = name.trim();

    if (cleaned.isEmpty) {
      return false;
    }

    final result = await _db!.insert(
      'accounts',
      {'name': cleaned},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await refresh();

    return result > 0;
  }

  Future<bool> renameAccount({
    required String oldName,
    required String newName,
  }) async {
    final cleaned = newName.trim();

    if (cleaned.isEmpty || cleaned == oldName) {
      return false;
    }

    if (accounts.contains(cleaned)) {
      return false;
    }

    final db = _db;

    if (db == null) {
      return false;
    }

    await db.transaction((txn) async {
      await txn.update(
        'accounts',
        {'name': cleaned},
        where: 'name = ?',
        whereArgs: [oldName],
      );

      await txn.update(
        'transactions',
        {'account': cleaned},
        where: 'account = ?',
        whereArgs: [oldName],
      );
    });

    if (activeAccount == oldName) {
      activeAccount = cleaned;
    }

    await refresh();

    return true;
  }

  Future<bool> deleteAccount(String name) async {
    if (accounts.length <= 1) {
      return false;
    }

    if (!accounts.contains(name)) {
      return false;
    }

    final db = _db;

    if (db == null) {
      return false;
    }

    await db.transaction((txn) async {
      await txn.delete(
        'transactions',
        where: 'account = ?',
        whereArgs: [name],
      );

      await txn.delete(
        'accounts',
        where: 'name = ?',
        whereArgs: [name],
      );
    });

    if (activeAccount == name) {
      final remainingAccounts =
          accounts.where((item) => item != name).toList();

      if (remainingAccounts.isNotEmpty) {
        activeAccount = remainingAccounts.first;
      }
    }

    await refresh();

    return true;
  }

  Future<int> transactionCountForAccount(
    String account,
  ) async {
    final db = _db;

    if (db == null) {
      return 0;
    }

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*)
        FROM transactions
        WHERE account = ?
        ''',
        [account],
      ),
    );

    return result ?? 0;
  }

  Future<void> addTransaction(Tx tx) async {
    await _db!.insert(
      'transactions',
      {
        'title': tx.title,
        'amount': tx.amount,
        'type': tx.type.name,
        'date': tx.date.toIso8601String(),
        'account': tx.account,
        'category': tx.category,
      },
    );

    await refresh();
  }

  Future<bool> updateTransaction(Tx tx) async {
    if (tx.id == null) {
      return false;
    }

    final db = _db;

    if (db == null) {
      return false;
    }

    final result = await db.update(
      'transactions',
      {
        'title': tx.title,
        'amount': tx.amount,
        'type': tx.type.name,
        'date': tx.date.toIso8601String(),
        'account': tx.account,
        'category': tx.category,
      },
      where: 'id = ?',
      whereArgs: [tx.id],
    );

    await refresh();

    return result > 0;
  }

  Future<void> deleteTransaction(int id) async {
    await _db!.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    await refresh();
  }

  double get income {
    return transactions
        .where(
          (tx) => tx.type == TransactionType.income,
        )
        .fold(
          0.0,
          (total, tx) => total + tx.amount,
        );
  }

  double get expense {
    return transactions
        .where(
          (tx) => tx.type == TransactionType.expense,
        )
        .fold(
          0.0,
          (total, tx) => total + tx.amount,
        );
  }

  double get balance => income - expense;

  double incomeForMonth(DateTime month) {
    return transactions
        .where(
          (tx) =>
              tx.type == TransactionType.income &&
              tx.date.year == month.year &&
              tx.date.month == month.month,
        )
        .fold(
          0.0,
          (total, tx) => total + tx.amount,
        );
  }

  double expenseForMonth(DateTime month) {
    return transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              tx.date.year == month.year &&
              tx.date.month == month.month,
        )
        .fold(
          0.0,
          (total, tx) => total + tx.amount,
        );
  }
}
