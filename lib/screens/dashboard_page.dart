```dart
import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../services/budget_store.dart';
import '../services/finance_store.dart';
import 'add_transaction_page.dart';
import 'recurring_transactions_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final BudgetStore _budgetStore;

  Future<_DashboardData>? _dataFuture;
  String? _futureKey;

  @override
  void initState() {
    super.initState();

    _budgetStore = BudgetStore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final store = FinanceScope.of(context);
    final account = store.activeAccount;
    final key = account ?? '__no_account__';

    if (_futureKey == key && _dataFuture != null) {
      return;
    }

    _futureKey = key;

    _dataFuture = _loadData(
      store: store,
      account: account,
    );
  }

  @override
  void dispose() {
    _budgetStore.close();
    super.dispose();
  }

  Future<_DashboardData> _loadData({
    required FinanceStore store,
    required String? account,
  }) async {
    if (account == null) {
      return const _DashboardData(
        balance: 0,
        income: 0,
        expense: 0,
        recentTransactions: <Tx>[],
        budgets: <Budget>[],
        recurringTransactions: <RecurringTransaction>[],
      );
    }

    await _budgetStore.load();

    final now = DateTime.now();

    final startOfMonth = DateTime(
      now.year,
      now.month,
      1,
    );

    final startOfNextMonth = DateTime(
      now.year,
      now.month + 1,
      1,
    );

    final balance = await store.getBalance(
      account: account,
    );

    final income = await store.getTotalIncome(
      account: account,
      startDate: startOfMonth,
      endDate: startOfNextMonth,
    );

    final expense = await store.getTotalExpense(
      account: account,
      startDate: startOfMonth,
      endDate: startOfNextMonth,
    );

    final transactions = await store.getTransactions(
      account: account,
    );

    final budgets = await _budgetStore.getBudgets(
      account: account,
      month: startOfMonth,
    );

    final recurringTransactions =
        await store.getRecurringTransactions(
      account: account,
    );

    return _DashboardData(
      balance: balance,
      income: income,
      expense: expense,
      recentTransactions: transactions.take(5).toList(),
      budgets: budgets,
      recurringTransactions: recurringTransactions,
    );
  }

  void _refresh() {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    if (!mounted) {
      return;
    }

    setState(() {
      _futureKey = account ?? '__no_account__';

      _dataFuture = _loadData(
        store: store,
        account: account,
      );
    });
  }

  Future<void> _openAddTransaction() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddTransactionPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    _refresh();
  }

  Future<void> _openRecurringTransactions() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const RecurringTransactionsPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    _refresh();
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
        onRetry: _refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await store.load();

        if (!mounted) {
          return;
        }

        _refresh();
      },
      child: FutureBuilder<_DashboardData>(
        future: _dataFuture,
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
              onRetry: _refresh,
            );
          }

          final data = snapshot.data ??
              const _DashboardData(
                balance: 0,
                income: 0,
                expense: 0,
                recentTransactions: <Tx>[],
                budgets: <Budget>[],
                recurringTransactions:
                    <RecurringTransaction>[],
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
                            fontWeight: FontWeight.w800,
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
                formatRupiah: _formatRupiah,
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
                      formatRupiah: _formatRupiah,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Pengeluaran',
                      amount: data.expense,
                      icon: Icons
                          .arrow_upward_rounded,
                      formatRupiah: _formatRupiah,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FinancialHealthCard(
                income: data.income,
                expense: data.expense,
                formatRupiah: _formatRupiah,
              ),
              const SizedBox(height: 20),
              _BudgetAlertSection(
                budgets: data.budgets,
                formatRupiah: _formatRupiah,
              ),
              const SizedBox(height: 20),
              _RecurringSummaryCard(
                recurringTransactions:
                    data.recurringTransactions,
                formatRupiah: _formatRupiah,
                onOpen:
                    _openRecurringTransactions,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed:
                      _openAddTransaction,
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
                      formatRupiah:
                          _formatRupiah,
                      formatDate: _formatDate,
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
    required this.recentTransactions,
    required this.budgets,
    required this.recurringTransactions,
  });

  final double balance;
  final double income;
  final double expense;
  final List<Tx> recentTransactions;
  final List<Budget> budgets;
  final List<RecurringTransaction> recurringTransactions;
}

class _RecurringSummaryCard
    extends StatelessWidget {
  const _RecurringSummaryCard({
    required this.recurringTransactions,
    required this.formatRupiah,
    required this.onOpen,
  });

  final List<RecurringTransaction> recurringTransactions;
  final String Function(double) formatRupiah;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final active = recurringTransactions
        .where((item) => item.isActive)
        .toList();

    final activeIncome = active
        .where((item) => item.isIncome)
        .fold<double>(
          0,
          (total, item) => total + item.amount,
        );

    final activeExpense = active
        .where((item) => !item.isIncome)
        .fold<double>(
          0,
          (total, item) => total + item.amount,
        );

    if (recurringTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1E22),
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 21,
              backgroundColor:
                  Color(0xFF34373D),
              child: Icon(
                Icons.repeat_rounded,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaksi Berulang',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Belum ada jadwal transaksi berulang.',
                    style: TextStyle(
                      color: Color(0xFF9A9DA3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Kelola transaksi berulang',
              onPressed: onOpen,
              icon: const Icon(
                Icons.chevron_right_rounded,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 21,
                backgroundColor:
                    Color(0xFF34373D),
                child: Icon(
                  Icons.repeat_rounded,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaksi Berulang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Ringkasan jadwal aktif',
                      style: TextStyle(
                        color: Color(0xFF9A9DA3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onOpen,
                child: const Text('Kelola'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RecurringValue(
                  label: 'Total jadwal',
                  value:
                      '${recurringTransactions.length}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RecurringValue(
                  label: 'Aktif',
                  value: '${active.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RecurringAmount(
                  label: 'Pemasukan aktif',
                  amount: activeIncome,
                  formatRupiah: formatRupiah,
                  icon:
                      Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RecurringAmount(
                  label: 'Pengeluaran aktif',
                  amount: activeExpense,
                  formatRupiah: formatRupiah,
                  icon:
                      Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecurringValue
    extends StatelessWidget {
  const _RecurringValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF282B30),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Column(
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
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringAmount
    extends StatelessWidget {
  const _RecurringAmount({
    required this.label,
    required this.amount,
    required this.formatRupiah,
    required this.icon,
  });

  final String label;
  final double amount;
  final String Function(double) formatRupiah;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF282B30),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9A9DA3),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(amount),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

class _FinancialHealthCard
    extends StatelessWidget {
  const _FinancialHealthCard({
    required this.income,
    required this.expense,
    required this.formatRupiah,
  });

  final double income;
  final double expense;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    final surplus = income - expense;

    final hasIncome = income > 0;

    final ratio = hasIncome
        ? (expense / income)
            .clamp(0.0, 1.0)
        : 0.0;

    final percentage =
        (ratio * 100).round();

    final isSurplus = surplus >= 0;

    String title;
    String description;
    IconData icon;

    if (!hasIncome && expense <= 0) {
      title = 'Belum ada aktivitas bulan ini';
      description =
          'Tambahkan transaksi untuk melihat kesehatan keuangan.';
      icon = Icons.insights_outlined;
    } else if (!hasIncome && expense > 0) {
      title = 'Belum ada pemasukan';
      description =
          'Pengeluaran bulan ini sudah tercatat, tetapi belum ada pemasukan.';
      icon = Icons.warning_amber_rounded;
    } else if (isSurplus) {
      title = 'Keuangan bulan ini surplus';
      description =
          'Pemasukan masih lebih besar daripada pengeluaran.';
      icon = Icons.trending_up_rounded;
    } else {
      title = 'Pengeluaran melebihi pemasukan';
      description =
          'Perlu diperhatikan agar pengeluaran tidak terus bertambah.';
      icon = Icons.trending_down_rounded;
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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    const Color(0xFF34373D),
                child: Icon(
                  icon,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kesehatan Keuangan',
                      style: TextStyle(
                        color: Color(0xFF9A9DA3),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF282B30),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HealthValue(
                    label: isSurplus
                        ? 'Surplus'
                        : 'Defisit',
                    value:
                        formatRupiah(
                      surplus.abs(),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: const Color(
                    0xFF3A3D42,
                  ),
                ),
                Expanded(
                  child: _HealthValue(
                    label: 'Rasio Pengeluaran',
                    value: hasIncome
                        ? '$percentage%'
                        : '-',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF9A9DA3),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthValue
    extends StatelessWidget {
  const _HealthValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Column(
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetAlertSection
    extends StatelessWidget {
  const _BudgetAlertSection({
    required this.budgets,
    required this.formatRupiah,
  });

  final List<Budget> budgets;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    final alerts = budgets.where(
      (budget) {
        if (budget.limit <= 0) {
          return false;
        }

        return budget.isOverBudget ||
            budget.spent / budget.limit >= 0.8;
      },
    ).toList();

    if (alerts.isEmpty) {
      return const _SafeBudgetCard();
    }

    alerts.sort(
      (a, b) {
        final aRatio =
            a.limit <= 0
                ? 0.0
                : a.spent / a.limit;

        final bRatio =
            b.limit <= 0
                ? 0.0
                : b.spent / b.limit;

        return bRatio.compareTo(aRatio);
      },
    );

    final overBudgetCount = alerts
        .where(
          (budget) => budget.isOverBudget,
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                overBudgetCount > 0
                    ? Icons
                        .warning_amber_rounded
                    : Icons
                        .notifications_active_outlined,
                size: 22,
                color: overBudgetCount > 0
                    ? Colors.redAccent
                    : Colors.orangeAccent,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Peringatan Anggaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${alerts.length}',
                style: const TextStyle(
                  color: Color(0xFF9A9DA3),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            overBudgetCount > 0
                ? '$overBudgetCount kategori sudah melewati batas.'
                : 'Beberapa kategori mulai mendekati batas.',
            style: const TextStyle(
              color: Color(0xFF9A9DA3),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ...alerts.take(4).map(
            (budget) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: _BudgetAlertTile(
                budget: budget,
                formatRupiah:
                    formatRupiah,
              ),
            ),
          ),
          if (alerts.length > 4)
            Text(
              '+${alerts.length - 4} peringatan lainnya '
              'dapat dilihat di menu Anggaran.',
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

class _BudgetAlertTile
    extends StatelessWidget {
  const _BudgetAlertTile({
    required this.budget,
    required this.formatRupiah,
  });

  final Budget budget;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    final ratio = budget.limit <= 0
        ? 0.0
        : budget.spent / budget.limit;

    final percentage =
        (ratio * 100).round();

    final isOver = budget.isOverBudget;

    final remaining = budget.remaining;

    final statusColor = isOver
        ? Colors.redAccent
        : Colors.orangeAccent;

    final statusText = isOver
        ? 'Terlampaui'
        : '$percentage% terpakai';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF282B30),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.14,
              ),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              isOver
                  ? Icons.warning_rounded
                  : Icons.priority_high_rounded,
              size: 19,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  budget.category,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isOver
                      ? 'Melebihi ${formatRupiah(-remaining)}'
                      : '$statusText dari '
                          '${formatRupiah(budget.limit)}',
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatRupiah(budget.spent),
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeBudgetCard
    extends StatelessWidget {
  const _SafeBudgetCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                Color(0xFF34373D),
            child: Icon(
              Icons.check_circle_outline,
              size: 21,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Anggaran aman',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Belum ada kategori yang mencapai 80% anggaran.',
                  style: TextStyle(
                    color: Color(0xFF9A9DA3),
                    fontSize: 11,
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
}

class _BalanceCard
    extends StatelessWidget {
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

class _SummaryCard
    extends StatelessWidget {
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
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
  final String Function(double) formatRupiah;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final isIncome =
        transaction.type ==
            TransactionType.income;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                const Color(0xFF34373D),
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
                  '${transaction.category} • '
                  '${formatDate(transaction.date)}',
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
            '${isIncome ? '+' : '-'}'
            '${formatRupiah(transaction.amount)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius:
            BorderRadius.circular(20),
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
        padding: const EdgeInsets.all(24),
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
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9A9DA3),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text(
                'Coba Lagi',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```
