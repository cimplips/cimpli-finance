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
  late final BudgetStore _budgetStore;
  late final Future<void> _budgetStoreFuture;

  @override
  void initState() {
    super.initState();

    _budgetStore = BudgetStore();
    _budgetStoreFuture = _budgetStore.load();
  }

  @override
  void dispose() {
    _budgetStore.close();
    super.dispose();
  }

  Future<_DashboardData> _loadData() async {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    if (account == null) {
      return const _DashboardData(
        balance: 0,
        income: 0,
        expense: 0,
        recentTransactions: <Tx>[],
        budgets: <Budget>[],
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

    final budgets = await _budgetStore.getBudgets(
      account: account,
      month: startOfMonth,
    );

    return _DashboardData(
      balance: balance,
      income: income,
      expense: expense,
      recentTransactions: transactions.take(5).toList(),
      budgets: budgets,
    );
  }

  Future<void> _openAddTransaction() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddTransactionPage(),
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
      backgroundColor: const Color(0xFF1C1E22),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        account == store.activeAccount;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: selected
                            ? const Color(0xFFE8EAED)
                            : const Color(0xFF34373D),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: selected
                              ? const Color(0xFF111214)
                              : Colors.white,
                        ),
                      ),
                      title: Text(account),
                      trailing: selected
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () {
                        store.setActiveAccount(account);
                        Navigator.of(sheetContext).pop();
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
      child: FutureBuilder<void>(
        future: _budgetStoreFuture,
        builder: (context, budgetSnapshot) {
          if (budgetSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (budgetSnapshot.hasError) {
            return _ErrorView(
              message: budgetSnapshot.error.toString(),
              onRetry: () {
                setState(() {});
              },
            );
          }

          return FutureBuilder<_DashboardData>(
            future: _loadData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return _ErrorView(
                  message: snapshot.error.toString(),
                  onRetry: () {
                    setState(() {});
                  },
                );
              }

              final data = snapshot.data ??
                  const _DashboardData(
                    balance: 0,
                    income: 0,
                    expense: 0,
                    recentTransactions: <Tx>[],
                    budgets: <Budget>[],
                  );

              final account =
                  store.activeAccount ?? 'Pribadi';

              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
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
                                color: Color(0xFF9A9DA3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              account,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
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
                        onPressed: _showAccountSelector,
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
                    formatRupiah: _formatRupiah,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Pemasukan',
                          amount: data.income,
                          icon:
                              Icons.arrow_downward_rounded,
                          formatRupiah: _formatRupiah,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Pengeluaran',
                          amount: data.expense,
                          icon:
                              Icons.arrow_upward_rounded,
                          formatRupiah: _formatRupiah,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _BudgetSummaryCard(
                    budgets: data.budgets,
                    monthName:
                        _monthName(DateTime.now().month),
                    year: DateTime.now().year,
                    formatRupiah: _formatRupiah,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _openAddTransaction,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Tambah Transaksi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
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
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (data.recentTransactions
                          .isNotEmpty)
                        Text(
                          '${data.recentTransactions.length} transaksi',
                          style: const TextStyle(
                            color: Color(0xFF9A9DA3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (data.recentTransactions.isEmpty)
                    const _EmptyTransactions()
                  else
                    ...data.recentTransactions.map(
                      (transaction) => Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: _TransactionCard(
                          transaction: transaction,
                          formatRupiah: _formatRupiah,
                          formatDate: _formatDate,
                        ),
                      ),
                    ),
                ],
              );
            },
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
    required this.recentTransactions,
    required this.budgets,
  });

  final double balance;
  final double income;
  final double expense;
  final List<Tx> recentTransactions;
  final List<Budget> budgets;
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.formatRupiah,
  });

  final double balance;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF282B30),
        borderRadius: BorderRadius.circular(24),
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
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
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
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
    required this.budgets,
    required this.monthName,
    required this.year,
    required this.formatRupiah,
  });

  final List<Budget> budgets;
  final String monthName;
  final int year;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1E22),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: Color(0xFF30343A),
              child: Icon(
                Icons.account_balance_wallet_outlined,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anggaran bulan ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Belum ada anggaran yang dibuat.',
                    style: TextStyle(
                      color: Color(0xFF9A9DA3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final totalBudget = budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.limit,
    );

    final totalSpent = budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.spent,
    );

    final remaining = totalBudget - totalSpent;

    final percentage = totalBudget <= 0
        ? 0.0
        : totalSpent / totalBudget;

    final progress = percentage.clamp(0.0, 1.0);

    final overBudgets = budgets
        .where((budget) => budget.isOverBudget)
        .toList();

    final warningBudgets = budgets
        .where(
          (budget) =>
              !budget.isOverBudget &&
              budget.limit > 0 &&
              budget.spent / budget.limit >= 0.8,
        )
        .toList();

    final hasWarning =
        overBudgets.isNotEmpty ||
        warningBudgets.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Anggaran Bulan Ini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${budgets.length} kategori',
                style: const TextStyle(
                  color: Color(0xFF9A9DA3),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$monthName $year',
            style: const TextStyle(
              color: Color(0xFF9A9DA3),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _BudgetAmount(
                  label: 'Terpakai',
                  amount: totalSpent,
                  formatRupiah: formatRupiah,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BudgetAmount(
                  label: 'Batas',
                  amount: totalBudget,
                  formatRupiah: formatRupiah,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
                  const Color(0xFF30343A),
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                overBudgets.isNotEmpty
                    ? Colors.redAccent
                    : warningBudgets.isNotEmpty
                        ? Colors.orangeAccent
                        : Colors.greenAccent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                overBudgets.isNotEmpty
                    ? Icons.warning_amber_rounded
                    : warningBudgets.isNotEmpty
                        ? Icons.info_outline
                        : Icons.check_circle_outline,
                size: 18,
                color: overBudgets.isNotEmpty
                    ? Colors.redAccent
                    : warningBudgets.isNotEmpty
                        ? Colors.orangeAccent
                        : Colors.greenAccent,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  overBudgets.isNotEmpty
                      ? '${overBudgets.length} kategori melewati anggaran'
                      : warningBudgets.isNotEmpty
                          ? '${warningBudgets.length} kategori mendekati batas'
                          : 'Pengeluaran masih dalam batas',
                  style: TextStyle(
                    color: overBudgets.isNotEmpty
                        ? Colors.redAccent
                        : warningBudgets.isNotEmpty
                            ? Colors.orangeAccent
                            : Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(percentage * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF282B30),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sisa anggaran',
                        style: TextStyle(
                          color: Color(0xFF9A9DA3),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatRupiah(remaining),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: remaining < 0
                              ? Colors.redAccent
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasWarning)
                  Text(
                    overBudgets.isNotEmpty
                        ? 'Perlu perhatian'
                        : 'Pantau pengeluaran',
                    style: TextStyle(
                      color: overBudgets.isNotEmpty
                          ? Colors.redAccent
                          : Colors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (overBudgets.isNotEmpty ||
              warningBudgets.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(
              height: 1,
              color: Color(0xFF30343A),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kategori perlu perhatian',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...[
              ...overBudgets,
              ...warningBudgets,
            ].take(3).map(
              (budget) => Padding(
                padding:
                    const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Icon(
                      budget.isOverBudget
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                      size: 16,
                      color: budget.isOverBudget
                          ? Colors.redAccent
                          : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        budget.category,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${_percentageText(budget)}%',
                      style: TextStyle(
                        color: budget.isOverBudget
                            ? Colors.redAccent
                            : Colors.orangeAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _percentageText(Budget budget) {
    if (budget.limit <= 0) {
      return '0';
    }

    return ((budget.spent / budget.limit) * 100)
        .round()
        .toString();
  }
}

class _BudgetAmount extends StatelessWidget {
  const _BudgetAmount({
    required this.label,
    required this.amount,
    required this.formatRupiah,
    this.alignEnd = false,
  });

  final String label;
  final double amount;
  final String Function(double) formatRupiah;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9A9DA3),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatRupiah(amount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign:
              alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF34373D),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.category} • ${formatDate(transaction.date)}',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9A9DA3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isIncome ? '+' : '-'}${formatRupiah(transaction.amount)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 42,
            color: Color(0xFF777B82),
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Tambahkan pemasukan atau pengeluaran pertama Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9A9DA3),
              fontSize: 13,
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
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9A9DA3),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
