import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); //“UI load hone se pehle sab native cheezen ready kar lo”
  //
  //
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]); //landscape disable //App sirf vertical mode me chalegi
//
//
  await NotificationService.instance.init();
  //Notification permissions
  runApp(const PersonalFinanceApp());
}

class PersonalFinanceApp extends StatelessWidget {
  const PersonalFinanceApp({Key? key}) : super(key: key);

  // performance better
// Flutter rebuild fast karta hai

  @override
  Widget build(BuildContext context) {
    //Flutter har bar UI redraw karta hai build() se
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B998B),
      brightness: Brightness.light,
    ); //App ke colors ka base

    return MaterialApp(
      title: 'Finance Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        //App ka global design system
        useMaterial3: true,
        colorScheme: baseScheme.copyWith(
          surface: const Color(0xFFFFFFFF),
          background: const Color(0xFFF4F7F8),
        ),
        scaffoldBackgroundColor:
            const Color(0xFFF4F7F8), //Default screen background
        visualDensity: VisualDensity.compact, //UI compact & modern
        materialTapTargetSize:
            MaterialTapTargetSize.shrinkWrap, //Buttons zyada bade nahi
        appBarTheme: const AppBarTheme(
          //
          //Sab screens ka AppBar defined ha yhan
          //
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1E2A32),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1E2A32)),
        ),
        textTheme: const TextTheme(
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
        ),
        //
        //
        // Finance app ke cards
        //
        //
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: EdgeInsets.zero,
        ),
        //
        //TextFields ka design
        //
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF4F7F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E6EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E6EA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1B998B), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF5C6B75)),
          hintStyle: const TextStyle(color: Color(0xFF9AA7B2)),
        ),
        //
        // Add Button
        //
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1B998B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        //
        //Lists clean banane ke liye
        //
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          minLeadingWidth: 32,
          dense: true,
        ),
        //
        //Tabs styling
        //
        tabBarTheme: const TabBarThemeData(
          indicatorColor: Color(0xFF1B998B),
          labelColor: Colors.white,
          unselectedLabelColor: Color(0xFF5C6B75),
          labelStyle: TextStyle(fontWeight: FontWeight.w700),
        ),
        //
        // Save - Submit - continue buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B998B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
        //
        // Skip - Cancle Button
        //
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
