import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_constants.dart';
import '../viewmodels/category_viewmodel.dart';

/// Graphique en anneau de la répartition des dépenses par catégorie.
/// Un appui sur une portion (ou sur la légende) appelle [onCategorieTap].
class DepensesDonutChart extends StatefulWidget {
  /// Montant dépensé par identifiant de catégorie.
  final Map<String, double> parCategorie;
  final String devise;
  final void Function(String categorieId)? onCategorieTap;

  const DepensesDonutChart({
    super.key,
    required this.parCategorie,
    required this.devise,
    this.onCategorieTap,
  });

  @override
  State<DepensesDonutChart> createState() => _DepensesDonutChartState();
}

class _DepensesDonutChartState extends State<DepensesDonutChart> {
  int? _survole;

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoryViewModel>();
    final entrees = widget.parCategorie.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entrees.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Aucune dépense sur la période',
              style: TextStyle(color: AppConstants.texteSecondaire)),
        ),
      );
    }

    Color couleur(String id) => AppHelpers.hexToColor(cats.findById(id)!.couleur);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 58,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      final index = response?.touchedSection?.touchedSectionIndex;
                      setState(() => _survole = event.isInterestedForInteractions ? index : null);
                      if (event is FlTapUpEvent && index != null && index >= 0 && index < entrees.length) {
                        widget.onCategorieTap?.call(entrees[index].key);
                      }
                    },
                  ),
                  sections: [
                    for (var i = 0; i < entrees.length; i++)
                      PieChartSectionData(
                        value: entrees[i].value,
                        color: couleur(entrees[i].key),
                        radius: _survole == i ? 42 : 34,
                        title: entrees[i].value / total >= 0.07
                            ? '${(entrees[i].value / total * 100).round()}%'
                            : '',
                        titleStyle: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total', style: TextStyle(fontSize: 12, color: AppConstants.texteSecondaire)),
                  Text(AppHelpers.formatMontant(total, widget.devise),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final e in entrees)
              ActionChip(
                avatar: CircleAvatar(backgroundColor: couleur(e.key), radius: 6),
                label: Text(
                    '${cats.findById(e.key)!.nom} · ${(e.value / total * 100).round()}%',
                    style: const TextStyle(fontSize: 12)),
                onPressed: widget.onCategorieTap == null
                    ? null
                    : () => widget.onCategorieTap!(e.key),
              ),
          ],
        ),
      ],
    );
  }
}
