import 'package:intl/intl.dart';

enum TypePeriode {
  semaine('Semaine'),
  mois('Mois'),
  trimestre('Trimestre'),
  annee('Année');

  final String libelle;
  const TypePeriode(this.libelle);
}

/// Période d'analyse des rapports (bornes incluses).
class Periode {
  final TypePeriode type;
  final DateTime debut;
  final DateTime fin;

  const Periode._(this.type, this.debut, this.fin);

  /// Période de type [type] contenant [date] (semaines du lundi au dimanche).
  factory Periode.contenant(TypePeriode type, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    late DateTime debut;
    late DateTime finExclue;
    switch (type) {
      case TypePeriode.semaine:
        debut = DateTime(d.year, d.month, d.day - (d.weekday - 1));
        finExclue = DateTime(debut.year, debut.month, debut.day + 7);
      case TypePeriode.mois:
        debut = DateTime(d.year, d.month, 1);
        finExclue = DateTime(d.year, d.month + 1, 1);
      case TypePeriode.trimestre:
        final premierMois = ((d.month - 1) ~/ 3) * 3 + 1;
        debut = DateTime(d.year, premierMois, 1);
        finExclue = DateTime(d.year, premierMois + 3, 1);
      case TypePeriode.annee:
        debut = DateTime(d.year, 1, 1);
        finExclue = DateTime(d.year + 1, 1, 1);
    }
    return Periode._(type, debut, finExclue.subtract(const Duration(microseconds: 1)));
  }

  Periode get precedente => Periode.contenant(type, debut.subtract(const Duration(days: 1)));
  Periode get suivante => Periode.contenant(type, fin.add(const Duration(days: 1)));

  /// Même période un an plus tôt (comparaison « N-1 »).
  Periode get anneePrecedente =>
      Periode.contenant(type, DateTime(debut.year - 1, debut.month, debut.day));

  bool contient(DateTime date) => !date.isBefore(debut) && !date.isAfter(fin);

  bool get estEnCours => contient(DateTime.now());
  bool get estFuture => debut.isAfter(DateTime.now());

  String get libelle => switch (type) {
        TypePeriode.semaine =>
          'Semaine du ${DateFormat('d MMM yyyy', 'fr_FR').format(debut)}',
        TypePeriode.mois => DateFormat.yMMMM('fr_FR').format(debut),
        TypePeriode.trimestre => 'T${(debut.month - 1) ~/ 3 + 1} ${debut.year}',
        TypePeriode.annee => '${debut.year}',
      };

  @override
  bool operator ==(Object other) =>
      other is Periode && other.type == type && other.debut == debut;

  @override
  int get hashCode => Object.hash(type, debut);
}
