import 'package:flutter/material.dart';

import 'core/finance_scope.dart';
import 'screens/app_lock_page.dart';
import 'screens/home_page.dart';
import 'services/app_lock_service.dart';
import 'services/finance_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = FinanceStore();
  await store.load();

  await store.generateDueRecurringTransactions();

  runApp(
    FinanceApp(
      store: store,
    ),
  );
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
        title: 'Cimpli Finance',
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
        home: const AppLockGate(),
      ),
    );
  }
}

class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
  });

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  final AppLockService _lockService = AppLockService();

  bool _checking = true;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  Future<void> _checkLockStatus() async {
    final enabled = await _lockService.isEnabled();

    if (!mounted) {
      return;
    }

    setState(() {
      _locked = enabled;
      _checking = false;
    });
  }

  void _unlock() {
    if (!mounted) {
      return;
    }

    setState(() {
      _locked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_locked) {
      return AppLockPage(
        onUnlocked: _unlock,
      );
    }

    return const HomePage();
  }
}
