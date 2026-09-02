import 'package:flutter/material.dart';
import 'app.dart';
import 'services/finance_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = FinanceStore();
  await store.load();
  runApp(FinanceApp(store: store));
}
