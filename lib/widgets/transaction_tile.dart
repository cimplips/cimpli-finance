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

  static const _lightText = Color(0xFF202735);
  static const _lightSecondary = Color(0xFF687386);
  static const _lightBorder = Color(0xFFE1E6EF);
  static const _lightIncome = Color(0xFF61B9A7);
  static const _lightIncomeSoft = Color(0xFFE7F6F2);
  static const _lightExpense = Color(0xFFD87979);
  static const _lightExpenseSoft = Color(0xFFFFECEC);

  static const _darkText = Color(0xFFF1F3F6);
  static const _darkSecondary = Color(0xFFB8BDC6);
  static const _darkBorder = Color(0xFF50535A);
  static const _darkIncome = Color(0xFF86CBBB);
  static const _darkIncomeSoft = Color(0xFF3C4F4B);
  static const _darkExpense = Color(0xFFE39A9A);
  static const _darkExpenseSoft = Color(0xFF514143);

  @override
  Widget build(BuildContext context) {
    final isIncome =
        tx.type == TransactionType.income;
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? _darkText : _lightText;
    final secondaryColor =
        isDark ? _darkSecondary : _lightSecondary;
    final borderColor =
        isDark ? _darkBorder : _lightBorder;

    final accentColor = isIncome
        ? (isDark ? _darkIncome : _lightIncome)
        : (isDark ? _darkExpense : _lightExpense);

    final accentSoft = isIncome
        ? (isDark ? _darkIncomeSoft : _lightIncomeSoft)
        : (isDark ? _darkExpenseSoft : _lightExpenseSoft);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isIncome
                      ? Icons.south_west
                      : Icons.north_east,
                  color: accentColor,
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
                      tx.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tx.category} • ${DateFormat('dd MMM yyyy', 'id_ID').format(tx.date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${isIncome ? '+' : '-'}${money.format(tx.amount)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
