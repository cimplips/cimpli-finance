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

  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surface;

  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    HistoryPage(),
    BudgetPage(),
    ReportPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        elevation: 0,
        height: 78,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        shadowColor: Colors.transparent,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        overlayColor: WidgetStatePropertyAll(_surface),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
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
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
