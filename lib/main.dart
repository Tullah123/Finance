import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';

// App entry point: init services and run UI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await NotificationService.instance.init();
  await ThemeService.init();
  runApp(const PersonalFinanceApp());
}

/// Root widget that wires theme modes and navigation.
class PersonalFinanceApp extends StatelessWidget {
  const PersonalFinanceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService.modeNotifier,
      builder: (context, mode, _) {
        final isBlack = mode == AppThemeMode.black;
        return MaterialApp(
          title: 'Finance Tracker',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(brightness: Brightness.light, pureBlack: false),
          darkTheme: _buildTheme(brightness: Brightness.dark, pureBlack: isBlack),
          themeMode: ThemeService.toThemeMode(mode),
          home: const SplashScreen(),
        );
      },
    );
  }

  // Build light/dark theme palettes.
  ThemeData _buildTheme({
    required Brightness brightness,
    required bool pureBlack,
  }) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B998B),
      brightness: brightness,
    );

    final colorScheme = brightness == Brightness.light
        ? baseScheme.copyWith(
            surface: const Color(0xFFFFFFFF),
            background: const Color(0xFFF4F7F8),
          )
        : baseScheme.copyWith(
            surface:
                pureBlack ? const Color(0xFF0D0F10) : const Color(0xFF171A1C),
            background: pureBlack ? Colors.black : const Color(0xFF0F1214),
          );

    final textTheme = _buildTextTheme(brightness);
    final appBarTheme = _buildAppBarTheme(colorScheme, brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      appBarTheme: appBarTheme,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: colorScheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.45)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 32,
        dense: true,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: colorScheme.primary,
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // Text styles for light vs dark modes.
  TextTheme _buildTextTheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E2A32),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E2A32),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF394955),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Color(0xFF5C6B75),
        ),
      );
    }

    return const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFFCDD6DC),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Color(0xFF9AA7B2),
      ),
    );
  }

  // AppBar styling for each mode.
  AppBarTheme _buildAppBarTheme(
    ColorScheme colorScheme,
    Brightness brightness,
  ) {
    final isLight = brightness == Brightness.light;
    return AppBarTheme(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: isLight ? const Color(0xFF1E2A32) : colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(
        color: isLight ? const Color(0xFF1E2A32) : colorScheme.onSurface,
      ),
    );
  }
}

