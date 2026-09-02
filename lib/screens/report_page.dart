import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/finance_scope.dart';
import '../services/finance_store.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() =>
      _ReportPageState();
}

class _ReportPageState
    extends State<ReportPage> {
  DateTime selectedMonth =
      DateTime(DateTime.now().year,
          DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);

    final money = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final income =
        store.incomeForMonth(selectedMonth);

    final expense =
        store.expenseForMonth(selectedMonth);

    final balance = income - expense;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Laporan Bulanan',
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ListTile(
              tileColor: const Color(
                0xFF1C1E22,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(18),
              ),
              leading: const Icon(
                Icons.calendar_month_outlined,
              ),
              title: const Text(
                'Periode Laporan',
              ),
              subtitle: Text(
                DateFormat(
                  'MMMM yyyy',
                  'id_ID',
                ).format(selectedMonth),
              ),
              trailing: const Icon(
                Icons.expand_more,
              ),
              onTap: () async {
                final picked =
                    await showDatePicker(
                  context: context,
                  initialDate: selectedMonth,
                  firstDate:
                      DateTime(2020),
                  lastDate:
                      DateTime(2100),
                  helpText:
                      'Pilih bulan laporan',
                );

                if (picked != null) {
                  setState(() {
                    selectedMonth =
                        DateTime(
                      picked.year,
                      picked.month,
                    );
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            _ReportCard(
              title: 'Pemasukan',
              value: money.format(income),
              icon: Icons.arrow_downward,
            ),
            const SizedBox(height: 12),
            _ReportCard(
              title: 'Pengeluaran',
              value: money.format(expense),
              icon: Icons.arrow_upward,
            ),
            const SizedBox(height: 12),
            _ReportCard(
              title: 'Saldo Bulan Ini',
              value: money.format(balance),
              icon:
                  Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 26),
            const Text(
              'Ringkasan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Text(
                  expense > income
                      ? 'Pengeluaran bulan ini lebih besar daripada pemasukan.'
                      : 'Kondisi keuangan bulan ini masih terkendali.',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    height: 1.5,
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(
              0xFF30343A,
            ),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: Icon(icon),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
