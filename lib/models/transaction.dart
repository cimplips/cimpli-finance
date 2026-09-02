import 'package:flutter/foundation.dart';

enum TransactionType {
  income,
  expense,
}

class Tx {
  Tx({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.account,
    required this.category,
  });

  final int? id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String account;
  final String category;
}
