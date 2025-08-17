import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'speech_bubble.dart'; // Assicurati che il percorso sia corretto

class WelcomeDialog extends StatefulWidget {
  final VoidCallback onNameSubmitted;

  const WelcomeDialog({
    Key? key,
    required this.onNameSubmitted,
  }) : super(key: key);

  @override
  State<WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<WelcomeDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _saveNameAndClose() async {
    if (_formKey.currentState!.validate()) {
      final String name = _nameController.text.trim();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reviewer_name', name);
      print("WelcomeDialog: Nome '$name' salvato.");

      widget.onNameSubmitted();

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String welcomeMessage =
        "Salve reviewer e benvenuto nel mondo delle recensioni dei film. "
        "Sei stato selezionato con scrupolo per entrare a far parte del nostro team di reviewers. "
        "Qual è il tuo nome?";

    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      titlePadding: const EdgeInsets.only(top: 20.0, bottom: 0),
      contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 20.0),
      title: Center(
        child: Image.asset(
          'assets/images/giovanni.png',
          height: 100,
          errorBuilder: (context, error, stackTrace) {
            print("Errore caricamento immagine Giovanni: $error");
            return const Icon(Icons.person_pin_circle_outlined, size: 70, color: Colors.grey);
          },
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 10),
            SpeechBubble(
              text: welcomeMessage,
              backgroundColor: Colors.grey[200]!,
              textColor: Colors.black87,
              textAlign: TextAlign.left,
              borderRadius: 10.0,
              arrowHeight: 10.0,
              arrowWidth: 15.0,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            const SizedBox(height: 25),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Il tuo nome d\'arte',
                hintText: 'Es. Il Critico Cinematografico',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Per favore, inserisci il tuo nome';
                }
                if (value.trim().length < 3) {
                  return 'Il nome deve contenere almeno 3 caratteri';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _saveNameAndClose(),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: 15.0, top: 5.0),
      actions: <Widget>[
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onPressed: _saveNameAndClose,
          child: const Text('Conferma Nome'),
        ),
      ],
    );
  }
}
