import 'package:flutter/widgets.dart';

import '../services/finance_store.dart';

class FinanceScope extends InheritedNotifier<FinanceStore> {
  const FinanceScope({
    super.key,
    required FinanceStore store,
    required super.child,
  }) : super(
          notifier: store,
        );

  static FinanceStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<FinanceScope>();

    assert(
      scope != null,
      'FinanceScope tidak ditemukan di atas widget ini.',
    );

    return scope!.notifier!;
  }
}
