import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
import '../models/transaction.dart';
import 'add_transaction_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? _selectedCategory;
  TransactionType? _selectedType;

  Future<List<Tx>> _loadTransactions() async {
    final store = FinanceScope.of(context);

    return store.getTransactions(
      account: store.activeAccount,
      category: _selectedCategory,
      type: _selectedType,
    );
  }

  Future<List<String>> _loadCategories() async {
    final store = FinanceScope.of(context);

    final categories = await store.getCategories(
      account: store.activeAccount,
    );

    return <String>[
      'Semua',
      ...categories,
    ];
  }

  Future<void> _editTransaction(Tx transaction) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddTransactionPage(
          transaction: transaction,
        ),
      ),
    );

    if (changed == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteTransaction(Tx transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus transaksi?'),
          content: Text(
            'Transaksi "${transaction.title}" akan dihapus secara permanen.',
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

    if (confirmed != true || !mounted) {
      return;
    }

    final store = FinanceScope.of(context);
    final success = await store.deleteTransaction(
      transaction.id!,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {});

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dihapus.'),
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Transaksi gagal dihapus.'),
          ),
        );
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1E22),
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      'Filter transaksi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Jenis transaksi',
                      style: TextStyle(
                        color: Color(0xFF9A9DA3),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TransactionType?>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Jenis',
                      ),
                      items: const [
                        DropdownMenuItem<TransactionType?>(
                          value: null,
                          child: Text('Semua'),
                        ),
                        DropdownMenuItem<TransactionType?>(
                          value: TransactionType.income,
                          child: Text('Pemasukan'),
                        ),
                        DropdownMenuItem<TransactionType?>(
                          value: TransactionType.expense,
                          child: Text('Pengeluaran'),
                        ),
                      ],
                      onChanged: (value) {
                        setSheetState(() {
                          _selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        color: Color(0xFF9A9DA3),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<String>>(
                      future: _loadCategories(),
                      builder: (context, snapshot) {
                        final categories =
                            snapshot.data ?? <String>['Semua'];

                        final selected =
                            categories.contains(_selectedCategory)
                                ? _selectedCategory
                                : 'Semua';

                        return DropdownButtonFormField<String>(
                          value: selected,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                          ),
                          items: categories
                              .map(
                                (category) =>
                                    DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(
                                    category,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setSheetState(() {
                              _selectedCategory =
                                  value == 'Semua'
                                      ? null
                                      : value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                _selectedType = null;
                                _selectedCategory = null;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();

                              if (mounted) {
                                setState(() {});
                              }
                            },
                            child: const Text('Terapkan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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

  String _typeLabel(TransactionType? type) {
    if (type == TransactionType.income) {
      return 'Pemasukan';
    }

    if (type == TransactionType.expense) {
      return 'Pengeluaran';
    }

    return 'Semua jenis';
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Riwayat Transaksi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Filter',
                onPressed: _showFilterSheet,
                icon: Icon(
                  (_selectedCategory != null ||
                          _selectedType != null)
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            account ?? 'Belum ada akun',
            style: const TextStyle(
              color: Color(0xFF9A9DA3),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedCategory != null ||
              _selectedType != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedType != null)
                  Chip(
                    label: Text(
                      _typeLabel(_selectedType),
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedType = null;
                      });
                    },
                  ),
                if (_selectedCategory != null)
                  Chip(
                    label: Text(_selectedCategory!),
                    onDeleted: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                  ),
              ],
            ),
          if (_selectedCategory != null ||
              _selectedType != null)
            const SizedBox(height: 12),
          FutureBuilder<List<Tx>>(
            future: _loadTransactions(),
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
                return _HistoryMessage(
                  icon: Icons.error_outline,
                  title: 'Gagal memuat transaksi',
                  message: snapshot.error.toString(),
                );
              }

              final transactions =
                  snapshot.data ?? <Tx>[];

              if (transactions.isEmpty) {
                return const _HistoryMessage(
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum ada transaksi',
                  message:
                      'Transaksi yang sesuai filter akan muncul di sini.',
                );
              }

              return Column(
                children: transactions.map(
                  (transaction) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: _TransactionItem(
                        transaction: transaction,
                        formatRupiah: _formatRupiah,
                        formatDate: _formatDate,
                        onEdit: () {
                          _editTransaction(transaction);
                        },
                        onDelete: () {
                          _deleteTransaction(transaction);
                        },
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.transaction,
    required this.formatRupiah,
    required this.formatDate,
    required this.onEdit,
    required this.onDelete,
  });

  final Tx transaction;
  final String Function(double) formatRupiah;
  final String Function(DateTime) formatDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome =
        transaction.type == TransactionType.income;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        8,
        14,
      ),
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
                const SizedBox(height: 5),
                Text(
                  '${isIncome ? '+' : '-'}${formatRupiah(transaction.amount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu transaksi',
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline),
                  title: Text('Hapus'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 70,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: const Color(0xFF777B82),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
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
