import 'package:flutter/material.dart';

import 'budget_page.dart';
import 'dashboard_page.dart';
import 'history_page.dart';
import 'report_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    HistoryPage(),
    BudgetPage(),
    ReportPage(),
    SettingsPage(),
  ];

  Future<void> _openRecurringTransactions() async {
    await Navigator.pushNamed(
      context,
      '/recurring-transactions',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navigationBackground = isDark
        ? const Color(0xFF20242A)
        : Colors.white;

    final navigationColor = isDark
        ? const Color(0xFFB8D0F2)
        : const Color(0xFF3F6FAE);

    final indicatorColor = isDark
        ? const Color(0xFF3A506F)
        : const Color(0xFFE7EFFC);

    return Scaffold(
      body: SafeArea(
        child: _pages[_currentIndex],
      ),
      floatingActionButton: _currentIndex == 4
          ? FloatingActionButton.extended(
              onPressed: _openRecurringTransactions,
              icon: const Icon(
                Icons.repeat_rounded,
              ),
              label: const Text(
                'Transaksi Berulang',
              ),
            )
          : null,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: navigationBackground,
          surfaceTintColor: Colors.transparent,
          indicatorColor: indicatorColor,
          elevation: 0,
          iconTheme: WidgetStatePropertyAll<IconThemeData>(
            IconThemeData(
              color: navigationColor,
              size: 24,
            ),
          ),
          labelTextStyle: WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              color: navigationColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: navigationBackground,
          surfaceTintColor: Colors.transparent,
          indicatorColor: indicatorColor,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(
                Icons.dashboard_outlined,
              ),
              selectedIcon: Icon(
                Icons.dashboard,
              ),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.receipt_long_outlined,
              ),
              selectedIcon: Icon(
                Icons.receipt_long,
              ),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.account_balance_wallet_outlined,
              ),
              selectedIcon: Icon(
                Icons.account_balance_wallet,
              ),
              label: 'Anggaran',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.bar_chart_outlined,
              ),
              selectedIcon: Icon(
                Icons.bar_chart,
              ),
              label: 'Laporan',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.settings_outlined,
              ),
              selectedIcon: Icon(
                Icons.settings,
              ),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}
