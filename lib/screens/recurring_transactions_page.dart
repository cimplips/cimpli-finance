import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../services/finance_store.dart';

class RecurringTransactionsPage extends StatefulWidget {
  const RecurringTransactionsPage({
    super.key,
  });

  @override
  State<RecurringTransactionsPage> createState() =>
      _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState
    extends State<RecurringTransactionsPage> {
  Future<List<RecurringTransaction>>? _recurringFuture;
  String? _futureAccount;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _textSecondary =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  Color get _surfaceSoft =>
      Theme.of(context).colorScheme.surfaceContainerLow;

  Color get _borderColor => _isDark
      ? const Color(0xFF50535A)
      : const Color(0xFFE1E6EF);

  Color get _incomeColor => _isDark
      ? const Color(0xFF86CBBB)
      : const Color(0xFF4F8A68);

  Color get _incomeSoft => _isDark
      ? const Color(0xFF394B48)
      : const Color(0xFFE7F6F2);

  Color get _expenseColor => _isDark
      ? const Color(0xFFE39A9A)
      : const Color(0xFFB85C5C);

  Color get _expenseSoft => _isDark
      ? const Color(0xFF4B3D40)
      : const Color(0xFFFFECEC);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    if (_futureAccount != account) {
      _futureAccount = account;
      _recurringFuture = account == null
          ? Future.value(<RecurringTransaction>[])
          : store.getRecurringTransactions(
              account: account,
            );
    }
  }

  void _refresh() {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    setState(() {
      _futureAccount = account;
      _recurringFuture = account == null
          ? Future.value(<RecurringTransaction>[])
          : store.getRecurringTransactions(
              account: account,
            );
    });
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

  String _typeLabel(TransactionType type) {
    if (type == TransactionType.income) {
      return 'Pemasukan';
    }

    return 'Pengeluaran';
  }

  IconData _typeIcon(TransactionType type) {
    if (type == TransactionType.income) {
      return Icons.arrow_downward_rounded;
    }

    return Icons.arrow_upward_rounded;
  }

  String _frequencyDescription(
    RecurringFrequency frequency,
  ) {
    switch (frequency) {
      case RecurringFrequency.weekly:
        return 'Setiap minggu';
      case RecurringFrequency.monthly:
        return 'Setiap bulan';
      case RecurringFrequency.yearly:
        return 'Setiap tahun';
    }
  }

  Future<List<String>> _getCategories(
    FinanceStore store,
    String account,
  ) async {
    final categories = await store.getCategories(
      account: account,
    );

    categories.sort(
      (a, b) => a.toLowerCase().compareTo(
            b.toLowerCase(),
          ),
    );

    return categories;
  }

  Future<void> _showRecurringDialog({
    RecurringTransaction? recurring,
  }) async {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    if (account == null) {
      _showMessage(
        'Pilih akun terlebih dahulu.',
      );
      return;
    }

    final titleController = TextEditingController(
      text: recurring?.title ?? '',
    );

    final amountController = TextEditingController(
      text: recurring == null
          ? ''
          : recurring.amount.round().toString(),
    );

    final formKey = GlobalKey<FormState>();

    var selectedType =
        recurring == null
            ? TransactionType.expense
            : TransactionType.values.byName(
                recurring.type,
              );

    var selectedFrequency =
        recurring?.frequency ??
            RecurringFrequency.monthly;

    var selectedCategory =
        recurring?.category;

    var selectedStartDate =
        recurring?.startDate ??
            DateTime.now();

    try {
      final categories = await _getCategories(
        store,
        account,
      );

      if (!mounted) {
        return;
      }

      if (selectedCategory == null ||
          !categories.contains(selectedCategory)) {
        selectedCategory =
            categories.isEmpty
                ? null
                : categories.first;
      }

      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
              context,
              setDialogState,
            ) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  recurring == null
                      ? 'Tambah Transaksi Berulang'
                      : 'Edit Transaksi Berulang',
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller:
                              titleController,
                          textCapitalization:
                              TextCapitalization.sentences,
                          textInputAction:
                              TextInputAction.next,
                          decoration:
                              const InputDecoration(
                            labelText: 'Nama transaksi',
                            hintText:
                                'Contoh: Gaji bulanan',
                            prefixIcon: Icon(
                              Icons.receipt_long_outlined,
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Nama transaksi wajib diisi.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller:
                              amountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction:
                              TextInputAction.next,
                          decoration:
                              const InputDecoration(
                            labelText: 'Nominal',
                            hintText: 'Contoh: 5000000',
                            prefixIcon: Icon(
                              Icons.payments_outlined,
                            ),
                          ),
                          validator: (value) {
                            final text =
                                value?.trim() ?? '';

                            if (text.isEmpty) {
                              return 'Nominal wajib diisi.';
                            }

                            final normalized =
                                text.replaceAll(
                              '.',
                              '',
                            ).replaceAll(
                              ',',
                              '.',
                            );

                            final amount =
                                double.tryParse(
                              normalized,
                            );

                            if (amount == null ||
                                amount <= 0) {
                              return 'Nominal tidak valid.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<
                            TransactionType>(
                          initialValue:
                              selectedType,
                          decoration:
                              const InputDecoration(
                            labelText: 'Jenis transaksi',
                            prefixIcon: Icon(
                              Icons.swap_vert_rounded,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem<
                                TransactionType>(
                              value:
                                  TransactionType.expense,
                              child: Text(
                                'Pengeluaran',
                              ),
                            ),
                            DropdownMenuItem<
                                TransactionType>(
                              value:
                                  TransactionType.income,
                              child: Text(
                                'Pemasukan',
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setDialogState(() {
                              selectedType =
                                  value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<
                            String>(
                          initialValue:
                              selectedCategory,
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
                                (category) {
                                  return DropdownMenuItem<
                                      String>(
                                    value: category,
                                    child: Text(
                                      category,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                    ),
                                  );
                                },
                              )
                              .toList(),
                          onChanged: categories
                                  .isEmpty
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    selectedCategory =
                                        value;
                                  });
                                },
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Kategori wajib dipilih.';
                            }

                            return null;
                          },
                        ),
                        if (categories.isEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(
                              top: 8,
                            ),
                            child: Align(
                              alignment:
                                  Alignment.centerLeft,
                              child: Text(
                                'Belum ada kategori. '
                                'Tambahkan kategori di Pengaturan.',
                                style: TextStyle(
                                  color:
                                      Theme.of(context)
                                          .colorScheme
                                          .error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<
                            RecurringFrequency>(
                          initialValue:
                              selectedFrequency,
                          decoration:
                              const InputDecoration(
                            labelText: 'Frekuensi',
                            prefixIcon: Icon(
                              Icons.repeat_rounded,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem<
                                RecurringFrequency>(
                              value:
                                  RecurringFrequency.weekly,
                              child: Text(
                                'Mingguan',
                              ),
                            ),
                            DropdownMenuItem<
                                RecurringFrequency>(
                              value:
                                  RecurringFrequency.monthly,
                              child: Text(
                                'Bulanan',
                              ),
                            ),
                            DropdownMenuItem<
                                RecurringFrequency>(
                              value:
                                  RecurringFrequency.yearly,
                              child: Text(
                                'Tahunan',
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setDialogState(() {
                              selectedFrequency =
                                  value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          borderRadius:
                              BorderRadius.circular(12),
                          onTap: () async {
                            final selected =
                                await showDatePicker(
                              context: context,
                              initialDate:
                                  selectedStartDate,
                              firstDate:
                                  DateTime(2020),
                              lastDate:
                                  DateTime(2100),
                              helpText:
                                  'Pilih tanggal mulai',
                              cancelText: 'Batal',
                              confirmText: 'Pilih',
                            );

                            if (selected ==
                                null) {
                              return;
                            }

                            setDialogState(() {
                              selectedStartDate =
                                  DateTime(
                                selected.year,
                                selected.month,
                                selected.day,
                              );
                            });
                          },
                          child: InputDecorator(
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Tanggal mulai',
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                              ),
                            ),
                            child: Text(
                              _formatDate(
                                selectedStartDate,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        dialogContext,
                      ).pop(false);
                    },
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!
                          .validate()) {
                        return;
                      }

                      final normalized =
                          amountController.text
                              .trim()
                              .replaceAll(
                                '.',
                                '',
                              )
                              .replaceAll(
                                ',',
                                '.',
                              );

                      final amount =
                          double.tryParse(
                        normalized,
                      );

                      if (amount == null ||
                          amount <= 0 ||
                          selectedCategory ==
                              null) {
                        return;
                      }

                      final success =
                          recurring == null
                              ? await store
                                  .addRecurringTransaction(
                                  title:
                                      titleController
                                          .text
                                          .trim(),
                                  amount: amount,
                                  type: selectedType,
                                  account: account,
                                  category:
                                      selectedCategory!,
                                  startDate:
                                      selectedStartDate,
                                  frequency:
                                      selectedFrequency,
                                )
                              : await store
                                  .updateRecurringTransaction(
                                  id: recurring.id!,
                                  title:
                                      titleController
                                          .text
                                          .trim(),
                                  amount: amount,
                                  type: selectedType,
                                  account: account,
                                  category:
                                      selectedCategory!,
                                  startDate:
                                      selectedStartDate,
                                  frequency:
                                      selectedFrequency,
                                );

                      if (!dialogContext.mounted) {
                        return;
                      }

                      Navigator.of(
                        dialogContext,
                      ).pop(success);
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted || saved != true) {
        return;
      }

      _refresh();

      _showMessage(
        recurring == null
            ? 'Transaksi berulang berhasil ditambahkan.'
            : 'Transaksi berulang berhasil diperbarui.',
      );
    } finally {
      titleController.dispose();
      amountController.dispose();
    }
  }

  Future<void> _toggleRecurring(
    RecurringTransaction recurring,
  ) async {
    final id = recurring.id;

    if (id == null) {
      return;
    }

    final store = FinanceScope.of(context);

    final success =
        await store.setRecurringTransactionActive(
      id: id,
      active: !recurring.isActive,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _refresh();

      _showMessage(
        recurring.isActive
            ? 'Transaksi berulang dinonaktifkan.'
            : 'Transaksi berulang diaktifkan.',
      );
    } else {
      _showMessage(
        'Status transaksi berulang gagal diubah.',
      );
    }
  }

  Future<void> _deleteRecurring(
    RecurringTransaction recurring,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Hapus Transaksi Berulang?',
          ),
          content: Text(
            'Jadwal "${recurring.title}" akan dihapus. '
            'Transaksi yang sudah dibuat sebelumnya tidak ikut dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    final id = recurring.id;

    if (id == null) {
      _showMessage(
        'ID transaksi berulang tidak valid.',
      );
      return;
    }

    final store = FinanceScope.of(context);

    final success =
        await store.deleteRecurringTransaction(id);

    if (!mounted) {
      return;
    }

    if (success) {
      _refresh();

      _showMessage(
        'Transaksi berulang berhasil dihapus.',
      );
    } else {
      _showMessage(
        'Transaksi berulang gagal dihapus.',
      );
    }
  }

  Future<void> _generateDueTransactions() async {
    final store = FinanceScope.of(context);

    final count =
        await store.generateDueRecurringTransactions();

    if (!mounted) {
      return;
    }

    _refresh();

    if (count == 0) {
      _showMessage(
        'Tidak ada transaksi berulang yang perlu dibuat.',
      );
      return;
    }

    _showMessage(
      '$count transaksi berulang berhasil dibuat.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Widget _buildRecurringCard(
    RecurringTransaction recurring,
  ) {
    final isIncome = recurring.isIncome;
    final secondaryText = _textSecondary;
    final iconBackground = isIncome ? _incomeSoft : _expenseSoft;
    final amountColor = isIncome ? _incomeColor : _expenseColor;
    final accentColor = isIncome ? _incomeColor : _expenseColor;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          8,
          16,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                _typeIcon(
                  TransactionType.values.byName(
                    recurring.type,
                  ),
                ),
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recurring.title,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!recurring.isActive)
                        Chip(
                          label: const Text(
                            'Nonaktif',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          backgroundColor: _surfaceSoft,
                          side: BorderSide(color: _borderColor),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${recurring.category} • '
                    '${_typeLabel(TransactionType.values.byName(recurring.type))}',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${isIncome ? '+' : '-'}'
                    '${_formatRupiah(recurring.amount)}',
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_frequencyDescription(recurring.frequency)} • '
                    'mulai ${_formatDate(recurring.startDate)}',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  if (recurring.lastGeneratedDate !=
                      null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Terakhir dibuat '
                      '${_formatDate(recurring.lastGeneratedDate!)}',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip:
                  'Menu transaksi berulang',
              onSelected: (value) {
                if (value == 'edit') {
                  _showRecurringDialog(
                    recurring: recurring,
                  );
                } else if (value ==
                    'toggle') {
                  _toggleRecurring(
                    recurring,
                  );
                } else if (value ==
                    'delete') {
                  _deleteRecurring(
                    recurring,
                  );
                }
              },
              itemBuilder: (context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: Icon(
                        Icons.edit_outlined,
                      ),
                      title: Text('Edit'),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'toggle',
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: Icon(
                        recurring.isActive
                            ? Icons
                                .pause_circle_outline
                            : Icons
                                .play_circle_outline,
                      ),
                      title: Text(
                        recurring.isActive
                            ? 'Nonaktifkan'
                            : 'Aktifkan',
                      ),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline,
                      ),
                      title: Text('Hapus'),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String account,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: _borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: _isDark
                    ? const Color(0xFF46506A)
                    : const Color(0xFFE8EEFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.repeat_rounded,
                size: 34,
                color: _isDark
                    ? const Color(0xFF9CB3F4)
                    : const Color(0xFF6F8FEA),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada transaksi berulang',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Buat jadwal pemasukan atau pengeluaran '
              'otomatis untuk akun $account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                _showRecurringDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'Tambah Transaksi Berulang',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);
    final account = store.activeAccount;

    if (account == null) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Transaksi Berulang',
            ),
          ),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada akun keuangan aktif.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    if (_futureAccount != account) {
      _futureAccount = account;
      _recurringFuture =
          store.getRecurringTransactions(
        account: account,
      );
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Transaksi Berulang',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Buat transaksi jatuh tempo',
              onPressed:
                  _generateDueTransactions,
              icon: const Icon(
                Icons.playlist_add_check_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: _refresh,
              icon: const Icon(
                Icons.refresh,
              ),
            ),
          ],
        ),
        floatingActionButton:
            FloatingActionButton.extended(
          onPressed: () {
            _showRecurringDialog();
          },
          backgroundColor: _isDark
              ? const Color(0xFF9CB3F4)
              : const Color(0xFF6F8FEA),
          foregroundColor: _isDark
              ? const Color(0xFF20242A)
              : Colors.white,
          icon: const Icon(Icons.add),
          label: const Text(
            'Transaksi',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: FutureBuilder<
            List<RecurringTransaction>>(
          future: _recurringFuture,
          builder: (
            context,
            snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gagal memuat transaksi berulang.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(
                          Icons.refresh,
                        ),
                        label: const Text(
                          'Coba Lagi',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final recurring =
                snapshot.data ??
                    <RecurringTransaction>[];

            if (recurring.isEmpty) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  120,
                ),
                children: [
                  Text(
                    account,
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildEmptyState(
                    account,
                  ),
                ],
              );
            }

            final activeCount =
                recurring
                    .where(
                      (item) =>
                          item.isActive,
                    )
                    .length;

            return RefreshIndicator(
              onRefresh: () async {
                _refresh();
                await _recurringFuture;
              },
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  120,
                ),
                children: [
                  Text(
                    account,
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryItem(
                              label: 'Total jadwal',
                              value:
                                  '${recurring.length}',
                            ),
                          ),
                          Expanded(
                            child: _SummaryItem(
                              label: 'Aktif',
                              value:
                                  '$activeCount',
                            ),
                          ),
                          Expanded(
                            child: _SummaryItem(
                              label: 'Nonaktif',
                              value:
                                  '${recurring.length - activeCount}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Jadwal Transaksi',
                          style:
                              TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed:
                            _generateDueTransactions,
                        icon: const Icon(
                          Icons
                              .playlist_add_check_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Proses',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...recurring.map(
                    _buildRecurringCard,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
