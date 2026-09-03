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

/// Menyimpan preferensi tema aplikasi secara lokal.
///
/// Tidak mengubah data transaksi atau alur bisnis aplikasi.
class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedTheme = preferences.getString(_themeKey);

    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _themeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
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

/// Palet utama Cimpli Finance.
///
/// Light mode menggunakan warna pastel yang lembut.
/// Dark mode menggunakan abu-abu lembut, bukan hitam pekat.
class _AppPalette {
  const _AppPalette._();

  // Light
  static const lightBackground = Color(0xFFF7F8FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceSoft = Color(0xFFF1F4FA);
  static const lightSurfaceMuted = Color(0xFFE9EDF5);
  static const lightBorder = Color(0xFFE1E6EF);
  static const lightText = Color(0xFF202735);
  static const lightTextSecondary = Color(0xFF687386);
  static const lightTextTertiary = Color(0xFF98A2B3);

  // Soft pastel accents
  static const blue = Color(0xFF6F8FEA);
  static const blueSoft = Color(0xFFE8EEFF);
  static const green = Color(0xFF61B9A7);
  static const greenSoft = Color(0xFFE7F6F2);
  static const purple = Color(0xFF9A83D9);
  static const purpleSoft = Color(0xFFF0EBFB);
  static const red = Color(0xFFD87979);
  static const redSoft = Color(0xFFFFECEC);

  // Dark: neutral gray, still comfortable to read.
  static const darkBackground = Color(0xFF2C2F34);
  static const darkSurface = Color(0xFF36393F);
  static const darkSurfaceSoft = Color(0xFF40434A);
  static const darkSurfaceMuted = Color(0xFF484B52);
  static const darkBorder = Color(0xFF50535A);
  static const darkText = Color(0xFFF1F3F6);
  static const darkTextSecondary = Color(0xFFB8BDC6);
  static const darkTextTertiary = Color(0xFF8E949E);

  static const darkBlue = Color(0xFF9CB3F4);
  static const darkBlueSoft = Color(0xFF46506A);
  static const darkGreen = Color(0xFF86CBBB);
  static const darkPurple = Color(0xFFB6A5E5);
  static const darkRed = Color(0xFFE39A9A);
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({
    super.key,
    required this.store,
    required this.themeController,
  });

  final FinanceStore store;
  final ThemeController themeController;

  ThemeData _buildLightTheme() {
    const scheme = ColorScheme.light(
      primary: _AppPalette.blue,
      onPrimary: Colors.white,
      primaryContainer: _AppPalette.blueSoft,
      onPrimaryContainer: _AppPalette.lightText,
      secondary: _AppPalette.green,
      onSecondary: Colors.white,
      secondaryContainer: _AppPalette.greenSoft,
      onSecondaryContainer: _AppPalette.lightText,
      tertiary: _AppPalette.purple,
      onTertiary: Colors.white,
      tertiaryContainer: _AppPalette.purpleSoft,
      onTertiaryContainer: _AppPalette.lightText,
      error: _AppPalette.red,
      onError: Colors.white,
      errorContainer: _AppPalette.redSoft,
      onErrorContainer: _AppPalette.lightText,
      surface: _AppPalette.lightSurface,
      onSurface: _AppPalette.lightText,
      surfaceContainerHighest: _AppPalette.lightSurfaceMuted,
      onSurfaceVariant: _AppPalette.lightTextSecondary,
      outline: _AppPalette.lightBorder,
      outlineVariant: _AppPalette.lightBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: _AppPalette.lightBackground,
      dividerColor: _AppPalette.lightBorder,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: _AppPalette.lightBackground,
        foregroundColor: _AppPalette.lightText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _AppPalette.lightText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),

      cardTheme: CardThemeData(
        color: _AppPalette.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: _AppPalette.lightBorder,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _AppPalette.lightSurfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: _AppPalette.lightTextTertiary,
        ),
        labelStyle: const TextStyle(
          color: _AppPalette.lightTextSecondary,
        ),
        prefixIconColor: _AppPalette.lightTextSecondary,
        suffixIconColor: _AppPalette.lightTextSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: _AppPalette.blue,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: _AppPalette.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: _AppPalette.red,
            width: 1.2,
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _AppPalette.lightSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _AppPalette.blueSoft,
        elevation: 0,
        height: 72,
        labelTextStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            color: _AppPalette.lightTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const WidgetStatePropertyAll<IconThemeData>(
          IconThemeData(
            color: _AppPalette.lightTextSecondary,
            size: 23,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _AppPalette.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _AppPalette.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _AppPalette.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _AppPalette.lightText,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(
            color: _AppPalette.lightBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _AppPalette.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _AppPalette.lightTextSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: _AppPalette.lightSurfaceSoft,
        selectedColor: _AppPalette.blueSoft,
        disabledColor: _AppPalette.lightSurfaceMuted,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: const TextStyle(
          color: _AppPalette.lightTextSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: _AppPalette.lightTextSecondary,
        textColor: _AppPalette.lightText,
        contentPadding: EdgeInsets.symmetric(horizontal: 4),
      ),

      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return _AppPalette.lightTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _AppPalette.blue;
          }
          return _AppPalette.lightSurfaceMuted;
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _AppPalette.lightText,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _AppPalette.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _AppPalette.lightSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: _AppPalette.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _AppPalette.blue,
        linearTrackColor: _AppPalette.blueSoft,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const scheme = ColorScheme.dark(
      primary: _AppPalette.darkBlue,
      onPrimary: Color(0xFF26303F),
      primaryContainer: _AppPalette.darkBlueSoft,
      onPrimaryContainer: _AppPalette.darkText,
      secondary: _AppPalette.darkGreen,
      onSecondary: Color(0xFF26302E),
      secondaryContainer: Color(0xFF435B56),
      onSecondaryContainer: _AppPalette.darkText,
      tertiary: _AppPalette.darkPurple,
      onTertiary: Color(0xFF302A3E),
      tertiaryContainer: Color(0xFF514967),
      onTertiaryContainer: _AppPalette.darkText,
      error: _AppPalette.darkRed,
      onError: Color(0xFF3A2929),
      errorContainer: Color(0xFF5B4141),
      onErrorContainer: _AppPalette.darkText,
      surface: _AppPalette.darkSurface,
      onSurface: _AppPalette.darkText,
      surfaceContainerHighest: _AppPalette.darkSurfaceMuted,
      onSurfaceVariant: _AppPalette.darkTextSecondary,
      outline: _AppPalette.darkBorder,
      outlineVariant: _AppPalette.darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: _AppPalette.darkBackground,
      dividerColor: _AppPalette.darkBorder,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: _AppPalette.darkBackground,
        foregroundColor: _AppPalette.darkText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _AppPalette.darkText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),

      cardTheme: CardThemeData(
        color: _AppPalette.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: _AppPalette.darkBorder,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _AppPalette.darkSurfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: _AppPalette.darkTextTertiary,
        ),
        labelStyle: const TextStyle(
          color: _AppPalette.darkTextSecondary,
        ),
        prefixIconColor: _AppPalette.darkTextSecondary,
        suffixIconColor: _AppPalette.darkTextSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: _AppPalette.darkBlue,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: _AppPalette.darkRed,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: _AppPalette.darkRed,
            width: 1.2,
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _AppPalette.darkSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _AppPalette.darkBlueSoft,
        elevation: 0,
        height: 72,
        labelTextStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            color: _AppPalette.darkTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const WidgetStatePropertyAll<IconThemeData>(
          IconThemeData(
            color: _AppPalette.darkTextSecondary,
            size: 23,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _AppPalette.darkBlue,
        foregroundColor: const Color(0xFF27303D),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _AppPalette.darkBlue,
          foregroundColor: const Color(0xFF27303D),
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _AppPalette.darkBlue,
          foregroundColor: const Color(0xFF27303D),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _AppPalette.darkText,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(
            color: _AppPalette.darkBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _AppPalette.darkBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _AppPalette.darkTextSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: _AppPalette.darkSurfaceSoft,
        selectedColor: _AppPalette.darkBlueSoft,
        disabledColor: _AppPalette.darkSurfaceMuted,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: const TextStyle(
          color: _AppPalette.darkTextSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: _AppPalette.darkTextSecondary,
        textColor: _AppPalette.darkText,
        contentPadding: EdgeInsets.symmetric(horizontal: 4),
      ),

      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF30343A);
          }
          return _AppPalette.darkTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _AppPalette.darkBlue;
          }
          return _AppPalette.darkSurfaceMuted;
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _AppPalette.darkSurfaceMuted,
        contentTextStyle: const TextStyle(
          color: _AppPalette.darkText,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _AppPalette.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _AppPalette.darkSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: _AppPalette.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _AppPalette.darkBlue,
        linearTrackColor: _AppPalette.darkSurfaceMuted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = _buildLightTheme();
    final darkTheme = _buildDarkTheme();

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
