import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/export_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/periode.dart';
import '../../utils/recommandations.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../viewmodels/category_viewmodel.dart';
import '../../viewmodels/recurrence_viewmodel.dart';
import '../../viewmodels/transaction_viewmodel.dart';
import '../../widgets/depenses_donut_chart.dart';
import '../transactions/transactions_screen.dart';

/// Suivi et visualisation : synthèse d'une période (semaine, mois, trimestre,
/// année), comparaisons, graphiques, prévisions et recommandations.
class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  Periode _periode = Periode.contenant(TypePeriode.mois, DateTime.now());
  bool _export = false;

  Map<String, double> _parNom(Map<String, double> parId, CategoryViewModel cats) {
    final r = <String, double>{};
    parId.forEach((id, v) {
      final nom = cats.findById(id)!.nom;
      r[nom] = (r[nom] ?? 0) + v;
    });
    return r;
  }

  List<String> _recommandations(TransactionViewModel tx, CategoryViewModel cats,
      BudgetViewModel budgets, String devise) {
    final t = tx.totauxSurPeriode(_periode.debut, _periode.fin);
    final prec = _periode.precedente;
    return genererRecommandations(DonneesRecommandation(
      depenses: t.depenses,
      revenus: t.revenus,
      depensesPrecedentes: tx.totauxSurPeriode(prec.debut, prec.fin).depenses,
      parCategorie: _parNom(tx.depensesParCategorieSurPeriode(_periode.debut, _periode.fin), cats),
      parCategoriePrecedente: _parNom(tx.depensesParCategorieSurPeriode(prec.debut, prec.fin), cats),
      budgetsDepasses: budgets.budgets
          .where((b) => b.estDepasse && !b.dateFin.isBefore(_periode.debut) && !b.dateDebut.isAfter(_periode.fin))
          .map((b) => b.categorie?.nom ?? 'global')
          .toList(),
      devise: devise,
    ));
  }

  Future<void> _exporter() async {
    final tx = context.read<TransactionViewModel>();
    final cats = context.read<CategoryViewModel>();
    final budgets = context.read<BudgetViewModel>();
    final user = context.read<AuthViewModel>().currentUser;
    final devise = user?.devise ?? 'FCFA';
    final t = tx.totauxSurPeriode(_periode.debut, _periode.fin);
    final prec = _periode.precedente;
    setState(() => _export = true);
    try {
      await ExportService().exportRapportPdf(
        titre: 'Rapport — ${_periode.libelle}',
        utilisateur: '${user?.prenom ?? ''} ${user?.nom ?? ''}'.trim(),
        revenus: t.revenus,
        depenses: t.depenses,
        depensesPeriodePrecedente: tx.totauxSurPeriode(prec.debut, prec.fin).depenses,
        depensesParCategorie:
            _parNom(tx.depensesParCategorieSurPeriode(_periode.debut, _periode.fin), cats),
        transactions: tx.rechercher(FiltreTransactions(debut: _periode.debut, fin: _periode.fin)),
        recommandations: _recommandations(tx, cats, budgets, devise),
        devise: devise,
      );
    } finally {
      if (mounted) setState(() => _export = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionViewModel>();
    final cats = context.watch<CategoryViewModel>();
    final budgets = context.watch<BudgetViewModel>();
    final rec = context.watch<RecurrenceViewModel>();
    final devise = context.watch<AuthViewModel>().currentUser?.devise ?? 'FCFA';

    final totaux = tx.totauxSurPeriode(_periode.debut, _periode.fin);
    final prec = _periode.precedente;
    final nMoins1 = _periode.anneePrecedente;
    final totPrec = tx.totauxSurPeriode(prec.debut, prec.fin);
    final totN1 = tx.totauxSurPeriode(nMoins1.debut, nMoins1.fin);
    final parCat = tx.depensesParCategorieSurPeriode(_periode.debut, _periode.fin);
    final prevu = rec.montantPrevuSurPeriode(
        _periode.estEnCours ? DateTime.now() : _periode.debut, _periode.fin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports & Analyses'),
        actions: [
          IconButton(
            tooltip: 'Exporter le rapport en PDF',
            onPressed: _export ? null : _exporter,
            icon: _export
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          SegmentedButton<TypePeriode>(
            segments: [
              for (final t in TypePeriode.values)
                ButtonSegment(value: t, label: Text(t.libelle, style: const TextStyle(fontSize: 12))),
            ],
            selected: {_periode.type},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                setState(() => _periode = Periode.contenant(s.first, DateTime.now())),
          ),
          const SizedBox(height: 12),
          _SelecteurPeriode(
            libelle: _periode.libelle,
            onPrec: () => setState(() => _periode = _periode.precedente),
            onSuiv: _periode.suivante.estFuture
                ? null
                : () => setState(() => _periode = _periode.suivante),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _SummaryCard(
                      label: 'Revenus',
                      montant: totaux.revenus,
                      devise: devise,
                      color: AppConstants.revenuColor,
                      icon: Icons.arrow_downward_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _SummaryCard(
                      label: 'Dépenses',
                      montant: totaux.depenses,
                      devise: devise,
                      color: AppConstants.depenseColor,
                      icon: Icons.arrow_upward_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _SummaryCard(
                      label: 'Solde',
                      montant: totaux.solde,
                      signe: true,
                      devise: devise,
                      color: AppConstants.secondaryColor,
                      icon: Icons.account_balance_wallet_rounded)),
            ],
          ),
          if (prevu != 0) ...[
            const SizedBox(height: 8),
            Text(
              'Récurrences à venir sur la période : ${AppHelpers.formatMontantSigne(-prevu, devise, plus: true)}',
              style: TextStyle(fontSize: 12, color: AppConstants.texteSecondaire),
            ),
          ],
          const _Titre('Comparaison'),
          _Carte(
            child: Column(
              children: [
                _LigneComparaison(
                    libelle: 'vs ${_periode.type == TypePeriode.annee ? 'année' : 'période'} précédente',
                    actuel: totaux.depenses,
                    reference: totPrec.depenses),
                if (_periode.type != TypePeriode.annee) ...[
                  const Divider(height: 20),
                  _LigneComparaison(
                      libelle: 'vs ${nMoins1.libelle}',
                      actuel: totaux.depenses,
                      reference: totN1.depenses),
                ],
              ],
            ),
          ),
          const _Titre('Budget prévu vs réel'),
          _BudgetPrevuReel(periode: _periode, depenses: totaux.depenses, devise: devise),
          const _Titre('Répartition des dépenses'),
          _Carte(
            child: DepensesDonutChart(
              parCategorie: parCat,
              devise: devise,
              onCategorieTap: (id) => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CategorieTransactionsScreen(
                          categorieId: id, debut: _periode.debut, fin: _periode.fin))),
            ),
          ),
          const _Titre('Évolution sur 12 mois'),
          _Carte(child: _EvolutionChart(data: tx.getEvolutionMensuelle(12))),
          const _Titre('Solde cumulé'),
          _Carte(child: _SoldeCumuleChart(points: tx.soldeCumule(12), devise: devise)),
          const _Titre('Prévisions (moyenne mobile)'),
          Text('Dépense mensuelle attendue, calculée sur les derniers mois complets',
              style: TextStyle(color: AppConstants.texteSecondaire, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final n in [3, 6, 12]) ...[
                Expanded(
                    child: _ForecastCard(
                        label: '$n mois',
                        amount: tx.previsionDepensesMensuelles(n),
                        devise: devise)),
                if (n != 12) const SizedBox(width: 8),
              ],
            ],
          ),
          const _Titre('Trajectoire financière'),
          _Trajectoire(tx: tx, devise: devise),
          const _Titre('Recommandations'),
          ..._recommandations(tx, cats, budgets, devise).map((r) => _Carte(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: AppConstants.primaryColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  final String texte;
  const _Titre(this.texte);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(texte, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );
}

class _Carte extends StatelessWidget {
  final Widget child;
  const _Carte({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: child,
      );
}

class _SelecteurPeriode extends StatelessWidget {
  final String libelle;
  final VoidCallback onPrec;
  final VoidCallback? onSuiv;

  const _SelecteurPeriode({required this.libelle, required this.onPrec, required this.onSuiv});

  @override
  Widget build(BuildContext context) {
    return _Carte(
      child: Row(
        children: [
          IconButton(onPressed: onPrec, icon: const Icon(Icons.chevron_left_rounded)),
          Expanded(
            child: Text(libelle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          IconButton(onPressed: onSuiv, icon: const Icon(Icons.chevron_right_rounded)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double montant;
  final String devise;
  final Color color;
  final IconData icon;
  final bool signe;

  const _SummaryCard(
      {required this.label,
      required this.montant,
      required this.devise,
      required this.color,
      required this.icon,
      this.signe = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
                signe
                    ? AppHelpers.formatMontantSigne(montant, devise)
                    : AppHelpers.formatMontant(montant, devise),
                maxLines: 1,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _LigneComparaison extends StatelessWidget {
  final String libelle;
  final double actuel;
  final double reference;

  const _LigneComparaison({required this.libelle, required this.actuel, required this.reference});

  @override
  Widget build(BuildContext context) {
    if (reference <= 0) {
      return Row(
        children: [
          Expanded(child: Text('Dépenses $libelle')),
          Text('pas de données', style: TextStyle(color: AppConstants.texteSecondaire, fontSize: 12)),
        ],
      );
    }
    final pct = ((actuel - reference) / reference * 100).round();
    final hausse = pct > 0;
    final couleur = hausse ? AppConstants.depenseColor : AppConstants.revenuColor;
    return Row(
      children: [
        Expanded(child: Text('Dépenses $libelle')),
        Icon(hausse ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: couleur, size: 18),
        const SizedBox(width: 6),
        Text('${pct > 0 ? '+' : ''}$pct %',
            style: TextStyle(fontWeight: FontWeight.bold, color: couleur)),
      ],
    );
  }
}

/// Écart entre le budget prévisionnel et les dépenses réelles de la période.
class _BudgetPrevuReel extends StatelessWidget {
  final Periode periode;
  final double depenses;
  final String devise;

  const _BudgetPrevuReel({required this.periode, required this.depenses, required this.devise});

  @override
  Widget build(BuildContext context) {
    final budgets = context.watch<BudgetViewModel>().budgets.where(
        (b) => !b.dateFin.isBefore(periode.debut) && !b.dateDebut.isAfter(periode.fin));
    // Un budget global prime sur la somme des budgets par catégorie.
    final globaux = budgets.where((b) => b.categorieId == null);
    final retenus = globaux.isNotEmpty ? globaux : budgets;
    double prevu = 0;
    for (final b in retenus) {
      // Part du budget correspondant aux jours communs avec la période.
      final debut = b.dateDebut.isAfter(periode.debut) ? b.dateDebut : periode.debut;
      final fin = b.dateFin.isBefore(periode.fin) ? b.dateFin : periode.fin;
      final joursCommuns = fin.difference(debut).inHours / 24 + 1;
      final joursBudget = b.dateFin.difference(b.dateDebut).inHours / 24 + 1;
      if (joursCommuns > 0 && joursBudget > 0) {
        prevu += b.montantAlloue * math.min(1, joursCommuns / joursBudget);
      }
    }
    if (prevu <= 0) {
      return _Carte(
        child: Text('Aucun budget défini sur cette période.',
            style: TextStyle(color: AppConstants.texteSecondaire)),
      );
    }
    final ecart = prevu - depenses;
    final pct = (depenses / prevu).clamp(0.0, 1.0);
    return _Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prévu : ${AppHelpers.formatMontant(prevu, devise)}'),
              Text('Réel : ${AppHelpers.formatMontant(depenses, devise)}'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: AppHelpers.couleurConsommation(depenses / prevu),
            backgroundColor: AppConstants.texteColor.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 8),
          Text(
            ecart >= 0
                ? 'Reste ${AppHelpers.formatMontant(ecart, devise)} sous le budget'
                : 'Dépassement de ${AppHelpers.formatMontant(-ecart, devise)}',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: ecart >= 0 ? AppConstants.revenuColor : AppConstants.depenseColor),
          ),
        ],
      ),
    );
  }
}

class _EvolutionChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _EvolutionChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold<double>(
        0, (m, d) => math.max(m, math.max(d['depenses'] as double, d['revenus'] as double)));
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY <= 0 ? 1 : maxY * 1.2,
              barGroups: [
                for (var i = 0; i < data.length; i++)
                  BarChartGroupData(x: i, barsSpace: 2, barRods: [
                    BarChartRodData(
                        toY: data[i]['revenus'] as double,
                        color: AppConstants.revenuColor,
                        width: 6,
                        borderRadius: BorderRadius.circular(3)),
                    BarChartRodData(
                        toY: data[i]['depenses'] as double,
                        color: AppConstants.depenseColor,
                        width: 6,
                        borderRadius: BorderRadius.circular(3)),
                  ]),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= data.length || i.isOdd && data.length > 6) {
                        return const SizedBox();
                      }
                      return Text(AppHelpers.formatMoisCourt(data[i]['mois'] as DateTime),
                          style: const TextStyle(fontSize: 10, color: Colors.grey));
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.withValues(alpha: 0.15), strokeWidth: 1)),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legende(couleur: AppConstants.revenuColor, texte: 'Revenus'),
            SizedBox(width: 16),
            _Legende(couleur: AppConstants.depenseColor, texte: 'Dépenses'),
          ],
        ),
      ],
    );
  }
}

class _Legende extends StatelessWidget {
  final Color couleur;
  final String texte;
  const _Legende({required this.couleur, required this.texte});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(texte, style: const TextStyle(fontSize: 11)),
        ],
      );
}

/// Courbe de tendance du solde cumulé (revenus − dépenses depuis le début).
class _SoldeCumuleChart extends StatelessWidget {
  final List<({DateTime mois, double solde})> points;
  final String devise;
  const _SoldeCumuleChart({required this.points, required this.devise});

  @override
  Widget build(BuildContext context) {
    final valeurs = points.map((p) => p.solde).toList();
    final minY = valeurs.reduce(math.min);
    final maxY = valeurs.reduce(math.max);
    final marge = math.max((maxY - minY) * 0.15, 1.0);
    return SizedBox(
      height: 170,
      child: LineChart(
        LineChartData(
          minY: minY - marge,
          maxY: maxY + marge,
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].solde)],
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppConstants.primaryColor,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                  show: true, color: AppConstants.primaryColor.withValues(alpha: 0.15)),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                      '${AppHelpers.formatMoisCourt(points[s.x.toInt()].mois)}\n'
                      '${AppHelpers.formatMontantSigne(s.y, devise)}',
                      const TextStyle(color: Colors.white, fontSize: 11)))
                  .toList(),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length || i.isOdd) return const SizedBox();
                  return Text(AppHelpers.formatMoisCourt(points[i].mois),
                      style: const TextStyle(fontSize: 10, color: Colors.grey));
                },
              ),
            ),
          ),
          gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.withValues(alpha: 0.15), strokeWidth: 1)),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

/// Projection du solde dans 3, 6 et 12 mois à partir des moyennes de revenus
/// et de dépenses des 6 derniers mois complets.
class _Trajectoire extends StatelessWidget {
  final TransactionViewModel tx;
  final String devise;
  const _Trajectoire({required this.tx, required this.devise});

  @override
  Widget build(BuildContext context) {
    final soldeActuel = tx.solde;
    final mensuel = tx.previsionRevenusMensuels(6) - tx.previsionDepensesMensuelles(6);
    return _Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Au rythme actuel, votre solde évolue de '
            '${AppHelpers.formatMontantSigne(mensuel, devise, plus: true)} par mois.',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final n in [3, 6, 12])
                Expanded(
                  child: Column(
                    children: [
                      Text('Dans $n mois',
                          style: TextStyle(fontSize: 12, color: AppConstants.texteSecondaire)),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Text(
                          AppHelpers.formatMontantSigne(soldeActuel + n * mensuel, devise),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: soldeActuel + n * mensuel >= 0
                                  ? AppConstants.revenuColor
                                  : AppConstants.depenseColor),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final String label;
  final double amount;
  final String devise;

  const _ForecastCard({required this.label, required this.amount, required this.devise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppConstants.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(AppHelpers.formatMontant(amount, devise),
                maxLines: 1,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
