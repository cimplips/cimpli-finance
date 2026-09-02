enum RecurringFrequency {
  monthly,
  weekly,
  yearly,
}

class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.account,
    required this.category,
    required this.startDate,
    required this.frequency,
    this.isActive = true,
    this.lastGeneratedDate,
  });

  final int? id;
  final String title;
  final double amount;
  final String type;
  final String account;
  final String category;
  final DateTime startDate;
  final RecurringFrequency frequency;
  final bool isActive;
  final DateTime? lastGeneratedDate;

  RecurringTransaction copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    String? account,
    String? category,
    DateTime? startDate,
    RecurringFrequency? frequency,
    bool? isActive,
    DateTime? lastGeneratedDate,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      account: account ?? this.account,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      lastGeneratedDate:
          lastGeneratedDate ?? this.lastGeneratedDate,
    );
  }

  String get frequencyLabel {
    switch (frequency) {
      case RecurringFrequency.monthly:
        return 'Bulanan';
      case RecurringFrequency.weekly:
        return 'Mingguan';
      case RecurringFrequency.yearly:
        return 'Tahunan';
    }
  }

  bool get isIncome => type == 'income';

  bool get isExpense => type == 'expense';

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'account': account,
      'category': category,
      'start_date': startDate.toIso8601String(),
      'frequency': frequency.name,
      'is_active': isActive ? 1 : 0,
      'last_generated_date':
          lastGeneratedDate?.toIso8601String(),
    };
  }

  factory RecurringTransaction.fromMap(
    Map<String, Object?> map,
  ) {
    final frequencyName =
        map['frequency'] as String? ?? 'monthly';

    final frequency = RecurringFrequency.values.firstWhere(
      (item) => item.name == frequencyName,
      orElse: () => RecurringFrequency.monthly,
    );

    return RecurringTransaction(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      type: map['type'] as String? ?? 'expense',
      account: map['account'] as String? ?? '',
      category: map['category'] as String? ?? '',
      startDate: DateTime.parse(
        map['start_date'] as String,
      ),
      frequency: frequency,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      lastGeneratedDate:
          map['last_generated_date'] == null
              ? null
              : DateTime.parse(
                  map['last_generated_date'] as String,
                ),
    );
  }
}
