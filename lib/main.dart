import 'package:flutter/material.dart';

import 'core/finance_scope.dart';
import 'screens/home_page.dart';
import 'services/finance_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = FinanceStore();
  await store.load();

  await store.generateDueRecurringTransactions();

  runApp(FinanceApp(store: store));
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({
    super.key,
    required this.store,
  });

  final FinanceStore store;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF111214);
    const surface = Color(0xFF1C1E22);
    const surfaceVariant = Color(0xFF282B30);
    const primary = Color(0xFFE8EAED);

    return FinanceScope(
      store: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Keuangan Prima',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: background,
          colorScheme: const ColorScheme.dark(
            primary: primary,
            secondary: Color(0xFFB8BCC2),
            surface: surface,
            surfaceContainerHighest: surfaceVariant,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: surface,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF8E939B),
              ),
            ),
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
