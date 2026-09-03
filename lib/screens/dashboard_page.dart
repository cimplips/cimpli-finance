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
                            max

