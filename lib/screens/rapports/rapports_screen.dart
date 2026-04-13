import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recurrence_provider.dart';
import '../../utils/app_constants.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  DateTime _selectedMois = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final recProvider = context.watch<RecurrenceProvider>();
    final auth = context.watch<AuthProvider>();
    final devise = auth.currentUser?.devise ?? 'FCFA';
    final depensesParCat = txProvider.getDepensesParCategorie(_selectedMois);
    final evolution = txProvider.getEvolutionMensuelle(6);
    final sortedCats = depensesParCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalDepMois =
        depensesParCat.values.fold<double>(0, (sum, v) => sum + v);
    final prevMonth = DateTime(_selectedMois.year, _selectedMois.month - 1, 1);
    final depPrev = txProvider.getDepensesParCategorie(prevMonth).values.fold<double>(0, (s, v) => s + v);
    final diff = totalDepMois - depPrev;
    final diffPct = depPrev > 0 ? (diff / depPrev * 100).round() : 0;

    double avgDepenses(int nbMois) {
      final evo = txProvider.getEvolutionMensuelle(nbMois);
      final total = evo.fold<double>(0, (s, e) => s + (e['depenses'] as double));
      return nbMois == 0 ? 0 : total / nbMois;
    }

    final avg3 = avgDepenses(3);
    final avg6 = avgDepenses(6);
    final avg12 = avgDepenses(12);
    final debutMois = DateTime(_selectedMois.year, _selectedMois.month, 1);
    final finMois = DateTime(_selectedMois.year, _selectedMois.month + 1, 0);
    final prevu = recProvider.montantPrevuSurPeriode(debutMois, finMois);

    return Scaffold(
      appBar: AppBar(title: const Text('Rapports & Analyses')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month selector
            _MonthSelector(
              current: _selectedMois,
              onPrev: () => setState(() => _selectedMois =
                  DateTime(_selectedMois.year, _selectedMois.month - 1)),
              onNext: () {
                final next =
                    DateTime(_selectedMois.year, _selectedMois.month + 1);
                if (!next.isAfter(DateTime.now())) {
                  setState(() => _selectedMois = next);
                }
              },
            ),
            const SizedBox(height: 20),
            // Summary cards
            Row(
              children: [
                Expanded(
                    child: _SummaryCard(
                        label: 'Revenus',
                        montant: txProvider
                            .filtrer(type: 'revenu')
                            .where((t) =>
                                t.dateTransaction.month ==
                                    _selectedMois.month &&
                                t.dateTransaction.year == _selectedMois.year)
                            .fold<double>(0, (s, t) => s + t.montant),
                        devise: devise,
                        color: AppConstants.revenuColor,
                        icon: Icons.arrow_downward_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _SummaryCard(
                        label: 'Dépenses',
                        montant: totalDepMois,
                        devise: devise,
                        color: AppConstants.depenseColor,
                        icon: Icons.arrow_upward_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _SummaryCard(
                        label: 'Prévu',
                        montant: prevu.abs(),
                        devise: devise,
                        color: AppConstants.secondaryColor,
                        icon: Icons.schedule_rounded)),
              ],
            ),
            const SizedBox(height: 24),
            // Comparison
            const Text('Comparaison avec le mois précédent',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    diff >= 0 ? 'Dépenses en hausse' : 'Dépenses en baisse',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Icon(
                        diff >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: diff >= 0 ? AppConstants.depenseColor : Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${diff >= 0 ? '+' : ''}$diffPct%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: diff >= 0 ? AppConstants.depenseColor : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Forecast
            const Text('Prévisions (moyenne mobile)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _ForecastCard(label: '3 mois', amount: avg3, devise: devise)),
                const SizedBox(width: 12),
                Expanded(
                    child: _ForecastCard(label: '6 mois', amount: avg6, devise: devise)),
                const SizedBox(width: 12),
                Expanded(
                    child: _ForecastCard(label: '12 mois', amount: avg12, devise: devise)),
              ],
            ),
            const SizedBox(height: 24),
            // Pie chart
            if (depensesParCat.isNotEmpty) ...[
              const Text('Répartition des dépenses',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _PieChartSection(
                  data: depensesParCat, total: totalDepMois, devise: devise),
              const SizedBox(height: 24),
            ],
            // Evolution bar chart
            const Text('Évolution sur 6 mois',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _EvolutionChart(data: evolution, devise: devise),
            // Category breakdown
            if (sortedCats.isNotEmpty) ...[
              const Text('Détail par catégorie',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...sortedCats.map((e) => _CategoryRow(
                  name: e.key,
                  amount: e.value,
                  total: totalDepMois,
                  devise: devise)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime current;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthSelector(
      {required this.current, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left_rounded),
              padding: EdgeInsets.zero),
          Text(AppHelpers.formatMois(current),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
              padding: EdgeInsets.zero),
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

  const _SummaryCard(
      {required this.label,
      required this.montant,
      required this.devise,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w500))
          ]),
          const SizedBox(height: 6),
          Text(AppHelpers.formatMontant(montant, devise),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _PieChartSection extends StatefulWidget {
  final Map<String, double> data;
  final double total;
  final String devise;

  const _PieChartSection(
      {required this.data, required this.total, required this.devise});

  @override
  State<_PieChartSection> createState() => _PieChartSectionState();
}

class _PieChartSectionState extends State<_PieChartSection> {
  int _touched = -1;
  final List<Color> _colors = [
    const Color(0xFFE53935),
    const Color(0xFF1E88E5),
    const Color(0xFF43A047),
    const Color(0xFFFB8C00),
    const Color(0xFF8E24AA),
    const Color(0xFF00ACC1),
    const Color(0xFFF4511E),
    const Color(0xFF6D4C41),
    const Color(0xFF039BE5),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
          ]),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                    touchCallback: (e, r) => setState(() => _touched =
                        r?.touchedSection?.touchedSectionIndex ?? -1)),
                sections: entries.asMap().entries.map((e) {
                  final idx = e.key;
                  final isTouched = idx == _touched;
                  return PieChartSectionData(
                    value: e.value.value,
                    color: _colors[idx % _colors.length],
                    radius: isTouched ? 70 : 60,
                    title: isTouched
                        ? '${(e.value.value / widget.total * 100).toInt()}%'
                        : '',
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  );
                }).toList(),
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: entries
                .asMap()
                .entries
                .map((e) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                color: _colors[e.key % _colors.length],
                                borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 4),
                        Text(e.value.key,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _EvolutionChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String devise;

  const _EvolutionChart({required this.data, required this.devise});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
          ]),
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.fold<double>(
                  0,
                  (max, d) => [
                        max,
                        d['depenses'] as double,
                        d['revenus'] as double
                      ].reduce((a, b) => a > b ? a : b)) *
              1.2,
          barGroups: data
              .asMap()
              .entries
              .map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                          toY: e.value['revenus'] as double,
                          color:
                              AppConstants.revenuColor.withValues(alpha: 0.7),
                          width: 8,
                          borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(
                          toY: e.value['depenses'] as double,
                          color:
                              AppConstants.depenseColor.withValues(alpha: 0.7),
                          width: 8,
                          borderRadius: BorderRadius.circular(4)),
                    ],
                  ))
              .toList(),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx >= 0 && idx < data.length) {
                  final mois = data[idx]['mois'] as DateTime;
                  return Text(AppHelpers.formatMoisCourt(mois),
                      style: const TextStyle(fontSize: 11, color: Colors.grey));
                }
                return const SizedBox();
              },
            )),
          ),
          gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final double amount;
  final double total;
  final String devise;

  const _CategoryRow(
      {required this.name,
      required this.amount,
      required this.total,
      required this.devise});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
          ]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
              Row(children: [
                Text(AppHelpers.formatMontant(amount, devise),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppConstants.depenseColor)),
                const SizedBox(width: 8),
                Text('${(pct * 100).toInt()}%',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.shade200,
              color: AppConstants.depenseColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6),
        ],
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final String label;
  final double amount;
  final String devise;

  const _ForecastCard(
      {required this.label, required this.amount, required this.devise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppConstants.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppConstants.primaryColor.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Text(AppHelpers.formatMontant(amount, devise),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
