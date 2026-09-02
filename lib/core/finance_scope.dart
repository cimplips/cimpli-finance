import 'package:flutter/widgets.dart';
import '../services/finance_store.dart';

class FinanceScope extends InheritedNotifier<FinanceStore> {
  const FinanceScope({
    super.key,
    required FinanceStore store,
    required super.child,
  }) : super(notifier: store);

  static FinanceStore of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FinanceScope>()!
        .notifier!;
  }
}
