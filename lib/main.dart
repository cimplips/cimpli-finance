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
    required ThemeController controller,
    super.child,
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
    //
    // Dark:
    // - Background: navy charcoal, tidak hitam pekat.
    // - Surface: blue-gray gelap.
    // - Elevated: sedikit lebih terang untuk membedakan kartu.
    // - Primary: biru lembut seperti navigasi bawah.
    //
    // Light:
    // - Background: abu-biru sangat terang.
    // - Surface: putih.
    // - Elevated: biru-abu tipis.
    // - Primary: biru yang sama nadanya dengan mode gelap.
    //
    const darkBackground = Color(0xFF14181D);
    const darkSurface = Color(0xFF1D232B);
    const darkSurfaceVariant = Color(0xFF252D37);
    const darkElevated = Color(0xFF29333F);

    const darkPrimary = Color(0xFF9DBFEF);
    const darkPrimaryContainer = Color(0xFF344D6B);
    const darkOnPrimary = Color(0xFF102033);

    const darkPrimaryText = Color(0xFFF3F6FA);
    const darkSecondaryText = Color(0xFFB1BBC7);
    const darkTertiaryText = Color(0xFF8995A3);
    const darkOutline = Color(0xFF394552);

    const incomeColorDark = Color(0xFF45D38A);
    const expenseColorDark = Color(0xFFFF7777);
    const warningColorDark = Color(0xFFE7B35B);
    const infoColorDark = Color(0xFF8FB9FF);

    const lightBackground = Color(0xFFF3F6FA);
    const lightSurface = Color(0xFFFFFFFF);
    const lightSurfaceVariant = Color(0xFFE7EDF4);
    const lightElevated = Color(0xFFF8FAFC);

    const lightPrimary = Color(0xFF527EAF);
    const lightPrimaryContainer = Color(0xFFDCE9F8);
    const lightOnPrimary = Color(0xFFFFFFFF);

    const lightPrimaryText = Color(0xFF17202B);
    const lightSecondaryText = Color(0xFF657386);
    const lightTertiaryText = Color(0xFF8A97A6);
    const lightOutline = Color(0xFFD3DCE6);

    const incomeColorLight = Color(0xFF218957);
    const expenseColorLight = Color(0xFFD94B4B);
    const warningColorLight = Color(0xFFAA711D);
    const infoColorLight = Color(0xFF4E79B0);

    // ============================================================
    // DARK THEME
    // ============================================================

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,

      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        primaryContainer: darkPrimaryContainer,
        onPrimaryContainer: Color(0xFFE5EFFC),
        secondary: Color(0xFF9BAFC6),
        onSecondary: Color(0xFF17202A),
        secondaryContainer: Color(0xFF304052),
        onSecondaryContainer: Color(0xFFDCE7F4),
        tertiary: Color(0xFFA7BBD2),
        surface: darkSurface,
        surfaceContainerHighest: darkSurfaceVariant,
        onSurface: darkPrimaryText,
        onSurfaceVariant: darkSecondaryText,
        outline: darkOutline,
        outlineVariant: Color(0xFF303A46),
        error: expenseColorDark,
        onError: Color(0xFF3A0A0A),
      ),

      scaffoldBackgroundColor: darkBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkPrimaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkPrimaryText,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: darkPrimaryText,
        ),
      ),

      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: const TextStyle(
          color: darkPrimaryText,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: darkSecondaryText,
          fontSize: 14,
          height: 1.45,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: darkPrimary,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: expenseColorDark,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: expenseColorDark,
            width: 1.4,
          ),
        ),
        labelStyle: const TextStyle(
          color: darkSecondaryText,
        ),
        floatingLabelStyle: const TextStyle(
          color: darkPrimary,
        ),
        hintStyle: const TextStyle(
          color: darkTertiaryText,
        ),
        prefixIconColor: darkSecondaryText,
        suffixIconColor: darkSecondaryText,
      ),

      dividerTheme: const DividerThemeData(
        color: darkOutline,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(
        color: darkSecondaryText,
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: darkSecondaryText,
        textColor: darkPrimaryText,
        tileColor: Colors.transparent,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return darkOnPrimary;
            }
            return darkSecondaryText;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return darkPrimary;
            }
            return darkSurfaceVariant;
          },
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return darkPrimary;
            }
            return darkOutline;
          },
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return darkPrimary;
            }
            return darkSurfaceVariant;
          },
        ),
        checkColor: WidgetStateProperty.all(
          darkOnPrimary,
        ),
        side: const BorderSide(
          color: darkOutline,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return darkPrimary;
            }
            return darkSecondaryText;
          },
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: darkPrimary,
        linearTrackColor: darkSurfaceVariant,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkElevated,
        contentTextStyle: const TextStyle(
          color: darkPrimaryText,
          fontSize: 13,
        ),
        actionTextColor: darkPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: darkOnPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(18),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(
            color: darkPrimary,
            width: 1,
          ),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 76,
        indicatorColor: darkPrimaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) {
            final selected =
                states.contains(WidgetState.selected);

            return TextStyle(
              color: selected
                  ? darkPrimary
                  : darkSecondaryText,
              fontSize: 11,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w600,
            );
          },
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) {
            final selected =
                states.contains(WidgetState.selected);

            return IconThemeData(
              color: selected
                  ? darkPrimary
                  : darkSecondaryText,
              size: 23,
            );
          },
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          color: darkPrimaryText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: darkSurface,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          color: darkPrimaryText,
          fontSize: 12,
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android:
              FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS:
              CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux:
              FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS:
              FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows:
              FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia:
              FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );

    // ============================================================
    // LIGHT THEME
    // ============================================================

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,

      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        onPrimary: lightOnPrimary,
        primaryContainer: lightPrimaryContainer,
        onPrimaryContainer: Color(0xFF29496A),
        secondary: Color(0xFF6E849D),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFE2EAF2),
        onSecondaryContainer: Color(0xFF304458),
        tertiary: Color(0xFF7389A0),
        surface: lightSurface,
        surfaceContainerHighest: lightSurfaceVariant,
        onSurface: lightPrimaryText,
        onSurfaceVariant: lightSecondaryText,
        outline: lightOutline,
        outlineVariant: Color(0xFFE0E6ED),
        error: expenseColorLight,
        onError: Color(0xFFFFFFFF),
      ),

      scaffoldBackgroundColor: lightBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightPrimaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightPrimaryText,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: lightPrimaryText,
        ),
      ),

      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: const TextStyle(
          color: lightPrimaryText,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: lightSecondaryText,
          fontSize: 14,
          height: 1.45,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: lightOutline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: lightPrimary,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: expenseColorLight,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: expenseColorLight,
            width: 1.4,
          ),
        ),
        labelStyle: const TextStyle(
          color: lightSecondaryText,
        ),
        floatingLabelStyle: const TextStyle(
          color: lightPrimary,
        ),
        hintStyle: const TextStyle(
          color: lightTertiaryText,
        ),
        prefixIconColor: lightSecondaryText,
        suffixIconColor: lightSecondaryText,
      ),

      dividerTheme: const DividerThemeData(
        color: lightOutline,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(
        color: lightSecondaryText,
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: lightSecondaryText,
        textColor: lightPrimaryText,
        tileColor: Colors.transparent,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return lightOnPrimary;
            }
            return lightSecondaryText;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return lightPrimary;
            }
            return lightSurfaceVariant;
          },
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return lightPrimary;
            }
            return lightOutline;
          },
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return lightPrimary;
            }
            return lightSurface;
          },
        ),
        checkColor: WidgetStateProperty.all(
          lightOnPrimary,
        ),
        side: const BorderSide(
          color: lightOutline,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return lightPrimary;
            }
            return lightSecondaryText;
          },
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: lightPrimary,
        linearTrackColor: lightSurfaceVariant,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2B3948),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF5F8FC),
          fontSize: 13,
        ),
        actionTextColor: Color(0xFFB9D4F7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightPrimary,
        foregroundColor: lightOnPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(18),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: lightOnPrimary,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPrimary,
          side: const BorderSide(
            color: lightPrimary,
            width: 1,
          ),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 76,
        indicatorColor: lightPrimaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) {
            final selected =
                states.contains(WidgetState.selected);

            return TextStyle(
              color: selected
                  ? lightPrimary
                  : lightSecondaryText,
              fontSize: 11,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w600,
            );
          },
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) {
            final selected =
                states.contains(WidgetState.selected);

            return IconThemeData(
              color: selected
                  ? lightPrimary
                  : lightSecondaryText,
              size: 23,
            );
          },
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          color: lightPrimaryText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: lightSurface,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF2B3948),
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          color: Color(0xFFF5F8FC),
          fontSize: 12,
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android:
              FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS:
              CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux:
              FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS:
              FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows:
              FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia:
              FadeForwardsPageTransitionsBuilder(),
        },
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
                '/recurring-transactions':
                    (context) =>
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
