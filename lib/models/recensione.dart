class Recensione {
  final String titolo;
  final double voto;
  final String genere;
  final String trama;
  final String recensione;

  Recensione({
    required this.titolo,
    required this.voto,
    required this.genere,
    required this.trama,
    required this.recensione,
  });

  // Metodo per convertire l'oggetto in una mappa JSON
  Map<String, dynamic> toJson() => {
        'titolo': titolo,
        'voto': voto,
        'genere': genere,
        'trama': trama,
        'recensione': recensione,
      };

  // Metodo per creare un oggetto Recensione da una mappa JSON
  factory Recensione.fromJson(Map<String, dynamic> json) => Recensione(
        titolo: json['titolo'],
        voto: (json['voto'] as num).toDouble(),
        genere: json['genere'],
        trama: json['trama'],
        recensione: json['recensione'],
      );
}
