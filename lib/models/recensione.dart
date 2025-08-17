import 'package:flutter/foundation.dart' show immutable; // Per @immutable

@immutable // Buona pratica per modelli di dati
class Recensione {
  final String titolo;
  final String genere;
  final double voto;
  final String trama;
  final String recensione;
  final String? reviewerName; // NUOVO CAMPO: nome del reviewer (opzionale)

  const Recensione({
    required this.titolo,
    required this.genere,
    required this.voto,
    required this.trama,
    required this.recensione,
    this.reviewerName, // Aggiunto al costruttore
  });

  // Metodo toJson per la serializzazione (per SharedPreferences e server)
  Map<String, dynamic> toJson() {
    return {
      'titolo': titolo,
      'genere': genere,
      'voto': voto,
      'trama': trama,
      'recensione': recensione,
      'reviewerName': reviewerName, // AGGIUNTO
    };
  }

  // Metodo fromJson per la deserializzazione
  factory Recensione.fromJson(Map<String, dynamic> json) {
    return Recensione(
      titolo: json['titolo'] as String? ?? 'N/A',
      genere: json['genere'] as String? ?? 'N/A',
      voto: (json['voto'] as num? ?? 0).toDouble(),
      trama: json['trama'] as String? ?? 'N/A',
      recensione: json['recensione'] as String? ?? 'N/A',
      reviewerName: json['reviewerName'] as String?, // AGGIUNTO (può essere null)
    );
  }

  // (Opzionale ma utile) Override equals e hashCode se usi questi oggetti in Set o come chiavi di Map
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Recensione &&
              runtimeType == other.runtimeType &&
              titolo == other.titolo &&
              genere == other.genere &&
              voto == other.voto &&
              // Compara anche reviewerName se vuoi che sia parte dell'identità unica
              reviewerName == other.reviewerName;

  @override
  int get hashCode => titolo.hashCode ^ genere.hashCode ^ voto.hashCode ^ (reviewerName?.hashCode ?? 0);

  // (Opzionale) Metodo copyWith per creare facilmente una copia modificata
  Recensione copyWith({
    String? titolo,
    String? genere,
    double? voto,
    String? trama,
    String? recensione,
    String? reviewerName, // Aggiunto qui
  }) {
    return Recensione(
      titolo: titolo ?? this.titolo,
      genere: genere ?? this.genere,
      voto: voto ?? this.voto,
      trama: trama ?? this.trama,
      recensione: recensione ?? this.recensione,
      reviewerName: reviewerName ?? this.reviewerName, // Gestisci anche il caso di volerlo settare a null
    );
  }
}

