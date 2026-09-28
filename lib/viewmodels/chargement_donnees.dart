import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_constants.dart';
import 'alert_viewmodel.dart';
import 'auth_viewmodel.dart';
import 'budget_viewmodel.dart';
import 'category_viewmodel.dart';
import 'compte_viewmodel.dart';
import 'objectif_viewmodel.dart';
import 'preferences_viewmodel.dart';
import 'recurrence_viewmodel.dart';
import 'transaction_viewmodel.dart';

/// Charge (et synchronise si possible) toutes les données de l'utilisateur
/// connecté, puis exécute les traitements automatiques :
/// - enregistrement des transactions récurrentes arrivées à échéance ;
/// - rapports hebdomadaire et mensuel (processus « Génération des rapports »
///   du MCT, déclenché en fin de semaine / de mois) ;
/// - vérification budgétaire.
Future<void> chargerDonneesUtilisateur(BuildContext context) async {
  final auth = context.read<AuthViewModel>();
  final cat = context.read<CategoryViewModel>();
  final comptes = context.read<CompteViewModel>();
  final tx = context.read<TransactionViewModel>();
  final budgets = context.read<BudgetViewModel>();
  final objectifs = context.read<ObjectifViewModel>();
  final alertes = context.read<AlertViewModel>();
  final recurrences = context.read<RecurrenceViewModel>();
  final prefs = context.read<PreferencesViewModel>();
  final userId = auth.currentUser!.id;

  await cat.charger(userId);
  await comptes.charger(userId);
  await tx.charger(userId, cat);
  await budgets.charger(userId, cat, tx);
  await objectifs.charger(userId);
  await alertes.charger(userId);
  await recurrences.charger(userId, cat);

  await _enregistrerEcheancesRecurrentes(userId, recurrences, tx, cat, comptes, alertes);
  await _genererRapportsPeriodiques(userId, auth.currentUser!.devise, tx, alertes);
  budgets.rafraichirDepenses(tx,
      alertProvider: alertes, userId: userId, emitAlerts: prefs.alertesBudget);
}

Future<void> _enregistrerEcheancesRecurrentes(
  String userId,
  RecurrenceViewModel recurrences,
  TransactionViewModel tx,
  CategoryViewModel cat,
  CompteViewModel comptes,
  AlertViewModel alertes,
) async {
  final dues = recurrences.echeancesDues();
  final dernieres = <String, DateTime>{};
  for (final e in dues) {
    final r = e.recurrence;
    await tx.ajouter(
      montant: r.montant,
      type: r.type,
      date: e.date,
      description: r.description ?? r.categorie?.nom,
      modePaiement: r.modePaiement,
      categorieId: r.categorieId,
      compteId: r.compteId,
      userId: userId,
      catProvider: cat,
      compteProvider: comptes,
    );
    dernieres[r.id] = e.date;
  }
  for (final r in recurrences.recurrences.toList()) {
    final derniere = dernieres[r.id];
    if (derniere != null) await recurrences.avancerApres(r, derniere);
  }
  if (dues.isNotEmpty) {
    await alertes.ajouter(
      type: 'recurrence',
      message: '${dues.length} transaction${dues.length > 1 ? 's' : ''} récurrente'
          '${dues.length > 1 ? 's' : ''} enregistrée${dues.length > 1 ? 's' : ''} automatiquement.',
      userId: userId,
    );
  }
}

Future<void> _genererRapportsPeriodiques(
    String userId, String devise, TransactionViewModel tx, AlertViewModel alertes) async {
  final p = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final debutSemaine = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  final debutMois = DateTime(now.year, now.month, 1);

  final cleSemaine = 'rapport_hebdo_$userId';
  final derniereSemaine = p.getString(cleSemaine);
  if (derniereSemaine != null && DateTime.parse(derniereSemaine).isBefore(debutSemaine)) {
    final debut = debutSemaine.subtract(const Duration(days: 7));
    final t = tx.totauxSurPeriode(debut, debutSemaine.subtract(const Duration(microseconds: 1)));
    if (t.depenses > 0 || t.revenus > 0) {
      await alertes.ajouter(
        type: 'rapport_hebdo',
        message: 'Rapport de la semaine du ${AppHelpers.formatDate(debut)} : '
            'dépenses ${AppHelpers.formatMontant(t.depenses, devise)}, '
            'revenus ${AppHelpers.formatMontant(t.revenus, devise)}.',
        userId: userId,
      );
    }
  }
  await p.setString(cleSemaine, debutSemaine.toIso8601String());

  final cleMois = 'rapport_mensuel_$userId';
  final dernierMois = p.getString(cleMois);
  if (dernierMois != null && DateTime.parse(dernierMois).isBefore(debutMois)) {
    final debut = DateTime(now.year, now.month - 1, 1);
    final t = tx.totauxSurPeriode(debut, debutMois.subtract(const Duration(microseconds: 1)));
    if (t.depenses > 0 || t.revenus > 0) {
      await alertes.ajouter(
        type: 'rapport_mensuel',
        message: 'Bilan de ${AppHelpers.formatMois(debut)} : '
            'dépenses ${AppHelpers.formatMontant(t.depenses, devise)}, '
            'revenus ${AppHelpers.formatMontant(t.revenus, devise)}, '
            'solde ${t.solde >= 0 ? '+' : '-'}${AppHelpers.formatMontant(t.solde, devise)}.',
        userId: userId,
      );
    }
  }
  await p.setString(cleMois, debutMois.toIso8601String());
}
