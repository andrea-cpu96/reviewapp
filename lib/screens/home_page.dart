import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/recensione.dart';
import '../widgets/recensione_form.dart';

class RecensioneHomePage extends StatefulWidget {
  final String? reviewerName; // Nome del reviewer loggato

  const RecensioneHomePage({
    super.key,
    this.reviewerName,
  });

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
      if (mounted) {
        setState(() {
          _searchText = _searchController.text.toLowerCase();
        });
      }
    });
    if (widget.reviewerName != null && widget.reviewerName!.isNotEmpty) {
      print("HomePage: Benvenuto ${widget.reviewerName}!");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _salvaRecensioni() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _recensioni.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setString('lista_recensioni', jsonEncode(jsonList));
  }

  Future<void> _caricaRecensioni() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('lista_recensioni');
    if (data != null) {
      final jsonList = List<String>.from(jsonDecode(data));
      if (!mounted) return;
      setState(() {
        _recensioni.clear();
        _recensioni.addAll(jsonList.map((r) => Recensione.fromJson(jsonDecode(r))));
        _recensioni.sort((a, b) => b.titolo.compareTo(a.titolo)); // Ordina al caricamento
      });
    }
  }

  // ... _sincronizzaConServer, eliminaRecensioneDalServer, inviaRecensioneAlServer (invariate per questa modifica) ...
  // Assicurati solo che inviaRecensioneAlServer usi recensione.toJson() che ora include reviewerName

  Future<void> _sincronizzaConServer() async {
    final url = Uri.parse('https://andreaitareviews.duckdns.org/recensioni');
    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> dati = jsonDecode(response.body);
        int aggiunte = 0;
        for (var rJson in dati) {
          final nuova = Recensione.fromJson(rJson); // fromJson ora gestisce reviewerName
          final esiste = _recensioni.any((rec) =>
          rec.titolo == nuova.titolo &&
              rec.genere == nuova.genere &&
              (rec.reviewerName == null || nuova.reviewerName == null || rec.reviewerName == nuova.reviewerName) // Considera reviewerName nell'unicità
          );
          if (!esiste) {
            if (mounted) {
              setState(() => _recensioni.add(nuova));
            }
            aggiunte++;
          }
        }
        _recensioni.sort((a, b) => b.titolo.compareTo(a.titolo));
        await _salvaRecensioni();
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sincronizzazione completata: $aggiunte nuove recensioni.')),
          );
        }
      } else {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Errore dal server durante la sincronizzazione: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore di rete durante la sincronizzazione: $e")),
      );
    }
  }

  Future<void> eliminaRecensioneDalServer(String titolo, String? reviewerName) async {
    // Potrebbe essere necessario passare anche il reviewerName se il server lo usa per identificare univocamente
    // Per ora, assumiamo che il titolo sia sufficiente o che il server gestisca i duplicati di titolo.
    final url = Uri.parse('https://andreaitareviews.duckdns.org/recensioni/${Uri.encodeComponent(titolo)}');
    try {
      final response = await http.delete(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recensione eliminata anche dal server')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore dal server durante l''eliminazione: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore di rete durante l''eliminazione: $e')),
      );
    }
  }


  Future<void> inviaRecensioneAlServer(Recensione r) async {
    final baseUrl = 'https://andreaitareviews.duckdns.org/recensioni';
    // L'URL per il check/PUT potrebbe dipendere da come il tuo server identifica univocamente le recensioni
    // (es. solo titolo, o titolo + reviewerName)
    final checkUrl = Uri.parse('$baseUrl/${Uri.encodeComponent(r.titolo)}');
    try {
      final checkResponse = await http.get(checkUrl);
      if (!mounted) return;

      final body = jsonEncode(r.toJson()); // toJson() ora include reviewerName

      if (checkResponse.statusCode == 200) {
        final updateResponse = await http.put(
          checkUrl,
          headers: const {'Content-Type': 'application/json'},
          body: body,
        );
        if (!mounted) return;
        if (updateResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recensione aggiornata sul server!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Errore nell'aggiornamento: ${updateResponse.statusCode} - ${updateResponse.body}")),
          );
        }
      } else if (checkResponse.statusCode == 404) {
        final createResponse = await http.post(
          Uri.parse(baseUrl),
          headers: const {'Content-Type': 'application/json'},
          body: body,
        );
        if (!mounted) return;
        if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recensione inviata al server!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Errore nell'invio: ${createResponse.statusCode} - ${createResponse.body}")),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore nel controllo esistenza recensione: ${checkResponse.statusCode} - ${checkResponse.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore di rete durante l'invio/aggiornamento: $e")),
      );
    }
  }


  void _apriForm({Recensione? iniziale, int? index}) async {
    final String? currentReviewerNameForNewReview = (iniziale == null) ? widget.reviewerName : null;

    final Recensione? risultatoForm = await showModalBottomSheet<Recensione>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: RecensioneForm(
          recensione: iniziale,
          defaultReviewerName: currentReviewerNameForNewReview, // Passa il nome per nuove recensioni
        ),
      ),
    );

    if (!mounted) return;
    if (risultatoForm != null) {
      setState(() {
        if (index != null) {
          _recensioni[index] = risultatoForm;
        } else {
          _recensioni.add(risultatoForm);
        }
        _recensioni.sort((a, b) => b.titolo.compareTo(a.titolo)); // Riordina dopo aggiunta/modifica
      });
      await _salvaRecensioni();
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // MOSTRA IL NOME DEL REVIEWER QUI, se presente
              if (r.reviewerName != null && r.reviewerName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Autore: ${r.reviewerName}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              Text('🎯 Voto: ${r.voto.toStringAsFixed(1)}'),
              RatingBarIndicator(
                rating: r.voto,
                itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                itemCount: 3,
                itemSize: 24.0,
                direction: Axis.horizontal,
              ),
              const SizedBox(height: 8),
              Text('🎬 Genere: ${r.genere}'),
              const SizedBox(height: 8),
              const Text('📖 Trama:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(r.trama),
              const SizedBox(height: 8),
              const Text('📝 Recensione:', style: TextStyle(fontWeight: FontWeight.bold)),
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


  @override
  Widget build(BuildContext context) {
    final String appBarTitle = widget.reviewerName != null && widget.reviewerName!.isNotEmpty
        ? 'Recensioni di ${widget.reviewerName}'
        : 'Le mie recensioni';

    final List<Recensione> recensioniFiltrate = _searchText.isEmpty
        ? _recensioni
        : _recensioni.where((r) {
      return r.titolo.toLowerCase().startsWith(_searchText);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
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
              decoration: const InputDecoration(
                labelText: '🔍 Cerca per titolo',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: recensioniFiltrate.isEmpty
                ? Center( /* ... testo "Nessuna recensione" ... */ )
                : ListView.builder(
              itemCount: recensioniFiltrate.length,
              itemBuilder: (context, index) {
                final r = recensioniFiltrate[index];
                final itemKey = ValueKey(r.titolo + r.voto.toString() + r.genere + (r.reviewerName ?? '')); // Chiave più univoca

                return Dismissible(
                  key: itemKey,
                  // ... background, secondaryBackground ...
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) { // Elimina
                      final confermaServer = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Elimina Recensione'),
                          content: const Text('Vuoi eliminare questa recensione anche dal server remoto (se presente)?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Solo Locale')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina da Server')),
                          ],
                        ),
                      );
                      if (mounted) {
                        setState(() {
                          final originalIndex = _recensioni.indexWhere((rec) => rec.titolo == r.titolo && rec.voto == r.voto && rec.genere == r.genere && rec.reviewerName == r.reviewerName);
                          if (originalIndex != -1) {
                            _recensioni.removeAt(originalIndex);
                          }
                        });
                        await _salvaRecensioni();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recensione eliminata localmente')));
                      }
                      if (confermaServer == true) {
                        await eliminaRecensioneDalServer(r.titolo, r.reviewerName); // Passa anche reviewerName se necessario al server
                      }
                      return true;
                    } else if (direction == DismissDirection.startToEnd) { // Modifica
                      final originalIndex = _recensioni.indexWhere((rec) => rec.titolo == r.titolo && rec.voto == r.voto && rec.genere == r.genere && rec.reviewerName == r.reviewerName);
                      if (originalIndex != -1) {
                        _apriForm(iniziale: r, index: originalIndex);
                      } else {
                        _apriForm(iniziale: r, index: _recensioni.indexOf(r)); // Fallback
                      }
                      return false;
                    }
                    return false;
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.titolo, style: Theme.of(context).textTheme.titleLarge),
                          // MOSTRA IL NOME DEL REVIEWER QUI, se presente
                          if (r.reviewerName != null && r.reviewerName!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                              child: Text(
                                'Recensito da: ${r.reviewerName}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[600]),
                              ),
                            ),
                          const SizedBox(height: 4), // Ridotto spazio se c'è il nome reviewer
                          Row(
                            children: [
                              RatingBarIndicator(
                                rating: r.voto,
                                itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                                itemCount: 3,
                                itemSize: 20.0,
                                direction: Axis.horizontal,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text('(${r.voto.toStringAsFixed(1)}) • 🎬 ${r.genere}', overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            r.trama,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => _mostraDettagli(r),
                                child: const Text('Leggi tutto'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => inviaRecensioneAlServer(r),
                                icon: const Icon(Icons.cloud_upload_outlined),
                                label: const Text('Condividi'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
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
