import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
import '../models/transaction.dart';
import '../services/budget_store.dart';
import 'add_transaction_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Future<_DashboardData> _loadData() async {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    if (account == null) {
      return const _DashboardData(
        balance: 0,
        income: 0,
        expense: 0,
        totalBudget: 0,
        budgetCategories: <_BudgetCategoryData>[],
        recentTransactions: <Tx>[],
      );
    }

    final now = DateTime.now();

    final startOfMonth = DateTime(
      now.year,
      now.month,
      1,
    );

    final endOfMonth = DateTime(
      now.year,
      now.month + 1,
      0,
    );

    final balance = await store.getBalance(
      account: account,
    );

    final income = await store.getTotalIncome(
      account: account,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    final expense = await store.getTotalExpense(
      account: account,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    final transactions = await store.getTransactions(
      account: account,
    );

    final monthTransactions =
        await store.getTransactions(
      account: account,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    final budgetStore = BudgetStore();

    try {
      await budgetStore.load();

      final budgets = await budgetStore.getBudgets(
        account: account,
        month: startOfMonth,
      );

      final expenseByCategory =
          <String, double>{};

      for (final transaction in monthTransactions) {
        if (transaction.type !=
            TransactionType.expense) {
          continue;
        }

        final category = transaction.category.trim();

        if (category.isEmpty) {
          continue;
        }

        expenseByCategory[category] =
            (expenseByCategory[category] ?? 0) +
                transaction.amount;
      }

      final budgetCategories =
          <_BudgetCategoryData>[];

      for (final budget in budgets) {
        budgetCategories.add(
          _BudgetCategoryData(
            category: budget.category,
            budget: budget.limit,
            spent: budget.spent,
          ),
        );
      }

      final budgetedCategories =
          budgetCategories.map(
        (item) => item.category.toLowerCase(),
      ).toSet();

      final unbudgetedCategories =
          expenseByCategory.entries.where(
        (entry) =>
            !budgetedCategories.contains(
          entry.key.toLowerCase(),
        ),
      );

      for (final entry in unbudgetedCategories) {
        budgetCategories.add(
          _BudgetCategoryData(
            category: entry.key,
            budget: 0,
            spent: entry.value,
          ),
        );
      }

      budgetCategories.sort(
        (a, b) {
          if (a.spent != b.spent) {
            return b.spent.compareTo(a.spent);
          }

          return a.category
              .toLowerCase()
              .compareTo(
                b.category.toLowerCase(),
              );
        },
      );

      final totalBudget = budgets.fold<double>(
        0,
        (sum, budget) => sum + budget.limit,
      );

      return _DashboardData(
        balance: balance,
        income: income,
        expense: expense,
        totalBudget: totalBudget,
        budgetCategories: budgetCategories,
        recentTransactions:
            transactions.take(5).toList(),
      );
    } finally {
      await budgetStore.close();
    }
  }

  Future<void> _openAddTransaction() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const AddTransactionPage(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _showAccountSelector() {
    final store = FinanceScope.of(context);

    if (store.accounts.isEmpty) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          const Color(0xFF1C1E22),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih akun',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ...store.accounts.map(
                  (account) {
                    final selected =
                        account ==
                            store.activeAccount;

                    return ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            selected
                                ? const Color(
                                    0xFFE8EAED,
                                  )
                                : const Color(
                                    0xFF34373D,
                                  ),
                        child: Icon(
                          Icons
                              .account_balance_wallet_outlined,
                          color: selected
                              ? const Color(
                                  0xFF111214,
                                )
                              : Colors.white,
                        ),
                      ),
                      title: Text(account),
                      trailing: selected
                          ? const Icon(
                              Icons.check,
                            )
                          : null,
                      onTap: () {
                        store.setActiveAccount(
                          account,
                        );
                        Navigator.of(
                          sheetContext,
                        ).pop();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);

    if (store.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (store.error != null) {
      return _ErrorView(
        message: store.error!,
        onRetry: () {
          setState(() {});
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await store.load();

        if (mounted) {
          setState(() {});
        }
      },
      child: FutureBuilder<_DashboardData>(
        future: _loadData(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ErrorView(
              message:
                  snapshot.error.toString(),
              onRetry: () {
                setState(() {});
              },
            );
          }

          final data =
              snapshot.data ??
                  const _DashboardData(
                    balance: 0,
                    income: 0,
                    expense: 0,
                    totalBudget: 0,
                    budgetCategories:
                        <_BudgetCategoryData>[],
                    recentTransactions:
                        <Tx>[],
                  );

          final account =
              store.activeAccount ??
                  'Pribadi';

          final now = DateTime.now();

          final monthName =
              _monthName(now.month);

          return ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              32,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keuangan Prima',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Color(0xFF9A9DA3),
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          account,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Pilih akun',
                    onPressed:
                        _showAccountSelector,
                    icon: const Icon(
                      Icons
                          .account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _BalanceCard(
                balance: data.balance,
                formatRupiah:
                    _formatRupiah,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Pemasukan',
                      amount: data.income,
                      icon: Icons
                          .arrow_downward_rounded,
                      formatRupiah:
                          _formatRupiah,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Pengeluaran',
                      amount: data.expense,
                      icon: Icons
                          .arrow_upward_rounded,
                      formatRupiah:
                          _formatRupiah,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _BudgetSummaryCard(
                totalBudget:
                    data.totalBudget,
                totalExpense:
                    data.expense,
                monthName:
                    monthName,
                formatRupiah:
                    _formatRupiah,
              ),
              const SizedBox(height: 24),
              if (data.budgetCategories
                  .isNotEmpty)
                _BudgetCategoriesSection(
                  categories:
                      data.budgetCategories,
                  formatRupiah:
                      _formatRupiah,
                ),
              if (data.budgetCategories
                  .isNotEmpty)
                const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed:
                      _openAddTransaction,
                  icon:
                      const Icon(Icons.add),
                  label: const Text(
                    'Tambah Transaksi',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Transaksi Terbaru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                  if (data
                      .recentTransactions
                      .isNotEmpty)
                    Text(
                      '${data.recentTransactions.length} transaksi',
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF9A9DA3),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (data
                  .recentTransactions
                  .isEmpty)
                const _EmptyTransactions()
              else
                ...data
                    .recentTransactions
                    .map(
                  (transaction) =>
                      Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child:
                        _TransactionCard(
                      transaction:
                          transaction,
                      formatRupiah:
                          _formatRupiah,
                      formatDate:
                          _formatDate,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.balance,
    required this.income,
    required this.expense,
    required this.totalBudget,
    required this.budgetCategories,
    required this.recentTransactions,
  });

  final double balance;
  final double income;
  final double expense;
  final double totalBudget;
  final List<_BudgetCategoryData>
      budgetCategories;
  final List<Tx> recentTransactions;
}

class _BudgetCategoryData {
  const _BudgetCategoryData({
    required this.category,
    required this.budget,
    required this.spent,
  });

  final String category;
  final double budget;
  final double spent;

  bool get hasBudget => budget > 0;

  bool get isOverBudget =>
      hasBudget && spent > budget;

  bool get isWarning =>
      hasBudget &&
      !isOverBudget &&
      spent / budget >= 0.8;

  double get percentage =>
      budget <= 0 ? 0 : spent / budget;

  double get remaining =>
      budget - spent;
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.formatRupiah,
  });

  final double balance;
  final String Function(double)
      formatRupiah;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF282B30),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo',
            style: TextStyle(
              color: Color(0xFFB8BCC2),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            formatRupiah(balance),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Saldo seluruh transaksi akun aktif',
            style: TextStyle(
              color: Color(0xFF9A9DA3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.formatRupiah,
  });

  final String title;
  final double amount;
  final IconData icon;
  final String Function(double)
      formatRupiah;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9A9DA3),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            formatRupiah(amount),
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSummaryCard
    extends StatelessWidget {
  const _BudgetSummaryCard({
    required this.totalBudget,
    required this.totalExpense,
    required this.monthName,
    required this.formatRupiah,
  });

  final double totalBudget;
  final double totalExpense;
  final String monthName;
  final String Function(double)
      formatRupiah;

  @override
  Widget build(BuildContext context) {
    if (totalBudget <= 0) {
      return Container(
        padding:
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1E22),
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color:
                const Color(0xFF30343A),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration:
                  BoxDecoration(
                color: const Color(
                  0xFF30343A,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: const Icon(
                Icons
                    .account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    'Belum ada anggaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Atur anggaran kategori untuk memantau pengeluaran.',
                    style: TextStyle(
                      color: Color(
                        0xFF9A9DA3,
                      ),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final remaining =
        totalBudget - totalExpense;

    final percentage =
        totalExpense / totalBudget;

    final progress =
        percentage.clamp(0.0, 1.0);

    final isOver =
        totalExpense > totalBudget;

    final isWarning =
        !isOver && percentage >= 0.8;

    final Color statusColor;

    if (isOver) {
      statusColor =
          Colors.redAccent;
    } else if (isWarning) {
      statusColor =
          Colors.orangeAccent;
    } else {
      statusColor =
          Colors.greenAccent;
    }

    final IconData statusIcon;

    if (isOver) {
      statusIcon =
          Icons.warning_amber_rounded;
    } else if (isWarning) {
      statusIcon =
          Icons.info_outline;
    } else {
      statusIcon =
          Icons.check_circle_outline;
    }

    final String statusText;

    if (isOver) {
      statusText =
          'Pengeluaran sudah melebihi total anggaran.';
    } else if (isWarning) {
      statusText =
          'Pengeluaran sudah mendekati batas anggaran.';
    } else {
      statusText =
          'Pengeluaran masih dalam batas anggaran.';
    }

    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              const Color(0xFF30343A),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons
                    .account_balance_wallet_outlined,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Anggaran Bulan Ini',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              Text(
                monthName,
                style:
                    const TextStyle(
                  color:
                      Color(0xFF9A9DA3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _BudgetValue(
                  label: 'Anggaran',
                  value:
                      formatRupiah(
                    totalBudget,
                  ),
                ),
              ),
              Expanded(
                child: _BudgetValue(
                  label: 'Terpakai',
                  value:
                      formatRupiah(
                    totalExpense,
                  ),
                ),
              ),
              Expanded(
                child: _BudgetValue(
                  label: isOver
                      ? 'Lebih'
                      : 'Sisa',
                  value:
                      formatRupiah(
                    remaining.abs(),
                  ),
                  valueColor: isOver
                      ? Colors.redAccent
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
            child:
                LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
                  const Color(
                0xFF30343A,
              ),
              valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                statusColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                statusIcon,
                size: 17,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percentage * 100).round()}%',
                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoriesSection
    extends StatelessWidget {
  const _BudgetCategoriesSection({
    required this.categories,
    required this.formatRupiah,
  });

  final List<_BudgetCategoryData>
      categories;
  final String Function(double)
      formatRupiah;

  @override
  Widget build(BuildContext context) {
    final topCategories =
        categories.take(5).toList();

    final budgetedCategories =
        categories
            .where(
              (item) => item.hasBudget,
            )
            .toList();

    final unbudgeted =
        categories
            .where(
              (item) => !item.hasBudget,
            )
            .toList();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pengeluaran per Kategori',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
            if (categories.length > 5)
              Text(
                'Top 5',
                style: const TextStyle(
                  color:
                      Color(0xFF9A9DA3),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...topCategories.map(
          (category) =>
              Padding(
            padding:
                const EdgeInsets.only(
              bottom: 10,
            ),
            child: _BudgetCategoryCard(
              data: category,
              formatRupiah:
                  formatRupiah,
            ),
          ),
        ),
        if (budgetedCategories
            .isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(
              top: 6,
            ),
            child: _CategoryInsight(
              categories:
                  budgetedCategories,
            ),
          ),
        if (unbudgeted.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(
              top: 10,
            ),
            child: _UnbudgetedNotice(
              count:
                  unbudgeted.length,
            ),
          ),
      ],
    );
  }
}

class _BudgetCategoryCard
    extends StatelessWidget {
  const _BudgetCategoryCard({
    required this.data,
    required this.formatRupiah,
  });

  final _BudgetCategoryData data;
  final String Function(double)
      formatRupiah;

  @override
  Widget build(BuildContext context) {
    if (!data.hasBudget) {
      return Container(
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(
            0xFF1C1E22,
          ),
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: const Color(
              0xFF30343A,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.category_outlined,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    data.category,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Belum memiliki anggaran',
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF9A9DA3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatRupiah(
                data.spent,
              ),
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    final percentage =
        data.percentage;

    final progress =
        percentage.clamp(
      0.0,
      1.0,
    );

    final Color statusColor;

    if (data.isOverBudget) {
      statusColor =
          Colors.redAccent;
    } else if (data.isWarning) {
      statusColor =
          Colors.orangeAccent;
    } else {
      statusColor =
          Colors.greenAccent;
    }

    final String status;

    if (data.isOverBudget) {
      status =
          'Melebihi ${formatRupiah(data.remaining.abs())}';
    } else if (data.isWarning) {
      status =
          'Sisa ${formatRupiah(data.remaining)}';
    } else {
      status =
          'Sisa ${formatRupiah(data.remaining)}';
    }

    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(
          0xFF1C1E22,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color: const Color(
                    0xFF30343A,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: const Icon(
                  Icons
                      .category_outlined,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      data.category,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      '${formatRupiah(data.spent)} dari ${formatRupiah(data.budget)}',
                      style:
                          const TextStyle(
                        color: Color(
                          0xFF9A9DA3,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percentage * 100).round()}%',
                style:
                    TextStyle(
                  color: statusColor,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
            child:
                LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  const Color(
                0xFF30343A,
              ),
              valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                statusColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                data.isOverBudget
                    ? Icons
                        .warning_amber_rounded
                    : data.isWarning
                        ? Icons
                            .info_outline
                        : Icons
                            .check_circle_outline,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    color:
                        statusColor,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryInsight
    extends StatelessWidget {
  const _CategoryInsight({
    required this.categories,
  });

  final List<_BudgetCategoryData>
      categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final overBudget = categories
        .where(
          (item) => item.isOverBudget,
        )
        .length;

    final warning = categories
        .where(
          (item) => item.isWarning,
        )
        .length;

    if (overBudget > 0) {
      return _InsightContainer(
        icon:
            Icons.warning_amber_rounded,
        text:
            '$overBudget kategori sudah melewati anggaran.',
        color: Colors.redAccent,
      );
    }

    if (warning > 0) {
      return _InsightContainer(
        icon: Icons.info_outline,
        text:
            '$warning kategori sudah menggunakan 80% atau lebih dari anggarannya.',
        color: Colors.orangeAccent,
      );
    }

    return _InsightContainer(
      icon:
          Icons.check_circle_outline,
      text:
          'Semua kategori masih dalam batas anggaran.',
      color: Colors.greenAccent,
    );
  }
}

class _InsightContainer
    extends StatelessWidget {
  const _InsightContainer({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(
          0xFF1C1E22,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: const Color(
            0xFF30343A,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: color,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnbudgetedNotice
    extends StatelessWidget {
  const _UnbudgetedNotice({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(
          0xFF1C1E22,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 19,
            color: Color(
              0xFF9A9DA3,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '$count kategori memiliki pengeluaran tetapi belum memiliki anggaran.',
              style:
                  const TextStyle(
                color:
                    Color(0xFF9A9DA3),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetValue
    extends StatelessWidget {
  const _BudgetValue({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9A9DA3),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _TransactionCard
    extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.formatRupiah,
    required this.formatDate,
  });

  final Tx transaction;
  final String Function(double)
      formatRupiah;
  final String Function(DateTime)
      formatDate;

  @override
  Widget build(BuildContext context) {
    final isIncome =
        transaction.type ==
            TransactionType.income;

    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(
          0xFF1C1E22,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                const Color(
              0xFF34373D,
            ),
            child: Icon(
              isIncome
                  ? Icons
                      .arrow_downward_rounded
                  : Icons
                      .arrow_upward_rounded,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  '${transaction.category} • ${formatDate(transaction.date)}',
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color: Color(
                      0xFF9A9DA3,
                    ),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isIncome ? '+' : '-'}${formatRupiah(transaction.amount)}',
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions
    extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(
          0xFF1C1E22,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons
                .receipt_long_outlined,
            size: 42,
            color: Color(
              0xFF777B82,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontWeight:
                  FontWeight.w700,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Tambahkan pemasukan atau pengeluaran pertama Anda.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Color(0xFF9A9DA3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView
    extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Terjadi kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              maxLines: 4,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color:
                    Color(0xFF9A9DA3),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onRetry,
              child:
                  const Text(
                'Coba Lagi',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
