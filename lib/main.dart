// lib/main.dart
import 'package:flutter/material.dart';
import 'package:reviewapp/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Review App',
      // IMPOSTA IL TEMA DARK QUI
      themeMode: ThemeMode.dark, // Puoi anche usare ThemeMode.system per seguire le impostazioni del telefono
      theme: ThemeData( // Tema chiaro (usato se themeMode è light o system e il sistema è light)
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        // Altre personalizzazioni per il tema chiaro
      ),
      darkTheme: ThemeData( // Tema scuro effettivo
        brightness: Brightness.dark,
        primarySwatch: Colors.blue, // Puoi scegliere un altro swatch se vuoi
        // Esempio di colori per un tema dark:
        scaffoldBackgroundColor: Colors.grey[900], // Sfondo scuro per le Scaffold
        cardColor: Colors.grey[850], // Sfondo per le Card
        // canvasColor sarà scuro di default con Brightness.dark
        // Personalizza altri colori come accentColor, buttonTheme, ecc.
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700], // Un blu più scuro per i bottoni
              foregroundColor: Colors.white,
            )
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.grey[800]?.withOpacity(0.5), // Sfondo per i campi di input
          // Altre personalizzazioni per i campi di input
        ),
        // ... altre personalizzazioni del tema dark
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
