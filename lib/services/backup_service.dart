import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  static const String backupType = 'cimpli_finance_backup';
  static const int backupVersion = 1;
  static const String databaseName = 'keuangan_prima.db';

  static const List<String> _tables = <String>[
    'accounts',
    'transactions',
    'categories',
    'recurring_transactions',
    'budgets',
  ];

  Future<String> exportBackup({
    required String outputPath,
  }) async {
    final dbPath = join(
      await getDatabasesPath(),
      databaseName,
    );

    final db = await openDatabase(
      dbPath,
      version: 3,
      singleInstance: false,
    );

    try {
      final data = <String, dynamic>{
        'backup_type': backupType,
        'backup_version': backupVersion,
        'created_at': DateTime.now().toIso8601String(),
        'database_name': databaseName,
        'tables': <String, dynamic>{},
      };

      final tables = data['tables'] as Map<String, dynamic>;

      for (final table in _tables) {
        final exists = await _tableExists(
          db,
          table,
        );

        if (!exists) {
          tables[table] = <Map<String, dynamic>>[];
          continue;
        }

        final rows = await db.query(table);

        tables[table] = rows
            .map(
              (row) => Map<String, dynamic>.from(row),
            )
            .toList();
      }

      final file = File(outputPath);

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
        flush: true,
      );

      return file.path;
    } finally {
      await db.close();
    }
  }

  Future<void> restoreBackup({
    required String inputPath,
  }) async {
    final file = File(inputPath);

    if (!await file.exists()) {
      throw BackupException(
        'File backup tidak ditemukan.',
      );
    }

    final content = await file.readAsString();

    if (content.trim().isEmpty) {
      throw BackupException(
        'File backup kosong.',
      );
    }

    final decoded = jsonDecode(content);

    if (decoded is! Map) {
      throw BackupException(
        'Format file backup tidak valid.',
      );
    }

    final data = Map<String, dynamic>.from(decoded);

    _validateBackup(data);

    final tablesValue = data['tables'];

    if (tablesValue is! Map) {
      throw BackupException(
        'Data tabel backup tidak valid.',
      );
    }

    final tables = Map<String, dynamic>.from(
      tablesValue,
    );

    final dbPath = join(
      await getDatabasesPath(),
      databaseName,
    );

    final db = await openDatabase(
      dbPath,
      version: 3,
      singleInstance: false,
      onOpen: (openedDb) async {
        await _ensureSchema(openedDb);
      },
    );

    try {
      await db.transaction(
        (txn) async {
          await _clearTables(
            txn,
          );

          await _restoreAccounts(
            txn,
            tables['accounts'],
          );

          await _restoreCategories(
            txn,
            tables['categories'],
          );

          await _restoreTransactions(
            txn,
            tables['transactions'],
          );

          await _restoreRecurringTransactions(
            txn,
            tables['recurring_transactions'],
          );

          await _restoreBudgets(
            txn,
            tables['budgets'],
          );
        },
      );
    } finally {
      await db.close();
    }
  }

  Future<bool> isValidBackup(
    String inputPath,
  ) async {
    final file = File(inputPath);

    if (!await file.exists()) {
      return false;
    }

    try {
      final content = await file.readAsString();

      if (content.trim().isEmpty) {
        return false;
      }

      final decoded = jsonDecode(content);

      if (decoded is! Map) {
        return false;
      }

      final data = Map<String, dynamic>.from(
        decoded,
      );

      _validateBackup(data);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> getBackupItemCount(
    String inputPath,
  ) async {
    final file = File(inputPath);

    if (!await file.exists()) {
      throw BackupException(
        'File backup tidak ditemukan.',
      );
    }

    final content = await file.readAsString();

    final decoded = jsonDecode(content);

    if (decoded is! Map) {
      throw BackupException(
        'Format file backup tidak valid.',
      );
    }

    final data = Map<String, dynamic>.from(
      decoded,
    );

    _validateBackup(data);

    final tablesValue = data['tables'];

    if (tablesValue is! Map) {
      throw BackupException(
        'Data tabel backup tidak valid.',
      );
    }

    final tables = Map<String, dynamic>.from(
      tablesValue,
    );

    var count = 0;

    for (final table in _tables) {
      final rows = tables[table];

      if (rows is List) {
        count += rows.length;
      }
    }

    return count;
  }

  void _validateBackup(
    Map<String, dynamic> data,
  ) {
    if (data['backup_type'] != backupType) {
      throw BackupException(
        'File bukan backup Cimpli Finance.',
      );
    }

    final version = data['backup_version'];

    if (version is! num) {
      throw BackupException(
        'Versi backup tidak valid.',
      );
    }

    if (version.toInt() > backupVersion) {
      throw BackupException(
        'Backup dibuat oleh versi aplikasi yang lebih baru.',
      );
    }

    final tables = data['tables'];

    if (tables is! Map) {
      throw BackupException(
        'Struktur backup tidak lengkap.',
      );
    }
  }

  Future<bool> _tableExists(
    DatabaseExecutor db,
    String table,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name = ?
      LIMIT 1
      ''',
      [table],
    );

    return result.isNotEmpty;
  }

  Future<void> _ensureSchema(
    Database db,
  ) async {
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
  }

  Future<void> _clearTables(
    DatabaseExecutor db,
  ) async {
    for (final table in <String>[
      'budgets',
      'recurring_transactions',
      'transactions',
      'categories',
      'accounts',
    ]) {
      final exists = await _tableExists(
        db,
        table,
      );

      if (exists) {
        await db.delete(table);
      }
    }
  }

  Future<void> _restoreAccounts(
    DatabaseExecutor db,
    dynamic value,
  ) async {
    final rows = _rowsFromValue(
      value,
      'accounts',
    );

    for (final row in rows) {
      final name = row['name'];

      if (name is! String || name.trim().isEmpty) {
        continue;
      }

      await db.insert(
        'accounts',
        <String, Object?>{
          'name': name,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  Future<void> _restoreCategories(
    DatabaseExecutor db,
    dynamic value,
  ) async {
    final rows = _rowsFromValue(
      value,
      'categories',
    );

    for (final row in rows) {
      final account = row['account'];
      final name = row['name'];
      final createdAt = row['created_at'];

      if (account is! String ||
          name is! String ||
          createdAt is! String ||
          account.trim().isEmpty ||
          name.trim().isEmpty) {
        continue;
      }

      await db.insert(
        'categories',
        <String, Object?>{
          'account': account,
          'name': name,
          'created_at': createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  Future<void> _restoreTransactions(
    DatabaseExecutor db,
    dynamic value,
  ) async {
    final rows = _rowsFromValue(
      value,
      'transactions',
    );

    for (final row in rows) {
      await db.insert(
        'transactions',
        <String, Object?>{
          'id': _intValue(row['id']),
          'title': _requiredString(
            row['title'],
            'transactions.title',
          ),
          'amount': _doubleValue(
            row['amount'],
            'transactions.amount',
          ),
          'type': _requiredString(
            row['type'],
            'transactions.type',
          ),
          'date': _requiredString(
            row['date'],
            'transactions.date',
          ),
          'account': _requiredString(
            row['account'],
            'transactions.account',
          ),
          'category': _requiredString(
            row['category'],
            'transactions.category',
          ),
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  Future<void> _restoreRecurringTransactions(
    DatabaseExecutor db,
    dynamic value,
  ) async {
    final rows = _rowsFromValue(
      value,
      'recurring_transactions',
    );

    for (final row in rows) {
      await db.insert(
        'recurring_transactions',
        <String, Object?>{
          'id': _intValue(row['id']),
          'title': _requiredString(
            row['title'],
            'recurring_transactions.title',
          ),
          'amount': _doubleValue(
            row['amount'],
            'recurring_transactions.amount',
          ),
          'type': _requiredString(
            row['type'],
            'recurring_transactions.type',
          ),
          'account': _requiredString(
            row['account'],
            'recurring_transactions.account',
          ),
          'category': _requiredString(
            row['category'],
            'recurring_transactions.category',
          ),
          'start_date': _requiredString(
            row['start_date'],
            'recurring_transactions.start_date',
          ),
          'frequency': _requiredString(
            row['frequency'],
            'recurring_transactions.frequency',
          ),
          'is_active': _intValue(
            row['is_active'],
            defaultValue: 1,
          ),
          'last_generated_date':
              _nullableString(
            row['last_generated_date'],
          ),
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  Future<void> _restoreBudgets(
    DatabaseExecutor db,
    dynamic value,
  ) async {
    final rows = _rowsFromValue(
      value,
      'budgets',
    );

    for (final row in rows) {
      await db.insert(
        'budgets',
        <String, Object?>{
          'id': _intValue(row['id']),
          'account': _requiredString(
            row['account'],
            'budgets.account',
          ),
          'category': _requiredString(
            row['category'],
            'budgets.category',
          ),
          'month': _requiredString(
            row['month'],
            'budgets.month',
          ),
          'amount': _doubleValue(
            row['amount'],
            'budgets.amount',
          ),
          'created_at': _requiredString(
            row['created_at'],
            'budgets.created_at',
          ),
          'updated_at': _requiredString(
            row['updated_at'],
            'budgets.updated_at',
          ),
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  List<Map<String, dynamic>> _rowsFromValue(
    dynamic value,
    String table,
  ) {
    if (value == null) {
      return <Map<String, dynamic>>[];
    }

    if (value is! List) {
      throw BackupException(
        'Data tabel $table tidak valid.',
      );
    }

    final rows = <Map<String, dynamic>>[];

    for (final item in value) {
      if (item is! Map) {
        throw BackupException(
          'Baris data tabel $table tidak valid.',
        );
      }

      rows.add(
        Map<String, dynamic>.from(item),
      );
    }

    return rows;
  }

  int _intValue(
    dynamic value, {
    int defaultValue = 0,
  }) {
    if (value == null) {
      return defaultValue;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }

    return defaultValue;
  }

  double _doubleValue(
    dynamic value,
    String field,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    throw BackupException(
      'Nilai $field tidak valid.',
    );
  }

  String _requiredString(
    dynamic value,
    String field,
  ) {
    if (value is String && value.isNotEmpty) {
      return value;
    }

    throw BackupException(
      'Nilai $field tidak valid.',
    );
  }

  String? _nullableString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      return value;
    }

    return null;
  }
}

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
