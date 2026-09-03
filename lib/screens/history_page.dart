import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
import '../models/transaction.dart';
import 'add_transaction_page.dart';

class _HistoryTheme {
  const _HistoryTheme(this.context);

  final BuildContext context;

  ThemeData get theme => Theme.of(context);

  bool get isDark => theme.brightness == Brightness.dark;

  Color get background =>
      isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FB);

  Color get card =>
      isDark ? const Color(0xFF161B22) : Colors.white;

  Color get elevated =>
      isDark ? const Color(0xFF1C232D) : const Color(0xFFF9FAFC);

  Color get input =>
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

  Color get shadow =>
      isDark ? Colors.transparent : const Color(0x12000000);
}

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
    final t = _HistoryTheme(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogTheme = _HistoryTheme(dialogContext);

        return AlertDialog(
          title: const Text('Hapus transaksi?'),
          content: Text(
            'Transaksi "${transaction.title}" akan dihapus secara permanen.',
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            18,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: dialogTheme.negative,
              ),
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
          SnackBar(
            content: const Text(
              'Transaksi berhasil dihapus.',
            ),
            backgroundColor: t.card,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: t.divider,
              ),
            ),
            contentTextStyle: TextStyle(
              color: t.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              'Transaksi gagal dihapus.',
            ),
            backgroundColor: t.card,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: t.divider,
              ),
            ),
            contentTextStyle: TextStyle(
              color: t.primaryText,
              fontWeight: FontWeight.w600,
            ),
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
    final t = _HistoryTheme(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.card,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final sheetTheme = _HistoryTheme(context);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  2,
                  20,
                  24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: sheetTheme.accent.withValues(
                                alpha: sheetTheme.isDark
                                    ? 0.14
                                    : 0.08,
                              ),
                              borderRadius:
                                  BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: sheetTheme.accent,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Filter transaksi',
                                  style: TextStyle(
                                    color:
                                        sheetTheme.primaryText,
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Persempit daftar transaksi yang ingin dilihat.',
                                  style: TextStyle(
                                    color:
                                        sheetTheme.secondaryText,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _FilterLabel(
                        label: 'Periode',
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPeriod,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Periode tanggal',
                          prefixIcon: Icon(
                            Icons.calendar_month_outlined,
                          ),
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
                            child: Text(
                              '7 hari terakhir',
                            ),
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
                            child: Text(
                              'Rentang tanggal',
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == null) {
                            return;
                          }

                          if (value ==
                              'Rentang tanggal') {
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
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sheetTheme.elevated,
                            borderRadius:
                                BorderRadius.circular(13),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.date_range_outlined,
                                size: 17,
                                color:
                                    sheetTheme.secondaryText,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _periodLabel(),
                                  style: TextStyle(
                                    color:
                                        sheetTheme.primaryText,
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _FilterLabel(
                        label: 'Jenis transaksi',
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TransactionType?>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Jenis',
                          prefixIcon: Icon(
                            Icons.swap_vert_rounded,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem<TransactionType?>(
                            value: null,
                            child: Text('Semua jenis'),
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
                      const SizedBox(height: 18),
                      _FilterLabel(
                        label: 'Kategori',
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
                              prefixIcon: Icon(
                                Icons.category_outlined,
                              ),
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
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _resetFilters();

                                Navigator.of(
                                  sheetContext,
                                ).pop();
                              },
                              icon: const Icon(
                                Icons.restart_alt_rounded,
                                size: 18,
                              ),
                              label:
                                  const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(
                                  sheetContext,
                                ).pop();

                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              icon: const Icon(
                                Icons.check_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Terapkan',
                              ),
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

  int _countActiveFilters() {
    var count = 0;

    if (_selectedPeriod != 'Semua') {
      count++;
    }

    if (_selectedType != null) {
      count++;
    }

    if (_selectedCategory != null) {
      count++;
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;
    final t = _HistoryTheme(context);

    return RefreshIndicator(
      onRefresh: () async {
        if (mounted) {
          setState(() {});
        }
      },
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          14,
          18,
          34,
        ),
        children: [
          _HistoryHeader(
            account: account,
            hasFilter: _hasActiveFilter,
            filterCount: _countActiveFilters(),
            onFilter: _showFilterSheet,
          ),
          const SizedBox(height: 19),
          _SearchField(
            value: _searchQuery,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onClear: () {
              setState(() {
                _searchQuery = '';
              });
            },
          ),
          const SizedBox(height: 12),
          if (_hasActiveFilter)
            _ActiveFilterBar(
              period: _selectedPeriod,
              periodLabel: _periodLabel(),
              type: _selectedType,
              category: _selectedCategory,
              typeLabel: _typeLabel,
              onClearPeriod: () {
                setState(() {
                  _selectedPeriod = 'Semua';
                  _startDate = null;
                  _endDate = null;
                });
              },
              onClearType: () {
                setState(() {
                  _selectedType = null;
                });
              },
              onClearCategory: () {
                setState(() {
                  _selectedCategory = null;
                });
              },
              onReset: _resetFilters,
            ),
          if (_hasActiveFilter)
            const SizedBox(height: 17),
          FutureBuilder<List<Tx>>(
            future: _loadTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(
                    top: 75,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _HistoryMessage(
                  icon: Icons.error_outline_rounded,
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
                      ? Icons.search_off_rounded
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Aktivitas',
                        style: TextStyle(
                          color: t.primaryText,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: t.input,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${transactions.length}',
                          style: TextStyle(
                            color: t.secondaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...transactions.map(
                    (transaction) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 9,
                        ),
                        child: _TransactionItem(
                          transaction: transaction,
                          formatRupiah: _formatRupiah,
                          formatDate: _formatDate,
                          onEdit: () {
                            _editTransaction(
                              transaction,
                            );
                          },
                          onDelete: () {
                            _deleteTransaction(
                              transaction,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.account,
    required this.hasFilter,
    required this.filterCount,
    required this.onFilter,
  });

  final String? account;
  final bool hasFilter;
  final int filterCount;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final t = _HistoryTheme(context);

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat Transaksi',
                style: TextStyle(
                  color: t.primaryText,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 13,
                    color: t.tertiaryText,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      account ?? 'Belum ada akun',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: t.card,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onFilter,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color: hasFilter
                      ? t.accent.withValues(
                          alpha: 0.65,
                        )
                      : t.divider,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      hasFilter
                          ? Icons.filter_alt_rounded
                          : Icons.tune_rounded,
                      size: 20,
                      color: hasFilter
                          ? t.accent
                          : t.secondaryText,
                    ),
                  ),
                  if (hasFilter)
                    Positioned(
                      right: -2,
                      top: -3,
                      child: Container(
                        constraints:
                            const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: t.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: t.card,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$filterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = _HistoryTheme(context);

    return Container(
      decoration: BoxDecoration(
        color: t.input,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: t.divider.withValues(
            alpha: t.isDark ? 0.7 : 0.8,
          ),
        ),
      ),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          color: t.primaryText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Cari transaksi atau kategori',
          hintStyle: TextStyle(
            color: t.tertiaryText,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: t.secondaryText,
            size: 21,
          ),
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close_rounded,
                    color: t.secondaryText,
                    size: 19,
                  ),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterBar
    extends StatelessWidget {
  const _ActiveFilterBar({
    required this.period,
    required this.periodLabel,
    required this.type,
    required this.category,
    required this.typeLabel,
    required this.onClearPeriod,
    required this.onClearType,
    required this.onClearCategory,
    required this.onReset,
  });

  final String period;
  final String periodLabel;
  final TransactionType? type;
  final String? category;
  final String Function(TransactionType?) typeLabel;
  final VoidCallback onClearPeriod;
  final VoidCallback onClearType;
  final VoidCallback onClearCategory;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final t = _HistoryTheme(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(17),
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
              Icon(
                Icons.filter_alt_outlined,
                size: 15,
                color: t.accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Filter aktif',
                  style: TextStyle(
                    color: t.primaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: onReset,
                borderRadius:
                    BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  child: Text(
                    'Reset semua',
                    style: TextStyle(
                      color: t.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (period != 'Semua')
                _FilterChip(
                  icon: Icons.date_range_outlined,
                  label: periodLabel,
                  onDeleted: onClearPeriod,
                ),
              if (type != null)
                _FilterChip(
                  icon: type ==
                          TransactionType.income
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  label: typeLabel(type),
                  onDeleted: onClearType,
                ),
              if (category != null)
                _FilterChip(
                  icon: Icons.category_outlined,
                  label: category!,
                  onDeleted: onClearCategory,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onDeleted,
  });

  final IconData icon;
  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final t = _HistoryTheme(context);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 250,
      ),
      padding: const EdgeInsets.only(
        left: 8,
        right: 5,
        top: 5,
        bottom: 5,
      ),
      decoration: BoxDecoration(
        color: t.input,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: t.accent,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.primaryText,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 3),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 13,
                color: t.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = _HistoryTheme(context);

    return Text(
      label,
      style: TextStyle(
        color: t.secondaryText,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TransactionItem
    extends StatelessWidget {
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
    final t = _HistoryTheme(context);

    final isIncome =
        transaction.type == TransactionType.income;

    final accent =
        isIncome ? t.positive : t.negative;

    final icon = isIncome
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        13,
        13,
        7,
        13,
      ),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: t.divider,
        ),
        boxShadow: [
          if (!t.isDark)
            BoxShadow(
              color: t.shadow,
              blurRadius: 13,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: t.isDark ? 0.12 : 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: 11),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        transaction.category,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.secondaryText,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 5,
                      ),
                      child: Text(
                        '•',
                        style: TextStyle(
                          color: t.tertiaryText,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        formatDate(transaction.date),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.tertiaryText,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '${isIncome ? '+' : '-'}${formatRupiah(transaction.amount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            tooltip: 'Menu transaksi',
            padding: EdgeInsets.zero,
            iconSize: 20,
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    const Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: t.negative,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Hapus',
                      style: TextStyle(
                        color: t.negative,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryMessage
    extends StatelessWidget {
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
    final t = _HistoryTheme(context);

    return Padding(
      padding: const EdgeInsets.only(
        top: 58,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          22,
          27,
          22,
          27,
        ),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: t.divider,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: t.input,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 27,
                color: t.tertiaryText,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.secondaryText,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
