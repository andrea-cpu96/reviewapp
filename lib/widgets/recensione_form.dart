import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import '../models/recensione.dart';

class RecensioneForm extends StatefulWidget {
  final Recensione? recensione;
  final String? defaultReviewerName;

  const RecensioneForm({
    Key? key,
    this.recensione,
    this.defaultReviewerName,
  }) : super(key: key);

  @override
  State<RecensioneForm> createState() => _RecensioneFormState();
}

class _RecensioneFormState extends State<RecensioneForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titoloController;
  late TextEditingController _tramaController;
  late TextEditingController _recensioneController;
  late double _voto;
  late String _genereSelezionato;
  bool _inviataAlServer = false; // Per tracciare se l'invio al server è già avvenuto

  // Lista dei generi, potresti renderla più dinamica o prenderla da altrove
  final List<String> _generiDisponibili = [
    'Azione', 'Avventura', 'Commedia', 'Drammatico', 'Fantascienza',
    'Fantasy', 'Horror', 'Mistero', 'Romantico', 'Thriller', 'Animazione', 'Documentario'
  ];

  @override
  void initState() {
    super.initState();
    _titoloController = TextEditingController(text: widget.recensione?.titolo ?? '');
    _tramaController = TextEditingController(text: widget.recensione?.trama ?? '');
    _recensioneController = TextEditingController(text: widget.recensione?.recensione ?? '');
    _voto = widget.recensione?.voto ?? 1.5; // Default a 1.5 stelle
    _genereSelezionato = widget.recensione?.genere ?? _generiDisponibili.firstWhere((g) => g == 'Drammatico', orElse: () => _generiDisponibili.first);

    // Se stiamo modificando una recensione che è già stata inviata al server (dovresti avere un modo per saperlo),
    // potresti voler inizializzare _inviataAlServer = true.
    // Per ora, assumiamo che al caricamento del form per modifica, non sia considerata "appena inviata".
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
      final String? finalReviewerName = widget.recensione?.reviewerName ?? widget.defaultReviewerName;

      final recensioneSalvata = Recensione(
        titolo: _titoloController.text.trim(),
        genere: _genereSelezionato,
        voto: _voto,
        trama: _tramaController.text.trim(),
        recensione: _recensioneController.text.trim(),
        reviewerName: finalReviewerName,
        dataCreazione: widget.recensione?.dataCreazione ?? DateTime.now(),
      );
      Navigator.of(context).pop(recensioneSalvata);
    }
  }

  Future<void> _inviaAlServer() async {
    if (!_formKey.currentState!.validate()) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Per favore, correggi gli errori nel form prima di inviare.')),
        );
      }
      return;
    }

    final String? finalReviewerName = widget.recensione?.reviewerName ?? widget.defaultReviewerName;

    final recensioneDaInviare = Recensione(
      titolo: _titoloController.text.trim(),
      genere: _genereSelezionato,
      voto: _voto,
      trama: _tramaController.text.trim(),
      recensione: _recensioneController.text.trim(),
      reviewerName: finalReviewerName,
      dataCreazione: widget.recensione?.dataCreazione ?? DateTime.now(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invio al server in corso...')),
    );

    // Determina se è una creazione (POST) o un aggiornamento (PUT)
    // Questo dipende da come il tuo server gestisce gli aggiornamenti.
    // Se il server usa POST per creare e PUT per aggiornare (identificando tramite titolo/id),
    // dovrai cambiare il metodo HTTP e l'URL di conseguenza.
    // Per semplicità, qui usiamo POST, assumendo che il server gestisca duplicati o aggiornamenti tramite POST.
    // URL per creare una nuova recensione
    final url = Uri.parse('https://andreaitareviews.duckdns.org/recensioni');
    // Se fosse un aggiornamento, l'URL potrebbe essere qualcosa come:
    // final url = Uri.parse('https://andreaitareviews.duckdns.org/recensioni/${Uri.encodeComponent(recensioneDaInviare.titolo)}');
    // e il metodo http.put(...)

    try {
      // Per ora usiamo POST, il server dovrebbe gestire la logica di creazione/aggiornamento
      final response = await http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(recensioneDaInviare.toJson()),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) { // 201 Created, 200 OK (se aggiorna)
        setState(() {
          _inviataAlServer = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recensione inviata/aggiornata con successo al server! ✅')),
        );
        // Opzionale: puoi anche chiudere il form qui se l'invio ha successo
        // Navigator.of(context).pop(recensioneDaInviare);
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
          // fillColor: Colors.white.withOpacity(0.1), // Considera il tema qui
        ),
        // style: Theme.of(context).textTheme.bodyMedium, // Considera il tema per il testo
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
        top: 20, // Aggiunto un po' di padding in alto
      ),
      child: Form(
        key: _formKey,
        child: ListView( // Usato ListView per evitare overflow se la tastiera appare
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
              labelText: 'Titolo del Film/Serie TV',
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
                  // fillColor: Colors.white.withOpacity(0.1),
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
                validator: (value) => value == null || value.isEmpty ? 'Seleziona un genere' : null,
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
                    maxRating: 3, // Max 3 stelle
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 3, // 3 stelle visualizzate
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
                backgroundColor: _inviataAlServer ? Colors.green[700] : Theme.of(context).colorScheme.primary, // Colore diverso se inviata
              ),
              onPressed: _inviaAlServer,
            ),
            const SizedBox(height: 10), // Spazio per non far toccare i bottoni al fondo del bottom sheet
          ],
        ),
      ),
    );
  }
}
