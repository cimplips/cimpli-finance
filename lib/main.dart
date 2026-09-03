import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/finance_scope.dart';
import 'screens/app_lock_page.dart';
import 'screens/home_page.dart';
import 'screens/recurring_transactions_page.dart';
import 'services/app_lock_service.dart';
import 'services/finance_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = FinanceStore();
  await store.load();

  await store.generateDueRecurringTransactions();

  final themeController = ThemeController();
  await themeController.load();

  runApp(
    FinanceApp(
      store: store,
      themeController: themeController,
    ),
  );
}

class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedTheme = preferences.getString(_themeKey);

    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _themeKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );

    notifyListeners();
  }

  Future<void> toggle() async {
    await setThemeMode(
      isDarkMode ? ThemeMode.light : ThemeMode.dark,
    );
  }
}

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required super.child,
    required ThemeController controller,
  }) : super(
          notifier: controller,
        );

  static ThemeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>();

    assert(
      scope != null,
      'ThemeControllerScope tidak ditemukan di widget tree.',
    );

    return scope!.notifier!;
  }
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({
    super.key,
    required this.store,
    required this.themeController,
  });

  final FinanceStore store;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // PALET UTAMA CIMPLI FINANCE
    // ============================================================

    // Aksen biru yang digunakan bersama di seluruh aplikasi.
    const primaryBlue = Color(0xFF5B7DB1);
    const primaryBlueDark = Color(0xFF8EACD5);

    // ============================================================
    // DARK MODE
    // ============================================================

    // Background dibuat lebih cerah daripada versi sebelumnya
    // agar nyaman digunakan dalam waktu lama.
    const darkBackground = Color(0xFF17191D);
    const darkSurface = Color(0xFF202227);
    const darkSurfaceVariant = Color(0xFF30333A);
    const darkElevated = Color(0xFF292C32);

    const darkPrimaryText = Color(0xFFF8FAFC);
    const darkSecondaryText = Color(0xFFA4A7AE);
    const darkTertiaryText = Color(0xFF858991);
    const darkDivider = Color(0xFF3A3D42);

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: darkBackground,

      colorScheme: const ColorScheme.dark(
        primary: primaryBlueDark,
        onPrimary: Color(0xFF142033),
        secondary: primaryBlueDark,
        onSecondary: Color(0xFF142033),
        surface: darkSurface,
        onSurface: darkPrimaryText,
        surfaceContainerHighest: darkSurfaceVariant,
        onSurfaceVariant: darkSecondaryText,
        outline: darkDivider,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkPrimaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkElevated,

        labelStyle: const TextStyle(
          color: darkSecondaryText,
        ),

        hintStyle: const TextStyle(
          color: darkTertiaryText,
        ),

        prefixIconColor: darkSecondaryText,

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
            color: primaryBlueDark,
            width: 1.2,
          ),
        ),
      ),

      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF202328),
        surfaceTintColor: Colors.transparent,
        indicatorColor: Color(0xFF34465F),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF202328),
        selectedItemColor: primaryBlueDark,
        unselectedItemColor: darkSecondaryText,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlueDark,
        foregroundColor: Color(0xFF142033),
        elevation: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkElevated,
        contentTextStyle: const TextStyle(
          color: darkPrimaryText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: darkElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlueDark,
      ),
    );

    // ============================================================
    // LIGHT MODE
    // ============================================================

    const lightBackground = Color(0xFFF5F6F8);
    const lightSurface = Color(0xFFFFFFFF);
    const lightSurfaceVariant = Color(0xFFE8EBF0);
    const lightElevated = Color(0xFFF1F3F6);

    const lightPrimaryText = Color(0xFF101828);
    const lightSecondaryText = Color(0xFF667085);
    const lightTertiaryText = Color(0xFF98A2B3);
    const lightDivider = Color(0xFFE1E5EA);

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor: lightBackground,

      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        onPrimary: Colors.white,
        secondary: primaryBlue,
        onSecondary: Colors.white,
        surface: lightSurface,
        onSurface: lightPrimaryText,
        surfaceContainerHighest: lightSurfaceVariant,
        onSurfaceVariant: lightSecondaryText,
        outline: lightDivider,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightPrimaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightElevated,

        labelStyle: const TextStyle(
          color: lightSecondaryText,
        ),

        hintStyle: const TextStyle(
          color: lightTertiaryText,
        ),

        prefixIconColor: lightSecondaryText,

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
            color: primaryBlue,
            width: 1.2,
          ),
        ),
      ),

      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Color(0xFFE3ECFA),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: lightSecondaryText,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF20242A),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
      ),
    );

    return FinanceScope(
      store: store,
      child: ThemeControllerScope(
        controller: themeController,
        child: AnimatedBuilder(
          animation: themeController,
          builder: (context, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Cimpli Finance',

              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeController.themeMode,

              home: const AppLockGate(),

              routes: {
                '/recurring-transactions': (context) =>
                    const RecurringTransactionsPage(),
              },
            );
          },
        ),
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
