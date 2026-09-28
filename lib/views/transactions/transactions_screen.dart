import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../viewmodels/category_viewmodel.dart';
import '../../viewmodels/compte_viewmodel.dart';
import '../../viewmodels/transaction_viewmodel.dart';
import '../../models/models.dart';
import '../../utils/app_constants.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _search = '';
  FiltreTransactions _filtre = const FiltreTransactions();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  FiltreTransactions _avecType(String? type) => FiltreTransactions(
        type: type,
        categorieId: _filtre.categorieId,
        modePaiement: _filtre.modePaiement,
        debut: _filtre.debut,
        fin: _filtre.fin,
        montantMin: _filtre.montantMin,
        montantMax: _filtre.montantMax,
        recherche: _search,
      );

  Future<void> _ouvrirFiltres() async {
    final resultat = await showModalBottomSheet<FiltreTransactions>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FiltresSheet(initial: _filtre),
    );
    if (resultat != null) setState(() => _filtre = resultat);
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionViewModel>();
    final auth = context.watch<AuthViewModel>();
    final devise = auth.currentUser?.devise ?? 'FCFA';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryColor,
          labelColor: AppConstants.texteColor,
          unselectedLabelColor: AppConstants.texteSecondaire,
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'Dépenses'),
            Tab(text: 'Revenus'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              })
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Filtrer',
                  onPressed: _ouvrirFiltres,
                  icon: Badge(
                    isLabelVisible: !_filtre.estVide,
                    backgroundColor: AppConstants.primaryColor,
                    child: const Icon(Icons.tune_rounded),
                  ),
                ),
              ],
            ),
          ),
          if (!_filtre.estVide)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.filter_alt_rounded, size: 16, color: AppConstants.primaryColor),
                  const SizedBox(width: 6),
                  const Expanded(child: Text('Filtres actifs', style: TextStyle(fontSize: 12))),
                  TextButton(
                    onPressed: () => setState(() => _filtre = const FiltreTransactions()),
                    child: const Text('Effacer'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TransactionList(
                    transactions: txProvider.rechercher(_avecType(null)), devise: devise),
                _TransactionList(
                    transactions: txProvider.rechercher(_avecType('depense')), devise: devise),
                _TransactionList(
                    transactions: txProvider.rechercher(_avecType('revenu')), devise: devise),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Panneau de filtres : catégorie, mode de paiement, période et montant.
class _FiltresSheet extends StatefulWidget {
  final FiltreTransactions initial;
  const _FiltresSheet({required this.initial});

  @override
  State<_FiltresSheet> createState() => _FiltresSheetState();
}

class _FiltresSheetState extends State<_FiltresSheet> {
  late String? _categorieId = widget.initial.categorieId;
  late String? _mode = widget.initial.modePaiement;
  late DateTimeRange? _periode = widget.initial.debut != null && widget.initial.fin != null
      ? DateTimeRange(start: widget.initial.debut!, end: widget.initial.fin!)
      : null;
  late final _minCtrl = TextEditingController(
      text: widget.initial.montantMin?.toStringAsFixed(0) ?? '');
  late final _maxCtrl = TextEditingController(
      text: widget.initial.montantMax?.toStringAsFixed(0) ?? '');

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryViewModel>().categories;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Filtrer les transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _categorieId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Toutes')),
                ...categories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.nom} (${c.type == 'depense' ? 'dépense' : 'revenu'})'))),
              ],
              onChanged: (v) => setState(() => _categorieId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _mode,
              decoration: const InputDecoration(labelText: 'Mode de paiement'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous')),
                for (final m in ['especes', 'mobile_money', 'virement', 'carte'])
                  DropdownMenuItem(value: m, child: Text(AppHelpers.getModeLabel(m))),
              ],
              onChanged: (v) => setState(() => _mode = v),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range_rounded),
              label: Text(_periode == null
                  ? 'Toute période'
                  : '${AppHelpers.formatDate(_periode!.start)} → ${AppHelpers.formatDate(_periode!.end)}'),
              onPressed: () async {
                final p = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: _periode,
                );
                if (p != null) setState(() => _periode = p);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Montant min'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Montant max'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                FiltreTransactions(
                  categorieId: _categorieId,
                  modePaiement: _mode,
                  debut: _periode?.start,
                  fin: _periode == null
                      ? null
                      : DateTime(_periode!.end.year, _periode!.end.month, _periode!.end.day, 23, 59, 59),
                  montantMin: AppHelpers.parseMontant(_minCtrl.text),
                  montantMax: AppHelpers.parseMontant(_maxCtrl.text),
                ),
              ),
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Transactions d'une catégorie sur une période (ouvert depuis le graphique
/// en anneau du tableau de bord).
class CategorieTransactionsScreen extends StatelessWidget {
  final String categorieId;
  final DateTime debut;
  final DateTime fin;
  const CategorieTransactionsScreen(
      {super.key, required this.categorieId, required this.debut, required this.fin});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionViewModel>();
    final cat = context.watch<CategoryViewModel>().findById(categorieId);
    final devise = context.watch<AuthViewModel>().currentUser?.devise ?? 'FCFA';
    final liste = tx.rechercher(FiltreTransactions(categorieId: categorieId, debut: debut, fin: fin));
    final total = liste.fold<double>(0, (s, t) => s + t.montant);
    return Scaffold(
      appBar: AppBar(title: Text(cat?.nom ?? 'Catégorie')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${liste.length} transaction${liste.length > 1 ? 's' : ''} · '
              '${AppHelpers.formatMontant(total, devise)} '
              '(${AppHelpers.formatMois(debut)})',
              style: TextStyle(color: AppConstants.texteSecondaire),
            ),
          ),
          Expanded(child: _TransactionList(transactions: liste, devise: devise)),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final String devise;

  const _TransactionList({required this.transactions, required this.devise});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Aucune transaction',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<Transaction>>{};
    for (final t in transactions) {
      final key = AppHelpers.formatDate(t.dateTransaction);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: grouped.entries.map((entry) {
        final dayTotal = entry.value.fold<double>(
            0,
            (sum, t) =>
                t.type == 'depense' ? sum - t.montant : sum + t.montant);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey)),
                  Text(
                    AppHelpers.formatMontantSigne(dayTotal, devise, plus: true),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: dayTotal >= 0
                            ? AppConstants.revenuColor
                            : AppConstants.depenseColor),
                  ),
                ],
              ),
            ),
            ...entry.value
                .map((t) => _TransactionCard(transaction: t, devise: devise)),
          ],
        );
      }).toList(),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final String devise;

  const _TransactionCard({required this.transaction, required this.devise});

  bool get isDepense => transaction.type == 'depense';

  @override
  Widget build(BuildContext context) {
    final cat = transaction.categorie;
    final color =
        cat != null ? AppHelpers.hexToColor(cat.couleur) : Colors.grey;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer ?'),
            content: const Text('Cette action est irréversible.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annuler')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Supprimer',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) {
        final txProvider = context.read<TransactionViewModel>();
        final budgetProvider = context.read<BudgetViewModel>();
        // Le compte associé est recrédité / redébité.
        txProvider
            .supprimer(transaction.id, compteProvider: context.read<CompteViewModel>())
            .then((_) => budgetProvider.rafraichirDepenses(txProvider));
      },
      child: GestureDetector(
        onTap: () => ouvrirSaisieTransaction(context, transaction: transaction),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
              ]),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(
                    AppHelpers.getCategoryIcon(cat?.icone ?? 'more_horiz'),
                    color: color,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat?.nom ?? 'Autre',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (transaction.description != null &&
                        transaction.description!.isNotEmpty)
                      Text(transaction.description!,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.payment_rounded,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(AppHelpers.getModeLabel(transaction.modePaiement),
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 11)),
                      if (transaction.justificatif != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.receipt_rounded,
                            size: 12, color: Colors.grey.shade400),
                      ],
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDepense ? '-' : '+'} ${AppHelpers.formatMontant(transaction.montant, devise)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDepense
                            ? AppConstants.depenseColor
                            : AppConstants.revenuColor),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
