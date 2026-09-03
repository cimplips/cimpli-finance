import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/finance_scope.dart';
import '../models/transaction.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({import 'package:flutter/material.dart';

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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
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
                            fontSize: 26,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ekspor laporan',
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fitur ekspor laporan akan tersedia pada tahap berikutnya.',
                            ),
                          ),
                        );
                    },
                    icon: Icon(
                      Icons.download_outlined,
                      color: theme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _MonthSelector(
                monthLabel:
                    '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                theme: theme,
                onPrevious: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
              ),
              const SizedBox(height: 16),
              _NetFlowCard(
                net: net,
                income: income,
                expense: expense,
                formatRupiah: _formatRupiah,
                theme: theme,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 30),
              Text(
                'Pengeluaran per Kategori',
                style: TextStyle(
                  color: theme.primaryText,
                  fontSize: 20,
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
              const SizedBox(height: 30),
              Text(
                'Aktivitas Bulan Ini',
                style: TextStyle(
                  color: theme.primaryText,
                  fontSize: 20,
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
      height: 68,
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
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
                    fontSize: 30,
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
        borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(24),
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
          const SizedBox(height: 16),
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
        borderRadius: BorderRadius.circular(24),
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
          borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
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
            const SizedBox(height: 16),
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

    super.key,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime _selectedMonth = DateTime.now();

  Future<_ReportData> _loadReport() async {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    if (account == null) {
      return const _ReportData(
        transactions: <Tx>[],
        income: 0,
        expense: 0,
      );
    }

    final startDate = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );

    final endDate = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );

    final transactions = await store.getTransactions(
      account: account,
      startDate: startDate,
      endDate: endDate,
    );

    double income = 0;
    double expense = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
      }
    }

    return _ReportData(
      transactions: transactions,
      income: income,
      expense: expense,
    );
  }

  Future<void> _changeMonth(int offset) async {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
    });
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

  String _formatMonth(DateTime date) {
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

    return '${months[date.month - 1]} ${date.year}';
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

  String _formatCsvDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _csvEscape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _buildCsv({
    required String account,
    required _ReportData data,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
      _csvEscape('Laporan Keuangan Prima'),
    );
    buffer.writeln(
      '${_csvEscape('Akun')},${_csvEscape(account)}',
    );
    buffer.writeln(
      '${_csvEscape('Periode')},'
      '${_csvEscape(_formatMonth(_selectedMonth))}',
    );
    buffer.writeln();

    buffer.writeln(
      '${_csvEscape('Ringkasan')},'
      '${_csvEscape('Nominal')}',
    );
    buffer.writeln(
      '${_csvEscape('Pemasukan')},'
      '${data.income.toStringAsFixed(2)}',
    );
    buffer.writeln(
      '${_csvEscape('Pengeluaran')},'
      '${data.expense.toStringAsFixed(2)}',
    );
    buffer.writeln(
      '${_csvEscape('Arus Bersih')},'
      '${(data.income - data.expense).toStringAsFixed(2)}',
    );
    buffer.writeln();

    buffer.writeln(
      '${_csvEscape('Tanggal')},'
      '${_csvEscape('Judul')},'
      '${_csvEscape('Kategori')},'
      '${_csvEscape('Jenis')},'
      '${_csvEscape('Nominal')}',
    );

    for (final transaction in data.transactions) {
      final isIncome =
          transaction.type == TransactionType.income;

      buffer.writeln(
        '${_csvEscape(_formatCsvDate(transaction.date))},'
        '${_csvEscape(transaction.title)},'
        '${_csvEscape(transaction.category)},'
        '${_csvEscape(isIncome ? 'Pemasukan' : 'Pengeluaran')},'
        '${transaction.amount.toStringAsFixed(2)}',
      );
    }

    return buffer.toString();
  }

  Future<void> _exportCsv() async {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    if (account == null) {
      _showMessage('Belum ada akun keuangan aktif.');
      return;
    }

    final data = await _loadReport();

    if (!mounted) {
      return;
    }

    if (data.transactions.isEmpty) {
      _showMessage(
        'Belum ada transaksi untuk periode yang dipilih.',
      );
      return;
    }

    final csv = _buildCsv(
      account: account,
      data: data,
    );

    await _showCsvDialog(
      csv: csv,
      account: account,
    );
  }

  Future<void> _showCsvDialog({
    required String csv,
    required String account,
  }) async {
    final copied = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.table_chart_outlined),
              SizedBox(width: 10),
              Expanded(
                child: Text('Ekspor CSV'),
              ),
            ],
          ),
          content: SizedBox(
            width: 700,
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laporan $account • '
                  '${_formatMonth(_selectedMonth)}',
                  style: const TextStyle(
                    color: Color(0xFF9A9DA3),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1E22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        csv,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Tutup'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: csv),
                );

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Salin CSV'),
            ),
          ],
        );
      },
    );

    if (!mounted || copied != true) {
      return;
    }

    _showMessage(
      'CSV berhasil disalin. '
      'Tempelkan ke Excel atau Google Sheets.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Map<String, double> _groupExpensesByCategory(
    List<Tx> transactions,
  ) {
    final result = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense) {
        continue;
      }

      result.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        if (mounted) {
          setState(() {});
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          32,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Laporan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.activeAccount ?? 'Belum ada akun',
                      style: const TextStyle(
                        color: Color(0xFF9A9DA3),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ekspor CSV',
                onPressed: _exportCsv,
                icon: const Icon(
                  Icons.file_download_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _MonthSelector(
            month: _formatMonth(_selectedMonth),
            onPrevious: () {
              _changeMonth(-1);
            },
            onNext: () {
              _changeMonth(1);
            },
          ),
          const SizedBox(height: 18),
          FutureBuilder<_ReportData>(
            future: _loadReport(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _ReportMessage(
                  icon: Icons.error_outline,
                  title: 'Gagal memuat laporan',
                  message: snapshot.error.toString(),
                );
              }

              final data = snapshot.data ??
                  const _ReportData(
                    transactions: <Tx>[],
                    income: 0,
                    expense: 0,
                  );

              final balance =
                  data.income - data.expense;

              final categoryExpenses =
                  _groupExpensesByCategory(
                data.transactions,
              );

              return Column(
                children: [
                  _BalanceReportCard(
                    balance: balance,
                    income: data.income,
                    expense: data.expense,
                    formatRupiah: _formatRupiah,
                  ),
                  const SizedBox(height: 16),
                  _ReportSummary(
                    income: data.income,
                    expense: data.expense,
                    formatRupiah: _formatRupiah,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Pengeluaran per Kategori',
                  ),
                  const SizedBox(height: 12),
                  if (categoryExpenses.isEmpty)
                    const _ReportMessage(
                      icon: Icons.pie_chart_outline,
                      title: 'Belum ada pengeluaran',
                      message:
                          'Belum ada data pengeluaran pada bulan ini.',
                    )
                  else
                    _CategoryReport(
                      categories: categoryExpenses,
                      totalExpense: data.expense,
                      formatRupiah: _formatRupiah,
                    ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Aktivitas Bulan Ini',
                  ),
                  const SizedBox(height: 12),
                  if (data.transactions.isEmpty)
                    const _ReportMessage(
                      icon: Icons.receipt_long_outlined,
                      title: 'Belum ada transaksi',
                      message:
                          'Belum ada transaksi pada periode yang dipilih.',
                    )
                  else
                    ...data.transactions.take(10).map(
                      (transaction) => Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: _ReportTransactionItem(
                          transaction: transaction,
                          formatRupiah: _formatRupiah,
                          formatDate: _formatDate,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportData {
  const _ReportData({
    required this.transactions,
    required this.income,
    required this.expense,
  });

  final List<Tx> transactions;
  final double income;
  final double expense;
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final String month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bulan sebelumnya',
            onPressed: onPrevious,
            icon: const Icon(
              Icons.chevron_left,
            ),
          ),
          Expanded(
            child: Text(
              month,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Bulan berikutnya',
            onPressed: onNext,
            icon: const Icon(
              Icons.chevron_right,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceReportCard extends StatelessWidget {
  const _BalanceReportCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.formatRupiah,
  });

  final double balance;
  final double income;
  final double expense;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF282B30),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Arus Bersih',
            style: TextStyle(
              color: Color(0xFFB8BCC2),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatRupiah(balance),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniAmount(
                  label: 'Pemasukan',
                  amount: income,
                  formatRupiah: formatRupiah,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniAmount(
                  label: 'Pengeluaran',
                  amount: expense,
                  formatRupiah: formatRupiah,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAmount extends StatelessWidget {
  const _MiniAmount({
    required this.label,
    required this.amount,
    required this.formatRupiah,
  });

  final String label;
  final double amount;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9A9DA3),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            formatRupiah(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({
    required this.income,
    required this.expense,
    required this.formatRupiah,
  });

  final double income;
  final double expense;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    final total = income + expense;

    final incomePercentage =
        total <= 0 ? 0.0 : income / total;

    final expensePercentage =
        total <= 0 ? 0.0 : expense / total;

    return Row(
      children: [
        Expanded(
          child: _ProgressCard(
            title: 'Pemasukan',
            amount: income,
            percentage: incomePercentage,
            formatRupiah: formatRupiah,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProgressCard(
            title: 'Pengeluaran',
            amount: expense,
            percentage: expensePercentage,
            formatRupiah: formatRupiah,
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.amount,
    required this.percentage,
    required this.formatRupiah,
  });

  final String title;
  final double amount;
  final double percentage;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9A9DA3),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatRupiah(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor:
                  const Color(0xFF34373D),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryReport extends StatelessWidget {
  const _CategoryReport({
    required this.categories,
    required this.totalExpense,
    required this.formatRupiah,
  });

  final Map<String, double> categories;
  final double totalExpense;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    final entries = categories.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: entries.map(
          (entry) {
            final percentage = totalExpense <= 0
                ? 0.0
                : entry.value / totalExpense;

            return Padding(
              padding: const EdgeInsets.only(
                bottom: 18,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatRupiah(entry.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(20),
                          child:
                              LinearProgressIndicator(
                            value: percentage.clamp(
                              0.0,
                              1.0,
                            ),
                            minHeight: 7,
                            backgroundColor:
                                const Color(0xFF34373D),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${(percentage * 100).round()}%',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color:
                                Color(0xFF9A9DA3),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ).toList(),
      ),
    );
  }
}

class _ReportTransactionItem extends StatelessWidget {
  const _ReportTransactionItem({
    required this.transaction,
    required this.formatRupiah,
    required this.formatDate,
  });

  final Tx transaction;
  final String Function(double) formatRupiah;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final isIncome =
        transaction.type == TransactionType.income;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor:
                const Color(0xFF34373D),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 19,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.category} • ${formatDate(transaction.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9A9DA3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${isIncome ? '+' : '-'}${formatRupiah(transaction.amount)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReportMessage extends StatelessWidget {
  const _ReportMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: const Color(0xFF777B82),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9A9DA3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
