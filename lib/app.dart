import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

class RecensioneApp extends StatelessWidget {
  const RecensioneApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recensioni',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
            titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            bodyMedium: TextStyle(fontSize: 16),
        ),
        cardTheme: const CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
        ),
        home: const SplashScreen(),
    );
  }
}
