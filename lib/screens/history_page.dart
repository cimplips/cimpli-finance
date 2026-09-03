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
  String _searchQuery = '';

  String _selectedPeriod = 'Semua';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<List<Tx>> _loadTransactions() async {
    final store = FinanceScope.of(context);

    final transactions = await store.getTransactions(
      account: store.activeAccount,
      category: _selectedCategory,
      type: _selectedType,
    );

    final query = _searchQuery.trim().toLowerCase();

    var filtered = transactions;

    if (query.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return transaction.title.toLowerCase().contains(query) ||
            transaction.category.toLowerCase().contains(query);
      }).toList();
    }

    if (_startDate != null && _endDate != null) {
      final start = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );

      final end = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
        999,
      );

      filtered = filtered.where((transaction) {
        final date = transaction.date;

        return !date.isBefore(start) && !date.isAfter(end);
      }).toList();
    }

    return filtered;
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

  Future<void> _selectCustomDateRange(
    BuildContext pickerContext,
  ) async {
    final now = DateTime.now();

    final initialStart = _startDate ?? now;
    final initialEnd = _endDate ?? now;

    final firstDate = DateTime(2000);
    final lastDate = DateTime(
      now.year + 10,
      now.month,
      now.day,
    );

    final start = initialStart.isBefore(firstDate)
        ? firstDate
        : initialStart;

    final end = initialEnd.isAfter(lastDate)
        ? lastDate
        : initialEnd;

    final initialRange = start.isAfter(end)
        ? DateTimeRange(
            start: start,
            end: start,
          )
        : DateTimeRange(
            start: start,
            end: end,
          );

    final selected = await showDateRangePicker(
      context: pickerContext,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialRange,
      helpText: 'Pilih periode transaksi',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      saveText: 'Simpan',
      fieldStartHintText: 'Tanggal mulai',
      fieldEndHintText: 'Tanggal akhir',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedPeriod = 'Rentang tanggal';
      _startDate = selected.start;
      _endDate = selected.end;
    });
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  void _setPeriod(String period) {
    final now = DateTime.now();
    final today = _dateOnly(now);

    DateTime? start;
    DateTime? end;

    switch (period) {
      case 'Hari ini':
        start = today;
        end = today;
        break;

      case '7 hari terakhir':
        start = today.subtract(
          const Duration(days: 6),
        );
        end = today;
        break;

      case 'Bulan ini':
        start = DateTime(
          now.year,
          now.month,
          1,
        );
        end = DateTime(
          now.year,
          now.month + 1,
          0,
        );
        break;

      case 'Bulan lalu':
        start = DateTime(
          now.year,
          now.month - 1,
          1,
        );
        end = DateTime(
          now.year,
          now.month,
          0,
        );
        break;

      default:
        start = null;
        end = null;
    }

    setState(() {
      _selectedPeriod = period;
      _startDate = start;
      _endDate = end;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedType = null;
      _selectedPeriod = 'Semua';
      _startDate = null;
      _endDate = null;
    });
  }

  bool get _hasActiveFilter {
    return _selectedCategory != null ||
        _selectedType != null ||
        _selectedPeriod != 'Semua';
  }

  String _periodLabel() {
    if (_selectedPeriod != 'Rentang tanggal') {
      return _selectedPeriod;
    }

    if (_startDate == null || _endDate == null) {
      return 'Rentang tanggal';
    }

    return '${_formatShortDate(_startDate!)} - ${_formatShortDate(_endDate!)}';
  }

  String _formatShortDate(DateTime date) {
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

  void _showFilterSheet() {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final sheetColorScheme =
                Theme.of(context).colorScheme;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter transaksi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Periode',
                        style: TextStyle(
                          color: sheetColorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPeriod,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Periode tanggal',
                        ),
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'Semua',
                            child: Text('Semua tanggal'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'Hari ini',
                            child: Text('Hari ini'),
                          ),
                          DropdownMenuItem<String>(
                            value: '7 hari terakhir',
                            child: Text('7 hari terakhir'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'Bulan ini',
                            child: Text('Bulan ini'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'Bulan lalu',
                            child: Text('Bulan lalu'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'Rentang tanggal',
                            child: Text('Rentang tanggal'),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == null) {
                            return;
                          }

                          if (value == 'Rentang tanggal') {
                            await _selectCustomDateRange(
                              sheetContext,
                            );

                            if (mounted) {
                              setSheetState(() {});
                            }
                            return;
                          }

                          _setPeriod(value);
                          setSheetState(() {});
                        },
                      ),
                      if (_selectedPeriod ==
                              'Rentang tanggal' &&
                          _startDate != null &&
                          _endDate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _periodLabel(),
                          style: TextStyle(
                            color:
                                sheetColorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Jenis transaksi',
                        style: TextStyle(
                          color: sheetColorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TransactionType?>(
                        initialValue: _selectedType,
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
                      Text(
                        'Kategori',
                        style: TextStyle(
                          color: sheetColorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<String>>(
                        future: _loadCategories(),
                        builder: (context, snapshot) {
                          final categories =
                              snapshot.data ??
                                  <String>['Semua'];

                          final selected =
                              categories.contains(
                                _selectedCategory,
                              )
                                  ? _selectedCategory
                                  : 'Semua';

                          return DropdownButtonFormField<String>(
                            initialValue: selected,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(
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
                                _resetFilters();
                                Navigator.of(sheetContext).pop();
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
    final colorScheme = Theme.of(context).colorScheme;

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
                  _hasActiveFilter
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            account ?? 'Belum ada akun',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari transaksi atau kategori',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          if (_hasActiveFilter)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedPeriod != 'Semua')
                  Chip(
                    avatar: const Icon(
                      Icons.date_range_outlined,
                      size: 18,
                    ),
                    label: Text(
                      _periodLabel(),
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedPeriod = 'Semua';
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                  ),
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
          if (_hasActiveFilter)
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
                final hasSearch =
                    _searchQuery.trim().isNotEmpty;

                return _HistoryMessage(
                  icon: hasSearch || _hasActiveFilter
                      ? Icons.search_off_outlined
                      : Icons.receipt_long_outlined,
                  title: hasSearch || _hasActiveFilter
                      ? 'Transaksi tidak ditemukan'
                      : 'Belum ada transaksi',
                  message: hasSearch || _hasActiveFilter
                      ? 'Coba ubah kata pencarian atau filter yang digunakan.'
                      : 'Transaksi yang ditambahkan akan muncul di sini.',
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
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome =
        transaction.type == TransactionType.income;

    final incomeColor = const Color(0xFF4F8A68);
    final expenseColor = const Color(0xFFB85C5C);

    final accentColor =
        isIncome ? incomeColor : expenseColor;

    final iconBackground = isIncome
        ? const Color(0xFFEAF5EE)
        : const Color(0xFFF9ECEC);

    final darkIconBackground = isIncome
        ? const Color(0xFF294035)
        : const Color(0xFF493033);

    final cardColor = colorScheme.surfaceContainerLow;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        8,
        14,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.45,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                Theme.of(context).brightness == Brightness.dark
                    ? darkIconBackground
                    : iconBackground,
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: accentColor,
              size: 21,
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
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${isIncome ? '+' : '-'}${formatRupiah(transaction.amount)}',
                  style: TextStyle(
                    color: accentColor,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: 70,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: colorScheme.onSurfaceVariant,
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
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
