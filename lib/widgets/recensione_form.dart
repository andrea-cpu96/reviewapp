import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/recensione.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecensioneForm extends StatefulWidget {
  final Recensione? recensione;

  const RecensioneForm({super.key, this.recensione});

  @override
  State<RecensioneForm> createState() => _RecensioneFormState();
}

class _RecensioneFormState extends State<RecensioneForm> {
  late TextEditingController _titoloController;
  late TextEditingController _tramaController;
  late TextEditingController _recensioneController;
  double _voto = 1.5;
  String _genere = 'Drammatico';

  final List<String> _generiDisponibili = const [
    'Azione',
    'Commedia',
    'Drammatico',
    'Horror',
    'Fantascienza',
    'Romantico',
    'Thriller',
    'Animazione',
    'Documentario',
  ];

  bool _inviata = false;

  @override
  void initState() {
    super.initState();
    _titoloController =
        TextEditingController(text: widget.recensione?.titolo ?? '');
    _tramaController =
        TextEditingController(text: widget.recensione?.trama ?? '');
    _recensioneController =
        TextEditingController(text: widget.recensione?.recensione ?? '');
    _voto = widget.recensione?.voto ?? 1.5;
    _genere = widget.recensione?.genere ?? _genere;
  }

  void _invia() {
    final nuova = Recensione(
      titolo: _titoloController.text,
      voto: _voto,
      genere: _genere,
      trama: _tramaController.text,
      recensione: _recensioneController.text,
    );
    Navigator.pop(context, nuova);
  }

  Future<void> _inviaAlServer() async {
    final recensione = Recensione(
      titolo: _titoloController.text,
      voto: _voto,
      genere: _genere,
      trama: _tramaController.text,
      recensione: _recensioneController.text,
    );

    final url = Uri.parse('https://andreaitareviews.duckdns.org/recensioni');
    try {
      final response = await http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(recensione.toJson()),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _inviata = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recensione inviata al server!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore nell'invio: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore di rete: $e")),
      );
    }
  }

  Widget _campo(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.edit),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        _campo('Titolo', _titoloController),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voto (fino a 3 stelle):',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RatingBar.builder(
              initialRating: _voto,
              minRating: 0.5,
              maxRating: 3,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 3,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _voto = rating;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _genere,
          decoration: InputDecoration(
            labelText: 'Genere',
            prefixIcon: const Icon(Icons.movie),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _generiDisponibili
              .map((genere) => DropdownMenuItem(
                    value: genere,
                    child: Text(genere),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _genere = val;
              });
            }
          },
        ),
        _campo('Trama', _tramaController, maxLines: 3),
        _campo('Recensione', _recensioneController, maxLines: 5),
        const SizedBox(height: 16),
        ElevatedButton(
          child: const Text('Salva localmente'),
          onPressed: _invia,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.cloud_upload),
          label: Text(_inviata ? 'Inviata ✅' : 'Invia al server'),
          onPressed: _inviaAlServer,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
