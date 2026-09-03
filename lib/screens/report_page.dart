import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
import '../models/transaction.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late DateTime _selectedMonth;
  Future<List<Tx>>? _transactionsFuture;
  String? _futureKey;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final store = FinanceScope.of(context);
    final account = store.activeAccount;
    final key = account ?? '__no_account__';

    if (_futureKey == key && _transactionsFuture != null) {
      return;
    }

    _futureKey = key;
    _transactionsFuture = _loadTransactions(store, account);
  }

  Future<List<Tx>> _loadTransactions(
    dynamic store,
    String? account,
  ) async {
    if (account == null) {
      return <Tx>[];
    }

    return store.getTransactions(account: account);
  }

  Future<void> _refresh() async {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    if (!mounted) {
      return;
    }

    setState(() {
      _futureKey = account ?? '__no_account__';
      _transactionsFuture = _loadTransactions(store, account);
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
  }

  Future<void> _exportCsv(List<Tx> transactions, String accountName) async {
    if (transactions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Belum ada transaksi untuk diekspor.')),
        );
      return;
    }

    final rows = <List<String>>[
      ['Tanggal', 'Jenis', 'Judul', 'Kategori', 'Jumlah'],
      ...transactions.map(
        (tx) => <String>[
          _formatDate(tx.date),
          tx.type == TransactionType.income ? 'Pemasukan' : 'Pengeluaran',
          tx.title,
          tx.category,
          tx.amount.round().toString(),
        ],
      ),
    ];

    String escapeCsv(String value) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }

    final csv = rows
        .map((row) => row.map(escapeCsv).join(','))
        .join('\r\n');

    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final safeAccount = accountName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
      final fileName =
          'cimpli_finance_${safeAccount}_${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString('﻿$csv', encoding: utf8);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Laporan CSV tersimpan di Download/$fileName.')),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Laporan gagal diekspor. Pastikan izin penyimpanan tersedia.',
            ),
          ),
        );
    }
  }

  String _monthName(int month) {
    const months = <String>[
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return months[month - 1];
  }

  String _formatRupiah(double value) {
    final rounded = value.round();
    final digits = rounded.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    final result = buffer.toString();

    if (rounded < 0) {
      return '-Rp $result';
    }

    return 'Rp $result';
  }

  String _formatDate(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = _ReportTheme(isDark);

    if (store.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (store.error != null) {
      return _ErrorView(
        message: store.error!,
        onRetry: _refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await store.load();
        await _refresh();
      },
      child: FutureBuilder<List<Tx>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final transactions = snapshot.data ?? <Tx>[];
          final monthTransactions = transactions.where((tx) {
            return tx.date.year == _selectedMonth.year &&
                tx.date.month == _selectedMonth.month;
          }).toList();

          final income = monthTransactions
              .where((tx) => tx.type == TransactionType.income)
              .fold<double>(0, (total, tx) => total + tx.amount);

          final expense = monthTransactions
              .where((tx) => tx.type == TransactionType.expense)
              .fold<double>(0, (total, tx) => total + tx.amount);

          final net = income - expense;

          final categoryTotals = <String, double>{};
          for (final tx in monthTransactions) {
            if (tx.type != TransactionType.expense) {
              continue;
            }

            categoryTotals[tx.category] =
                (categoryTotals[tx.category] ?? 0) + tx.amount;
          }

          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final recentTransactions = [...monthTransactions]
            ..sort((a, b) {
              final dateCompare = b.date.compareTo(a.date);
              if (dateCompare != 0) {
                return dateCompare;
              }

              return (b.id ?? 0).compareTo(a.id ?? 0);
            });

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laporan',
                          style: TextStyle(
                            color: theme.primaryText,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          store.activeAccount ?? 'Keuangan Kantor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ekspor laporan',
                    onPressed: () => _exportCsv(
                        monthTransactions,
                        store.activeAccount ?? 'akun',
                      ),
                    icon: Icon(
                      Icons.download_outlined,
                      color: theme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _MonthSelector(
                monthLabel:
                    '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                theme: theme,
                onPrevious: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
              ),
              const SizedBox(height: 12),
              _NetFlowCard(
                net: net,
                income: income,
                expense: expense,
                formatRupiah: _formatRupiah,
                theme: theme,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Pemasukan',
                      value: income,
                      color: theme.income,
                      progress: _progressValue(income, income + expense),
                      formatRupiah: _formatRupiah,
                      icon: Icons.arrow_downward_rounded,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'Pengeluaran',
                      value: expense,
                      color: theme.expense,
                      progress: _progressValue(expense, income + expense),
                      formatRupiah: _formatRupiah,
                      icon: Icons.arrow_upward_rounded,
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                'Pengeluaran per Kategori',
                style: TextStyle(
                  color: theme.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (sortedCategories.isEmpty)
                _EmptyReportCard(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'Belum ada pengeluaran',
                  subtitle: 'Belum ada data pengeluaran pada bulan ini.',
                  iconColor: theme.info,
                  theme: theme,
                )
              else
                _CategoryCard(
                  categories: sortedCategories,
                  totalExpense: expense,
                  formatRupiah: _formatRupiah,
                  theme: theme,
                ),
              const SizedBox(height: 26),
              Text(
                'Aktivitas Bulan Ini',
                style: TextStyle(
                  color: theme.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (recentTransactions.isEmpty)
                _EmptyReportCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum ada transaksi',
                  subtitle:
                      'Belum ada transaksi pada periode yang dipilih.',
                  iconColor: theme.info,
                  theme: theme,
                )
              else
                ...recentTransactions.map(
                  (tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ActivityCard(
                      transaction: tx,
                      formatRupiah: _formatRupiah,
                      formatDate: _formatDate,
                      theme: theme,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _progressValue(double value, double total) {
    if (total <= 0) {
      return 0;
    }

    return (value / total).clamp(0.0, 1.0);
  }
}

class _ReportTheme {
  const _ReportTheme(this.isDark);

  final bool isDark;

  Color get background =>
      isDark ? const Color(0xFF0F1418) : const Color(0xFFF7F8FA);

  Color get card =>
      isDark ? const Color(0xFF151C21) : Colors.white;

  Color get cardAlt =>
      isDark ? const Color(0xFF192229) : const Color(0xFFF9FAFB);

  Color get border =>
      isDark ? const Color(0xFF26333B) : const Color(0xFFE6EAF0);

  Color get primaryText =>
      isDark ? const Color(0xFFF5F7F8) : const Color(0xFF101828);

  Color get secondaryText =>
      isDark ? const Color(0xFF9CA7AE) : const Color(0xFF667085);

  Color get tertiaryText =>
      isDark ? const Color(0xFF74818A) : const Color(0xFF98A2B3);

  Color get income =>
      isDark ? const Color(0xFF35C878) : const Color(0xFF159447);

  Color get expense =>
      isDark ? const Color(0xFFFF6262) : const Color(0xFFE53935);

  Color get info =>
      isDark ? const Color(0xFF78A8FF) : const Color(0xFF6E97E8);

  Color get netPositive =>
      isDark ? const Color(0xFF1A3529) : const Color(0xFFF0FBF5);

  Color get netNegative =>
      isDark ? const Color(0xFF351E22) : const Color(0xFFFFF3F2);
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.monthLabel,
    required this.theme,
    required this.onPrevious,
    required this.onNext,
  });

  final String monthLabel;
  final _ReportTheme theme;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.border),
        boxShadow: theme.isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bulan sebelumnya',
            onPressed: onPrevious,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: theme.primaryText,
              size: 28,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                monthLabel,
                style: TextStyle(
                  color: theme.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Bulan berikutnya',
            onPressed: onNext,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: theme.primaryText,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetFlowCard extends StatelessWidget {
  const _NetFlowCard({
    required this.net,
    required this.income,
    required this.expense,
    required this.formatRupiah,
    required this.theme,
  });

  final double net;
  final double income;
  final double expense;
  final String Function(double) formatRupiah;
  final _ReportTheme theme;

  @override
  Widget build(BuildContext context) {
    final positive = net >= 0;
    final accent = positive ? theme.income : theme.expense;
    final background = positive ? theme.netPositive : theme.netNegative;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.isDark
              ? theme.border
              : Color.alphaBlend(accent.withValues(alpha: 0.10), theme.border),
        ),
        boxShadow: theme.isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Arus Bersih',
            style: TextStyle(
              color: theme.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatRupiah(net),
                  style: TextStyle(
                    color: positive ? theme.income : theme.expense,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: theme.isDark
                    ? const Color(0x667E8A91)
                    : const Color(0x4D667085),
                size: 62,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _FlowMiniCard(
                  title: 'Pemasukan',
                  value: income,
                  color: theme.income,
                  icon: Icons.arrow_downward_rounded,
                  formatRupiah: formatRupiah,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FlowMiniCard(
                  title: 'Pengeluaran',
                  value: expense,
                  color: theme.expense,
                  icon: Icons.arrow_upward_rounded,
                  formatRupiah: formatRupiah,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowMiniCard extends StatelessWidget {
  const _FlowMiniCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.formatRupiah,
    required this.theme,
  });

  final String title;
  final double value;
  final Color color;
  final IconData icon;
  final String Function(double) formatRupiah;
  final _ReportTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
      decoration: BoxDecoration(
        color: theme.card.withValues(alpha: theme.isDark ? 0.72 : 0.86),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.secondaryText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatRupiah(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: theme.isDark ? 0.16 : 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.progress,
    required this.formatRupiah,
    required this.icon,
    required this.theme,
  });

  final String title;
  final double value;
  final Color color;
  final double progress;
  final String Function(double) formatRupiah;
  final IconData icon;
  final _ReportTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.border),
        boxShadow: theme.isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatRupiah(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                icon,
                color: color.withValues(alpha: 0.80),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReportCard extends StatelessWidget {
  const _EmptyReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final _ReportTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border),
        boxShadow: theme.isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0B000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.primaryText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.secondaryText,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.categories,
    required this.totalExpense,
    required this.formatRupiah,
    required this.theme,
  });

  final List<MapEntry<String, double>> categories;
  final double totalExpense;
  final String Function(double) formatRupiah;
  final _ReportTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border),
        boxShadow: theme.isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0B000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < categories.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == categories.length - 1 ? 0 : 16,
              ),
              child: _CategoryRow(
                name: categories[i].key,
                amount: categories[i].value,
                totalExpense: totalExpense,
                formatRupiah: formatRupiah,
                theme: theme,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.amount,
    required this.totalExpense,
    required this.formatRupiah,
    required this.theme,
  });

  final String name;
  final double amount;
  final double totalExpense;
  final String Function(double) formatRupiah;
  final _ReportTheme theme;

  @override
  Widget build(BuildContext context) {
    final ratio = totalExpense <= 0
        ? 0.0
        : (amount / totalExpense).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatRupiah(amount),
              style: TextStyle(
                color: theme.expense,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: ratio,
            backgroundColor: theme.expense.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(theme.expense),
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.transaction,
    required this.formatRupiah,
    required this.formatDate,
    required this.theme,
  });

  final Tx transaction;
  final String Function(double) formatRupiah;
  final String Function(DateTime) formatDate;
  final _ReportTheme theme;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? theme.income : theme.expense;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: theme.isDark ? 0.13 : 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.category} • ${formatDate(transaction.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isIncome ? '+' : '-'}${formatRupiah(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Laporan tidak dapat dimuat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
