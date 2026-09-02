import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
import '../models/transaction.dart';

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

  Future<_ReportData> _loadReport() async {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    if (account == null) {
      return const _ReportData.empty();
    }

    final monthStart = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    final monthEnd = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
    );

    final income = await store.getTotalIncome(
      account: account,
      startDate: monthStart,
      endDate: monthEnd,
    );

    final expense = await store.getTotalExpense(
      account: account,
      startDate: monthStart,
      endDate: monthEnd,
    );

    final transactions = await store.getTransactions(
      account: account,
      startDate: monthStart,
      endDate: monthEnd,
    );

    final expenseByCategory = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense) {
        continue;
      }

      expenseByCategory.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final categoryEntries = expenseByCategory.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    final monthlyTrend = <_MonthlyReport>[];

    for (var offset = 5; offset >= 0; offset--) {
      final month = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - offset,
      );

      final start = DateTime(
        month.year,
        month.month,
      );

      final end = DateTime(
        month.year,
        month.month + 1,
      );

      final monthlyIncome = await store.getTotalIncome(
        account: account,
        startDate: start,
        endDate: end,
      );

      final monthlyExpense = await store.getTotalExpense(
        account: account,
        startDate: start,
        endDate: end,
      );

      monthlyTrend.add(
        _MonthlyReport(
          month: month,
          income: monthlyIncome,
          expense: monthlyExpense,
        ),
      );
    }

    return _ReportData(
      income: income,
      expense: expense,
      balance: income - expense,
      transactionCount: transactions.length,
      categoryEntries: categoryEntries,
      monthlyTrend: monthlyTrend,
    );
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih bulan laporan',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        picked.year,
        picked.month,
      );
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

  String _formatShortMonth(DateTime date) {
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

    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan'),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            if (mounted) {
              setState(() {});
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              32,
            ),
            children: [
              _PeriodSelector(
                month: _selectedMonth,
                label: _formatMonth(_selectedMonth),
                onPrevious: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
                onPick: _pickMonth,
              ),
              const SizedBox(height: 18),
              if (account == null)
                const _ReportMessage(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Belum ada akun',
                  message:
                      'Tambahkan akun terlebih dahulu untuk melihat laporan.',
                )
              else
                FutureBuilder<_ReportData>(
                  future: _loadReport(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 80),
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

                    final data =
                        snapshot.data ?? const _ReportData.empty();

                    if (data.transactionCount == 0) {
                      return Column(
                        children: [
                          _SummaryGrid(
                            data: data,
                            formatRupiah: _formatRupiah,
                          ),
                          const SizedBox(height: 20),
                          const _ReportMessage(
                            icon: Icons.receipt_long_outlined,
                            title: 'Belum ada transaksi',
                            message:
                                'Belum ada transaksi pada bulan yang dipilih.',
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryGrid(
                          data: data,
                          formatRupiah: _formatRupiah,
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Kondisi Keuangan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FinancialInsight(
                          data: data,
                          formatRupiah: _formatRupiah,
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Pengeluaran per Kategori',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CategoryReportCard(
                          entries: data.categoryEntries,
                          totalExpense: data.expense,
                          formatRupiah: _formatRupiah,
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Tren 6 Bulan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _MonthlyTrendCard(
                          months: data.monthlyTrend,
                          formatRupiah: _formatRupiah,
                          shortMonth: _formatShortMonth,
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportData {
  const _ReportData({
    required this.income,
    required this.expense,
    required this.balance,
    required this.transactionCount,
    required this.categoryEntries,
    required this.monthlyTrend,
  });

  const _ReportData.empty()
      : income = 0,
        expense = 0,
        balance = 0,
        transactionCount = 0,
        categoryEntries = const <MapEntry<String, double>>[],
        monthlyTrend = const <_MonthlyReport>[];

  final double income;
  final double expense;
  final double balance;
  final int transactionCount;
  final List<MapEntry<String, double>> categoryEntries;
  final List<_MonthlyReport> monthlyTrend;
}

class _MonthlyReport {
  const _MonthlyReport({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;

  double get balance => income - expense;
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.month,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime month;
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          8,
          8,
          8,
          8,
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
                onTap: onPick,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Periode Laporan',
                        style: TextStyle(
                          color: Color(0xFF9A9DA3),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
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
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.data,
    required this.formatRupiah,
  });

  final _ReportData data;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Pemasukan',
                value: formatRupiah(data.income),
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Pengeluaran',
                value: formatRupiah(data.expense),
                icon: Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          title: data.balance >= 0
              ? 'Surplus Bulan Ini'
              : 'Defisit Bulan Ini',
          value: formatRupiah(data.balance),
          icon: Icons.account_balance_wallet_outlined,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.fullWidth = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(
          fullWidth ? 20 : 16,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF30343A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialInsight extends StatelessWidget {
  const _FinancialInsight({
    required this.data,
    required this.formatRupiah,
  });

  final _ReportData data;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    final bool positive = data.balance >= 0;

    final double ratio = data.income > 0
        ? (data.expense / data.income) * 100
        : 0;

    final String message;

    if (data.income <= 0 && data.expense > 0) {
      message =
          'Bulan ini belum memiliki pemasukan, sementara '
          'pengeluaran mencapai ${formatRupiah(data.expense)}.';
    } else if (data.expense > data.income) {
      message =
          'Pengeluaran lebih besar daripada pemasukan. '
          'Defisit bulan ini ${formatRupiah(data.balance.abs())}.';
    } else if (data.expense == 0) {
      message =
          'Belum ada pengeluaran pada bulan ini. '
          'Seluruh pemasukan masih tersisa.';
    } else {
      message =
          'Pengeluaran menggunakan sekitar '
          '${ratio.toStringAsFixed(0)}% dari pemasukan bulan ini. '
          'Sisa ${formatRupiah(data.balance)}.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF30343A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                positive
                    ? Icons.trending_up
                    : Icons.trending_down,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    positive
                        ? 'Keuangan Positif'
                        : 'Perlu Perhatian',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF9A9DA3),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryReportCard extends StatelessWidget {
  const _CategoryReportCard({
    required this.entries,
    required this.totalExpense,
    required this.formatRupiah,
  });

  final List<MapEntry<String, double>> entries;
  final double totalExpense;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Belum ada pengeluaran berdasarkan kategori.',
            style: TextStyle(
              color: Color(0xFF9A9DA3),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            ...entries.take(8).map(
              (entry) {
                final percentage = totalExpense > 0
                    ? (entry.value / totalExpense) * 100
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 16,
                  ),
                  child: _CategoryRow(
                    category: entry.key,
                    amount: entry.value,
                    percentage: percentage,
                    formatRupiah: formatRupiah,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.formatRupiah,
  });

  final String category;
  final double amount;
  final double percentage;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    final progress = (percentage / 100).clamp(
      0.0,
      1.0,
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatRupiah(amount),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFF30343A),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${percentage.toStringAsFixed(0)}% dari total pengeluaran',
          style: const TextStyle(
            color: Color(0xFF777B82),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MonthlyTrendCard extends StatelessWidget {
  const _MonthlyTrendCard({
    required this.months,
    required this.formatRupiah,
    required this.shortMonth,
  });

  final List<_MonthlyReport> months;
  final String Function(double) formatRupiah;
  final String Function(DateTime) shortMonth;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxValue = 0;

    for (final month in months) {
      if (month.income > maxValue) {
        maxValue = month.income;
      }

      if (month.expense > maxValue) {
        maxValue = month.expense;
      }
    }

    if (maxValue <= 0) {
      maxValue = 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          16,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Pemasukan',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Pengeluaran',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 190,
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: months.map(
                  (month) {
                    return Expanded(
                      child: _MonthBar(
                        data: month,
                        maxValue: maxValue,
                        formatRupiah: formatRupiah,
                        shortMonth: shortMonth,
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.data,
    required this.maxValue,
    required this.formatRupiah,
    required this.shortMonth,
  });

  final _MonthlyReport data;
  final double maxValue;
  final String Function(double) formatRupiah;
  final String Function(DateTime) shortMonth;

  @override
  Widget build(BuildContext context) {
    const chartHeight = 130.0;

    final incomeHeight =
        (data.income / maxValue) * chartHeight;

    final expenseHeight =
        (data.expense / maxValue) * chartHeight;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.end,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    width: 12,
                    height: incomeHeight.clamp(
                      2.0,
                      chartHeight,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                          const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Container(
                    width: 12,
                    height: expenseHeight.clamp(
                      2.0,
                      chartHeight,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius:
                          const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            shortMonth(data.month),
            style: const TextStyle(
              color: Color(0xFF9A9DA3),
              fontSize: 11,
            ),
          ),
        ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9A9DA3),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
