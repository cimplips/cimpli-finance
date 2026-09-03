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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final background = isDark
        ? const Color(0xFF0D1117)
        : const Color(0xFFF6F8FB);

    final navigationBackground = isDark
        ? const Color(0xFF151A21)
        : Colors.white;

    final navigationForeground = isDark
        ? const Color(0xFFE8EEF8)
        : const Color(0xFF1B2433);

    final navigationMuted = isDark
        ? const Color(0xFF8D99AA)
        : const Color(0xFF697586);

    final indicatorColor = isDark
        ? const Color(0xFF293A55)
        : const Color(0xFFEAF0FF);

    final borderColor = isDark
        ? const Color(0xFF29313D)
        : const Color(0xFFE2E7EF);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: _pages[_currentIndex],
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 4
          ? Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: FloatingActionButton.extended(
                elevation: 4,
                onPressed: _openRecurringTransactions,
                icon: const Icon(Icons.repeat_rounded),
                label: const Text('Transaksi Berulang'),
              ),
            )
          : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: navigationBackground,
            border: Border(
              top: BorderSide(
                color: borderColor,
                width: 0.7,
              ),
            ),
            boxShadow: [
              if (!isDark)
                const BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 18,
                  offset: Offset(0, -5),
                ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: navigationBackground,
              surfaceTintColor: Colors.transparent,
              indicatorColor: indicatorColor,
              elevation: 0,
              height: 72,
              labelBehavior:
                  NavigationDestinationLabelBehavior.alwaysShow,
              iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
                (states) {
                  final selected = states.contains(
                    WidgetState.selected,
                  );

                  return IconThemeData(
                    color: selected
                        ? navigationForeground
                        : navigationMuted,
                    size: selected ? 23 : 22,
                  );
                },
              ),
              labelTextStyle:
                  WidgetStateProperty.resolveWith<TextStyle>(
                (states) {
                  final selected = states.contains(
                    WidgetState.selected,
                  );

                  return TextStyle(
                    color: selected
                        ? navigationForeground
                        : navigationMuted,
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  );
                },
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                if (_currentIndex == index) {
                  return;
                }

                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: navigationBackground,
              surfaceTintColor: Colors.transparent,
              indicatorColor: indicatorColor,
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Riwayat',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.account_balance_wallet_outlined,
                  ),
                  selectedIcon: Icon(
                    Icons.account_balance_wallet_rounded,
                  ),
                  label: 'Anggaran',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Laporan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Pengaturan',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
