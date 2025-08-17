import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/recensione.dart';
import '../widgets/recensione_form.dart';

class RecensioneHomePage extends StatefulWidget {
  const RecensioneHomePage({super.key});

  @override
  State<RecensioneHomePage> createState() => _RecensioneHomePageState();
}

class _RecensioneHomePageState extends State<RecensioneHomePage> {
  final List<Recensione> _recensioni = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _caricaRecensioni();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _salvaRecensioni() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _recensioni.map((r) => jsonEncode(r.toJson())).toList();
    prefs.setString('recensioni', jsonEncode(jsonList));
  }

  Future<void> _caricaRecensioni() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('recensioni');
    if (data != null) {
      final jsonList = List<String>.from(jsonDecode(data));
      if (!mounted) return;
      setState(() {
        _recensioni.clear();
        _recensioni
            .addAll(jsonList.map((r) => Recensione.fromJson(jsonDecode(r))));
      });
    }
  }

  Future<void> _sincronizzaConServer() async {
    final url = Uri.parse('https://andreaitareviews.duckdns.org/recensioni');
    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> dati = jsonDecode(response.body);
        int aggiunte = 0;
        for (var r in dati) {
          final nuova = Recensione.fromJson(r);
          final esiste = _recensioni.any((rec) =>
          rec.titolo == nuova.titolo &&
              rec.genere == nuova.genere &&
              rec.trama == nuova.trama &&
              rec.recensione == nuova.recensione &&
              rec.voto == nuova.voto);
          if (!esiste) {
            setState(() => _recensioni.add(nuova));
            aggiunte++;
          }
        }
        _salvaRecensioni();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Sincronizzazione completata: $aggiunte nuove recensioni.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore dal server: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore di rete: $e")),
      );
    }
  }

  Future<void> eliminaRecensioneDalServer(String titolo) async {
    final url = Uri.parse(
        'https://andreaitareviews.duckdns.org/recensioni/${Uri.encodeComponent(titolo)}');

    try {
      final response = await http.delete(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recensione eliminata anche dal server')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore dal server: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore di rete: $e')),
      );
    }
  }

  void _apriForm({Recensione? iniziale, int? index}) async {
    final nuova = await showModalBottomSheet<Recensione>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: RecensioneForm(recensione: iniziale),
      ),
    );

    if (!mounted) return;

    if (nuova != null) {
      setState(() {
        if (index != null) {
          _recensioni[index] = nuova;
        } else {
          _recensioni.add(nuova);
        }
      });
      _salvaRecensioni();
    }
  }

  void _mostraDettagli(Recensione r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(r.titolo),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎯 Voto: ${r.voto.toStringAsFixed(1)}'),
              RatingBarIndicator(
                rating: r.voto,
                itemBuilder: (context, index) =>
                const Icon(Icons.star, color: Colors.amber),
                itemCount: 3,
                itemSize: 24.0,
                direction: Axis.horizontal,
              ),
              const SizedBox(height: 8),
              Text('🎬 Genere: ${r.genere}'),
              const SizedBox(height: 8),
              const Text('📖 Trama:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(r.trama),
              const SizedBox(height: 8),
              const Text('📝 Recensione:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(r.recensione),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Future<void> inviaRecensioneAlServer(Recensione r) async {
    final baseUrl = 'https://andreaitareviews.duckdns.org/recensioni';
    final checkUrl = Uri.parse('$baseUrl/${Uri.encodeComponent(r.titolo)}');

    try {
      final checkResponse = await http.get(checkUrl);
      if (!mounted) return;

      if (checkResponse.statusCode == 200) {
        final updateResponse = await http.put(
          checkUrl,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(r.toJson()),
        );

        if (updateResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recensione aggiornata sul server!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Errore nell'aggiornamento: ${updateResponse.statusCode}")),
          );
        }
      } else if (checkResponse.statusCode == 404) {
        final createResponse = await http.post(
          Uri.parse(baseUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(r.toJson()),
        );

        if (createResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recensione inviata al server!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                Text("Errore nell'invio: ${createResponse.statusCode}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text("Errore nel controllo: ${checkResponse.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore di rete: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Recensione> recensioniFiltrate = _recensioni.where((r) {
      return r.titolo.toLowerCase().startsWith(_searchText);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Le mie recensioni'),
        actions: [
          IconButton(
            onPressed: _sincronizzaConServer,
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizza con il server',
          ),
        ],
      ),
      body: Column(
          children: [
      Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: '🔍 Cerca per titolo',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
      ),
    ),
            Expanded(
              child: recensioniFiltrate.isEmpty
                  ? Center(
                child: Text(
                  'Nessuna recensione trovata',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
                  : ListView.builder(
                itemCount: recensioniFiltrate.length,
                itemBuilder: (context, index) {
                  final r = recensioniFiltrate[index];
                  return Dismissible(
                    key: ValueKey(r.titolo + r.voto.toString()),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.blue,
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        final conferma = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminare anche dal server?'),
                            content: const Text(
                                'Vuoi eliminare questa recensione anche dal server remoto?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Solo locale'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Elimina anche dal server'),
                              ),
                            ],
                          ),
                        );

                        setState(() => _recensioni.removeAt(index));
                        _salvaRecensioni();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Recensione eliminata')),
                        );

                        if (conferma == true) {
                          await eliminaRecensioneDalServer(r.titolo);
                        }

                        return true;
                      } else if (direction == DismissDirection.startToEnd) {
                        _apriForm(iniziale: r, index: index);
                        return false;
                      }
                      return false;
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.titolo,
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: r.voto,
                                  itemBuilder: (context, index) =>
                                  const Icon(Icons.star, color: Colors.amber),
                                  itemCount: 3,
                                  itemSize: 20.0,
                                  direction: Axis.horizontal,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                    '(${r.voto.toStringAsFixed(1)}) • 🎬 ${r.genere}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              r.trama,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => _mostraDettagli(r),
                                  child: const Text('Leggi tutto'),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () => inviaRecensioneAlServer(r),
                                  icon: const Icon(Icons.cloud_upload),
                                  label: const Text('Condividi'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _apriForm(),
        tooltip: 'Aggiungi Recensione',
        child: const Icon(Icons.add),
      ),
    );
  }
}
