import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/finance_scope.dart';
import '../models/transaction.dart';
import '../services/finance_store.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({
    super.key,
    this.initialType = TransactionType.expense,
    this.transaction,
  });

  final TransactionType initialType;
  final Tx? transaction;

  @override
  State<AddTransactionPage> createState() =>
      _AddTransactionPageState();
}

class _AddTransactionPageState
    extends State<AddTransactionPage> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  TransactionType type = TransactionType.expense;

  String selectedCategory = 'Umum';
  String? selectedAccount;
  DateTime date = DateTime.now();

  final categories = const [
    'Umum',
    'Makanan',
    'Transportasi',
    'Belanja',
    'Tagihan',
    'Kesehatan',
    'Gaji',
    'Bonus',
    'Usaha',
    'Lainnya',
  ];

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;

    if (transaction != null) {
      titleController.text = transaction.title;

      amountController.text =
          transaction.amount.toStringAsFixed(0);

      type = transaction.type;
      selectedCategory = transaction.category;
      selectedAccount = transaction.account;
      date = transaction.date;
    } else {
      type = widget.initialType;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);

    selectedAccount ??= store.activeAccount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Edit Transaksi'
              : 'Tambah Transaksi',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.income,
                icon: Icon(Icons.arrow_downward),
                label: Text('Pemasukan'),
              ),
              ButtonSegment(
                value: TransactionType.expense,
                icon: Icon(Icons.arrow_upward),
                label: Text('Pengeluaran'),
              ),
            ],
            selected: {type},
            onSelectionChanged: (value) {
              setState(() {
                type = value.first;
              });
            },
          ),
          const SizedBox(height: 22),

          TextField(
            controller: titleController,
            textCapitalization:
                TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nama transaksi',
              prefixIcon: Icon(
                Icons.edit_outlined,
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixIcon: Icon(
                Icons.payments_outlined,
              ),
              prefixText: 'Rp ',
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Akun Keuangan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            initialValue: selectedAccount,
            decoration: const InputDecoration(
              prefixIcon: Icon(
                Icons.account_balance_wallet_outlined,
              ),
            ),
            items: store.accounts
                .map(
                  (account) => DropdownMenuItem(
                    value: account,
                    child: Text(account),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedAccount = value;
              });
            },
          ),

          const SizedBox(height: 22),

          const Text(
            'Kategori',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map(
              (category) => ChoiceChip(
                label: Text(category),
                selected:
                    selectedCategory == category,
                onSelected: (_) {
                  setState(() {
                    selectedCategory = category;
                  });
                },
              ),
            ).toList(),
          ),

          const SizedBox(height: 22),

          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 4,
            ),
            tileColor: const Color(
              0xFF1C1E22,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16),
            ),
            leading: const Icon(
              Icons.calendar_month_outlined,
            ),
            title: const Text('Tanggal'),
            subtitle: Text(
              DateFormat(
                'dd MMMM yyyy',
                'id_ID',
              ).format(date),
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () async {
              final selected =
                  await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (selected != null) {
                setState(() {
                  date = selected;
                });
              }
            },
          ),

          const SizedBox(height: 28),

          FilledButton(
            onPressed: () async {
              final amountText =
                  amountController.text
                      .replaceAll('.', '')
                      .replaceAll(',', '.');

              final value =
                  double.tryParse(amountText);

              final title =
                  titleController.text.trim();

              if (title.isEmpty ||
                  value == null ||
                  value <= 0 ||
                  selectedAccount == null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Lengkapi data transaksi dengan benar.',
                    ),
                  ),
                );

                return;
              }

              final tx = Tx(
                id: widget.transaction?.id,
                title: title,
                amount: value,
                type: type,
                date: date,
                account: selectedAccount!,
                category: selectedCategory,
              );

              if (isEditing) {
                await store.updateTransaction(tx);
              } else {
                await store.addTransaction(tx);
              }

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(
                    isEditing
                        ? 'Transaksi berhasil diperbarui.'
                        : 'Transaksi berhasil disimpan.',
                  ),
                ),
              );

              Navigator.of(context).pop();
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
              child: Text(
                isEditing
                    ? 'Simpan Perubahan'
                    : 'Simpan Transaksi',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
