```dart
import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../services/budget_store.dart';
import '../services/finance_store.dart';
import 'add_transaction_page.dart';
import 'recurring_transactions_page.dart';

class _DashboardTheme {
  const _DashboardTheme(this.isDark);

  final bool isDark;

  // Palette dashboard diselaraskan dengan tema global aplikasi.
  Color get background =>
      isDark ? const Color(0xFF2C2F34) : const Color(0xFFF7F8FC);

  Color get card =>
      isDark ? const Color(0xFF36393F) : const Color(0xFFFFFFFF);

  Color get elevatedCard =>
      isDark ? const Color(0xFF40434A) : const Color(0xFFF1F4FA);

  Color get softCard =>
      isDark ? const Color(0xFF484B52) : const Color(0xFFE9EDF5);

  Color get primaryText =>
      isDark ? const Color(0xFFF1F3F6) : const Color(0xFF202735);

  Color get secondaryText =>
      isDark ? const Color(0xFFB8BDC6) : const Color(0xFF687386);

  Color get tertiaryText =>
      isDark ? const Color(0xFF8E949E) : const Color(0xFF98A2B3);

  Color get divider =>
      isDark ? const Color(0xFF50535A) : const Color(0xFFE1E6EF);

  Color get selectedAccount =>
      isDark ? const Color(0xFF46506A) : const Color(0xFFE8EEFF);

  Color get selectedAccountIcon =>
      isDark ? const Color(0xFF9CB3F4) : const Color(0xFF6F8FEA);

  Color get income =>
      isDark ? const Color(0xFF86CBBB) : const Color(0xFF61B9A7);

  Color get incomeSoft =>
      isDark ? const Color(0xFF435B56) : const Color(0xFFE7F6F2);

  Color get expense =>
      isDark ? const Color(0xFFE39A9A) : const Color(0xFFD87979);

  Color get expenseSoft =>
      isDark ? const Color(0xFF5B4141) : const Color(0xFFFFECEC);

  Color get accent =>
      isDark ? const Color(0xFF9CB3F4) : const Color(0xFF6F8FEA);

  Color get warning =>
      isDark ? const Color(0xFFE6B486) : const Color(0xFFE6A66E);

  Color get shadow =>
      isDark ? Colors.transparent : const Color(0x0A202735);
}

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
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

    if (store.accounts.isEmpty) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: dashboardTheme.card,
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
                Text(
                  'Pilih akun',
                  style: TextStyle(
                    color: dashboardTheme.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                ...store.accounts.map(
                  (account) {
                    final selected =
                        account == store.activeAccount;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? dashboardTheme.selectedAccount
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? dashboardTheme.selectedAccount
                              : dashboardTheme.softCard,
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: selected
                                ? dashboardTheme.selectedAccountIcon
                                : dashboardTheme.secondaryText,
                          ),
                        ),
                        title: Text(
                          account,
                          style: TextStyle(
                            color: dashboardTheme.primaryText,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        trailing: selected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: dashboardTheme.selectedAccountIcon,
                              )
                            : null,
                        onTap: () {
                          store.setActiveAccount(account);
                          Navigator.of(sheetContext).pop();
                        },
                      ),
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
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

    if (store.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: dashboardTheme.accent,
        ),
      );
    }

    if (store.error != null) {
      return _ErrorView(
        message: store.error!,
        onRetry: _refresh,
      );
    }

    return Container(
      color: dashboardTheme.background,
      child: RefreshIndicator(
        color: dashboardTheme.accent,
        backgroundColor: dashboardTheme.card,
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: dashboardTheme.accent,
                ),
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
                  recurringTransactions: <RecurringTransaction>[],
                );

            final account = store.activeAccount ?? 'Pribadi';

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                32,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keuangan',
                            style: TextStyle(
                              color: dashboardTheme.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            account,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: dashboardTheme.primaryText,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: dashboardTheme.card,
                      borderRadius: BorderRadius.circular(15),
                      child: InkWell(
                        onTap: _showAccountSelector,
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: dashboardTheme.divider,
                            ),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: dashboardTheme.selectedAccountIcon,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _BalanceCard(
                  balance: data.balance,
                  formatRupiah: _formatRupiah,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Pemasukan',
                        amount: data.income,
                        icon: Icons.arrow_downward_rounded,
                        formatRupiah: _formatRupiah,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Pengeluaran',
                        amount: data.expense,
                        icon: Icons.arrow_upward_rounded,
                        formatRupiah: _formatRupiah,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _FinancialHealthCard(
                  income: data.income,
                  expense: data.expense,
                  formatRupiah: _formatRupiah,
                ),
                const SizedBox(height: 18),
                _BudgetAlertSection(
                  budgets: data.budgets,
                  formatRupiah: _formatRupiah,
                ),
                const SizedBox(height: 18),
                _RecurringSummaryCard(
                  recurringTransactions: data.recurringTransactions,
                  formatRupiah: _formatRupiah,
                  onOpen: _openRecurringTransactions,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _openAddTransaction,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Tambah Transaksi',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: dashboardTheme.isDark
                          ? dashboardTheme.selectedAccount
                          : dashboardTheme.incomeSoft,
                      foregroundColor:
                          dashboardTheme.selectedAccountIcon,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                        side: BorderSide(
                          color: dashboardTheme.isDark
                              ? dashboardTheme.divider
                              : dashboardTheme.income.withValues(
                                  alpha: 0.18,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Transaksi Terbaru',
                        style: TextStyle(
                          color: dashboardTheme.primaryText,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (data.recentTransactions.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: dashboardTheme.softCard,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${data.recentTransactions.length} transaksi',
                          style: TextStyle(
                            color: dashboardTheme.secondaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
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
                      padding: const EdgeInsets.only(bottom: 10),
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
        ),
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

class _RecurringSummaryCard extends StatelessWidget {
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
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

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
        decoration: _cardDecoration(
          dashboardTheme,
          radius: 20,
        ),
        child: Row(
          children: [
            _IconBadge(
              icon: Icons.repeat_rounded,
              background: dashboardTheme.softCard,
              foreground: dashboardTheme.accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaksi Berulang',
                    style: TextStyle(
                      color: dashboardTheme.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Belum ada jadwal transaksi berulang.',
                    style: TextStyle(
                      color: dashboardTheme.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Kelola transaksi berulang',
              onPressed: onOpen,
              icon: Icon(
                Icons.chevron_right_rounded,
                color: dashboardTheme.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(
        dashboardTheme,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                icon: Icons.repeat_rounded,
                background: dashboardTheme.selectedAccount,
                foreground: dashboardTheme.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaksi Berulang',
                      style: TextStyle(
                        color: dashboardTheme.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ringkasan jadwal aktif',
                      style: TextStyle(
                        color: dashboardTheme.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onOpen,
                style: TextButton.styleFrom(
                  foregroundColor: dashboardTheme.accent,
                ),
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
                  value: '${recurringTransactions.length}',
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
                  icon: Icons.arrow_downward_rounded,
                  color: dashboardTheme.income,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RecurringAmount(
                  label: 'Pengeluaran aktif',
                  amount: activeExpense,
                  formatRupiah: formatRupiah,
                  icon: Icons.arrow_upward_rounded,
                  color: dashboardTheme.expense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration(
  _DashboardTheme theme, {
  double radius = 20,
}) {
  return BoxDecoration(
    color: theme.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: theme.divider,
    ),
    boxShadow: theme.isDark
        ? null
        : [
            BoxShadow(
              color: theme.shadow,
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
  );
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: foreground,
        size: 21,
      ),
    );
  }
}

class _RecurringValue extends StatelessWidget {
  const _RecurringValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: dashboardTheme.elevatedCard,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: dashboardTheme.secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: dashboardTheme.primaryText,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringAmount extends StatelessWidget {
  const _RecurringAmount({
    required this.label,
    required this.amount,
    required this.formatRupiah,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final String Function(double) formatRupiah;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: dashboardTheme.elevatedCard,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dashboardTheme.secondaryText,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dashboardTheme.primaryText,
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

class _FinancialHealthCard extends StatelessWidget {
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
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

    final surplus = income - expense;
    final hasIncome = income > 0;

    final ratio = hasIncome
        ? (expense / income).clamp(0.0, 1.0)
        : 0.0;

    final percentage = (ratio * 100).round();
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

    final statusColor = !hasIncome && expense > 0
        ? dashboardTheme.warning
        : isSurplus
            ? dashboardTheme.income
            : dashboardTheme.expense;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(
        dashboardTheme,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                icon: icon,
                background: statusColor.withValues(alpha: 0.12),
                foreground: statusColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kesehatan Keuangan',
                      style: TextStyle(
                        color: dashboardTheme.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: TextStyle(
                        color: dashboardTheme.primaryText,
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dashboardTheme.elevatedCard,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HealthValue(
                    label: isSurplus ? 'Surplus' : 'Defisit',
                    value: formatRupiah(surplus.abs()),
                    valueColor: statusColor,
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: dashboardTheme.divider,
                ),
                Expanded(
                  child: _HealthValue(
                    label: 'Rasio Pengeluaran',
                    value: hasIncome ? '$percentage%' : '-',
                    valueColor: dashboardTheme.primaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: dashboardTheme.secondaryText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthValue extends StatelessWidget {
  const _HealthValue({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: dashboardTheme.secondaryText,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? dashboardTheme.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetAlertSection extends StatelessWidget {
  const _BudgetAlertSection({
    required this.budgets,
    required this.formatRupiah,
  });

  final List<Budget> budgets;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

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
            a.limit <= 0 ? 0.0 : a.spent / a.limit;

        final bRatio =
            b.limit <= 0 ? 0.0 : b.spent / b.limit;

        return bRatio.compareTo(aRatio);
      },
    );

    final overBudgetCount = alerts
        .where(
          (budget) => budget.isOverBudget,
        )
        .length;

    final statusColor = overBudgetCount > 0
        ? dashboardTheme.expense
        : dashboardTheme.warning;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(
        dashboardTheme,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                icon: overBudgetCount > 0
                    ? Icons.warning_amber_rounded
                    : Icons.notifications_active_outlined,
                background: statusColor.withValues(alpha: 0.12),
                foreground: statusColor,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Peringatan Anggaran',
                  style: TextStyle(
                    color: dashboardTheme.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: dashboardTheme.softCard,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${alerts.length}',
                  style: TextStyle(
                    color: dashboardTheme.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            overBudgetCount > 0
                ? '$overBudgetCount kategori sudah melewati batas.'
                : 'Beberapa kategori mulai mendekati batas.',
            style: TextStyle(
              color: dashboardTheme.secondaryText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ...alerts.take(4).map(
            (budget) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BudgetAlertTile(
                budget: budget,
                formatRupiah: formatRupiah,
              ),
            ),
          ),
          if (alerts.length > 4)
            Text(
              '+${alerts.length - 4} peringatan lainnya '
              'dapat dilihat di menu Anggaran.',
              style: TextStyle(
                color: dashboardTheme.secondaryText,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetAlertTile extends StatelessWidget {
  const _BudgetAlertTile({
    required this.budget,
    required this.formatRupiah,
  });

  final Budget budget;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

    final ratio = budget.limit <= 0
        ? 0.0
        : budget.spent / budget.limit;

    final percentage = (ratio * 100).round();
    final isOver = budget.isOverBudget;
    final remaining = budget.remaining;

    final statusColor = isOver
        ? dashboardTheme.expense
        : dashboardTheme.warning;

    final statusText = isOver
        ? 'Terlampaui'
        : '$percentage% terpakai';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: dashboardTheme.elevatedCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: dashboardTheme.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dashboardTheme.primaryText,
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
                  overflow: TextOverflow.ellipsis,
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
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: dashboardTheme.primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeBudgetCard extends StatelessWidget {
  const _SafeBudgetCard();

  @override
  Widget build(BuildContext context) {
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(
        dashboardTheme,
        radius: 20,
      ),
      child: Row(
        children: [
          _IconBadge(
            icon: Icons.check_circle_outline_rounded,
            background: dashboardTheme.incomeSoft,
            foreground: dashboardTheme.income,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anggaran aman',
                  style: TextStyle(
                    color: dashboardTheme.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Belum ada kategori yang mencapai 80% anggaran.',
                  style: TextStyle(
                    color: dashboardTheme.secondaryText,
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

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.formatRupiah,
  });

  final double balance;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: dashboardTheme.elevatedCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dashboardTheme.divider,
        ),
        boxShadow: dashboardTheme.isDark
            ? null
            : [
                BoxShadow(
                  color: dashboardTheme.shadow,
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                icon: Icons.account_balance_wallet_outlined,
                background: dashboardTheme.selectedAccount,
                foreground: dashboardTheme.accent,
              ),
              const SizedBox(width: 11),
              Text(
                'Saldo Saat Ini',
                style: TextStyle(
                  color: dashboardTheme.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatRupiah(balance),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: dashboardTheme.primaryText,
              fontSize: 29,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saldo seluruh transaksi akun aktif',
            style: TextStyle(
              color: dashboardTheme.secondaryText,
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
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

    final isIncome = title == 'Pemasukan';

    final accentColor = isIncome
        ? dashboardTheme.income
        : dashboardTheme.expense;

    final lightCardColor = isIncome
        ? dashboardTheme.incomeSoft
        : dashboardTheme.expenseSoft;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: dashboardTheme.isDark
            ? dashboardTheme.card
            : lightCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dashboardTheme.divider,
        ),
        boxShadow: dashboardTheme.isDark
            ? null
            : [
                BoxShadow(
                  color: dashboardTheme.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: dashboardTheme.isDark
                  ? dashboardTheme.softCard
                  : accentColor.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              size: 21,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: dashboardTheme.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            formatRupiah(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

    final isIncome =
        transaction.type == TransactionType.income;

    final accentColor = isIncome
        ? dashboardTheme.income
        : dashboardTheme.expense;

    final softColor = isIncome
        ? dashboardTheme.incomeSoft
        : dashboardTheme.expenseSoft;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(
        dashboardTheme,
        radius: 18,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 20,
              color: accentColor,
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
                    color: dashboardTheme.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.category} • '
                  '${formatDate(transaction.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dashboardTheme.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${isIncome ? '+' : '-'}'
            '${formatRupiah(transaction.amount)}',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: accentColor,
              fontSize: 12.5,
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
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(
        dashboardTheme,
        radius: 20,
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: dashboardTheme.softCard,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 29,
              color: dashboardTheme.tertiaryText,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
              color: dashboardTheme.primaryText,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Tambahkan pemasukan atau pengeluaran pertama Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dashboardTheme.secondaryText,
              fontSize: 12,
              height: 1.4,
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
    final dashboardTheme = _DashboardTheme(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      color: dashboardTheme.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: _cardDecoration(
              dashboardTheme,
              radius: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBadge(
                  icon: Icons.error_outline_rounded,
                  background:
                      dashboardTheme.expenseSoft,
                  foreground:
                      dashboardTheme.expense,
                ),
                const SizedBox(height: 14),
                Text(
                  'Terjadi kesalahan',
                  style: TextStyle(
                    color: dashboardTheme.primaryText,
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
                  style: TextStyle(
                    color: dashboardTheme.secondaryText,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dashboardTheme.accent,
                    side: BorderSide(
                      color: dashboardTheme.divider,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```
