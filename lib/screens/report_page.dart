import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
import '../models/transaction.dart';
import '../services/budget_store.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({
    super.key,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  late final BudgetStore _budgetStore;

  @override
  void initState() {
    super.initState();
    _budgetStore = BudgetStore();
    _budgetStore.load();
  }

  @override
  void dispose() {
    _budgetStore.close();
    super.dispose();
  }

  Future<_ReportData> _loadReport() async {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    if (account == null) {
      return const _ReportData(
        transactions: <Tx>[],
        income: 0,
        expense: 0,
        previousTransactions: <Tx>[],
        previousIncome: 0,
        previousExpense: 0,
        monthlyTrend: <_MonthlyTrend>[],
        budgets: <Budget>[],
      );
    }

    final currentStart = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    final currentEnd = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
    );

    final previousStart = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 1,
    );

    final previousEnd = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    final transactions = await store.getTransactions(
      account: account,
      startDate: currentStart,
      endDate: currentEnd,
    );

    final previousTransactions = await store.getTransactions(
      account: account,
      startDate: previousStart,
      endDate: previousEnd,
    );

    final income = _sumByType(
      transactions,
      TransactionType.income,
    );

    final expense = _sumByType(
      transactions,
      TransactionType.expense,
    );

    final previousIncome = _sumByType(
      previousTransactions,
      TransactionType.income,
    );

    final previousExpense = _sumByType(
      previousTransactions,
      TransactionType.expense,
    );

    final monthlyTrend = <_MonthlyTrend>[];

    for (var index = 5; index >= 0; index--) {
      final month = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - index,
      );

      final start = DateTime(
        month.year,
        month.month,
      );

      final end = DateTime(
        month.year,
        month.month + 1,
      );

      final monthTransactions = await store.getTransactions(
        account: account,
        startDate: start,
        endDate: end,
      );

      monthlyTrend.add(
        _MonthlyTrend(
          month: month,
          income: _sumByType(
            monthTransactions,
            TransactionType.income,
          ),
          expense: _sumByType(
            monthTransactions,
            TransactionType.expense,
          ),
        ),
      );
    }

    final budgets = await _budgetStore.getBudgets(
      account: account,
      month: _selectedMonth,
    );

    return _ReportData(
      transactions: transactions,
      income: income,
      expense: expense,
      previousTransactions: previousTransactions,
      previousIncome: previousIncome,
      previousExpense: previousExpense,
      monthlyTrend: monthlyTrend,
      budgets: budgets,
    );
  }

  double _sumByType(
    List<Tx> transactions,
    TransactionType type,
  ) {
    var total = 0.0;

    for (final transaction in transactions) {
      if (transaction.type == type) {
        total += transaction.amount;
      }
    }

    return total;
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
  }

  Future<void> _pickMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih bulan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        selected.year,
        selected.month,
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

  String _shortMonthName(int month) {
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

    return months[month - 1];
  }

  String _formatRupiah(double value) {
    final rounded = value.round();
    final absolute = rounded.abs();
    final digits = absolute.toString();

    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(digits[i]);
    }

    final prefix = rounded < 0 ? '-Rp ' : 'Rp ';

    return '$prefix$buffer';
  }

  String _formatCompactRupiah(double value) {
    final absolute = value.abs();

    if (absolute >= 1000000000) {
      return 'Rp ${(value / 1000000000).toStringAsFixed(1)} M';
    }

    if (absolute >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)} jt';
    }

    if (absolute >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)} rb';
    }

    return _formatRupiah(value);
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_shortMonthName(date.month)} ${date.year}';
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

  double _categoryAmount(
    List<Tx> transactions,
    String category,
  ) {
    var total = 0.0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense &&
          transaction.category == category) {
        total += transaction.amount;
      }
    }

    return total;
  }

  double _changePercentage(
    double current,
    double previous,
  ) {
    if (previous == 0) {
      if (current == 0) {
        return 0;
      }

      return 100;
    }

    return ((current - previous) / previous) * 100;
  }

  String _percentage(double value) {
    return '${value.round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    return RefreshIndicator(
      onRefresh: () async {
        await _budgetStore.refresh();

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
          const Text(
            'Laporan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            account ?? 'Belum ada akun',
            style: const TextStyle(
              color: Color(0xFF9A9DA3),
            ),
          ),
          const SizedBox(height: 18),
          _MonthSelector(
            month:
                '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
            onPrevious: () {
              _changeMonth(-1);
            },
            onNext: () {
              _changeMonth(1);
            },
            onPick: _pickMonth,
          ),
          const SizedBox(height: 18),
          FutureBuilder<_ReportData>(
            future: _loadReport(),
            builder: (
              context,
              snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
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
                  message: '${snapshot.error}',
                );
              }

              final data = snapshot.data ??
                  const _ReportData(
                    transactions: <Tx>[],
                    income: 0,
                    expense: 0,
                    previousTransactions: <Tx>[],
                    previousIncome: 0,
                    previousExpense: 0,
                    monthlyTrend: <_MonthlyTrend>[],
                    budgets: <Budget>[],
                  );

              final balance = data.income - data.expense;
              final previousBalance =
                  data.previousIncome - data.previousExpense;

              final categories =
                  _groupExpensesByCategory(data.transactions);

              return Column(
                children: [
                  _BalanceReportCard(
                    balance: balance,
                    income: data.income,
                    expense: data.expense,
                    formatRupiah: _formatRupiah,
                  ),
                  const SizedBox(height: 16),
                  _MonthComparisonCard(
                    currentIncome: data.income,
                    currentExpense: data.expense,
                    currentBalance: balance,
                    previousIncome: data.previousIncome,
                    previousExpense: data.previousExpense,
                    previousBalance: previousBalance,
                    formatRupiah: _formatRupiah,
                    percentage: _percentage,
                    changePercentage: _changePercentage,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Tren 6 Bulan',
                  ),
                  const SizedBox(height: 12),
                  _MonthlyTrendCard(
                    trend: data.monthlyTrend,
                    selectedMonth: _selectedMonth,
                    formatCompactRupiah: _formatCompactRupiah,
                    shortMonthName: _shortMonthName,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Insight Budget',
                  ),
                  const SizedBox(height: 12),
                  _BudgetInsightSection(
                    budgets: data.budgets,
                    transactions: data.transactions,
                    formatRupiah: _formatRupiah,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Insight Keuangan',
                  ),
                  const SizedBox(height: 12),
                  _InsightCard(
                    data: data,
                    categories: categories,
                    formatRupiah: _formatRupiah,
                    percentage: _percentage,
                    categoryAmount: _categoryAmount,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Pengeluaran per Kategori',
                  ),
                  const SizedBox(height: 12),
                  if (categories.isEmpty)
                    const _ReportMessage(
                      icon: Icons.pie_chart_outline,
                      title: 'Belum ada pengeluaran',
                      message:
                          'Belum ada data pengeluaran pada bulan ini.',
                    )
                  else
                    _CategoryReport(
                      categories: categories,
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
                      (transaction) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: _ReportTransactionItem(
                            transaction: transaction,
                            formatRupiah: _formatRupiah,
                            formatDate: _formatDate,
                          ),
                        );
                      },
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
    required this.previousTransactions,
    required this.previousIncome,
    required this.previousExpense,
    required this.monthlyTrend,
    required this.budgets,
  });

  final List<Tx> transactions;
  final double income;
  final double expense;

  final List<Tx> previousTransactions;
  final double previousIncome;
  final double previousExpense;

  final List<_MonthlyTrend> monthlyTrend;
  final List<Budget> budgets;
}

class _MonthlyTrend {
  const _MonthlyTrend({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;

  double get balance => income - expense;
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final String month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

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
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onPick,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Periode laporan',
                      style: TextStyle(
                        color: Color(0xFF9A9DA3),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      month,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
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
    final isSurplus = balance >= 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF282B30),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isSurplus
                      ? 'Surplus Bulan Ini'
                      : 'Defisit Bulan Ini',
                  style: const TextStyle(
                    color: Color(0xFFB8BCC2),
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(
                isSurplus
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 22,
              ),
            ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

class _MonthComparisonCard extends StatelessWidget {
  const _MonthComparisonCard({
    required this.currentIncome,
    required this.currentExpense,
    required this.currentBalance,
    required this.previousIncome,
    required this.previousExpense,
    required this.previousBalance,
    required this.formatRupiah,
    required this.percentage,
    required this.changePercentage,
  });

  final double currentIncome;
  final double currentExpense;
  final double currentBalance;

  final double previousIncome;
  final double previousExpense;
  final double previousBalance;

  final String Function(double) formatRupiah;
  final String Function(double) percentage;
  final double Function(double, double) changePercentage;

  @override
  Widget build(BuildContext context) {
    final incomeChange = changePercentage(
      currentIncome,
      previousIncome,
    );

    final expenseChange = changePercentage(
      currentExpense,
      previousExpense,
    );

    final balanceChange = currentBalance - previousBalance;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dibanding Bulan Lalu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _ComparisonRow(
            icon: Icons.south_west_rounded,
            title: 'Pemasukan',
            current: formatRupiah(currentIncome),
            change: incomeChange,
            percentage: percentage,
            positiveIsGood: true,
          ),
          const SizedBox(height: 14),
          _ComparisonRow(
            icon: Icons.north_east_rounded,
            title: 'Pengeluaran',
            current: formatRupiah(currentExpense),
            change: expenseChange,
            percentage: percentage,
            positiveIsGood: false,
          ),
          const SizedBox(height: 14),
          _ComparisonRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Surplus / Defisit',
            current: formatRupiah(currentBalance),
            change: previousBalance == 0
                ? (balanceChange == 0 ? 0 : 100)
                : (balanceChange / previousBalance.abs()) * 100,
            percentage: percentage,
            positiveIsGood: balanceChange >= 0,
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.icon,
    required this.title,
    required this.current,
    required this.change,
    required this.percentage,
    required this.positiveIsGood,
  });

  final IconData icon;
  final String title;
  final String current;
  final double change;
  final String Function(double) percentage;
  final bool positiveIsGood;

  @override
  Widget build(BuildContext context) {
    final isIncrease = change >= 0;
    final isGood = positiveIsGood == isIncrease;

    final iconData = isIncrease
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF282B30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF9A9DA3),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                current,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 15,
              color: isGood
                  ? Colors.greenAccent
                  : Colors.orangeAccent,
            ),
            const SizedBox(width: 3),
            Text(
              percentage(change.abs()),
              style: TextStyle(
                color: isGood
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthlyTrendCard extends StatelessWidget {
  const _MonthlyTrendCard({
    required this.trend,
    required this.selectedMonth,
    required this.formatCompactRupiah,
    required this.shortMonthName,
  });

  final List<_MonthlyTrend> trend;
  final DateTime selectedMonth;
  final String Function(double) formatCompactRupiah;
  final String Function(int) shortMonthName;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const _ReportMessage(
        icon: Icons.show_chart_rounded,
        title: 'Belum ada tren',
        message:
            'Belum ada data transaksi untuk menampilkan tren.',
      );
    }

    final maxValue = trend.fold<double>(
      0,
      (maximum, item) {
        return math.max(
          maximum,
          math.max(
            item.income,
            item.expense,
          ),
        );
      },
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LegendDot(
                label: 'Pemasukan',
              ),
              const SizedBox(width: 16),
              const _LegendDot(
                label: 'Pengeluaran',
              ),
              const Spacer(),
              const Text(
                '6 bulan',
                style: TextStyle(
                  color: Color(0xFF9A9DA3),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 230,
            child: CustomPaint(
              painter: _TrendChartPainter(
                trend: trend,
                maxValue: maxValue <= 0 ? 1 : maxValue,
                selectedMonth: selectedMonth,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: trend.map(
              (item) {
                final selected =
                    item.month.year == selectedMonth.year &&
                    item.month.month == selectedMonth.month;

                return Expanded(
                  child: Text(
                    shortMonthName(item.month.month),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected
                          ? FontWeight.w800
                          : FontWeight.normal,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF777B82),
                    ),
                  ),
                );
              },
            ).toList(),
          ),
          const SizedBox(height: 18),
          const Divider(
            color: Color(0xFF34373D),
            height: 1,
          ),
          const SizedBox(height: 14),
          ...trend.reversed.take(3).map(
            (item) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 9,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: Text(
                        shortMonthName(item.month.month),
                        style: const TextStyle(
                          color: Color(0xFF9A9DA3),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Masuk ${formatCompactRupiah(item.income)}',
                        style: const TextStyle(
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Keluar ${formatCompactRupiah(item.expense)}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Color(0xFFB8BCC2),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({
    required this.trend,
    required this.maxValue,
    required this.selectedMonth,
  });

  final List<_MonthlyTrend> trend;
  final double maxValue;
  final DateTime selectedMonth;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    const left = 8.0;
    const right = 8.0;
    const top = 12.0;
    const bottom = 12.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    final gridPaint = Paint()
      ..color = const Color(0xFF30343A)
      ..strokeWidth = 1;

    final linePaintIncome = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePaintExpense = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final incomeDotPaint = Paint()
      ..color = Colors.greenAccent;

    final expenseDotPaint = Paint()
      ..color = Colors.orangeAccent;

    for (var i = 0; i <= 4; i++) {
      final y = top + chartHeight * (i / 4);

      canvas.drawLine(
        const Offset(left, 0),
        Offset(
          size.width - right,
          y,
        ),
        gridPaint,
      );
    }

    if (trend.isEmpty) {
      return;
    }

    final spacing = trend.length <= 1
        ? chartWidth
        : chartWidth / (trend.length - 1);

    final incomePath = Path();
    final expensePath = Path();

    for (var index = 0; index < trend.length; index++) {
      final item = trend[index];

      final x = left + spacing * index;

      final incomeRatio = item.income / maxValue;
      final expenseRatio = item.expense / maxValue;

      final incomeY = top + chartHeight * (1 - incomeRatio);
      final expenseY = top + chartHeight * (1 - expenseRatio);

      final incomePoint = Offset(x, incomeY);
      final expensePoint = Offset(x, expenseY);

      if (index == 0) {
        incomePath.moveTo(
          incomePoint.dx,
          incomePoint.dy,
        );
        expensePath.moveTo(
          expensePoint.dx,
          expensePoint.dy,
        );
      } else {
        incomePath.lineTo(
          incomePoint.dx,
          incomePoint.dy,
        );
        expensePath.lineTo(
          expensePoint.dx,
          expensePoint.dy,
        );
      }
    }

    canvas.drawPath(
      incomePath,
      linePaintIncome,
    );

    canvas.drawPath(
      expensePath,
      linePaintExpense,
    );

    for (var index = 0; index < trend.length; index++) {
      final item = trend[index];

      final x = left + spacing * index;

      final incomeY =
          top + chartHeight * (1 - item.income / maxValue);

      final expenseY =
          top + chartHeight * (1 - item.expense / maxValue);

      final selected =
          item.month.year == selectedMonth.year &&
          item.month.month == selectedMonth.month;

      if (selected) {
        final selectedPaint = Paint()
          ..color = const Color(0xFF777B82)
          ..strokeWidth = 1;

        canvas.drawLine(
          Offset(x, top),
          Offset(
            x,
            size.height - bottom,
          ),
          selectedPaint,
        );
      }

      canvas.drawCircle(
        Offset(x, incomeY),
        selected ? 5 : 4,
        incomeDotPaint,
      );

      canvas.drawCircle(
        Offset(x, expenseY),
        selected ? 5 : 4,
        expenseDotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _TrendChartPainter oldDelegate,
  ) {
    return oldDelegate.trend != trend ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.selectedMonth != selectedMonth;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final isIncome = label == 'Pemasukan';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isIncome
                ? Colors.greenAccent
                : Colors.orangeAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB8BCC2),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _BudgetInsightSection extends StatelessWidget {
  const _BudgetInsightSection({
    required this.budgets,
    required this.transactions,
    required this.formatRupiah,
  });

  final List<Budget> budgets;
  final List<Tx> transactions;
  final String Function(double) formatRupiah;

  double _spentForCategory(
    String category,
  ) {
    var total = 0.0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense &&
          transaction.category == category) {
        total += transaction.amount;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return const _ReportMessage(
        icon: Icons.track_changes_outlined,
        title: 'Belum ada budget',
        message:
            'Belum ada budget pada bulan ini. Atur budget di halaman Anggaran untuk mendapatkan insight otomatis.',
      );
    }

    final items = budgets.map(
      (budget) {
        final spent = _spentForCategory(
          budget.category,
        );

        return _BudgetInsightItem(
          category: budget.category,
          limit: budget.limit,
          spent: spent,
          formatRupiah: formatRupiah,
        );
      },
    ).toList();

    final overBudget = items.where(
      (item) => item.isOverBudget,
    ).toList();

    final warningBudget = items.where(
      (item) =>
          !item.isOverBudget &&
          item.percentage >= 0.8,
    ).toList();

    String title;
    String message;
    IconData icon;

    if (overBudget.isNotEmpty) {
      final first = overBudget.first;

      title = '${overBudget.length} budget melewati batas';
      message =
          '${first.category} sudah melebihi budget sebesar '
          '${formatRupiah(first.spent - first.limit)}.';
      icon = Icons.warning_amber_rounded;
    } else if (warningBudget.isNotEmpty) {
      final first = warningBudget.first;

      title = '${warningBudget.length} budget mendekati batas';
      message =
          '${first.category} sudah terpakai '
          '${(first.percentage * 100).round()}% dari budget.';
      icon = Icons.info_outline_rounded;
    } else {
      title = 'Budget masih terkendali';
      message =
          'Semua kategori masih berada di bawah 80% budget.';
      icon = Icons.check_circle_outline;
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1E22),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF282B30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFFB8BCC2),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(
              bottom: 10,
            ),
            child: item,
          ),
        ),
      ],
    );
  }
}

class _BudgetInsightItem extends StatelessWidget {
  const _BudgetInsightItem({
    required this.category,
    required this.limit,
    required this.spent,
    required this.formatRupiah,
  });

  final String category;
  final double limit;
  final double spent;
  final String Function(double) formatRupiah;

  double get percentage {
    if (limit <= 0) {
      return 0;
    }

    return spent / limit;
  }

  bool get isOverBudget => spent > limit;

  @override
  Widget build(BuildContext context) {
    final ratio = percentage.clamp(0.0, 1.0);

    final isWarning =
        !isOverBudget && percentage >= 0.8;

    final status = isOverBudget
        ? 'Melewati budget'
        : isWarning
            ? 'Mendekati batas'
            : 'Masih aman';

    final remaining = limit - spent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                status,
                style: TextStyle(
                  color: isOverBudget
                      ? Colors.redAccent
                      : isWarning
                          ? Colors.orangeAccent
                          : Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF34373D),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(percentage * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Terpakai ${formatRupiah(spent)}',
                  style: const TextStyle(
                    color: Color(0xFF9A9DA3),
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                isOverBudget
                    ? 'Lebih ${formatRupiah(spent - limit)}'
                    : 'Sisa ${formatRupiah(remaining)}',
                style: TextStyle(
                  color: isOverBudget
                      ? Colors.redAccent
                      : const Color(0xFFB8BCC2),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.data,
    required this.categories,
    required this.formatRupiah,
    required this.percentage,
    required this.categoryAmount,
  });

  final _ReportData data;
  final Map<String, double> categories;
  final String Function(double) formatRupiah;
  final String Function(double) percentage;
  final double Function(
    List<Tx>,
    String,
  ) categoryAmount;

  @override
  Widget build(BuildContext context) {
    final balance = data.income - data.expense;

    final expenseRatio = data.income <= 0
        ? 0.0
        : (data.expense / data.income) * 100;

    final sorted = categories.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    String? largestCategory;
    double largestAmount = 0;

    if (sorted.isNotEmpty) {
      largestCategory = sorted.first.key;
      largestAmount = sorted.first.value;
    }

    String? increasedCategory;
    double biggestIncrease = 0;

    for (final entry in categories.entries) {
      final previous = categoryAmount(
        data.previousTransactions,
        entry.key,
      );

      final increase = entry.value - previous;

      if (increase > biggestIncrease) {
        biggestIncrease = increase;
        increasedCategory = entry.key;
      }
    }

    String statusTitle;
    String statusMessage;
    IconData statusIcon;

    if (data.income <= 0 && data.expense <= 0) {
      statusTitle = 'Belum cukup data';
      statusMessage =
          'Tambahkan transaksi agar insight keuangan dapat dibuat secara otomatis.';
      statusIcon = Icons.insights_outlined;
    } else if (balance < 0) {
      statusTitle = 'Pengeluaran lebih besar';
      statusMessage =
          'Bulan ini mengalami defisit ${formatRupiah(balance.abs())}. Perhatikan pengeluaran terbesar.';
      statusIcon = Icons.warning_amber_rounded;
    } else if (expenseRatio >= 90) {
      statusTitle = 'Perlu lebih waspada';
      statusMessage =
          'Pengeluaran mencapai ${percentage(expenseRatio)} dari pemasukan.';
      statusIcon = Icons.priority_high_rounded;
    } else if (expenseRatio >= 70) {
      statusTitle = 'Keuangan cukup ketat';
      statusMessage =
          'Sekitar ${percentage(expenseRatio)} pemasukan sudah digunakan untuk pengeluaran.';
      statusIcon = Icons.info_outline_rounded;
    } else {
      statusTitle = 'Kondisi cukup sehat';
      statusMessage =
          'Pengeluaran sekitar ${percentage(expenseRatio)} dari pemasukan. Pertahankan surplus dan sisihkan untuk tabungan.';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF282B30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  statusIcon,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      statusMessage,
                      style: const TextStyle(
                        color: Color(0xFFB8BCC2),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(
            color: Color(0xFF34373D),
            height: 1,
          ),
          const SizedBox(height: 16),
          _InsightRow(
            icon: Icons.percent_rounded,
            title: 'Rasio pengeluaran',
            value: data.income <= 0
                ? 'Belum tersedia'
                : percentage(expenseRatio),
            subtitle: data.income <= 0
                ? 'Belum ada pemasukan'
                : 'Dari pemasukan bulan ini',
          ),
          if (largestCategory != null) ...[
            const SizedBox(height: 16),
            _InsightRow(
              icon: Icons.category_outlined,
              title: 'Pengeluaran terbesar',
              value: largestCategory,
              subtitle: formatRupiah(largestAmount),
            ),
          ],
          if (increasedCategory != null &&
              biggestIncrease > 0) ...[
            const SizedBox(height: 16),
            _InsightRow(
              icon: Icons.trending_up_rounded,
              title: 'Kategori yang meningkat',
              value: increasedCategory,
              subtitle:
                  '+${formatRupiah(biggestIncrease)} dibanding bulan lalu',
            ),
          ],
          const SizedBox(height: 16),
          _RecommendationBox(
            balance: balance,
            expenseRatio: expenseRatio,
            largestCategory: largestCategory,
            largestAmount: largestAmount,
            increasedCategory: increasedCategory,
            biggestIncrease: biggestIncrease,
            formatRupiah: formatRupiah,
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFFB8BCC2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF9A9DA3),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9A9DA3),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecommendationBox extends StatelessWidget {
  const _RecommendationBox({
    required this.balance,
    required this.expenseRatio,
    required this.largestCategory,
    required this.largestAmount,
    required this.increasedCategory,
    required this.biggestIncrease,
    required this.formatRupiah,
  });

  final double balance;
  final double expenseRatio;
  final String? largestCategory;
  final double largestAmount;
  final String? increasedCategory;
  final double biggestIncrease;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    String recommendation;

    if (balance < 0) {
      if (largestCategory != null) {
        recommendation =
            'Evaluasi kategori "$largestCategory" karena menjadi pengeluaran terbesar sebesar ${formatRupiah(largestAmount)}.';
      } else {
        recommendation =
            'Kurangi pengeluaran non-prioritas agar arus kas kembali positif.';
      }
    } else if (expenseRatio >= 90) {
      recommendation =
          'Pengeluaran sudah sangat dekat dengan pemasukan. Sisakan ruang untuk tabungan atau dana darurat.';
    } else if (increasedCategory != null &&
        biggestIncrease > 0) {
      recommendation =
          'Perhatikan kategori "$increasedCategory" karena pengeluarannya meningkat ${formatRupiah(biggestIncrease)} dari bulan lalu.';
    } else if (largestCategory != null) {
      recommendation =
          'Pertahankan surplus. Jika ingin lebih hemat, mulai dari kategori "$largestCategory".';
    } else {
      recommendation =
          'Catat transaksi secara rutin agar pola keuangan semakin mudah dianalisis.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF282B30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rekomendasi',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation,
                  style: const TextStyle(
                    color: Color(0xFFB8BCC2),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
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
                          overflow: TextOverflow.ellipsis,
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
                          child: LinearProgressIndicator(
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
                            color: Color(0xFF9A9DA3),
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
            backgroundColor: const Color(0xFF34373D),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
