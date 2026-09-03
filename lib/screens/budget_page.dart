import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/finance_scope.dart';
import '../core/nominal_input_formatter.dart';
import '../services/budget_store.dart';
import '../services/finance_store.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({
    super.key,
  });

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late final BudgetStore _budgetStore;

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  Future<_BudgetPageData>? _dataFuture;
  String? _futureKey;

  @override
  void initState() {
    super.initState();

    _budgetStore = BudgetStore();
  }

  @override
  void dispose() {
    _budgetStore.close();
    super.dispose();
  }

  Color get _textSecondary => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _surfaceSoft => Theme.of(context).colorScheme.surfaceContainerLow;
  Color get _successColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF86CBBB)
      : const Color(0xFF4F8A68);
  Color get _warningColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFE1B47A)
      : const Color(0xFFB07A3A);
  Color get _dangerColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFE39A9A)
      : const Color(0xFFB85C5C);

  Future<_BudgetPageData> _loadData({
    required String account,
    required FinanceStore financeStore,
  }) async {
    await _budgetStore.load();

    final budgets = await _budgetStore.getBudgets(
      account: account,
      month: _selectedMonth,
    );

    final totalBudget = budgets.fold<double>(
      0,
      (sum, item) => sum + item.limit,
    );

    final totalSpent = await financeStore.getTotalExpense(
      account: account,
      startDate: DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
      ),
      endDate: DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      ),
    );

    return _BudgetPageData(
      budgets: budgets,
      totalBudget: totalBudget,
      totalSpent: totalSpent,
    );
  }

  void _ensureFuture({
    required String account,
    required FinanceStore financeStore,
  }) {
    final key =
        '$account-${_selectedMonth.year}-${_selectedMonth.month}';

    if (_futureKey == key && _dataFuture != null) {
      return;
    }

    _futureKey = key;

    _dataFuture = _loadData(
      account: account,
      financeStore: financeStore,
    );
  }

  void _refresh() {
    final financeStore = FinanceScope.of(context);
    final account = financeStore.activeAccount;

    if (account == null || !mounted) {
      return;
    }

    setState(() {
      _futureKey = null;

      _dataFuture = _loadData(
        account: account,
        financeStore: financeStore,
      );

      _futureKey =
          '$account-${_selectedMonth.year}-${_selectedMonth.month}';
    });
  }

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

      _futureKey = null;
      _dataFuture = null;
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );

      _futureKey = null;
      _dataFuture = null;
    });
  }

  String _monthName(int month) {
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

    return months[month - 1];
  }

  String _formatRupiah(double value) {
    final rounded = value.round();

    if (rounded < 0) {
      return '-${_formatRupiah(-value)}';
    }

    final digits = rounded.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 &&
          (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(digits[i]);
    }

    return 'Rp $buffer';
  }

  Future<void> _showBudgetDialog({
    required String account,
    Budget? budget,
  }) async {
    final categories = await _getCategories();

    if (!mounted) {
      return;
    }

    if (budget == null && categories.isEmpty) {
      _showMessage(
        'Belum ada kategori. Tambahkan kategori terlebih dahulu '
        'di Pengaturan.',
      );
      return;
    }

    final controller = TextEditingController(
      text: budget == null
          ? ''
          : formatNominalInput(budget.limit),
    );

    String? selectedCategory = budget?.category;

    if (selectedCategory == null &&
        categories.isNotEmpty) {
      selectedCategory = categories.first;
    }

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<_BudgetDialogResult>(
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
                        decoration:
                            const InputDecoration(
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
                          alignment:
                              Alignment.centerLeft,
                          child: Text(
                            budget.category,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
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
                      inputFormatters: const <TextInputFormatter>[
                        NominalInputFormatter(),
                      ],
                      decoration:
                          const InputDecoration(
                        labelText: 'Batas anggaran',
                        hintText: 'Contoh: 1.000.000',
                        prefixIcon: Icon(
                          Icons
                              .account_balance_wallet_outlined,
                        ),
                        prefixText: 'Rp ',
                      ),
                      validator: (value) {
                        final text =
                            (value ?? '').trim();

                        if (text.isEmpty) {
                          return 'Nominal wajib diisi.';
                        }

                        final amount =
                            parseNominalInput(text);

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
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!
                        .validate()) {
                      return;
                    }

                    final amount =
                        parseNominalInput(controller.text);

                    if (amount == null ||
                        amount <= 0) {
                      return;
                    }

                    if (budget == null &&
                        selectedCategory == null) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      _BudgetDialogResult(
                        category:
                            selectedCategory ??
                                budget?.category,
                        amount: amount,
                      ),
                    );
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

    bool success;

    if (budget == null) {
      final category = result.category;

      if (category == null) {
        return;
      }

      success = await _budgetStore.saveBudget(
        account: account,
        category: category,
        amount: result.amount,
        month: _selectedMonth,
      );
    } else {
      final id = budget.id;

      if (id == null) {
        _showMessage(
          'Anggaran tidak memiliki ID yang valid.',
        );
        return;
      }

      success = await _budgetStore.updateBudget(
        id: id,
        amount: result.amount,
      );
    }

    if (!mounted) {
      return;
    }

    if (success) {
      _refresh();

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

  Future<void> _showDeleteBudgetDialog(
    Budget budget,
  ) async {
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
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
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

    final success =
        await _budgetStore.deleteBudget(id);

    if (!mounted) {
      return;
    }

    if (success) {
      _refresh();
      _showMessage(
        'Anggaran berhasil dihapus.',
      );
    } else {
      _showMessage(
        'Anggaran gagal dihapus.',
      );
    }
  }

  Future<void> _showAddBudgetDialog(
    String account,
  ) async {
    await _showBudgetDialog(
      account: account,
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
      return 'Terlampaui';
    }

    if (budget.limit > 0 &&
        budget.spent / budget.limit >= 0.8) {
      return 'Hampir habis';
    }

    return 'Aman';
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
      return _dangerColor;
    }

    if (budget.limit > 0 &&
        budget.spent / budget.limit >= 0.8) {
      return _warningColor;
    }

    return _successColor;
  }

  Widget _buildBudgetCard({
    required Budget budget,
    required String account,
  }) {
    final percentage = budget.limit <= 0
        ? 0.0
        : budget.spent / budget.limit;

    final progress =
        percentage.clamp(0.0, 1.0);

    final statusColor =
        _statusColor(budget);

    final remaining = budget.remaining;

    final percentageText =
        '${(percentage * 100).round()}%';

    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
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
                    color: _surfaceSoft,
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
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Batas ${_formatRupiah(budget.limit)}',
                        style:
                            const TextStyle(
                          color:
                              Color(0xFF9A9DA3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Menu anggaran',
                  onSelected:
                      (value) async {
                    if (value == 'edit') {
                      await _showBudgetDialog(
                        account: account,
                        budget: budget,
                      );
                    } else if (
                        value == 'delete') {
                      await _showDeleteBudgetDialog(
                        budget,
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
                          color:
                              Color(0xFF9A9DA3),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRupiah(
                          budget.spent,
                        ),
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w800,
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
                        color:
                            Color(0xFF9A9DA3),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRupiah(
                        remaining,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            budget.isOverBudget
                                ? const Color(0xFFB85C5C)
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
                backgroundColor: _surfaceSoft,
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
                  percentageText,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w800,
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

    final percentage = totalBudget <= 0
        ? 0.0
        : totalSpent / totalBudget;

    final progress =
        percentage.clamp(0.0, 1.0);

    final isOver =
        totalSpent > totalBudget;

    final hasBudget =
        totalBudget > 0;

    final statusColor = !hasBudget
        ? _textSecondary
        : isOver
            ? _dangerColor
            : percentage >= 0.8
                ? _warningColor
                : _successColor;

    String statusTitle;

    if (!hasBudget) {
      statusTitle = 'Belum ada anggaran';
    } else if (isOver) {
      statusTitle =
          'Anggaran sudah terlampaui';
    } else if (percentage >= 0.8) {
      statusTitle =
          'Anggaran mulai menipis';
    } else {
      statusTitle = 'Anggaran masih aman';
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ringkasan Bulan Ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    statusTitle,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    label: 'Anggaran',
                    value:
                        _formatRupiah(
                      totalBudget,
                    ),
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    label: 'Terpakai',
                    value:
                        _formatRupiah(
                      totalSpent,
                    ),
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    label: 'Sisa',
                    value:
                        _formatRupiah(
                      remaining,
                    ),
                    valueColor:
                        !hasBudget
                            ? null
                            : isOver
                                ? Colors
                                    .redAccent
                                : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child:
                  LinearProgressIndicator(
                value:
                    hasBudget
                        ? progress
                        : 0,
                minHeight: 10,
                backgroundColor: _surfaceSoft,
                valueColor:
                    AlwaysStoppedAnimation<
                        Color>(
                  statusColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              !hasBudget
                  ? 'Belum ada anggaran bulan ini.'
                  : isOver
                      ? 'Pengeluaran sudah melebihi total anggaran.'
                      : percentage >= 0.8
                          ? 'Penggunaan anggaran sudah mendekati batas.'
                          : '${(percentage * 100).round()}% dari total anggaran telah digunakan.',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                height: 1.35,
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
          style: TextStyle(
            color: _textSecondary,
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

  Widget _buildMonthSelector() {
    final now = DateTime.now();

    final isCurrentMonth =
        _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;

    return Card(
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
                Icons.chevron_left,
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(14),
                onTap: _pickMonth,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Periode',
                        style: TextStyle(
                          color:
                              Color(0xFF9A9DA3),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_monthName(_selectedMonth.month)} '
                        '${_selectedMonth.year}',
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      if (isCurrentMonth)
                        const Padding(
                          padding:
                              EdgeInsets.only(
                            top: 3,
                          ),
                          child: Text(
                            'Bulan ini',
                            style:
                                TextStyle(
                              color: Color(
                                0xFF9A9DA3,
                              ),
                              fontSize: 10,
                            ),
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
                Icons.chevron_right,
              ),
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
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons
                  .account_balance_wallet_outlined,
              size: 46,
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada anggaran',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Buat batas pengeluaran untuk kategori pada '
              '${_monthName(_selectedMonth.month)} '
              '${_selectedMonth.year}.',
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
                _showAddBudgetDialog(
                  account,
                );
              },
              icon:
                  const Icon(Icons.add),
              label: const Text(
                'Tambah Anggaran',
              ),
            ),
          ],
        ),
      ),
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
            title:
                const Text('Anggaran'),
          ),
          body: const Center(
            child: Padding(
              padding:
                  EdgeInsets.all(24),
              child: Text(
                'Belum ada akun keuangan aktif.',
                textAlign:
                    TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    _ensureFuture(
      account: account,
      financeStore: financeStore,
    );

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Anggaran',
          ),
          actions: [
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
            _showAddBudgetDialog(
              account,
            );
          },
          icon:
              const Icon(Icons.add),
          label:
              const Text('Anggaran'),
        ),
        body:
            FutureBuilder<_BudgetPageData>(
          future: _dataFuture,
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

            if (snapshot.hasError ||
                !snapshot.hasData) {
              return Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 42,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        'Gagal memuat data anggaran.'
                        '${snapshot.error == null ? '' : '\n${snapshot.error}'}',
                        textAlign:
                            TextAlign.center,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      OutlinedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(
                          Icons.refresh,
                        ),
                        label:
                            const Text(
                          'Coba Lagi',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data =
                snapshot.data!;

            final budgets =
                data.budgets;

            return RefreshIndicator(
              onRefresh: () async {
                _refresh();

                await Future<void>.delayed(
                  const Duration(
                    milliseconds: 300,
                  ),
                );
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
                  _buildMonthSelector(),
                  const SizedBox(
                    height: 14,
                  ),
                  _buildSummary(
                    totalBudget:
                        data.totalBudget,
                    totalSpent:
                        data.totalSpent,
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Anggaran per Kategori',
                          style: TextStyle(
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
                  const SizedBox(
                    height: 12,
                  ),
                  if (budgets.isEmpty)
                    _buildEmptyState(
                      account,
                    )
                  else
                    ...budgets.map(
                      (budget) =>
                          _buildBudgetCard(
                        budget: budget,
                        account: account,
                      ),
                    ),
                  const SizedBox(
                    height: 18,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    decoration:
                        BoxDecoration(
                      color: _surfaceSoft,
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
                        SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            'Pengeluaran pada ringkasan dihitung dari '
                            'seluruh transaksi berjenis Pengeluaran '
                            'pada akun dan bulan yang sedang dipilih. '
                            'Nilai Terpakai pada setiap kartu hanya '
                            'menghitung kategori tersebut.',
                            style: TextStyle(
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BudgetPageData {
  const _BudgetPageData({
    required this.budgets,
    required this.totalBudget,
    required this.totalSpent,
  });

  final List<Budget> budgets;
  final double totalBudget;
  final double totalSpent;
}

class _BudgetDialogResult {
  const _BudgetDialogResult({
    required this.category,
    required this.amount,
  });

  final String? category;
  final double amount;
}
