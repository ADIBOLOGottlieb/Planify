import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/objectif_provider.dart';
import '../../providers/alert_provider.dart';
import '../../models/models.dart';
import '../../utils/app_constants.dart';
import '../transactions/add_transaction_screen.dart';
import '../alerts_screen.dart';
import '../../providers/compte_provider.dart';
import '../profil/comptes_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final objectifProvider = context.watch<ObjectifProvider>();
    final alertProvider = context.watch<AlertProvider>();
    final compteProvider = context.watch<CompteProvider>();
    final user = auth.currentUser;
    final devise = user?.devise ?? 'FCFA';

    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bonjour,',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14)),
                      Text(
                        '${user?.prenom ?? ''} ${user?.nom ?? ''}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AlertsScreen())),
                    child: Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.notifications_none_rounded,
                              color: Colors.white),
                        ),
                        if (alertProvider.nonLues > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                              child: Text(
                                alertProvider.nonLues.toString(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Balance Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Text('Solde du mois',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    AppHelpers.formatMontant(txProvider.soldeDuMois, devise),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _BalanceItem(
                              label: 'Revenus',
                              montant: txProvider.revenusDuMois,
                              devise: devise,
                              isRevenu: true)),
                      Container(
                          height: 40,
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.3)),
                      Expanded(
                          child: _BalanceItem(
                              label: 'Dépenses',
                              montant: txProvider.depensesDuMois,
                              devise: devise,
                              isRevenu: false)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                    color: AppConstants.bgColor,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28))),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Accounts Balances section
                      if (compteProvider.items.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Mes Soldes (Mobile Money)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComptesScreen())),
                              child: const Text('Gérer', style: TextStyle(color: AppConstants.primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: compteProvider.items.length,
                            itemBuilder: (ctx, i) {
                              final c = compteProvider.items[i];
                              return Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppConstants.surfaceColor,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: AppHelpers.hexToColor(c.couleur).withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(c.nom, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(AppHelpers.formatMontant(c.solde, devise), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Quick actions
                      Row(
                        children: [
                          Expanded(
                              child: _QuickAction(
                                  icon: Icons.arrow_upward_rounded,
                                  label: 'Dépense',
                                  color: AppConstants.depenseColor,
                                  onTap: () =>
                                      _addTransaction(context, 'depense'))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _QuickAction(
                                  icon: Icons.arrow_downward_rounded,
                                  label: 'Revenu',
                                  color: AppConstants.revenuColor,
                                  onTap: () =>
                                      _addTransaction(context, 'revenu'))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Budget alerts
                      if (budgetProvider.budgetsDuMois
                          .any((b) => b.statutAlerte)) ...[
                        const _SectionTitle(
                            title: 'Alertes budgétaires',
                            icon: Icons.warning_amber_rounded,
                            color: Colors.orange),
                        ...budgetProvider.budgetsDuMois
                            .where((b) => b.statutAlerte)
                            .map((b) =>
                                _BudgetAlertCard(budget: b, devise: devise)),
                        const SizedBox(height: 20),
                      ],
                      // Recent transactions
                      const _SectionTitle(
                          title: 'Transactions récentes',
                          icon: Icons.receipt_long_rounded,
                          color: AppConstants.primaryColor),
                      if (txProvider.transactions.isEmpty)
                        const _EmptyState(
                            message: 'Aucune transaction encore',
                            icon: Icons.receipt_long_rounded)
                      else
                        ...txProvider.transactions
                            .take(5)
                            .map((t) =>
                                _TransactionTile(transaction: t, devise: devise)),
                      const SizedBox(height: 20),
                      // Objectifs
                      if (objectifProvider.objectifsEnCours.isNotEmpty) ...[
                        const _SectionTitle(
                            title: "Objectifs d'épargne",
                            icon: Icons.savings_rounded,
                            color: AppConstants.secondaryColor),
                        ...objectifProvider.objectifsEnCours
                            .take(2)
                            .map((o) =>
                                _ObjectifCard(objectif: o, devise: devise)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTransaction(BuildContext context, String type) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AddTransactionScreen(initialType: type)));
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double montant;
  final String devise;
  final bool isRevenu;

  const _BalanceItem(
      {required this.label,
      required this.montant,
      required this.devise,
      required this.isRevenu});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                isRevenu
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: Colors.white70,
                size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(AppHelpers.formatMontant(montant, devise),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text('+ $label',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle(
      {required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String devise;

  const _TransactionTile(
      {required this.transaction, required this.devise});

  @override
  Widget build(BuildContext context) {
    final isDepense = transaction.type == 'depense';
    final cat = transaction.categorie;
    final color =
        cat != null ? AppHelpers.hexToColor(cat.couleur) : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)
          ]),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(
                AppHelpers.getCategoryIcon(cat?.icone ?? 'more_horiz'),
                color: color,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat?.nom ?? 'Autre',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                if (transaction.description != null &&
                    transaction.description!.isNotEmpty)
                  Text(transaction.description!,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                Text(AppHelpers.formatDate(transaction.dateTransaction),
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${isDepense ? '-' : '+'} ${AppHelpers.formatMontant(transaction.montant, devise)}',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDepense
                    ? AppConstants.depenseColor
                    : AppConstants.revenuColor),
          ),
        ],
      ),
    );
  }
}

class _BudgetAlertCard extends StatelessWidget {
  final Budget budget;
  final String devise;

  const _BudgetAlertCard({required this.budget, required this.devise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
              budget.estDepasse
                  ? Icons.warning_rounded
                  : Icons.warning_amber_rounded,
              color: budget.estDepasse ? Colors.red : Colors.orange,
              size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.estDepasse ? 'Budget dépassé !' : 'Budget à 80%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: budget.estDepasse
                          ? Colors.red
                          : Colors.orange.shade800),
                ),
                Text(
                  'Budget ${budget.categorie?.nom ?? "global"}: '
                  '${AppHelpers.formatMontant(budget.montantDepense, devise)} / '
                  '${AppHelpers.formatMontant(budget.montantAlloue, devise)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectifCard extends StatelessWidget {
  final Objectif objectif;
  final String devise;

  const _ObjectifCard({required this.objectif, required this.devise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings_rounded,
                  color: AppConstants.secondaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(objectif.nom,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('${(objectif.pourcentage * 100).toInt()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.secondaryColor)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: objectif.pourcentage,
            backgroundColor: Colors.grey.shade200,
            color: AppConstants.secondaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppHelpers.formatMontant(objectif.montantActuel, devise),
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(AppHelpers.formatMontant(objectif.montantCible, devise),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message,
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
