import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:reviewapp/screens/splash_screen.dart'; // Assicurati che questo sia il percorso corretto

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null); // Inizializza per la localizzazione italiana
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definiamo un colore seme che useremo per entrambi i temi (chiaro e scuro)
    // Puoi cambiare questo colore direttamente qui.
    const Color primarySeedColor = Colors.blueAccent; // Esempio: usa Colors.deepPurple, Colors.teal, etc.

    return MaterialApp(
      title: 'Review App',

      // Configurazione per la localizzazione
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', 'IT'),
        Locale('en', 'US'),
      ],

      // --- CONFIGURAZIONE DEL TEMA ---

      // 1. TEMA DI DEFAULT (LIGHT THEME)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primarySeedColor, // Usa direttamente il Color
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primarySeedColor, // Usa direttamente il Color
          foregroundColor: Colors.white,
          elevation: 4.0,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primarySeedColor, // Usa direttamente il Color
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primarySeedColor, // Usa direttamente il Color
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),

      // 2. TEMA SCURO (DARK THEME)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primarySeedColor, // Usa direttamente il Color (stesso seme o uno diverso)
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
          elevation: 4.0,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData( // CORREZIONE: Deve essere CardThemeData
          color: Colors.grey[800],
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primarySeedColor, // Usa direttamente il Color
          foregroundColor: Colors.black, // O bianco, per contrasto
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primarySeedColor, // Usa direttamente il Color
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),

      // 3. THEME MODE
      themeMode: ThemeMode.dark, // Forza il tema scuro

      home: const SplashScreen(),
    );
  }
}
