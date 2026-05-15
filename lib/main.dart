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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mescla Invest',
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
