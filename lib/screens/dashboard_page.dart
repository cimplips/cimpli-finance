import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../services/budget_store.dart';
import '../services/finance_store.dart';
import 'add_transaction_page.dart';
import 'recurring_transactions_page.dart';

class _DashboardTheme {
  const _DashboardTheme(this.context);

  final BuildContext context;

  ThemeData get theme => Theme.of(context);

  bool get isDark => theme.brightness == Brightness.dark;

  Color get background =>
      isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FB);

  Color get card =>
      isDark ? const Color(0xFF161B22) : Colors.white;

  Color get cardElevated =>
      isDark ? const Color(0xFF1C232D) : const Color(0xFFF9FAFC);

  Color get soft =>
      isDark ? const Color(0xFF202833) : const Color(0xFFF1F4F8);

  Color get primaryText =>
      isDark ? const Color(0xFFEAF2FF) : const Color(0xFF172033);

  Color get secondaryText =>
      isDark ? const Color(0xFF9DA9B8) : const Color(0xFF5D6878);

  Color get tertiaryText =>
      isDark ? const Color(0xFF718096) : const Color(0xFF8792A2);

  Color get divider =>
      isDark ? const Color(0xFF2B3440) : const Color(0xFFE3E8EF);

  Color get accent =>
      isDark ? const Color(0xFF7C9CFF) : const Color(0xFF536DCE);

  Color get positive => const Color(0xFF22A06B);

  Color get negative => const Color(0xFFE35D6A);

  Color get warning => const Color(0xFFE09B3D);

  Color get info => const Color(0xFF5B7FDB);

  Color get shadow =>
      isDark ? Colors.transparent : const Color(0x12000000);
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
    final dashboardTheme = _DashboardTheme(context);

    if (store.accounts.isEmpty) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: dashboardTheme.card,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final sheetTheme = _DashboardTheme(sheetContext);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
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
                    color: sheetTheme.primaryText,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pilih akun yang ingin ditampilkan di dashboard.',
                  style: TextStyle(
                    color: sheetTheme.secondaryText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                ...store.accounts.map(
                  (account) {
                    final selected =
                        account == store.activeAccount;

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 8,
                      ),
                      child: Material(
                        color: selected
                            ? sheetTheme.accent.withValues(
                                alpha: sheetTheme.isDark
                                    ? 0.16
                                    : 0.08,
                              )
                            : sheetTheme.soft,
                        borderRadius:
                            BorderRadius.circular(17),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(17),
                          onTap: () {
                            store.setActiveAccount(account);
                            Navigator.of(sheetContext).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? sheetTheme.accent
                                            .withValues(
                                            alpha: 0.14,
                                          )
                                        : sheetTheme.card,
                                    borderRadius:
                                        BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    Icons
                                        .account_balance_wallet_outlined,
                                    size: 21,
                                    color: selected
                                        ? sheetTheme.accent
                                        : sheetTheme.secondaryText,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    account,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          sheetTheme.primaryText,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: sheetTheme.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
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

  String _monthName() {
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

    final now = DateTime.now();

    return '${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);
    final dashboardTheme = _DashboardTheme(context);

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
              18,
              14,
              18,
              36,
            ),
            children: [
              _DashboardHeader(
                account: account,
                month: _monthName(),
                onAccountTap: _showAccountSelector,
              ),
              const SizedBox(height: 20),
              _BalanceCard(
                balance: data.balance,
                income: data.income,
                expense: data.expense,
                formatRupiah: _formatRupiah,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Pemasukan',
                      amount: data.income,
                      icon: Icons.south_west_rounded,
                      formatRupiah: _formatRupiah,
                      accentColor: dashboardTheme.positive,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Pengeluaran',
                      amount: data.expense,
                      icon: Icons.north_east_rounded,
                      formatRupiah: _formatRupiah,
                      accentColor: dashboardTheme.negative,
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
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'Anggaran',
                subtitle: 'Pantau penggunaan bulan ini',
              ),
              const SizedBox(height: 10),
              _BudgetAlertSection(
                budgets: data.budgets,
                formatRupiah: _formatRupiah,
              ),
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'Transaksi Berulang',
                subtitle: 'Jadwal otomatis Anda',
                actionLabel: 'Kelola',
                onAction: _openRecurringTransactions,
              ),
              const SizedBox(height: 10),
              _RecurringSummaryCard(
                recurringTransactions:
                    data.recurringTransactions,
                formatRupiah: _formatRupiah,
                onOpen: _openRecurringTransactions,
              ),
              const SizedBox(height: 22),
              _AddTransactionButton(
                onPressed: _openAddTransaction,
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Transaksi Terbaru',
                subtitle: data.recentTransactions.isEmpty
                    ? 'Belum ada aktivitas'
                    : '${data.recentTransactions.length} transaksi terakhir',
              ),
              const SizedBox(height: 10),
              if (data.recentTransactions.isEmpty)
                const _EmptyTransactions()
              else
                ...data.recentTransactions.map(
                  (transaction) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 9,
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.account,
    required this.month,
    required this.onAccountTap,
  });

  final String account;
  final String month;
  final VoidCallback onAccountTap;

  @override
  Widget build(BuildContext context) {
    final t = _DashboardTheme(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan Keuangan',
                style: TextStyle(
                  color: t.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                account,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: t.primaryText,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                month,
                style: TextStyle(
                  color: t.tertiaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: t.card,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onAccountTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color: t.divider,
                ),
              ),
              child: Icon(
                Icons
                    .account_balance_wallet_outlined,
                size: 21,
                color: t.secondaryText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = _DashboardTheme(context);

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: t.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: t.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              minimumSize: Size.zero,
              tapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: TextStyle(
                color: t.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
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
    final t = _DashboardTheme(context);

    final net = income - expense;
    final hasActivity =
        income > 0 || expense > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        21,
        20,
        21,
        18,
      ),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: t.divider,
        ),
        boxShadow: [
          if (!t.isDark)
            BoxShadow(
              color: t.shadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: t.accent.withValues(
                    alpha: t.isDark ? 0.14 : 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 19,
                  color: t.accent,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Saldo saat ini',
                  style: TextStyle(
                    color: t.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasActivity)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: net >= 0
                        ? t.positive.withValues(
                            alpha: 0.10,
                          )
                        : t.negative.withValues(
                            alpha: 0.10,
                          ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    net >= 0 ? 'Surplus' : 'Defisit',
                    style: TextStyle(
                      color: net >= 0
                          ? t.positive
                          : t.negative,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            formatRupiah(balance),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.primaryText,
              fontSize: 31,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saldo seluruh transaksi pada akun aktif',
            style: TextStyle(
              color: t.tertiaryText,
              fontSize: 11,
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
    required this.accentColor,
  });

  final String title;
  final double amount;
  final IconData icon;
  final String Function(double) formatRupiah;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final t = _DashboardTheme(context);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: t.divider,
        ),
        boxShadow: [
          if (!t.isDark)
            BoxShadow(
              color: t.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(
                alpha: t.isDark ? 0.12 : 0.09,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: TextStyle(
              color: t.secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            formatRupiah(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
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
    final t = _DashboardTheme(context);

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
    Color statusColor;

    if (!hasIncome && expense <= 0) {
      title = 'Belum ada aktivitas';
      description =
          'Tambahkan transaksi untuk mulai melihat kondisi keuangan bulan ini.';
      icon = Icons.insights_outlined;
      statusColor = t.accent;
    } else if (!hasIncome && expense > 0) {
      title = 'Belum ada pemasukan';
      description =
          'Pengeluaran sudah tercatat, tetapi belum ada pemasukan pada periode ini.';
      icon = Icons.info_outline_rounded;
      statusColor = t.warning;
    } else if (isSurplus) {
      title = 'Keuangan berjalan positif';
      description =
          'Pemasukan masih lebih besar daripada pengeluaran bulan ini.';
      icon = Icons.trending_up_rounded;
      statusColor = t.positive;
    } else {
      title = 'Perlu perhatian';
      description =
          'Pengeluaran saat ini lebih besar daripada pemasukan bulan ini.';
      icon = Icons.trending_down_rounded;
      statusColor = t.negative;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.cardElevated,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: t.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(
                    alpha: t.isDark ? 0.13 : 0.09,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
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
                      'Kesehatan Keuangan',
                      style: TextStyle(
                        color: t.secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: TextStyle(
                        color: t.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasIncome) ...[
            Row(
              children: [
                Expanded(
                  child: _HealthMetric(
                    label: 'Penggunaan pemasukan',
                    value: '$percentage%',
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _HealthMetric(
                    label: isSurplus
                        ? 'Surplus'
                        : 'Defisit',
                    value:
                        formatRupiah(surplus.abs()),
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: ratio,
                backgroundColor: t.soft,
                valueColor:
                    AlwaysStoppedAnimation<Color>(
                  statusColor,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: t.secondaryText,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  const _HealthMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = _DashboardTheme(context);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: t.secondaryText,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
    final t = _DashboardTheme(context);

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

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: t.divider,
        ),
        boxShadow: [
          if (!t.isDark)
            BoxShadow(
              color: t.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (overBudgetCount > 0
                          ? t.negative
                          : t.warning)
                      .withValues(
                    alpha: t.isDark ? 0.13 : 0.09,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  overBudgetCount > 0
                      ? Icons.warning_amber_rounded
                      : Icons.notifications_active_outlined,
                  size: 19,
                  color: overBudgetCount > 0
                      ? t.negative
                      : t.warning,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perlu diperhatikan',
                      style: TextStyle(
                        color: t.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      overBudgetCount > 0
                          ? '$overBudgetCount anggaran telah melewati batas.'
                          : 'Beberapa anggaran mulai mendekati batas.',
                      style: TextStyle(
                        color: t.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: t.soft,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  '${alerts.length}',
                  style: TextStyle(
                    color: t.primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...alerts.take(4).map(
            (budget) => Padding(
              padding:
                  const EdgeInsets.only(bottom: 8),
              child: _BudgetAlertTile(
                budget: budget,
                formatRupiah: formatRupiah,
              ),
            ),
          ),
          if (alerts.length > 4) ...[
            const SizedBox(height: 2),
            Text(
              '+${alerts.length - 4} peringatan lainnya dapat dilihat di menu Anggaran.',
              style: TextStyle(
                color: t.secondaryText,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ],
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
    final t = _DashboardTheme(context);

    final ratio = budget.limit <= 0
        ? 0.0
        : budget.spent / budget.limit;

    final percentage = (ratio * 100).round();
    final isOver = budget.isOverBudget;
    final remaining = budget.remaining;

    final statusColor =
        isOver ? t.negative : t.warning;

    final statusText = isOver
        ? 'Terlampaui'
        : '$percentage% terpakai';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.cardElevated,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: t.isDark ? 0.13 : 0.09,
              ),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              isOver
                  ? Icons.warning_rounded
                  : Icons.priority_high_rounded,
              size: 17,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  budget.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isOver
                      ? 'Melebihi ${formatRupiah(-remaining)}'
                      : '$statusText dari ${formatRupiah(budget.limit)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
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
              color: t.primaryText,
              fontSize: 11,
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
    final t = _DashboardTheme(context);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: t.divider,
        ),
        boxShadow: [
          if (!t.isDark)
            BoxShadow(
              color: t.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.positive.withValues(
                alpha: t.isDark ? 0.13 : 0.09,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 20,
              color: t.positive,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Anggaran aman',
                  style: TextStyle(
                    color: t.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Belum ada kategori yang mencapai 80% anggaran.',
                  style: TextStyle(
                    color: t.secondaryText,
                    fontSize: 10,
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
    final t = _DashboardTheme(context);

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
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius:
              BorderRadius.circular(21),
          border: Border.all(
            color: t.divider,
          ),
          boxShadow: [
            if (!t.isDark)
              BoxShadow(
                color: t.shadow,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.soft,
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.repeat_rounded,
                size: 21,
                color: t.secondaryText,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum ada transaksi berulang',
                    style: TextStyle(
                      color: t.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Buat jadwal untuk transaksi otomatis.',
                    style: TextStyle(
                      color: t.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            _SmallArrowButton(
              onPressed: onOpen,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: t.divider,
        ),
        boxShadow: [
          if (!t.isDark)
            BoxShadow(
              color: t.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: t.accent.withValues(
                    alpha: t.isDark ? 0.13 : 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.repeat_rounded,
                  size: 21,
                  color: t.accent,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal aktif',
                      style: TextStyle(
                        color: t.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${active.length} dari ${recurringTransactions.length} jadwal aktif',
                      style: TextStyle(
                        color: t.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _SmallArrowButton(
                onPressed: onOpen,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RecurringMetric(
                  label: 'Pemasukan aktif',
                  value:
                      formatRupiah(activeIncome),
                  icon: Icons.south_west_rounded,
                  color: t.positive,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _RecurringMetric(
                  label: 'Pengeluaran aktif',
                  value:
                      formatRupiah(activeExpense),
                  icon: Icons.north_east_rounded,
                  color: t.negative,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecurringMetric
    extends StatelessWidget {
  const _RecurringMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = _DashboardTheme(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.cardElevated,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: t.isDark ? 0.12 : 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
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
                  style: TextStyle(
                    color: t.secondaryText,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.primaryText,
                    fontSize: 11,
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

class _SmallArrowButton
    extends StatelessWidget {
  const _SmallArrowButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = _DashboardTheme(context);

    return Material(
      color: t.soft,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: t.secondaryText,
          ),
        ),
      ),
    );
  }
}

class _AddTransactionButton
    extends StatelessWidget {
  const _AddTransactionButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = _DashboardTheme(context);

    return Material(
      color: t.accent,
      borderRadius: BorderRadius.circular(18),
      elevation: t.isDark ? 0 : 2,
      shadowColor: t.accent.withValues(
        alpha: 0.22,
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 55,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.16,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Tambah Transaksi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 19,
                color: Colors.white,
              ),
            ],
          ),
        ),
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
    final t = _DashboardTheme(context);

    final isIncome =
        transaction.type == TransactionType.income;

    final accent =
        isIncome ? t.positive : t.negative;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: t.divider,
        ),
        boxShadow: [
          if (!t.isDark)
            BoxShadow(
              color: t.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: t.isDark ? 0.12 : 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              isIncome
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w750,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.category} • ${formatDate(transaction.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${formatRupiah(transaction.amount)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isIncome
                    ? 'Pemasukan'
                    : 'Pengeluaran',
                style: TextStyle(
                  color: t.tertiaryText,
                  fontSize: 9,
                ),
              ),
            ],
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
    final t = _DashboardTheme(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 26,
      ),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: t.divider,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: t.soft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 25,
              color: t.tertiaryText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
              color: t.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Tambahkan pemasukan atau pengeluaran pertama Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: t.secondaryText,
              fontSize: 11,
              height: 1.4,
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
    final t = _DashboardTheme(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color: t.divider,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: t.negative.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 27,
                  color: t.negative,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                'Terjadi kesalahan',
                style: TextStyle(
                  color: t.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: t.secondaryText,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 17),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text(
                  'Coba Lagi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
