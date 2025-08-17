import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recensione.dart';

class RecensioneForm extends StatefulWidget {
  final Recensione? recensione; // Per modificare una recensione esistente
  final String? defaultReviewerName; // Nome da usare per nuove recensioni

  const RecensioneForm({
    Key? key,
    this.recensione,
    this.defaultReviewerName, // Aggiunto al costruttore
  }) : super(key: key);

  @override
  State<RecensioneForm> createState() => _RecensioneFormState();
}

class _RecensioneFormState extends State<RecensioneForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titoloController;
  late TextEditingController _tramaController;
  late TextEditingController _recensioneController;
  double _voto = 1.5;
  String _genereSelezionato = 'Drammatico';

  final List<String> _generiDisponibili = const [
    'Azione', 'Avventura', 'Animazione', 'Commedia', 'Crime',
    'Documentario', 'Drammatico', 'Familiare', 'Fantasy', 'Storico',
    'Horror', 'Musicale', 'Mistero', 'Romantico', 'Fantascienza',
    'Sport', 'Thriller', 'Guerra', 'Western'
  ];
  bool _inviataAlServer = false;

  @override
  void initState() {
    super.initState();
    _titoloController = TextEditingController(text: widget.recensione?.titolo ?? '');
    _tramaController = TextEditingController(text: widget.recensione?.trama ?? '');
    _recensioneController = TextEditingController(text: widget.recensione?.recensione ?? '');
    _voto = widget.recensione?.voto ?? 1.5;
    _genereSelezionato = widget.recensione?.genere ?? _generiDisponibili.firstWhere((g) => g == 'Drammatico', orElse: () => _generiDisponibili.first);
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _tramaController.dispose();
    _recensioneController.dispose();
    super.dispose();
  }

  void _salvaLocalmente() {
    if (_formKey.currentState!.validate()) {
      // Se stiamo modificando una recensione esistente, usa il suo reviewerName originale.
      // Se ne stiamo creando una nuova, usa il defaultReviewerName passato dalla HomePage.
      final String? finalReviewerName = widget.recensione?.reviewerName ?? widget.defaultReviewerName;

      final recensioneSalvata = Recensione(
        titolo: _titoloController.text.trim(),
        genere: _genereSelezionato,
        voto: _voto,
        trama: _tramaController.text.trim(),
        recensione: _recensioneController.text.trim(),
        reviewerName: finalReviewerName, // ASSEGNA IL NOME QUI
      );
      Navigator.of(context).pop(recensioneSalvata);
    }
  }

  Future<void> _inviaAlServer() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Per favore, correggi gli errori nel form prima di inviare.')),
      );
      return;
    }

    final String? finalReviewerName = widget.recensione?.reviewerName ?? widget.defaultReviewerName;

    final recensioneDaInviare = Recensione(
      titolo: _titoloController.text.trim(),
      genere: _genereSelezionato,
      voto: _voto,
      trama: _tramaController.text.trim(),
      recensione: _recensioneController.text.trim(),
      reviewerName: finalReviewerName, // ASSEGNA IL NOME QUI
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invio al server in corso...')),
    );

    final url = Uri.parse('https://andreaitareviews.duckdns.org/recensioni');
    try {
      final response = await http.post( // Assumendo POST per semplicità, vedi note in HomePage
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(recensioneDaInviare.toJson()), // toJson() ora include reviewerName
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _inviataAlServer = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recensione inviata con successo al server! ✅')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante l\'invio al server: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore di rete durante l\'invio: $e')),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1), // Considera il tema qui
        ),
        style: Theme.of(context).textTheme.bodyMedium, // Considera il tema per il testo
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator ?? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Questo campo è obbligatorio';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Text(
              widget.recensione == null ? 'Nuova Recensione' : 'Modifica Recensione',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            _buildTextField(
              controller: _titoloController,
              labelText: 'Titolo del Film',
              icon: Icons.movie_filter_outlined,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                value: _genereSelezionato,
                decoration: InputDecoration(
                  labelText: 'Genere',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
                items: _generiDisponibili.map((String genere) {
                  return DropdownMenuItem<String>(
                    value: genere,
                    child: Text(genere),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _genereSelezionato = newValue;
                    });
                  }
                },
                validator: (value) => value == null ? 'Seleziona un genere' : null,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Voto (da 0.5 a 3 stelle):', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  RatingBar.builder(
                    initialRating: _voto,
                    minRating: 0.5,
                    maxRating: 3,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 3,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _voto = rating;
                      });
                    },
                  ),
                ],
              ),
            ),

            _buildTextField(
              controller: _tramaController,
              labelText: 'Breve Trama',
              icon: Icons.article_outlined,
              maxLines: 3,
            ),

            _buildTextField(
              controller: _recensioneController,
              labelText: 'La tua Recensione Completa',
              icon: Icons.rate_review_outlined,
              maxLines: 5,
            ),

            const SizedBox(height: 25),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt_outlined),
              label: Text(widget.recensione == null ? 'Salva Localmente' : 'Aggiorna Localmente'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: _salvaLocalmente,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(_inviataAlServer ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined),
              label: Text(_inviataAlServer ? 'Inviata al Server ✅' : 'Invia/Aggiorna sul Server'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: _inviataAlServer ? Colors.green[700] : Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}),
              ),
              onPressed: _inviaAlServer,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
