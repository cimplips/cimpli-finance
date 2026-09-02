import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/finance_scope.dart';
import '../models/transaction.dart';
import '../services/finance_store.dart';
import '../widgets/transaction_tile.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String typeFilter = 'Semua';
  String categoryFilter = 'Semua';
  DateTime? selectedMonth;

  List<Tx> _filteredTransactions(FinanceStore store) {
    return store.transactions.where((tx) {
      if (typeFilter == 'Pemasukan' &&
          tx.type != TransactionType.income) {
        return false;
      }

      if (typeFilter == 'Pengeluaran' &&
          tx.type != TransactionType.expense) {
        return false;
      }

      if (categoryFilter != 'Semua' &&
          tx.category != categoryFilter) {
        return false;
      }

      if (selectedMonth != null &&
          (tx.date.year != selectedMonth!.year ||
              tx.date.month != selectedMonth!.month)) {
        return false;
      }

      return true;
    }).toList();
  }

  List<String> _categories(FinanceStore store) {
    final categories = store.transactions
        .map((tx) => tx.category)
        .toSet()
        .toList()
      ..sort();

    return [
      'Semua',
      ...categories,
    ];
  }

  void _resetFilter() {
    setState(() {
      typeFilter = 'Semua';
      categoryFilter = 'Semua';
      selectedMonth = null;
    });
  }

  Future<void> _pickMonth(BuildContext pageContext) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: pageContext,
      initialDate: selectedMonth ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih bulan transaksi',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      selectedMonth = DateTime(
        picked.year,
        picked.month,
      );
    });
  }

  Future<bool> _confirmDelete(
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Hapus transaksi?',
          ),
          content: const Text(
            'Transaksi yang dihapus tidak dapat dikembalikan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);

    final money = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final transactions =
        _filteredTransactions(store);

    final categories = _categories(store);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Riwayat Transaksi',
          ),
          actions: [
            IconButton(
              tooltip: 'Reset filter',
              onPressed: _resetFilter,
              icon: const Icon(
                Icons.restart_alt,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                10,
              ),
              child: Column(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Semua',
                        label: Text('Semua'),
                      ),
                      ButtonSegment(
                        value: 'Pemasukan',
                        icon: Icon(
                          Icons.arrow_downward,
                        ),
                        label: Text('Masuk'),
                      ),
                      ButtonSegment(
                        value: 'Pengeluaran',
                        icon: Icon(
                          Icons.arrow_upward,
                        ),
                        label: Text('Keluar'),
                      ),
                    ],
                    selected: {typeFilter},
                    onSelectionChanged: (value) {
                      setState(() {
                        typeFilter = value.first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: categoryFilter,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            prefixIcon: Icon(
                              Icons.category_outlined,
                            ),
                          ),
                          items: categories
                              .map(
                                (category) =>
                                    DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              categoryFilter = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        tooltip: 'Pilih bulan',
                        onPressed: () {
                          _pickMonth(context);
                        },
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                        ),
                      ),
                    ],
                  ),
                  if (selectedMonth != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Periode: ${DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth!)}',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                selectedMonth = null;
                              });
                            },
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                            ),
                            label: const Text(
                              'Hapus',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tidak ada transaksi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tidak ada transaksi yang sesuai dengan filter.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                color:
                                    Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        110,
                      ),
                      itemCount:
                          transactions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        final tx =
                            transactions[index];

                        return Card(
                          child: ListTile(
                            onTap: () async {
                              await Navigator.of(
                                context,
                              ).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddTransactionPage(
                                    transaction: tx,
                                  ),
                                ),
                              );
                            },
                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration:
                                  BoxDecoration(
                                color: const Color(
                                  0xFF30343A,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                              ),
                              child: Icon(
                                tx.type ==
                                        TransactionType
                                            .income
                                    ? Icons
                                        .south_west
                                    : Icons
                                        .north_east,
                              ),
                            ),
                            title: Text(
                              tx.title,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  tx.category,
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                    'id_ID',
                                  ).format(
                                    tx.date,
                                  ),
                                  style: TextStyle(
                                    color:
                                        Colors.grey
                                            .shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .end,
                              children: [
                                Text(
                                  '${tx.type == TransactionType.income ? '+' : '-'}${money.format(tx.amount)}',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color: tx.type ==
                                            TransactionType
                                                .income
                                        ? Colors
                                            .greenAccent
                                            .shade200
                                        : Colors
                                            .redAccent
                                            .shade100,
                                  ),
                                ),
                                const SizedBox(
                                  height: 6,
                                ),
                                Row(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip:
                                          'Edit transaksi',
                                      iconSize: 19,
                                      onPressed:
                                          () async {
                                        await Navigator
                                            .of(
                                          context,
                                        ).push(
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    AddTransactionPage(
                                              transaction:
                                                  tx,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip:
                                          'Hapus transaksi',
                                      iconSize: 19,
                                      onPressed:
                                          () async {
                                        final confirm =
                                            await _confirmDelete(
                                          context,
                                        );

                                        if (!confirm) {
                                          return;
                                        }

                                        await store
                                            .deleteTransaction(
                                          tx.id!,
                                        );

                                        if (!context
                                            .mounted) {
                                          return;
                                        }

                                        ScaffoldMessenger
                                                .of(
                                          context,
                                        )
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text(
                                              'Transaksi berhasil dihapus.',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons
                                            .delete_outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
