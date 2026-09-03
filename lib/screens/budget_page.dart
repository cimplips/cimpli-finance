import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
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
          : budget.limit.round().toString(),
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
                      decoration:
                          const InputDecoration(
                        labelText: 'Batas anggaran',
                        hintText: 'Contoh: 1000000',
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

                        final normalized = text
                            .replaceAll('.', '')
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
      return const Color(0xFFB85C5C);
    }

    if (budget.limit > 0 &&
        budget.spent / budget.limit >= 0.8) {
      return const Color(0xFFB07A3A);
    }

    return const Color(0xFF4F8A68);
  }

  Color _statusColor(Budget budget) {
    if (budget.isOverBudget) return const Color(0xFFE06A78);
    if (budget.limit > 0 && budget.spent / budget.limit >= 0.8) {
      return const Color(0xFFD39A4A);
    }
    return const Color(0xFF35B47A);
  }

  String _statusText(Budget budget) {
    if (budget.isOverBudget) return 'Terlampaui';
    if (budget.limit > 0 && budget.spent / budget.limit >= 0.8) {
      return 'Hampir habis';
    }
    return 'Aman';
  }

  IconData _statusIcon(Budget budget) {
    if (budget.isOverBudget) return Icons.warning_amber_rounded;
    if (budget.limit > 0 && budget.spent / budget.limit >= 0.8) {
      return Icons.info_outline_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  Widget _buildBudgetCard({
    required Budget budget,
    required String account,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final percentage = budget.limit <= 0 ? 0.0 : budget.spent / budget.limit;
    final progress = percentage.clamp(0.0, 1.0);
    final statusColor = _statusColor(budget);
    final remaining = budget.remaining;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.55 : 0.75),
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: isDark ? 0.5 : 0.7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.category_rounded,
                    color: scheme.onPrimaryContainer,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Batas ${_formatRupiah(budget.limit)}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Menu anggaran',
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _showBudgetDialog(account: account, budget: budget);
                    } else if (value == 'delete') {
                      await _showDeleteBudgetDialog(budget);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 19),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 19),
                          SizedBox(width: 10),
                          Text('Hapus'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 19),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _metric(
                    'Terpakai',
                    _formatRupiah(budget.spent),
                  ),
                ),
                const SizedBox(width: 12),
                _metric(
                  'Sisa',
                  _formatRupiah(remaining),
                  valueColor: budget.isOverBudget ? statusColor : null,
                  alignEnd: true,
                ),
              ],
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(_statusIcon(budget), size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  _statusText(budget),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(percentage * 100).round()}%',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    String label,
    String value, {
    Color? valueColor,
    bool alignEnd = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary({
    required double totalBudget,
    required double totalSpent,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = totalBudget - totalSpent;
    final hasBudget = totalBudget > 0;
    final percentage = hasBudget ? totalSpent / totalBudget : 0.0;
    final progress = percentage.clamp(0.0, 1.0);
    final isOver = totalSpent > totalBudget;
    final statusColor = !hasBudget
        ? scheme.onSurfaceVariant
        : isOver
            ? const Color(0xFFE06A78)
            : percentage >= 0.8
                ? const Color(0xFFD39A4A)
                : const Color(0xFF35B47A);

    final status = !hasBudget
        ? 'Belum ada anggaran'
        : isOver
            ? 'Melewati batas'
            : percentage >= 0.8
                ? 'Perlu diperhatikan'
                : 'Masih aman';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [scheme.surfaceContainerHighest, scheme.surface]
              : [scheme.primaryContainer, scheme.surface],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Bulan Ini',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pantau penggunaan seluruh anggaranmu.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _metric('Anggaran', _formatRupiah(totalBudget))),
              Expanded(child: _metric('Terpakai', _formatRupiah(totalSpent))),
              Expanded(
                child: _metric(
                  'Sisa',
                  _formatRupiah(remaining),
                  valueColor: isOver ? statusColor : null,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: hasBudget ? progress : 0,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            !hasBudget
                ? 'Belum ada anggaran pada bulan ini.'
                : isOver
                    ? 'Pengeluaran sudah melebihi total anggaran.'
                    : '${(percentage * 100).round()}% dari total anggaran telah digunakan.',
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bulan sebelumnya',
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickMonth,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      'PERIODE',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isCurrentMonth)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'Bulan ini',
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Bulan berikutnya',
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String account) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: scheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada anggaran',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Buat batas pengeluaran untuk kategori pada ${_monthName(_selectedMonth.month)} ${_selectedMonth.year}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _showAddBudgetDialog(account),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Anggaran'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final financeStore = FinanceScope.of(context);
    final account = financeStore.activeAccount;

    if (account == null) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('Anggaran')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Belum ada akun keuangan aktif.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      );
    }

    _ensureFuture(account: account, financeStore: financeStore);

    return SafeArea(
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: const Text(
            'Anggaran',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 6),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddBudgetDialog(account),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Anggaran'),
        ),
        body: FutureBuilder<_BudgetPageData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 42, color: scheme.error),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat data anggaran.${snapshot.error == null ? '' : '\n${snapshot.error}'}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final budgets = data.budgets;

            return RefreshIndicator(
              onRefresh: () async {
                _refresh();
                await Future<void>.delayed(const Duration(milliseconds: 300));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
                children: [
                  _buildMonthSelector(),
                  const SizedBox(height: 12),
                  _buildSummary(totalBudget: data.totalBudget, totalSpent: data.totalSpent),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anggaran per Kategori',
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Atur batas dan pantau pengeluaran.',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${budgets.length} kategori',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (budgets.isEmpty)
                    _buildEmptyState(account)
                  else
                    ...budgets.map(
                      (budget) => _buildBudgetCard(
                        budget: budget,
                        account: account,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pengeluaran ringkasan dihitung dari seluruh transaksi Pengeluaran pada akun dan bulan yang dipilih. Nilai Terpakai pada kartu mengikuti kategorinya.',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 10,
                              height: 1.45,
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
