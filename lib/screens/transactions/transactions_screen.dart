import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final auth = context.watch<AuthProvider>();
    final devise = auth.currentUser?.devise ?? 'FCFA';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
            padding: const EdgeInsets.all(16),
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
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TransactionList(
                    transactions: txProvider.filtrer(recherche: _search),
                    devise: devise),
                _TransactionList(
                    transactions:
                        txProvider.filtrer(type: 'depense', recherche: _search),
                    devise: devise),
                _TransactionList(
                    transactions:
                        txProvider.filtrer(type: 'revenu', recherche: _search),
                    devise: devise),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
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
                    '${dayTotal >= 0 ? '+' : ''}${AppHelpers.formatMontant(dayTotal, devise)}',
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
        final txProvider = context.read<TransactionProvider>();
        final budgetProvider = context.read<BudgetProvider>();
        txProvider.supprimer(transaction.id);
        budgetProvider.rafraichirDepenses(txProvider);
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    AddTransactionScreen(transaction: transaction))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: Colors.white,
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
