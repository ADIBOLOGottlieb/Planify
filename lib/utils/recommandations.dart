import 'app_constants.dart';

/// Données d'entrée des recommandations pour une période.
class DonneesRecommandation {
  final double depenses;
  final double revenus;
  final double depensesPrecedentes;

  /// Dépenses par nom de catégorie (période analysée et période précédente).
  final Map<String, double> parCategorie;
  final Map<String, double> parCategoriePrecedente;

  /// Noms des budgets dépassés sur la période.
  final List<String> budgetsDepasses;
  final String devise;

  const DonneesRecommandation({
    required this.depenses,
    required this.revenus,
    required this.depensesPrecedentes,
    required this.parCategorie,
    required this.parCategoriePrecedente,
    required this.budgetsDepasses,
    required this.devise,
  });
}

/// Recommandations personnalisées d'optimisation du budget, calculées à
/// partir des habitudes de l'utilisateur (règles simples et explicables).
List<String> genererRecommandations(DonneesRecommandation d) {
  final conseils = <String>[];
  final categories = d.parCategorie.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final premiere = categories.isEmpty ? null : categories.first;

  // 1. Taux d'épargne
  if (d.revenus > 0) {
    final taux = (d.revenus - d.depenses) / d.revenus;
    if (taux < 0) {
      conseils.add('Vos dépenses dépassent vos revenus de '
          '${AppHelpers.formatMontant(d.depenses - d.revenus, d.devise)}.'
          '${premiere != null ? ' Réduisez en priorité « ${premiere.key} ».' : ''}');
    } else if (taux < 0.10) {
      conseils.add('Vous épargnez ${(taux * 100).round()} % de vos revenus. '
          'Visez au moins 10 % : mettez de côté '
          '${AppHelpers.formatMontant(d.revenus * 0.10, d.devise)} dès la réception de vos revenus.');
    } else {
      conseils.add('Bravo : vous épargnez ${(taux * 100).round()} % de vos revenus. '
          'Pensez à alimenter un objectif d\'épargne.');
    }
  }

  // 2. Plus forte hausse par catégorie
  String? hausseCat;
  double hausseMax = 0;
  for (final e in d.parCategorie.entries) {
    final avant = d.parCategoriePrecedente[e.key] ?? 0;
    if (avant <= 0) continue;
    final hausse = (e.value - avant) / avant;
    if (hausse > hausseMax) {
      hausseMax = hausse;
      hausseCat = e.key;
    }
  }
  if (hausseCat != null && hausseMax >= 0.20) {
    conseils.add('Vos dépenses « $hausseCat » ont augmenté de '
        '${(hausseMax * 100).round()} % par rapport à la période précédente.');
  }

  // 3. Concentration des dépenses
  if (premiere != null && d.depenses > 0 && premiere.value / d.depenses >= 0.40) {
    conseils.add('« ${premiere.key} » représente ${(premiere.value / d.depenses * 100).round()} % '
        'de vos dépenses : fixez-lui un budget dédié.');
  }

  // 4. Budgets dépassés
  for (final nom in d.budgetsDepasses) {
    conseils.add('Budget « $nom » dépassé : ajustez son montant ou limitez ces dépenses.');
  }

  // 5. Tendance globale
  if (d.depensesPrecedentes > 0 && d.depenses < d.depensesPrecedentes * 0.9) {
    conseils.add('Vos dépenses ont baissé de '
        '${((1 - d.depenses / d.depensesPrecedentes) * 100).round()} % : continuez ainsi !');
  }

  if (conseils.isEmpty) {
    conseils.add('Continuez à enregistrer vos dépenses et revenus pour obtenir '
        'des conseils personnalisés.');
  }
  return conseils;
}
