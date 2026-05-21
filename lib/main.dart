import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/authentication/login_page.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6A4CFF),
      primary: const Color(0xFF6A4CFF),
      secondary: const Color(0xFF00C896),
    );
    final textTheme = _buildCompactTextTheme(ThemeData.light().textTheme);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MesclaInvest',
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(0.94)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: colorScheme,
        textTheme: textTheme,
        primaryTextTheme: textTheme,
        scaffoldBackgroundColor: const Color(0xFFF2F5F9),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF3A1C71),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A4CFF),
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      // Login continua sendo a tela inicial.
      // Após autenticar, navegue para MainScreen usando:
      //   Navigator.pushReplacement(context,
      //     MaterialPageRoute(builder: (_) => const MainScreen()));
      home: const LoginPage(),
      routes: {
        '/home': (context) => const MainScreen(),
        '/wallet': (context) => const MainScreen(initialIndex: 3),
      },
    );
  }
}

TextTheme _buildCompactTextTheme(TextTheme base) {
  final themed = base.apply(
    fontFamily: 'Inter',
    bodyColor: const Color(0xFF1A1A2E),
    displayColor: const Color(0xFF1A1A2E),
  );

  return themed.copyWith(
    displayLarge: themed.displayLarge?.copyWith(fontSize: 44),
    displayMedium: themed.displayMedium?.copyWith(fontSize: 38),
    displaySmall: themed.displaySmall?.copyWith(fontSize: 32),
    headlineLarge: themed.headlineLarge?.copyWith(
      fontSize: 26,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: themed.headlineMedium?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: themed.headlineSmall?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: themed.titleLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: themed.titleMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: themed.titleSmall?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: themed.bodyLarge?.copyWith(fontSize: 14),
    bodyMedium: themed.bodyMedium?.copyWith(fontSize: 13),
    bodySmall: themed.bodySmall?.copyWith(fontSize: 11),
    labelLarge: themed.labelLarge?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: themed.labelMedium?.copyWith(fontSize: 11),
    labelSmall: themed.labelSmall?.copyWith(fontSize: 10),
  );
}
