import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/finance_scope.dart';
import '../models/transaction.dart';
import '../services/finance_store.dart';
import '../widgets/transaction_tile.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.onOpenHistory,
  });

  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);
    final money = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: store.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            120,
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
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ringkasan keuangan Anda',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Pengaturan',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const SettingsPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.settings_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                _accountPicker(context, store);
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: const Color(0xFF202329),
                  borderRadius:
                      BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF363A41,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Keuangan aktif',
                              style: TextStyle(
                                color:
                                    Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              store.activeAccount,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: const Color(0xFF292D33),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'TOTAL SALDO',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.2,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.visibility_outlined,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    money.format(store.balance),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _BalanceInfo(
                          icon: Icons.arrow_downward,
                          title: 'Masuk',
                          value: money.format(
                            store.income,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BalanceInfo(
                          icon: Icons.arrow_upward,
                          title: 'Keluar',
                          value: money.format(
                            store.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aksi Cepat',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_circle_outline,
                    title: 'Pemasukan',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const AddTransactionPage(
                            initialType:
                                TransactionType.income,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon:
                        Icons.remove_circle_outline,
                    title: 'Pengeluaran',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const AddTransactionPage(
                            initialType:
                                TransactionType.expense,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Transaksi Terbaru',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onOpenHistory,
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (store.transactions.isEmpty)
              _EmptyTransactionCard()
            else
              Card(
                child: Column(
                  children: store.transactions
                      .take(5)
                      .map(
                        (tx) => TransactionTile(
                          tx: tx,
                          money: money,
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _accountPicker(
    BuildContext context,
    FinanceStore store,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1E22),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 8,
                      bottom: 12,
                    ),
                    child: Text(
                      'Pilih Keuangan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ...store.accounts.map(
                  (name) => ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    tileColor:
                        name == store.activeAccount
                            ? const Color(
                                0xFF30343A,
                              )
                            : null,
                    title: Text(name),
                    leading: const Icon(
                      Icons.account_balance_wallet_outlined,
                    ),
                    trailing:
                        name == store.activeAccount
                            ? const Icon(
                                Icons.check_circle,
                              )
                            : null,
                    onTap: () async {
                      await store.selectAccount(
                        name,
                      );

                      if (!sheetContext.mounted) {
                        return;
                      }

                      Navigator.of(
                        sheetContext,
                      ).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BalanceInfo extends StatelessWidget {
  const _BalanceInfo({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF202329),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 14,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 30,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum ada transaksi',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tambahkan transaksi pertama Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
