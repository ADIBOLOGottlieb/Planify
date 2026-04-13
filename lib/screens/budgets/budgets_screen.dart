import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recurrence_provider.dart';
import '../../models/models.dart';
import '../../utils/app_constants.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final auth = context.watch<AuthProvider>();
    final devise = auth.currentUser?.devise ?? 'FCFA';
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: budgetProvider.budgets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline_rounded,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Aucun budget défini',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Créez des budgets pour mieux gérer vos dépenses',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _BudgetSummary(
                    budgets: budgetProvider.budgetsDuMois, devise: devise),
                const SizedBox(height: 20),
                const Text('Budgets du mois',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ...budgetProvider.budgetsDuMois
                    .map((b) => _BudgetCard(budget: b, devise: devise)),
                if (budgetProvider.budgets.length >
                    budgetProvider.budgetsDuMois.length) ...[
                  const SizedBox(height: 20),
                  const Text('Historique',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...budgetProvider.budgets
                      .where((b) => !budgetProvider.budgetsDuMois.contains(b))
                      .map((b) => _BudgetCard(budget: b, devise: devise)),
                ],
                const SizedBox(height: 20),
                const Text('Dépenses récurrentes',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                const _RecurrenceSection(),
                const SizedBox(height: 20),
                const Text('Calendrier des dépenses prévues',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                const _PlanningCalendar(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => const _AddBudgetSheet(),
        ),
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _BudgetSummary extends StatelessWidget {
  final List<Budget> budgets;
  final String devise;

  const _BudgetSummary({required this.budgets, required this.devise});

  double get totalAlloue =>
      budgets.fold<double>(0, (sum, b) => sum + b.montantAlloue);
  double get totalDepense =>
      budgets.fold<double>(0, (sum, b) => sum + b.montantDepense);
  double get globalPct =>
      totalAlloue > 0 ? (totalDepense / totalAlloue).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppConstants.primaryColor, Color(0xFF2A8C7A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          const Text('Budget Global',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppHelpers.formatMontant(totalDepense, devise),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22)),
              Text('/ ${AppHelpers.formatMontant(totalAlloue, devise)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: globalPct,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              color: globalPct >= 1
                  ? Colors.red
                  : globalPct >= 0.9
                      ? Colors.orange
                      : Colors.white,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('${(globalPct * 100).toInt()}% utilisé',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final String devise;

  const _BudgetCard({required this.budget, required this.devise});

  Color get color => budget.estDepasse
      ? AppConstants.depenseColor
      : budget.pourcentage >= 0.9
          ? Colors.orange
          : budget.pourcentage >= 0.6
              ? AppConstants.primaryColor
              : Colors.green;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => context.read<BudgetProvider>().supprimer(budget.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (budget.categorie != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                        color: AppHelpers.hexToColor(budget.categorie!.couleur)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(
                        AppHelpers.getCategoryIcon(budget.categorie!.icone),
                        size: 18,
                        color:
                            AppHelpers.hexToColor(budget.categorie!.couleur)),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(budget.categorie?.nom ?? 'Budget Global',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(budget.periode,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                if (budget.statutAlerte)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: (budget.estDepasse ? Colors.red : Colors.orange)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 16,
                        color: budget.estDepasse ? Colors.red : Colors.orange),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: budget.pourcentage,
                backgroundColor: Colors.grey.shade200,
                color: color,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppHelpers.formatMontant(budget.montantDepense, devise),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color)),
                Text(
                    '${AppHelpers.formatMontant(budget.restant, devise)} restant',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                    '/ ${AppHelpers.formatMontant(budget.montantAlloue, devise)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            if (budget.montantReporte > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Reporté: ${AppHelpers.formatMontant(budget.montantReporte, devise)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddBudgetSheet extends StatefulWidget {
  const _AddBudgetSheet();

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
  String _periode = 'mensuel';
  String? _categorieId;
  DateTime _debut = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fin = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  void _setPeriode(String p) {
    setState(() {
      _periode = p;
      final now = DateTime.now();
      if (p == 'mensuel') {
        _debut = DateTime(now.year, now.month, 1);
        _fin = DateTime(now.year, now.month + 1, 0);
      } else if (p == 'hebdomadaire') {
        final dayOfWeek = now.weekday;
        _debut = now.subtract(Duration(days: dayOfWeek - 1));
        _fin = _debut.add(const Duration(days: 6));
      } else {
        _debut = DateTime(now.year, 1, 1);
        _fin = DateTime(now.year, 12, 31);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final catProvider = context.read<CategoryProvider>();
    final txProvider = context.read<TransactionProvider>();

    final montant = AppHelpers.parseMontant(_montantCtrl.text);
    if (montant == null || montant <= 0) return;

    await budgetProvider.ajouter(
      montantAlloue: montant,
      periode: _periode,
      dateDebut: _debut,
      dateFin: _fin,
      categorieId: _categorieId,
      userId: auth.currentUser!.id,
      catProvider: catProvider,
    );

    budgetProvider.rafraichirDepenses(txProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nouveau budget',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _montantCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\s,\.]')),
              ],
              decoration: InputDecoration(
                  labelText: 'Montant alloué',
                  suffixText:
                      context.read<AuthProvider>().currentUser?.devise ??
                          'FCFA'),
              validator: (v) =>
                  v == null ||
                          v.trim().isEmpty ||
                          AppHelpers.parseMontant(v) == null
                      ? 'Montant invalide'
                      : null,
            ),
            const SizedBox(height: 16),
            const Text('Période',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: ['hebdomadaire', 'mensuel', 'annuel'].map((p) {
                final sel = _periode == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _setPeriode(p),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppConstants.primaryColor
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        p[0].toUpperCase() + p.substring(1),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: sel ? Colors.white : Colors.grey),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Catégorie (optionnel)',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _categorieId = null),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _categorieId == null
                          ? AppConstants.primaryColor
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Global',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _categorieId == null
                                ? Colors.white
                                : Colors.grey)),
                  ),
                ),
                ...catProvider.depenseCategories.map((cat) {
                  final sel = _categorieId == cat.id;
                  final color = AppHelpers.hexToColor(cat.couleur);
                  return GestureDetector(
                    onTap: () => setState(() => _categorieId = cat.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? color : color.withValues(alpha: 0.08),
                        border: Border.all(
                            color: sel ? color : color.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppHelpers.getCategoryIcon(cat.icone),
                              size: 14, color: sel ? Colors.white : color),
                          const SizedBox(width: 4),
                          Text(cat.nom,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: sel ? Colors.white : color,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _save, child: const Text('Créer le budget')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    super.dispose();
  }
}

class _RecurrenceSection extends StatelessWidget {
  const _RecurrenceSection();

  @override
  Widget build(BuildContext context) {
    final recProvider = context.watch<RecurrenceProvider>();
    final auth = context.read<AuthProvider>();
    final devise = auth.currentUser?.devise ?? 'FCFA';
    if (recProvider.recurrences.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Expanded(
                child: Text('Aucune dépense récurrente définie',
                    style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24))),
                builder: (_) => const _AddRecurrenceSheet(),
              ),
              child: const Text('Ajouter'),
            )
          ],
        ),
      );
    }

    return Column(
      children: [
        ...recProvider.recurrences.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8)
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppHelpers.hexToColor(r.categorie?.couleur ?? '#546E7A')
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                        AppHelpers.getCategoryIcon(r.categorie?.icone ?? 'more_horiz'),
                        size: 18,
                        color:
                            AppHelpers.hexToColor(r.categorie?.couleur ?? '#546E7A')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.categorie?.nom ?? 'Autre',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                            '${r.periodicite} • ${AppHelpers.formatDate(r.prochaineDate)}',
                            style:
                                const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(
                    AppHelpers.formatMontant(r.montant, devise),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: r.type == 'depense'
                            ? AppConstants.depenseColor
                            : AppConstants.revenuColor),
                  ),
                  IconButton(
                    onPressed: () =>
                        context.read<RecurrenceProvider>().supprimer(r.id),
                    icon: const Icon(Icons.delete_rounded,
                        color: Colors.red, size: 18),
                  ),
                ],
              ),
            )),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24))),
              builder: (_) => const _AddRecurrenceSheet(),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter'),
          ),
        ),
      ],
    );
  }
}

class _AddRecurrenceSheet extends StatefulWidget {
  const _AddRecurrenceSheet();

  @override
  State<_AddRecurrenceSheet> createState() => _AddRecurrenceSheetState();
}

class _AddRecurrenceSheetState extends State<_AddRecurrenceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _periodicite = 'mensuel';
  String _type = 'depense';
  String _modePaiement = 'especes';
  String? _categorieId;
  final DateTime _dateDebut = DateTime.now();

  @override
  void dispose() {
    _montantCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categorieId == null) return;
    final auth = context.read<AuthProvider>();
    final recProvider = context.read<RecurrenceProvider>();
    final catProvider = context.read<CategoryProvider>();
    final montant = AppHelpers.parseMontant(_montantCtrl.text);
    if (montant == null || montant <= 0) return;
    await recProvider.ajouter(
      montant: montant,
      type: _type,
      dateDebut: _dateDebut,
      periodicite: _periodicite,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      modePaiement: _modePaiement,
      categorieId: _categorieId!,
      userId: auth.currentUser!.id,
      catProvider: catProvider,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final categories = _type == 'depense'
        ? catProvider.depenseCategories
        : catProvider.revenuCategories;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nouvelle récurrence',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montantCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\\s,\\.]')),
              ],
              decoration: const InputDecoration(labelText: 'Montant'),
              validator: (v) =>
                  v == null || AppHelpers.parseMontant(v) == null
                      ? 'Montant invalide'
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            const Text('Type', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Row(
              children: ['depense', 'revenu'].map((t) {
                final sel = _type == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _type = t;
                      _categorieId = null;
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppConstants.primaryColor
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(t[0].toUpperCase() + t.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: sel ? Colors.white : Colors.grey)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Text('Catégorie',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: categories.map((cat) {
                final sel = _categorieId == cat.id;
                final color = AppHelpers.hexToColor(cat.couleur);
                return GestureDetector(
                  onTap: () => setState(() => _categorieId = cat.id),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? color : color.withValues(alpha: 0.08),
                      border: Border.all(
                          color: sel ? color : color.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppHelpers.getCategoryIcon(cat.icone),
                            size: 14, color: sel ? Colors.white : color),
                        const SizedBox(width: 4),
                        Text(cat.nom,
                            style: TextStyle(
                                fontSize: 11,
                                color: sel ? Colors.white : color,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _periodicite,
              decoration: const InputDecoration(labelText: 'Périodicité'),
              items: const [
                DropdownMenuItem(value: 'hebdomadaire', child: Text('Hebdomadaire')),
                DropdownMenuItem(value: 'mensuel', child: Text('Mensuel')),
                DropdownMenuItem(value: 'annuel', child: Text('Annuel')),
              ],
              onChanged: (v) => setState(() => _periodicite = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _modePaiement,
              decoration: const InputDecoration(labelText: 'Mode de paiement'),
              items: const [
                DropdownMenuItem(value: 'especes', child: Text('Espèces')),
                DropdownMenuItem(
                    value: 'mobile_money', child: Text('Mobile Money')),
                DropdownMenuItem(value: 'virement', child: Text('Virement bancaire')),
                DropdownMenuItem(value: 'carte', child: Text('Carte bancaire')),
              ],
              onChanged: (v) => setState(() => _modePaiement = v!),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _save, child: const Text('Créer')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PlanningCalendar extends StatefulWidget {
  const _PlanningCalendar();

  @override
  State<_PlanningCalendar> createState() => _PlanningCalendarState();
}

class _PlanningCalendarState extends State<_PlanningCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final recProvider = context.watch<RecurrenceProvider>();
    final events = recProvider.occurrencesForMonth(_focusedDay);
    List<TransactionRecurrente> getEvents(DateTime day) {
      final key = DateTime(day.year, day.month, day.day);
      return events[key] ?? [];
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2035),
            selectedDayPredicate: (day) =>
                _selectedDay != null && isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
            eventLoader: getEvents,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(
                  color: AppConstants.primaryColor, shape: BoxShape.circle),
              markerDecoration: const BoxDecoration(
                  color: AppConstants.secondaryColor, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _selectedDay == null
                  ? 'Sélectionnez une date'
                  : 'Prévu le ${AppHelpers.formatDate(_selectedDay!)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedDay != null)
            ...getEvents(_selectedDay!).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                          e.type == 'depense'
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 16,
                          color: e.type == 'depense'
                              ? AppConstants.depenseColor
                              : AppConstants.revenuColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e.categorie?.nom ?? 'Autre',
                            style: const TextStyle(fontSize: 12)),
                      ),
                      Text(AppHelpers.formatMontant(
                          e.montant,
                          context
                                  .read<AuthProvider>()
                                  .currentUser
                                  ?.devise ??
                              'FCFA')),
                    ],
                  ),
                )),
          if (_selectedDay != null && getEvents(_selectedDay!).isEmpty)
            Text('Aucune dépense prévue',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }
}
