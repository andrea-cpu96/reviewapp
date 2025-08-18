import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../models/recensione.dart';
import '../widgets/recensione_form.dart';

class RecensioneHomePage extends StatefulWidget {
  final String? reviewerName;

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
    _caricaRecensioni(); // L'ordinamento avverrà qui
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchText = _searchController.text.toLowerCase();
        });
      }
    });
    print("HomePage initState: Reviewer Name è ${widget.reviewerName}");
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Funzione helper per l'ordinamento
  void _ordinaRecensioni() {
    _recensioni.sort((a, b) {
      // Ordina per dataCreazione decrescente (più recenti prima)
      return b.dataCreazione.compareTo(a.dataCreazione);
    });
  }

  Future<void> _salvaRecensioni() async {
    final prefs = await SharedPreferences.getInstance();
    // L'ordinamento è già stato fatto prima di salvare, quindi la lista è già ordinata
    final jsonList = _recensioni.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setString('lista_recensioni', jsonEncode(jsonList));
  }

  Future<void> _caricaRecensioni() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('lista_recensioni');
    if (data != null) {
      try {
        final jsonListRaw = jsonDecode(data);
        if (jsonListRaw is List) {
          final jsonList = List<String>.from(jsonListRaw.map((item) => item is String ? item : jsonEncode(item)));
          if (!mounted) return;
          setState(() {
            _recensioni.clear();
            _recensioni.addAll(jsonList.map((rJson) {
              try {
                return Recensione.fromJson(jsonDecode(rJson));
              } catch (e) {
                print("Errore deserializzando una recensione: $rJson, errore: $e");
                // Restituisci un oggetto placeholder o gestisci l'errore diversamente
                return Recensione(
                    titolo: "Errore Dati",
                    genere: "",
                    voto: 0,
                    trama: "",
                    recensione: "Dati corrotti",
                    dataCreazione: DateTime.fromMicrosecondsSinceEpoch(0) // Data minima per metterla in fondo
                );
              }
            }).where((r) => r.titolo != "Errore Dati")); // Filtra gli errori
            _ordinaRecensioni(); // Ordina dopo il caricamento
          });
        }
      } catch (e) {
        print("Errore caricando le recensioni da SharedPreferences: $e");
        // Potresti voler pulire _recensioni o mostrare un errore all'utente
        if (mounted) {
          setState(() {
            _recensioni.clear();
          });
        }
      }
    }
  }

  Future<void> _sincronizzaConServer() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sincronizzazione col server...')),
    );
    final url = Uri.parse('https://andreaitareviews.duckdns.org/recensioni');
    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> datiDalServer = jsonDecode(response.body);
        int aggiunte = 0;
        int aggiornate = 0;

        final Set<String> chiaviLocali = _recensioni.map((r) {
          final reviewerKey = r.reviewerName?.toLowerCase().trim() ?? 'anonimo';
          return '${r.titolo.toLowerCase().trim()}_$reviewerKey';
        }).toSet();

        List<Recensione> recensioniDaAggiungere = [];
        Map<String, Recensione> recensioniDaAggiornareMap = {}; // Usiamo una mappa per evitare duplicati di aggiornamento

        for (var rJson in datiDalServer) {
          final recensioneServer = Recensione.fromJson(rJson as Map<String, dynamic>);
          final serverReviewerKey = recensioneServer.reviewerName?.toLowerCase().trim() ?? 'anonimo';
          final chiaveServer = '${recensioneServer.titolo.toLowerCase().trim()}_$serverReviewerKey';

          if (chiaviLocali.contains(chiaveServer)) {
            final indexLocale = _recensioni.indexWhere((rLoc) {
              final localReviewerKey = rLoc.reviewerName?.toLowerCase().trim() ?? 'anonimo';
              return rLoc.titolo.toLowerCase().trim() == recensioneServer.titolo.toLowerCase().trim() &&
                  localReviewerKey == serverReviewerKey;
            });

            if (indexLocale != -1) {
              final recensioneLocale = _recensioni[indexLocale];
              if (recensioneLocale.recensione != recensioneServer.recensione ||
                  recensioneLocale.voto != recensioneServer.voto ||
                  recensioneLocale.trama != recensioneServer.trama ||
                  recensioneLocale.genere != recensioneServer.genere ||
                  !recensioneLocale.dataCreazione.isAtSameMomentAs(recensioneServer.dataCreazione)) {
                // Metti in mappa per l'aggiornamento, usando la chiaveServer per evitare duplicati
                // Se ci sono più versioni server per la stessa chiave, l'ultima vince
                recensioniDaAggiornareMap[chiaveServer] = recensioneServer;
              }
            }
          } else {
            recensioniDaAggiungere.add(recensioneServer);
          }
        }

        if (!mounted) return;

        if (recensioniDaAggiungere.isNotEmpty || recensioniDaAggiornareMap.isNotEmpty) {
          setState(() {
            for (var recensioneNuova in recensioniDaAggiungere) {
              _recensioni.add(recensioneNuova);
              aggiunte++;
            }

            recensioniDaAggiornareMap.forEach((chiave, recensioneAggiornata) {
              final indexLocaleDaAggiornare = _recensioni.indexWhere((rLoc) {
                final localReviewerKey = rLoc.reviewerName?.toLowerCase().trim() ?? 'anonimo';
                final serverReviewerKeyAggiornata = recensioneAggiornata.reviewerName?.toLowerCase().trim() ?? 'anonimo';
                return rLoc.titolo.toLowerCase().trim() == recensioneAggiornata.titolo.toLowerCase().trim() &&
                    localReviewerKey == serverReviewerKeyAggiornata;
              });
              if (indexLocaleDaAggiornare != -1) {
                _recensioni[indexLocaleDaAggiornare] = recensioneAggiornata;
                aggiornate++;
              } else {
                // Non dovrebbe succedere se la logica sopra è corretta, ma per sicurezza:
                _recensioni.add(recensioneAggiornata); // Trattala come aggiunta
                aggiunte++;
                print("WARN: Recensione server (aggiornamento) ${recensioneAggiornata.titolo} non trovata, aggiunta come nuova.");
              }
            });

            _ordinaRecensioni(); // Riordina la lista completa
          });
          await _salvaRecensioni();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sincronizzazione completata: $aggiunte nuove, $aggiornate aggiornate localmente.')),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore dal server: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      print("Errore durante la sincronizzazione: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore di rete durante la sincronizzazione: $e')),
      );
    }
  }

  Future<void> _eliminaRecensioneEffettiva(Recensione recensione, int originalIndex) async {
    // L'indice originale dovrebbe essere ancora valido se la lista non è stata riordinata
    // tra la selezione e l'eliminazione, ma _recensioni è la nostra source of truth.
    // La ricerca per oggetto è più sicura se l'indice potesse cambiare.
    final indexDaRimuovere = _recensioni.indexWhere((r) => r.hashCode == recensione.hashCode && r.titolo == recensione.titolo);

    if (indexDaRimuovere == -1) {
      print("Errore: Recensione non trovata per l'eliminazione effettiva: ${recensione.titolo}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore: recensione non trovata per eliminazione.')),
      );
      return;
    }

    final recensioneDaEliminare = _recensioni[indexDaRimuovere];
    if (mounted) {
      setState(() {
        _recensioni.removeAt(indexDaRimuovere);
        // Non c'è bisogno di riordinare qui perché stiamo solo rimuovendo
      });
    }
    await _salvaRecensioni();
    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recensione "${recensioneDaEliminare.titolo}" eliminata localmente.')),
      );
    }
  }

  Future<void> _tentaEliminazioneServer(Recensione recensioneDaEliminare) async {
    String urlString = 'https://andreaitareviews.duckdns.org/recensioni/${Uri.encodeComponent(recensioneDaEliminare.titolo)}';
    final url = Uri.parse(urlString);

    try {
      final response = await http.delete(url);
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recensione eliminata anche dal server.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server: errore eliminazione ${response.statusCode} (${response.body}).')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore di rete durante l\'eliminazione dal server: $e')),
      );
    }
  }

  void _apriForm({Recensione? iniziale, int? index}) async {
    final String? defaultNameForNewReview = (iniziale == null) ? widget.reviewerName : null;

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
          defaultReviewerName: defaultNameForNewReview,
        ),
      ),
    );

    if (!mounted) return;

    if (risultatoForm != null) {
      setState(() {
        if (index != null && index >= 0 && index < _recensioni.length) {
          // Stiamo modificando una recensione esistente
          // L'indice potrebbe non essere più valido se la lista è stata filtrata.
          // Troviamo la recensione originale per riferimento sicuro
          final recensioneOriginale = (iniziale != null)
              ? _recensioni.firstWhere(
                  (r) => r.hashCode == iniziale.hashCode && r.titolo == iniziale.titolo,
              orElse: () => _recensioni[index] // Fallback se non trovata (improbabile)
          )
              : _recensioni[index]; // Se l'indice è valido e iniziale è null (improbabile qui)

          final indiceDaModificare = _recensioni.indexOf(recensioneOriginale);
          if (indiceDaModificare != -1) {
            _recensioni[indiceDaModificare] = risultatoForm;
          } else {
            // Non dovrebbe succedere, ma per sicurezza aggiungila
            _recensioni.add(risultatoForm);
          }
        } else {
          // Nuova recensione
          _recensioni.add(risultatoForm);
        }
        _ordinaRecensioni(); // Riordina dopo aggiunta o modifica
      });
      await _salvaRecensioni();
    }
  }

  void _mostraDettagli(Recensione r) {
    // Converti in ora locale PRIMA di formattare
    final String dataFormattata = DateFormat('dd/MM/yyyy HH:mm', 'it_IT').format(r.dataCreazione.toLocal());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(r.titolo),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (r.reviewerName != null && r.reviewerName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    'Recensito da: ${r.reviewerName}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[700]),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Pubblicato il: $dataFormattata', // Usa la data convertita e formattata
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
              const Text('📝 Recensione completa:', style: TextStyle(fontWeight: FontWeight.bold)),
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
        ? 'Recensioni (Utente: ${widget.reviewerName})'
        : 'Tutte le Recensioni';

    // La lista _recensioni è già ordinata, quindi recensioniFiltrate manterrà l'ordine
    // se il filtro non altera l'ordine relativo degli elementi che passano il filtro.
    final List<Recensione> recensioniFiltrate = _searchText.isEmpty
        ? _recensioni
        : _recensioni.where((r) {
      final titoloMatch = r.titolo.toLowerCase().contains(_searchText);
      final reviewerMatch = r.reviewerName?.toLowerCase().contains(_searchText) ?? false;
      return titoloMatch || reviewerMatch;
    }).toList();
    // Se la ricerca dovesse alterare l'ordine, si potrebbe riordinare recensioniFiltrate qui,
    // ma .where() di solito preserva l'ordine.

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizza con Server',
            onPressed: _sincronizzaConServer,
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
                labelText: '🔍 Cerca per titolo o autore...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: recensioniFiltrate.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _recensioni.isEmpty
                      ? 'Nessuna recensione ancora.\nPremi "+" per aggiungerne una!'
                      : 'Nessuna recensione trovata per "${_searchText}".',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            )
                : ListView.builder(
              itemCount: recensioniFiltrate.length,
              itemBuilder: (context, indexFiltro) {
                final recensione = recensioniFiltrate[indexFiltro];
                // Usiamo una chiave più affidabile basata sull'hashCode dell'oggetto e sulla data
                final itemKey = ValueKey('${recensione.hashCode}-${recensione.dataCreazione.toIso8601String()}');
                // Converti in ora locale PRIMA di formattare
                final String dataCardFormattata = DateFormat('dd/MM/yy', 'it_IT').format(recensione.dataCreazione.toLocal());

                return Dismissible(
                  key: itemKey,
                  background: Container(
                    color: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [Icon(Icons.edit, color: Colors.white), SizedBox(width: 8), Text('Modifica', style: TextStyle(color: Colors.white))],
                    ),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [Text('Elimina', style: TextStyle(color: Colors.white)), SizedBox(width: 8), Icon(Icons.delete, color: Colors.white)],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    // Trova l'indice originale nella lista _recensioni non filtrata
                    // È più sicuro trovare per oggetto piuttosto che affidarsi all'indice della lista filtrata
                    final originalIndexInFullList = _recensioni.indexWhere((r) =>
                    r.hashCode == recensione.hashCode && // Usa hashCode per un confronto più affidabile
                        r.titolo == recensione.titolo &&
                        r.reviewerName == recensione.reviewerName &&
                        r.dataCreazione.isAtSameMomentAs(recensione.dataCreazione)
                    );

                    if (originalIndexInFullList == -1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Errore: recensione non trovata per l\'operazione.')),
                      );
                      return false; // Non permettere il dismiss
                    }

                    if (direction == DismissDirection.endToStart) { // Elimina
                      final Recensione recensioneDaEliminare = _recensioni[originalIndexInFullList];
                      bool? confermaDialogo;
                      Function? eliminaDaServerAction;

                      confermaDialogo = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Conferma Eliminazione'),
                          content: Text('Sei sicuro di voler eliminare la recensione per "${recensioneDaEliminare.titolo}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              child: const Text('Elimina Solo Localmente', style: TextStyle(color: Colors.orange)),
                            ),
                            TextButton(
                                onPressed: () {
                                  eliminaDaServerAction = () => _tentaEliminazioneServer(recensioneDaEliminare);
                                  Navigator.pop(context, true);
                                },
                                child: const Text('Elimina da Server e Locale', style: TextStyle(color: Colors.red))
                            ),
                          ],
                        ),
                      );

                      if (confermaDialogo == true) {
                        // Passa la recensione stessa e l'indice trovato nella lista completa
                        await _eliminaRecensioneEffettiva(recensioneDaEliminare, originalIndexInFullList);
                        if (eliminaDaServerAction != null) {
                          await eliminaDaServerAction!();
                        }
                        return true; // Conferma il dismiss
                      }
                      return false; // Annulla il dismiss

                    } else if (direction == DismissDirection.startToEnd) { // Modifica
                      // Passa l'indice della recensione nella lista completa _recensioni
                      _apriForm(iniziale: _recensioni[originalIndexInFullList], index: originalIndexInFullList);
                      return false; // Non eseguire il dismiss, gestiamo la modifica
                    }
                    return false; // Default: non eseguire il dismiss
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    elevation: 2,
                    child: InkWell(
                      onTap: () => _mostraDettagli(recensione),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(recensione.titolo, style: Theme.of(context).textTheme.titleLarge),
                            if (recensione.reviewerName != null && recensione.reviewerName!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
                                child: Text(
                                  'Recensito da: ${recensione.reviewerName}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[600]),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                              child: Text(
                                dataCardFormattata, // Usa la data convertita e formattata
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey[500]),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: recensione.voto,
                                  itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                                  itemCount: 3,
                                  itemSize: 20.0,
                                  direction: Axis.horizontal,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '(${recensione.voto.toStringAsFixed(1)}) • 🎬 ${recensione.genere}',
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recensione.trama,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                            ),
                          ],
                        ),
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
        onPressed: () {
          if (widget.reviewerName == null || widget.reviewerName!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Per favore, imposta un nome utente per aggiungere recensioni.')),
            );
          } else {
            _apriForm();
          }
        },
        tooltip: 'Aggiungi Recensione',
        child: const Icon(Icons.add),
      ),
    );
  }
}
