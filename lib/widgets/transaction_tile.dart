import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.tx,
    required this.money,
    this.onTap,
  });

  final Tx tx;
  final NumberFormat money;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome =
        tx.type == TransactionType.income;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 5,
      ),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF30343A),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          isIncome
              ? Icons.south_west
              : Icons.north_east,
        ),
      ),
      title: Text(
        tx.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${tx.category} • ${DateFormat('dd MMM yyyy', 'id_ID').format(tx.date)}',
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${money.format(tx.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isIncome
              ? Colors.greenAccent.shade200
              : Colors.redAccent.shade100,
        ),
      ),
    );
  }
}
