import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
import '../services/budget_store.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({
    super.key,
  });

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  Future<void> _pickMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih bulan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        selected.year,
        selected.month,
      );
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
  }

  String _monthName(int month) {
    const months = [
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

    return months[month - 1];
  }

  String _formatRupiah(double value) {
    final rounded = value.round();
    final digits = rounded.toString();

    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(digits[i]);
    }

    return 'Rp $buffer';
  }

  Future<void> _showBudgetDialog({
    required BudgetStore budgetStore,
    required String account,
    Budget? budget,
    required List<String> categories,
  }) async {
    final controller = TextEditingController(
      text: budget == null
          ? ''
          : budget.limit.round().toString(),
    );

    String? selectedCategory = budget?.category;

    if (selectedCategory == null &&
        categories.isNotEmpty) {
      selectedCategory = categories.first;
    }

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                budget == null
                    ? 'Tambah Anggaran'
                    : 'Edit Anggaran',
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (budget == null)
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          prefixIcon: Icon(
                            Icons.category_outlined,
                          ),
                        ),
                        items: categories.map(
                          (category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        },
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Pilih kategori.';
                          }

                          return null;
                        },
                      )
                    else
                      InputDecorator(
                        decoration:
                            const InputDecoration(
                          labelText: 'Kategori',
                          prefixIcon: Icon(
                            Icons.category_outlined,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            budget.category,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Batas anggaran',
                        hintText: 'Contoh: 1000000',
                        prefixIcon: Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                        prefixText: 'Rp ',
                      ),
                      validator: (value) {
                        final text =
                            (value ?? '').trim();

                        if (text.isEmpty) {
                          return 'Nominal wajib diisi.';
                        }

                        final normalized =
                            text.replaceAll('.', '')
                                .replaceAll(',', '.');

                        final amount =
                            double.tryParse(normalized);

                        if (amount == null ||
                            amount <= 0) {
                          return 'Nominal tidak valid.';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!
                        .validate()) {
                      return;
                    }

                    final normalized = controller.text
                        .trim()
                        .replaceAll('.', '')
                        .replaceAll(',', '.');

                    final amount =
                        double.tryParse(normalized);

                    if (amount == null ||
                        amount <= 0) {
                      return;
                    }

                    if (budget == null &&
                        selectedCategory == null) {
                      return;
                    }

                    bool success;

                    if (budget == null) {
                      success =
                          await budgetStore.saveBudget(
                        account: account,
                        category: selectedCategory!,
                        amount: amount,
                        month: _selectedMonth,
                      );
                    } else {
                      success =
                          await budgetStore.updateBudget(
                        id: budget.id!,
                        amount: amount,
                      );
                    }

                    if (!dialogContext.mounted) {
                      return;
                    }

                    Navigator.of(dialogContext)
                        .pop(success);
                  },
                  child: Text(
                    budget == null
                        ? 'Tambah'
                        : 'Simpan',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (!mounted || result == null) {
      return;
    }

    if (result) {
      setState(() {});
      _showMessage(
        budget == null
            ? 'Anggaran berhasil ditambahkan.'
            : 'Anggaran berhasil diperbarui.',
      );
    } else {
      _showMessage(
        budget == null
            ? 'Anggaran gagal ditambahkan. '
                'Mungkin kategori sudah memiliki anggaran '
                'untuk bulan ini.'
            : 'Anggaran gagal diperbarui.',
      );
    }
  }

  Future<void> _showDeleteBudgetDialog({
    required BudgetStore budgetStore,
    required Budget budget,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Anggaran?'),
          content: Text(
            'Anggaran kategori "${budget.category}" '
            'untuk ${_monthName(budget.month.month)} '
            '${budget.month.year} akan dihapus.',
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

    if (!mounted || confirmed != true) {
      return;
    }

    final id = budget.id;

    if (id == null) {
      _showMessage(
        'Anggaran tidak memiliki ID yang valid.',
      );
      return;
    }

    final success = await budgetStore.deleteBudget(id);

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {});
    }

    _showMessage(
      success
          ? 'Anggaran berhasil dihapus.'
          : 'Anggaran gagal dihapus.',
    );
  }

  Future<void> _showAddBudgetDialog({
    required BudgetStore budgetStore,
    required String account,
  }) async {
    final categories = await _getCategories();

    if (!mounted) {
      return;
    }

    if (categories.isEmpty) {
      _showMessage(
        'Belum ada kategori. Tambahkan kategori terlebih dahulu '
        'di Pengaturan.',
      );
      return;
    }

    await _showBudgetDialog(
      budgetStore: budgetStore,
      account: account,
      categories: categories,
    );
  }

  Future<List<String>> _getCategories() async {
    final store = FinanceScope.of(context);

    final categories = await store.getCategories(
      account: store.activeAccount,
    );

    categories.sort(
      (a, b) => a.toLowerCase().compareTo(
        b.toLowerCase(),
      ),
    );

    return categories;
  }

  String _statusText(Budget budget) {
    if (budget.isOverBudget) {
      return 'Melebihi anggaran';
    }

    if (budget.limit > 0 &&
        budget.spent / budget.limit >= 0.8) {
      return 'Hampir mencapai batas';
    }

    return 'Masih dalam batas';
  }

  IconData _statusIcon(Budget budget) {
    if (budget.isOverBudget) {
      return Icons.warning_amber_rounded;
    }

    if (budget.limit > 0 &&
        budget.spent / budget.limit >= 0.8) {
      return Icons.info_outline;
    }

    return Icons.check_circle_outline;
  }

  Color _statusColor(Budget budget) {
    if (budget.isOverBudget) {
      return Colors.redAccent;
    }

    if (budget.limit > 0 &&
        budget.spent / budget.limit >= 0.8) {
      return Colors.orangeAccent;
    }

    return Colors.greenAccent;
  }

  Widget _buildBudgetCard({
    required BudgetStore budgetStore,
    required Budget budget,
  }) {
    final percentage =
        budget.limit <= 0
            ? 0.0
            : budget.spent / budget.limit;

    final progress = percentage.clamp(0.0, 1.0);
    final statusColor = _statusColor(budget);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF30343A),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                  ),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Batas ${_formatRupiah(budget.limit)}',
                        style: const TextStyle(
                          color: Color(0xFF9A9DA3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Menu anggaran',
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _showBudgetDialog(
                        budgetStore: budgetStore,
                        account: budget.account,
                        budget: budget,
                        categories: [
                          budget.category,
                        ],
                      );
                    } else if (value == 'delete') {
                      await _showDeleteBudgetDialog(
                        budgetStore: budgetStore,
                        budget: budget,
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                          ),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                          ),
                          SizedBox(width: 10),
                          Text('Hapus'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Terpakai',
                        style: TextStyle(
                          color: Color(0xFF9A9DA3),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRupiah(budget.spent),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Sisa',
                      style: TextStyle(
                        color: Color(0xFF9A9DA3),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRupiah(
                        budget.remaining,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: budget.isOverBudget
                            ? Colors.redAccent
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor:
                    const Color(0xFF30343A),
                valueColor:
                    AlwaysStoppedAnimation<Color>(
                  statusColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _statusIcon(budget),
                  size: 17,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _statusText(budget),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${(percentage * 100).round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary({
    required double totalBudget,
    required double totalSpent,
  }) {
    final remaining =
        totalBudget - totalSpent;

    final percentage =
        totalBudget <= 0
            ? 0.0
            : totalSpent / totalBudget;

    final progress =
        percentage.clamp(0.0, 1.0);

    final isOver = totalSpent > totalBudget;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Bulan Ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    label: 'Anggaran',
                    value:
                        _formatRupiah(totalBudget),
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    label: 'Terpakai',
                    value:
                        _formatRupiah(totalSpent),
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    label: 'Sisa',
                    value:
                        _formatRupiah(remaining),
                    valueColor: isOver
                        ? Colors.redAccent
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor:
                    const Color(0xFF30343A),
                valueColor:
                    AlwaysStoppedAnimation<Color>(
                  isOver
                      ? Colors.redAccent
                      : Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              totalBudget <= 0
                  ? 'Belum ada anggaran bulan ini.'
                  : isOver
                      ? 'Pengeluaran sudah melebihi total anggaran.'
                      : '${(percentage * 100).round()}% dari total anggaran telah digunakan.',
              style: TextStyle(
                color: isOver
                    ? Colors.redAccent
                    : const Color(0xFF9A9DA3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
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
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final financeStore =
        FinanceScope.of(context);

    final account =
        financeStore.activeAccount;

    if (account == null) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Anggaran'),
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

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Anggaran'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final budgetStore =
                BudgetStore();

            await budgetStore.load();

            if (!mounted) {
              await budgetStore.close();
              return;
            }

            await _showAddBudgetDialog(
              budgetStore: budgetStore,
              account: account,
            );

            await budgetStore.close();
          },
          icon: const Icon(Icons.add),
          label: const Text('Anggaran'),
        ),
        body: FutureBuilder<BudgetStore>(
          future: _createBudgetStore(),
          builder: (
            context,
            snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData) {
              return Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(24),
                  child: Text(
                    'Gagal memuat anggaran.'
                    '${snapshot.error == null ? '' : '\n${snapshot.error}'}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final budgetStore =
                snapshot.data!;

            return FutureBuilder<List<Budget>>(
              future: budgetStore.getBudgets(
                account: account,
                month: _selectedMonth,
              ),
              builder: (
                context,
                budgetSnapshot,
              ) {
                if (budgetSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (budgetSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(24),
                      child: Text(
                        'Gagal memuat data anggaran:\n'
                        '${budgetSnapshot.error}',
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  );
                }

                final budgets =
                    budgetSnapshot.data ??
                        <Budget>[];

                final totalBudget =
                    budgets.fold<double>(
                  0,
                  (sum, item) =>
                      sum + item.limit,
                );

                final totalSpent =
                    budgets.fold<double>(
                  0,
                  (sum, item) =>
                      sum + item.spent,
                );

                return ListView(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    120,
                  ),
                  children: [
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip:
                                  'Bulan sebelumnya',
                              onPressed: () {
                                _changeMonth(-1);
                              },
                              icon: const Icon(
                                Icons
                                    .chevron_left,
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                                onTap:
                                    _pickMonth,
                                child: Padding(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Periode',
                                        style:
                                            TextStyle(
                                          color: Color(
                                            0xFF9A9DA3,
                                          ),
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Text(
                                        '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                                        textAlign:
                                            TextAlign
                                                .center,
                                        style:
                                            const TextStyle(
                                          fontSize: 17,
                                          fontWeight:
                                              FontWeight
                                                  .w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip:
                                  'Bulan berikutnya',
                              onPressed: () {
                                _changeMonth(1);
                              },
                              icon: const Icon(
                                Icons
                                    .chevron_right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildSummary(
                      totalBudget:
                          totalBudget,
                      totalSpent:
                          totalSpent,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Anggaran per Kategori',
                            style:
                                TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${budgets.length} kategori',
                          style:
                              const TextStyle(
                            color:
                                Color(0xFF9A9DA3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (budgets.isEmpty)
                      Card(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            24,
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons
                                    .account_balance_wallet_outlined,
                                size: 46,
                              ),
                              const SizedBox(
                                height: 14,
                              ),
                              const Text(
                                'Belum ada anggaran',
                                style:
                                    TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Text(
                                'Buat batas pengeluaran untuk '
                                'kategori pada ${_monthName(_selectedMonth.month)} '
                                '${_selectedMonth.year}.',
                                textAlign:
                                    TextAlign.center,
                                style:
                                    const TextStyle(
                                  color:
                                      Color(
                                    0xFF9A9DA3,
                                  ),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(
                                height: 18,
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await _showAddBudgetDialog(
                                    budgetStore:
                                        budgetStore,
                                    account:
                                        account,
                                  );
                                },
                                icon:
                                    const Icon(
                                  Icons.add,
                                ),
                                label:
                                    const Text(
                                  'Tambah Anggaran',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...budgets.map(
                        (budget) =>
                            _buildBudgetCard(
                          budgetStore:
                              budgetStore,
                          budget: budget,
                        ),
                      ),
                    const SizedBox(height: 18),
                    Container(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      decoration:
                          BoxDecoration(
                        color: const Color(
                          0xFF1C1E22,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Color(
                              0xFF9A9DA3,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pengeluaran dihitung dari transaksi '
                              'berjenis Pengeluaran pada akun dan bulan '
                              'yang sedang dipilih.',
                              style:
                                  TextStyle(
                                color: Color(
                                  0xFF9A9DA3,
                                ),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<BudgetStore> _createBudgetStore() async {
    final store = BudgetStore();
    await store.load();
    return store;
  }
}
