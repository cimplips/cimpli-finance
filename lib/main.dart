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

  ThemeMode _themeMode = ThemeMode.light;

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
    required ThemeController controller,
    required super.child,
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
    // CIMPLI FINANCE DESIGN SYSTEM
    // ============================================================
    //
    // Bagian ini hanya mengatur presentation layer.
    //
    // Tidak mengubah:
    // - database
    // - transaksi
    // - budget
    // - laporan
    // - recurring transaction
    // - app lock
    // - navigation
    // - persistence
    //
    // Light dan Dark Mode menggunakan visual language yang sama.
    // ============================================================

    // -------------------------
    // DARK PALETTE
    // -------------------------
    const darkBackground = Color(0xFF0D1117);
    const darkSurface = Color(0xFF161B22);
    const darkSurfaceElevated = Color(0xFF1C232D);
    const darkInput = Color(0xFF202833);

    const darkPrimary = Color(0xFFEAF2FF);
    const darkSecondary = Color(0xFF9DA9B8);
    const darkTertiary = Color(0xFF718096);

    const darkAccent = Color(0xFF7C9CFF);
    const darkDivider = Color(0xFF2B3440);

    // -------------------------
    // LIGHT PALETTE
    // -------------------------
    const lightBackground = Color(0xFFF6F8FB);
    const lightSurface = Color(0xFFFFFFFF);
    const lightSurfaceElevated = Color(0xFFF9FAFC);
    const lightInput = Color(0xFFF1F4F8);

    const lightPrimary = Color(0xFF172033);
    const lightSecondary = Color(0xFF5D6878);
    const lightTertiary = Color(0xFF8792A2);

    const lightAccent = Color(0xFF536DCE);
    const lightDivider = Color(0xFFE3E8EF);

    final baseTextTheme = ThemeData.light().textTheme;

    // ============================================================
    // DARK THEME
    // ============================================================
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      dividerColor: darkDivider,
      visualDensity: VisualDensity.standard,

      colorScheme: const ColorScheme.dark(
        primary: darkAccent,
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF9BB2FF),
        onSecondary: Color(0xFF10172A),
        tertiary: Color(0xFF6FD6C5),
        surface: darkSurface,
        onSurface: darkPrimary,
        surfaceContainerHighest: darkSurfaceElevated,
        outline: darkDivider,
      ),

      textTheme: baseTextTheme.copyWith(
        displaySmall: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        headlineSmall: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: const TextStyle(
          fontSize: 15,
          height: 1.45,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.4,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: darkPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(
            color: darkDivider,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
            color: darkAccent,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFFF7B72),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFFF7B72),
            width: 1.5,
          ),
        ),
        hintStyle: const TextStyle(
          color: darkTertiary,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: darkAccent.withValues(
          alpha: 0.18,
        ),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      bottomNavigationBarTheme:
          const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimary,
        unselectedItemColor: darkSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          side: const BorderSide(
            color: darkDivider,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: darkSecondary,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      floatingActionButtonTheme:
          FloatingActionButtonThemeData(
        backgroundColor: darkAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceElevated,
        contentTextStyle: const TextStyle(
          color: darkPrimary,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: darkDivider,
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(
            color: darkDivider,
          ),
        ),
        titleTextStyle: const TextStyle(
          color: darkPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),

      bottomSheetTheme:
          const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(
            color: darkDivider,
          ),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: darkSecondary,
        minLeadingWidth: 44,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
        ),
      ),
    );

    // ============================================================
    // LIGHT THEME
    // ============================================================
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      dividerColor: lightDivider,
      visualDensity: VisualDensity.standard,

      colorScheme: const ColorScheme.light(
        primary: lightAccent,
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF6578C9),
        onSecondary: Color(0xFFFFFFFF),
        tertiary: Color(0xFF238F80),
        surface: lightSurface,
        onSurface: lightPrimary,
        surfaceContainerHighest: lightSurfaceElevated,
        outline: lightDivider,
      ),

      textTheme: baseTextTheme.copyWith(
        displaySmall: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: lightPrimary,
        ),
        headlineSmall: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: lightPrimary,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: lightPrimary,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: lightPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: 15,
          height: 1.45,
          color: lightPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.4,
          color: lightSecondary,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: lightPrimary,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: lightPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(
            color: lightDivider,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
            color: lightAccent,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFD92D20),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFD92D20),
            width: 1.5,
          ),
        ),
        hintStyle: const TextStyle(
          color: lightTertiary,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: lightAccent.withValues(
          alpha: 0.12,
        ),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      bottomNavigationBarTheme:
          const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightAccent,
        unselectedItemColor: lightSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          side: const BorderSide(
            color: lightDivider,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: lightSecondary,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      floatingActionButtonTheme:
          FloatingActionButtonThemeData(
        backgroundColor: lightAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(
            color: lightDivider,
          ),
        ),
        titleTextStyle: const TextStyle(
          color: lightPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),

      bottomSheetTheme:
          const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(
            color: lightDivider,
          ),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: lightSecondary,
        minLeadingWidth: 44,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
        ),
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
