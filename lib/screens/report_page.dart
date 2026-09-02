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
  DateTime _selectedMonth = DateTime.now();

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

    final previousStartDate = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 1,
      1,
    );

    final previousEndDate = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      0,
    );

    final transactions = await store.getTransactions(
      account: account,
      startDate: startDate,
      endDate: endDate,
    );

    final previousTransactions =
        await store.getTransactions(
      account: account,
      startDate: previousStartDate,
      endDate: previousEndDate,
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

    double previousIncome = 0;
    double previousExpense = 0;

    for (final transaction in previousTransactions) {
      if (transaction.type == TransactionType.income) {
        previousIncome += transaction.amount;
      } else {
        previousExpense += transaction.amount;
      }
    }

    return _ReportData(
      transactions: transactions,
      income: income,
      expense: expense,
      previousTransactions: previousTransactions,
      previousIncome: previousIncome,
      previousExpense: previousExpense,
    );
  }

  void _changeMonth(int offset) {
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
      if (i > 0 &&
          (digits.length - i) % 3 == 0) {
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

  String _percentageText(double value) {
    return '${value.round()}%';
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
                    previousTransactions: <Tx>[],
                    previousIncome: 0,
                    previousExpense: 0,
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
                  _SectionTitle(
                    title: 'Insight Keuangan',
                  ),
                  const SizedBox(height: 12),
                  _InsightCard(
                    data: data,
                    categoryExpenses: categoryExpenses,
                    formatRupiah: _formatRupiah,
                    percentageText: _percentageText,
                    categoryAmount: _categoryAmount,
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(
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
                  _SectionTitle(
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
    required this.previousTransactions,
    required this.previousIncome,
    required this.previousExpense,
  });

  final List<Tx> transactions;
  final double income;
  final double expense;

  final List<Tx> previousTransactions;
  final double previousIncome;
  final double previousExpense;
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
    final isSurplus = balance >= 0;

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

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.data,
    required this.categoryExpenses,
    required this.formatRupiah,
    required this.percentageText,
    required this.categoryAmount,
  });

  final _ReportData data;
  final Map<String, double> categoryExpenses;
  final String Function(double) formatRupiah;
  final String Function(double) percentageText;
  final double Function(List<Tx>, String) categoryAmount;

  @override
  Widget build(BuildContext context) {
    final balance = data.income - data.expense;

    final expenseRatio = data.income <= 0
        ? 0.0
        : (data.expense / data.income) * 100;

    final sortedCategories =
        categoryExpenses.entries.toList()
          ..sort(
            (a, b) => b.value.compareTo(a.value),
          );

    String? largestCategory;
    double largestAmount = 0;

    if (sortedCategories.isNotEmpty) {
      largestCategory =
          sortedCategories.first.key;
      largestAmount =
          sortedCategories.first.value;
    }

    String? increasedCategory;
    double biggestIncrease = 0;
    double previousCategoryAmount = 0;

    for (final entry in categoryExpenses.entries) {
      final previousAmount = categoryAmount(
        data.previousTransactions,
        entry.key,
      );

      final increase =
          entry.value - previousAmount;

      if (increase > biggestIncrease) {
        biggestIncrease = increase;
        increasedCategory = entry.key;
        previousCategoryAmount =
            previousAmount;
      }
    }

    final hasPreviousData =
        data.previousIncome > 0 ||
            data.previousExpense > 0 ||
            data.previousTransactions.isNotEmpty;

    String statusTitle;
    String statusMessage;
    IconData statusIcon;

    if (data.income <= 0 && data.expense <= 0) {
      statusTitle = 'Belum cukup data';
      statusMessage =
          'Tambahkan transaksi agar insight keuangan '
          'bisa dibuat secara otomatis.';
      statusIcon = Icons.insights_outlined;
    } else if (balance < 0) {
      statusTitle = 'Pengeluaran lebih besar';
      statusMessage =
          'Bulan ini mengalami defisit '
          '${formatRupiah(balance.abs())}. '
          'Coba tekan pengeluaran yang paling besar.';
      statusIcon = Icons.warning_amber_rounded;
    } else if (expenseRatio >= 90) {
      statusTitle = 'Perlu lebih waspada';
      statusMessage =
          'Pengeluaran sudah mencapai '
          '${percentageText(expenseRatio)} dari pemasukan. '
          'Ruang untuk menabung masih sangat kecil.';
      statusIcon = Icons.priority_high_rounded;
    } else if (expenseRatio >= 70) {
      statusTitle = 'Keuangan cukup ketat';
      statusMessage =
          'Pengeluaran menggunakan sekitar '
          '${percentageText(expenseRatio)} dari pemasukan. '
          'Pertimbangkan mengurangi pengeluaran non-prioritas.';
      statusIcon = Icons.info_outline_rounded;
    } else {
      statusTitle = 'Kondisi cukup sehat';
      statusMessage =
          'Pengeluaran berada di sekitar '
          '${percentageText(expenseRatio)} dari pemasukan. '
          'Pertahankan surplus dan sisihkan sebagian untuk tabungan.';
      statusIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF282B30),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  statusIcon,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                : percentageText(expenseRatio),
            subtitle: data.income <= 0
                ? 'Belum ada pemasukan'
                : 'Dari total pemasukan bulan ini',
          ),
          if (largestCategory != null) ...[
            const SizedBox(height: 16),
            _InsightRow(
              icon: Icons.category_outlined,
              title: 'Pengeluaran terbesar',
              value: largestCategory,
              subtitle:
                  formatRupiah(largestAmount),
            ),
          ],
          if (hasPreviousData &&
              increasedCategory != null &&
              biggestIncrease > 0) ...[
            const SizedBox(height: 16),
            _InsightRow(
              icon: Icons.trending_up_rounded,
              title: 'Kenaikan terbesar',
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
            previousCategoryAmount:
                previousCategoryAmount,
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
    required this.previousCategoryAmount,
    required this.formatRupiah,
  });

  final double balance;
  final double expenseRatio;
  final String? largestCategory;
  final double largestAmount;
  final String? increasedCategory;
  final double biggestIncrease;
  final double previousCategoryAmount;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    String recommendation;

    if (balance < 0) {
      if (largestCategory != null) {
        recommendation =
            'Prioritaskan mengevaluasi kategori '
            '"$largestCategory" karena menjadi '
            'pengeluaran terbesar sebesar '
            '${formatRupiah(largestAmount)}.';
      } else {
        recommendation =
            'Coba kurangi pengeluaran non-prioritas '
            'agar arus kas kembali positif.';
      }
    } else if (expenseRatio >= 90) {
      recommendation =
          'Sisihkan pengeluaran yang tidak wajib '
          'dan usahakan memberi ruang lebih besar '
          'untuk tabungan.';
    } else if (increasedCategory != null &&
        biggestIncrease > 0 &&
        previousCategoryAmount > 0) {
      final increasePercentage =
          (biggestIncrease /
                  previousCategoryAmount) *
              100;

      recommendation =
          'Kategori "$increasedCategory" meningkat '
          'sekitar ${increasePercentage.round()}% '
          'dibanding bulan lalu. Cek apakah kenaikan '
          'tersebut memang diperlukan.';
    } else if (largestCategory != null) {
      recommendation =
          'Pertahankan surplus. Perhatikan kategori '
          '"$largestCategory" sebagai area utama '
          'jika ingin menghemat lebih banyak.';
    } else {
      recommendation =
          'Pertahankan pencatatan transaksi secara '
          'rutin agar pola keuangan semakin jelas.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF282B30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
