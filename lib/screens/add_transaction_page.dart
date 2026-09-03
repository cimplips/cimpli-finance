import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/finance_scope.dart';
import '../models/transaction.dart';
import '../services/budget_store.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({
    super.key,
    this.transaction,
  });

  final Tx? transaction;

  @override
  State<AddTransactionPage> createState() =>
      _AddTransactionPageState();
}

class _AddTransactionPageState
    extends State<AddTransactionPage> {
  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _textSecondary =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  Color get _surfaceSoft =>
      Theme.of(context).colorScheme.surfaceContainerLow;

  Color get _borderColor => _isDark
      ? const Color(0xFF50535A)
      : const Color(0xFFE1E6EF);

  Color get _expenseColor => _isDark
      ? const Color(0xFFE39A9A)
      : const Color(0xFFB85C5C);

  Color get _expenseSoft => _isDark
      ? const Color(0xFF514145)
      : const Color(0xFFFFECEC);

  Color get _incomeColor => _isDark
      ? const Color(0xFF86CBBB)
      : const Color(0xFF4F8A68);

  Color get _incomeSoft => _isDark
      ? const Color(0xFF40514D)
      : const Color(0xFFE7F6F2);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();

  String? _selectedAccount;
  String? _selectedCategory;

  bool _saving = false;

  static const List<String> _defaultCategories = <String>[
    'Makanan',
    'Transportasi',
    'Belanja',
    'Tagihan',
    'Hiburan',
    'Kesehatan',
    'Pendidikan',
    'Gaji',
    'Bonus',
    'Lainnya',
  ];

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;

    if (transaction != null) {
      _titleController.text = transaction.title;
      _amountController.text =
          _formatAmountForInput(transaction.amount);
      _type = transaction.type;
      _date = transaction.date;
      _selectedAccount = transaction.account;
      _selectedCategory = transaction.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatAmountForInput(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }

    return amount.toString();
  }

  double? _parseAmount(String value) {
    var text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    text = text.replaceAll(RegExp(r'[^0-9,.]'), '');

    if (text.isEmpty) {
      return null;
    }

    final lastComma = text.lastIndexOf(',');
    final lastDot = text.lastIndexOf('.');

    if (lastComma >= 0 && lastDot >= 0) {
      if (lastComma > lastDot) {
        text = text.replaceAll('.', '');
        text = text.replaceAll(',', '.');
      } else {
        text = text.replaceAll(',', '');
      }
    } else if (lastComma >= 0) {
      final digitsAfterComma =
          text.length - lastComma - 1;

      if (digitsAfterComma == 3) {
        text = text.replaceAll(',', '');
      } else {
        text = text.replaceAll(',', '.');
      }
    } else if (lastDot >= 0) {
      final digitsAfterDot =
          text.length - lastDot - 1;

      if (digitsAfterDot == 3) {
        text = text.replaceAll('.', '');
      }
    }

    return double.tryParse(text);
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

  List<String> _categoriesForType() {
    if (_type == TransactionType.income) {
      return <String>[
        'Gaji',
        'Bonus',
        'Penjualan',
        'Investasi',
        'Hadiah',
        'Lainnya',
      ];
    }

    return _defaultCategories
        .where(
          (category) =>
              category != 'Gaji' &&
              category != 'Bonus',
        )
        .toList();
  }

  Future<List<String>> _loadCategories() async {
    final store = FinanceScope.of(context);

    final databaseCategories =
        await store.getCategories(
      account: _selectedAccount,
    );

    final categories = <String>{
      ..._categoriesForType(),
      ...databaseCategories,
    };

    if (_selectedCategory != null &&
        _selectedCategory!.trim().isNotEmpty) {
      categories.add(_selectedCategory!);
    }

    final result = categories.toList()
      ..sort(
        (a, b) => a.toLowerCase().compareTo(
              b.toLowerCase(),
            ),
      );

    return result;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
        _date.second,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final store = FinanceScope.of(context);

    final amount =
        _parseAmount(_amountController.text);

    if (amount == null || amount <= 0) {
      _showMessage(
        'Nominal transaksi tidak valid.',
      );
      return;
    }

    final account =
        _selectedAccount ?? store.activeAccount;

    if (account == null || account.isEmpty) {
      _showMessage(
        'Silakan pilih akun terlebih dahulu.',
      );
      return;
    }

    final category = _selectedCategory;

    if (category == null || category.isEmpty) {
      _showMessage(
        'Silakan pilih kategori.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    bool success;

    if (_isEditing) {
      success = await store.updateTransaction(
        id: widget.transaction!.id!,
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        date: _date,
        account: account,
        category: category,
      );
    } else {
      await store.addTransaction(
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        date: _date,
        account: account,
        category: category,
      );

      success = true;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });

    if (!success) {
      _showMessage(
        'Transaksi gagal disimpan. Silakan coba lagi.',
      );
      return;
    }

    await _showBudgetAlertIfNeeded(
      account: account,
      category: category,
      date: _date,
      type: _type,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _showBudgetAlertIfNeeded({
    required String account,
    required String category,
    required DateTime date,
    required TransactionType type,
  }) async {
    if (type != TransactionType.expense) {
      return;
    }

    final budgetStore = BudgetStore();

    try {
      await budgetStore.load();

      if (!mounted) {
        return;
      }

      final budget = await budgetStore.getBudget(
        account: account,
        category: category,
        month: date,
      );

      if (!mounted || budget == null) {
        return;
      }

      if (budget.limit <= 0) {
        return;
      }

      final percentage =
          (budget.spent / budget.limit) * 100;

      if (percentage < 80) {
        return;
      }

      final isOverBudget =
          percentage > 100;

      final title = isOverBudget
          ? 'Anggaran Terlampaui'
          : 'Anggaran Hampir Habis';

      final icon = isOverBudget
          ? Icons.warning_amber_rounded
          : Icons.notifications_active_outlined;

      final message = isOverBudget
          ? 'Pengeluaran kategori "$category" '
              'sudah melebihi anggaran bulan ini.'
          : 'Pengeluaran kategori "$category" '
              'sudah mencapai ${percentage.round()}% '
              'dari anggaran bulan ini.';

      final remaining = budget.remaining;

      final detail = isOverBudget
          ? 'Melebihi anggaran sebesar '
              '${_formatRupiah(remaining.abs())}.'
          : 'Sisa anggaran sekitar '
              '${_formatRupiah(remaining)}.';

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final colorScheme = Theme.of(dialogContext).colorScheme;

          return AlertDialog(
            icon: Icon(
              icon,
              size: 42,
            ),
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_formatRupiah(budget.spent)} '
                  'dari ${_formatRupiah(budget.limit)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Mengerti'),
              ),
            ],
          );
        },
      );
    } finally {
      await budgetStore.close();
    }
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

  String _formatDate(DateTime date) {
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);

    final accounts = store.accounts;

    if (_selectedAccount == null &&
        store.activeAccount != null) {
      _selectedAccount = store.activeAccount;
    }

    if (_selectedAccount != null &&
        !accounts.contains(_selectedAccount)) {
      _selectedAccount = store.activeAccount;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Edit Transaksi'
              : 'Tambah Transaksi',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            32,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: _surfaceSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _borderColor),
              ),
              child: _TypeSelector(
                value: _type,
                onChanged: (type) {
                  setState(() {
                    _type = type;

                    if (_selectedCategory != null) {
                      final categories =
                          _categoriesForType();

                      if (!categories.contains(
                        _selectedCategory,
                      )) {
                        _selectedCategory = null;
                      }
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Keterangan',
                hintText: 'Contoh: Belanja bulanan',
                prefixIcon: Icon(
                  Icons.description_outlined,
                ),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Keterangan wajib diisi.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9.,]'),
                ),
              ],
              decoration: const InputDecoration(
                labelText: 'Nominal',
                hintText: 'Contoh: 1.500.000',
                prefixIcon: Icon(
                  Icons.payments_outlined,
                ),
              ),
              validator: (value) {
                final amount =
                    _parseAmount(value ?? '');

                if (amount == null || amount <= 0) {
                  return 'Masukkan nominal yang valid.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedAccount,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Akun',
                prefixIcon: Icon(
                  Icons.account_balance_wallet_outlined,
                ),
              ),
              items: accounts
                  .map(
                    (account) =>
                        DropdownMenuItem<String>(
                      value: account,
                      child: Text(
                        account,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: accounts.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        _selectedAccount = value;
                        _selectedCategory = null;
                      });
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Pilih akun.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<String>>(
              future: _loadCategories(),
              builder: (context, snapshot) {
                final categories =
                    snapshot.data ?? <String>[];

                final selected =
                    categories.contains(
                  _selectedCategory,
                )
                        ? _selectedCategory
                        : null;

                return DropdownButtonFormField<String>(
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
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
                  onChanged: categories.isEmpty
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Pilih kategori.';
                    }

                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  prefixIcon: Icon(
                    Icons.calendar_today_outlined,
                  ),
                  suffixIcon: Icon(
                    Icons.chevron_right,
                  ),
                ),
                child: Text(
                  _formatDate(_date),
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (_amountController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 14,
                ),
                child: ValueListenableBuilder<
                    TextEditingValue>(
                  valueListenable: _amountController,
                  builder: (
                    context,
                    value,
                    child,
                  ) {
                    final amount =
                        _parseAmount(value.text);

                    if (amount == null ||
                        amount <= 0) {
                      return const SizedBox.shrink();
                    }

                    return Text(
                      _formatRupiah(amount),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                      ),
                    );
                  },
                ),
              ),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditing
                            ? 'Simpan Perubahan'
                            : 'Simpan Transaksi',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.value,
    required this.onChanged,
  });

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeButton(
            label: 'Pengeluaran',
            icon: Icons.arrow_upward_rounded,
            selected:
                value == TransactionType.expense,
            selectedColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFE39A9A)
                : const Color(0xFFB85C5C),
            selectedBackground: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF514145)
                : const Color(0xFFFFECEC),
            onTap: () {
              onChanged(TransactionType.expense);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeButton(
            label: 'Pemasukan',
            icon: Icons.arrow_downward_rounded,
            selected:
                value == TransactionType.income,
            selectedColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF86CBBB)
                : const Color(0xFF4F8A68),
            selectedBackground: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF40514D)
                : const Color(0xFFE7F6F2),
            onTap: () {
              onChanged(TransactionType.income);
            },
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final Color selectedBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = selected
        ? selectedBackground
        : colorScheme.surfaceContainerHighest;

    final foregroundColor = selected
        ? selectedColor
        : colorScheme.onSurfaceVariant;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: foregroundColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
