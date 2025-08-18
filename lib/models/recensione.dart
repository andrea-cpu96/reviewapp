import 'package:flutter/foundation.dart' show immutable;

@immutable
class Recensione {
  final String titolo;
  final String genere;
  final double voto;
  final String trama;
  final String recensione;
  final String? reviewerName;
  final DateTime dataCreazione; // NUOVO CAMPO

  const Recensione({
    required this.titolo,
    required this.genere,
    required this.voto,
    required this.trama,
    required this.recensione,
    this.reviewerName,
    required this.dataCreazione, // AGGIUNTO AL COSTRUTTORE
  });

  Map<String, dynamic> toJson() {
    return {
      'titolo': titolo,
      'genere': genere,
      'voto': voto,
      'trama': trama,
      'recensione': recensione,
      'reviewerName': reviewerName,
      'dataCreazione': dataCreazione.toIso8601String(), // Converti DateTime in Stringa ISO
    };
  }

  factory Recensione.fromJson(Map<String, dynamic> json) {
    return Recensione(
      titolo: json['titolo'] as String? ?? 'N/A',
      genere: json['genere'] as String? ?? 'N/A',
      voto: (json['voto'] as num? ?? 0).toDouble(),
      trama: json['trama'] as String? ?? 'N/A',
      recensione: json['recensione'] as String? ?? 'N/A',
      reviewerName: json['reviewerName'] as String?,
      // Leggi la stringa e convertila in DateTime.
      // Fornisci un fallback a DateTime.now() se il campo non esiste o è malformato.
      dataCreazione: json['dataCreazione'] != null
          ? DateTime.parse(json['dataCreazione'] as String)
          : DateTime.now(),
    );
  }

  Recensione copyWith({
    String? titolo,
    String? genere,
    double? voto,
    String? trama,
    String? recensione,
    String? reviewerName,
    DateTime? dataCreazione, // AGGIUNTO A COPYWITH
  }) {
    return Recensione(
      titolo: titolo ?? this.titolo,
      genere: genere ?? this.genere,
      voto: voto ?? this.voto,
      trama: trama ?? this.trama,
      recensione: recensione ?? this.recensione,
      reviewerName: reviewerName ?? this.reviewerName,
      dataCreazione: dataCreazione ?? this.dataCreazione,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Recensione &&
              runtimeType == other.runtimeType &&
              titolo == other.titolo &&
              genere == other.genere &&
              voto == other.voto &&
              trama == other.trama &&
              recensione == other.recensione &&
              reviewerName == other.reviewerName &&
              dataCreazione == other.dataCreazione; // AGGIUNTO A EQUALS

  @override
  int get hashCode =>
      titolo.hashCode ^
      genere.hashCode ^
      voto.hashCode ^
      trama.hashCode ^
      recensione.hashCode ^
      reviewerName.hashCode ^
      dataCreazione.hashCode; // AGGIUNTO A HASHCODE
}
