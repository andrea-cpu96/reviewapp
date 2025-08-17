import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart'; // Assicurati che il percorso sia corretto
import '../widgets/welcome_dialog.dart'; // Assicurati che il percorso sia corretto

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _mostraGif = true;
  String? _reviewerName;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _mostraGif = false;
    });

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    _reviewerName = prefs.getString('reviewer_name');

    if (_reviewerName == null) {
      print("SplashScreen: Reviewer nome NON trovato. Mostro il dialogo.");
      if (mounted) {
        _showWelcomeDialog();
      }
    } else {
      print("SplashScreen: Reviewer nome TROVATO: $_reviewerName. Navigo alla home.");
      Future.delayed(const Duration(milliseconds: 300), () {
        _navigateToHome(_reviewerName);
      });
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WelcomeDialog(
          onNameSubmitted: () {
            print("SplashScreen: Nome inviato dal dialogo. Ricarico e navigo.");
            _loadNameAndNavigate();
          },
        );
      },
    );
  }

  Future<void> _loadNameAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _reviewerName = prefs.getString('reviewer_name');
    _navigateToHome(_reviewerName);
  }

  void _navigateToHome(String? name) {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RecensioneHomePage(reviewerName: name)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _mostraGif
            ? Image.asset(
            'assets/cinepresa.gif',
            height: 150,
            errorBuilder: (context, error, stackTrace) {
              print("Errore caricamento GIF: $error");
              return const Text('Errore caricamento GIF', style: TextStyle(color: Colors.white));
            })
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
