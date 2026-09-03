import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  static const int backupVersion = 1;
  static const String databaseName = 'keuangan_prima.db';

  static const String _themeModeKey = 'theme_mode';
  static const String _appLockEnabledKey = 'app_lock_enabled';

  Future<Map<String, dynamic>> createBackup() async {
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
      final accounts = await _queryIfExists(
        db,
        'accounts',
        orderBy: 'name COLLATE NOCASE ASC',
      );

      final transactions = await _queryIfExists(
        db,
        'transactions',
        orderBy: 'date ASC, id ASC',
      );

      final categories = await _queryIfExists(
        db,
        'categories',
        orderBy: 'account COLLATE NOCASE ASC, name COLLATE NOCASE ASC',
      );

      final recurringTransactions = await _queryIfExists(
        db,
        'recurring_transactions',
        orderBy: 'id ASC',
      );

      final budgets = await _queryIfExists(
        db,
        'budgets',
        orderBy: 'month ASC, account COLLATE NOCASE ASC, '
            'category COLLATE NOCASE ASC',
      );

      final preferences = await SharedPreferences.getInstance();

      return <String, dynamic>{
        'format': 'cimpli_finance_backup',
        'backup_version': backupVersion,
        'created_at': DateTime.now().toIso8601String(),
        'database_name': databaseName,
        'data': <String, dynamic>{
          'accounts': accounts,
          'transactions': transactions,
          'categories': categories,
          'recurring_transactions': recurringTransactions,
          'budgets': budgets,
        },
        'settings': <String, dynamic>{
          'active_account': _findActiveAccount(
            accounts,
          ),
          'theme_mode': preferences.getString(
            _themeModeKey,
          ),
          'app_lock_enabled': preferences.getBool(
                _appLockEnabledKey,
              ) ??
              false,
        },
      };
    } finally {
      await db.close();
    }
  }

  Future<File> exportBackup() async {
    final backup = await createBackup();

    final directory = Directory(
      '/storage/emulated/0/Download',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    final timestamp = _fileTimestamp(
      DateTime.now(),
    );

    final file = File(
      '${directory.path}/cimpli_finance_backup_$timestamp.json',
    );

    final jsonText = const JsonEncoder.withIndent(
      '  ',
    ).convert(backup);

    await file.writeAsString(
      '\ufeff$jsonText',
      encoding: utf8,
      flush: true,
    );

    return file;
  }

  Future<void> restoreBackup(
    String filePath,
  ) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw BackupException(
        'File backup tidak ditemukan.',
      );
    }

    final content = await file.readAsString(
      encoding: utf8,
    );

    final cleanedContent = content.startsWith('\ufeff')
        ? content.substring(1)
        : content;

    dynamic decoded;

    try {
      decoded = jsonDecode(cleanedContent);
    } on FormatException {
      throw BackupException(
        'File backup bukan JSON yang valid.',
      );
    }

    if (decoded is! Map) {
      throw BackupException(
        'Format file backup tidak dikenali.',
      );
    }

    final backup = Map<String, dynamic>.from(
      decoded.map(
        (key, value) => MapEntry(
          key.toString(),
          value,
        ),
      ),
    );

    _validateBackup(backup);

    final dataValue = backup['data'];

    if (dataValue is! Map) {
      throw BackupException(
        'Bagian data pada backup tidak valid.',
      );
    }

    final data = Map<String, dynamic>.from(
      dataValue.map(
        (key, value) => MapEntry(
          key.toString(),
          value,
        ),
      ),
    );

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
      await _ensureTables(db);

      await db.transaction(
        (txn) async {
          await _clearData(txn);

          await _restoreAccounts(
            txn,
            data['accounts'],
          );

          await _restoreTransactions(
            txn,
            data['transactions'],
          );

          await _restoreCategories(
            txn,
            data['categories'],
          );

          await _restoreRecurringTransactions(
            txn,
            data['recurring_transactions'],
          );

          await _restoreBudgets(
            txn,
            data['budgets'],
          );
        },
      );

      await _restoreSettings(
        backup['settings'],
      );
    } finally {
      await db.close();
    }
  }

  Future<List<Map<String, dynamic>>> _queryIfExists(
    Database db,
    String table, {
    String? orderBy,
  }) async {
    try {
      final rows = await db.query(
        table,
        orderBy: orderBy,
      );

      return rows
          .map(
            (row) => Map<String, dynamic>.from(row),
          )
          .toList();
    } on DatabaseException {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _ensureTables(
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

  Future<void> _clearData(
    DatabaseExecutor db,
  ) async {
    await db.delete(
      'transactions',
    );

    await db.delete(
      'recurring_transactions',
    );

    await db.delete(
      'categories',
    );

    await db.delete(
      'budgets',
    );

    await db.delete(
      'accounts',
    );
  }

  Future<void> _restoreAccounts(
    DatabaseExecutor db,
    dynamic value,
  ) async {
    final rows = _asMapList(
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
        <String, dynamic>{
          'name': name,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _restoreTransactions(
    DatabaseExecutor db,
    dynamic value,
  ) async {
    final rows = _asMapList(
      value,
      'transactions',
    );

    for (final row in rows) {
      final title = row['title'];
      final amount = row['amount'];
      final type = row['type'];
      final date = row['date'];
      final account = row['account'];
      final category = row['category'];

      if (title is! String ||
          type is! String ||
          date is! String ||
          account is! String ||
          category is! String ||
          amount is! num) {
        continue;
      }

      final values = <String, dynamic>{
        'title': title,
        'amount': amount.toDouble(),
        'type': type,
        'date': date,
        'account': account,
        'category': category,
      };

      final id = _asInt(
        row['id'],
      );

      if (id != null) {
        values['id'] = id;
      }

      await db.insert(
        'transactions',
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _restoreCategories(
    DatabaseExecutor db,
    dynamic value,
  ) async {
    final rows = _asMapList(
      value,
      'categories',
    );

    for (final row in rows) {
      final account = row['account'];
      final name = row['name'];

      if (account is! String ||
          name is! String ||
          account.trim().isEmpty ||
          name.trim().isEmpty) {
        continue;
      }

      await db.insert(
        'categories',
        <String, dynamic>{
          'account': account,
          'name': name,
          'created_at': row['created_at'] is String
              ? row['created_at']
              : DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _restoreRecurringTransactions(
    DatabaseExecutor db,
    dynamic value,
  ) async {
    final rows = _asMapList(
      value,
      'recurring_transactions',
    );

    for (final row in rows) {
      final title = row['title'];
      final amount = row['amount'];
      final type = row['type'];
      final account = row['account'];
      final category = row['category'];
      final startDate = row['start_date'];
      final frequency = row['frequency'];

      if (title is! String ||
          type is! String ||
          account is! String ||
          category is! String ||
          startDate is! String ||
          frequency is! String ||
          amount is! num) {
        continue;
      }

      final values = <String, dynamic>{
        'title': title,
        'amount': amount.toDouble(),
        'type': type,
        'account': account,
        'category': category,
        'start_date': startDate,
        'frequency': frequency,
        'is_active': _asInt(
              row['is_active'],
            ) ??
            1,
        'last_generated_date':
            row['last_generated_date'] is String
                ? row['last_generated_date']
                : null,
      };

      final id = _asInt(
        row['id'],
      );

      if (id != null) {
        values['id'] = id;
      }

      await db.insert(
        'recurring_transactions',
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _restoreBudgets(
    DatabaseExecutor db,
    dynamic value,
  ) async {
    final rows = _asMapList(
      value,
      'budgets',
    );

    for (final row in rows) {
      final account = row['account'];
      final category = row['category'];
      final month = row['month'];
      final amount = row['amount'];

      if (account is! String ||
          category is! String ||
          month is! String ||
          amount is! num) {
        continue;
      }

      final values = <String, dynamic>{
        'account': account,
        'category': category,
        'month': month,
        'amount': amount.toDouble(),
        'created_at': row['created_at'] is String
            ? row['created_at']
            : DateTime.now().toIso8601String(),
        'updated_at': row['updated_at'] is String
            ? row['updated_at']
            : DateTime.now().toIso8601String(),
      };

      final id = _asInt(
        row['id'],
      );

      if (id != null) {
        values['id'] = id;
      }

      await db.insert(
        'budgets',
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _restoreSettings(
    dynamic value,
  ) async {
    if (value is! Map) {
      return;
    }

    final settings = Map<String, dynamic>.from(
      value.map(
        (key, item) => MapEntry(
          key.toString(),
          item,
        ),
      ),
    );

    final preferences = await SharedPreferences.getInstance();

    final themeMode = settings['theme_mode'];

    if (themeMode is String && themeMode.isNotEmpty) {
      await preferences.setString(
        _themeModeKey,
        themeMode,
      );
    }

    final appLockEnabled = settings['app_lock_enabled'];

    if (appLockEnabled is bool) {
      await preferences.setBool(
        _appLockEnabledKey,
        appLockEnabled,
      );
    }
  }

  String? _findActiveAccount(
    List<Map<String, dynamic>> accounts,
  ) {
    return null;
  }

  void _validateBackup(
    Map<String, dynamic> backup,
  ) {
    if (backup['format'] != 'cimpli_finance_backup') {
      throw BackupException(
        'File bukan backup Cimpli Finance.',
      );
    }

    final version = backup['backup_version'];

    if (version is! num ||
        version.toInt() != backupVersion) {
      throw BackupException(
        'Versi backup tidak didukung.',
      );
    }
  }

  List<Map<String, dynamic>> _asMapList(
    dynamic value,
    String fieldName,
  ) {
    if (value == null) {
      return <Map<String, dynamic>>[];
    }

    if (value is! List) {
      throw BackupException(
        'Data "$fieldName" pada backup tidak valid.',
      );
    }

    final result = <Map<String, dynamic>>[];

    for (final item in value) {
      if (item is! Map) {
        continue;
      }

      result.add(
        Map<String, dynamic>.from(
          item.map(
            (key, value) => MapEntry(
              key.toString(),
              value,
            ),
          ),
        ),
      );
    }

    return result;
  }

  int? _asInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  String _fileTimestamp(
    DateTime date,
  ) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');

    return '$year$month${day}_$hour$minute$second';
  }
}

class BackupException implements Exception {
  const BackupException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}
