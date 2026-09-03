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
      return _formatThousands(amount.toInt().toString());
    }

    return amount.toString();
  }

  String _formatThousands(String digits) {
    if (digits.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(digits[i]);
    }

    return buffer.toString();
  }

  double? _parseAmount(String value) {
    var text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    text = text.replaceAll('.', '');
    text = text.replaceAll(RegExp(r'[^0-9,]'), '');

    if (text.isEmpty) {
      return null;
    }

    if (text.contains(',')) {
      final lastComma = text.lastIndexOf(',');
      final digitsAfterComma =
          text.length - lastComma - 1;

      if (digitsAfterComma > 0 &&
          digitsAfterComma <= 2) {
        text = text.replaceFirst(',', '.');
      } else {
        text = text.replaceAll(',', '');
      }
    }

    return double.tryParse(text);
  }

  String _formatRupiah(double value) {
    final rounded = value.round();
    final digits = rounded.abs().toString();

    final result = _formatThousands(digits);

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
          final colorScheme =
              Theme.of(dialogContext).colorScheme;

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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          _isEditing ? 'Edit Transaksi' : 'Tambah Transaksi',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(
                  alpha: isDark ? 0.28 : 0.62,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.primary.withValues(
                    alpha: isDark ? 0.20 : 0.10,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(
                        alpha: isDark ? 0.20 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _isEditing
                          ? Icons.edit_rounded
                          : Icons.receipt_long_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing
                              ? 'Perbarui transaksi'
                              : 'Catat transaksi baru',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEditing
                              ? 'Pastikan detail transaksi sudah sesuai.'
                              : 'Lengkapi detail berikut agar pencatatan tetap rapi.',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.72),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _TypeSelector(
              value: _type,
              onChanged: (type) {
                setState(() {
                  _type = type;

                  if (_selectedCategory != null) {
                    final categories = _categoriesForType();

                    if (!categories.contains(_selectedCategory)) {
                      _selectedCategory = null;
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Keterangan',
                hintText: 'Contoh: Belanja bulanan',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Keterangan wajib diisi.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              inputFormatters: <TextInputFormatter>[
                _RupiahInputFormatter(),
              ],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nominal',
                hintText: 'Contoh: 1.500.000',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                final amount = _parseAmount(value ?? '');
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
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: accounts
                  .map(
                    (account) => DropdownMenuItem<String>(
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
                final categories = snapshot.data ?? <String>[];
                final selected = categories.contains(_selectedCategory)
                    ? _selectedCategory
                    : null;

                return DropdownButtonFormField<String>(
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
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
                    if (value == null || value.isEmpty) {
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
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  suffixIcon: Icon(Icons.chevron_right_rounded),
                ),
                child: Text(_formatDate(_date)),
              ),
            ),
            const SizedBox(height: 22),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _amountController,
              builder: (context, value, child) {
                final amount = _parseAmount(value.text);

                if (amount == null || amount <= 0) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Nominal transaksi',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _formatRupiah(amount),
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _isEditing
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                      ),
                label: Text(
                  _isEditing
                      ? 'Simpan Perubahan'
                      : 'Simpan Transaksi',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
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

class _RupiahInputFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsBeforeCursor =
        _countDigitsBeforeCursor(newValue);

    final digits =
        newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(
          offset: 0,
        ),
      );
    }

    final formatted = _formatDigits(digits);

    final cursorPosition =
        _cursorPositionForDigitCount(
      formatted,
      digitsBeforeCursor,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: cursorPosition,
      ),
    );
  }

  int _countDigitsBeforeCursor(
    TextEditingValue value,
  ) {
    final cursor = value.selection.baseOffset;

    if (cursor <= 0) {
      return 0;
    }

    final end = cursor > value.text.length
        ? value.text.length
        : cursor;

    return value.text
        .substring(0, end)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
  }

  int _cursorPositionForDigitCount(
    String text,
    int digitCount,
  ) {
    if (digitCount <= 0) {
      return 0;
    }

    var digitsSeen = 0;

    for (var i = 0; i < text.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(text[i])) {
        digitsSeen++;

        if (digitsSeen >= digitCount) {
          return i + 1;
        }
      }
    }

    return text.length;
  }

  String _formatDigits(String digits) {
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(digits[i]);
    }

    return buffer.toString();
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final backgroundColor = selected
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest;

    final foregroundColor = selected
        ? colorScheme.onSecondaryContainer
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
