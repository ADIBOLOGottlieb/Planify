import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import 'alert_viewmodel.dart';
import 'category_viewmodel.dart';
import 'transaction_viewmodel.dart';

class BudgetViewModel extends ChangeNotifier {
  List<Budget> _budgets = [];
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  final _api = ApiService();
  final _sync = SyncService();

  List<Budget> get budgets => _budgets;

  List<Budget> get budgetsDuMois {
    final now = DateTime.now();
    return _budgets.where((b) =>
      b.dateDebut.isBefore(now.add(const Duration(days: 1))) &&
      b.dateFin.isAfter(now.subtract(const Duration(days: 1)))
    ).toList();
  }

  Future<List<Map<String, dynamic>>> _lignes(String userId) => _db.query('budgets',
      where: 'utilisateur_id = ?', whereArgs: [userId], orderBy: 'date_debut DESC');

  Future<void> charger(String userId, CategoryViewModel catProvider, TransactionViewModel txProvider) async {
    await _sync.synchroniser<Budget>(
      table: 'budgets',
      lignesLocales: await _lignes(userId),
      lireDistant: _api.getBudgets,
      creerDistant: _api.createBudget,
      modifierDistant: _api.updateBudget,
      supprimerDistant: _api.deleteBudget,
      fromMap: Budget.fromMap,
      toMap: (b) => b.toMap(),
      idDe: (b) => b.id,
      modifieLe: (b) => b.updatedAt,
    );
    _budgets = (await _lignes(userId)).map((map) {
      final b = Budget.fromMap(map);
      b.categorie = b.categorieId != null ? catProvider.findById(b.categorieId!) : null;
      return b;
    }).toList();
    _mettreAJourDepenses(txProvider);
    notifyListeners();
  }

  /// Recalcule le montant dépensé de chaque budget à partir des transactions
  /// et, si [emitAlerts], émet les alertes de seuil et de dépassement
  /// (processus « Vérification budgétaire » du MCT).
  void _mettreAJourDepenses(TransactionViewModel txProvider,
      {AlertViewModel? alertProvider, String? userId, bool emitAlerts = false}) {
    for (final budget in _budgets) {
      final prevDepense = budget.montantDepense;
      if (budget.categorieId != null) {
        budget.montantDepense = txProvider.getDepensesParCategorieId(budget.categorieId!, budget.dateDebut, budget.dateFin);
      } else {
        // Budget global
        budget.montantDepense = txProvider.transactions
          .where((t) => t.type == 'depense' && !t.dateTransaction.isBefore(budget.dateDebut) && !t.dateTransaction.isAfter(budget.dateFin))
          .fold(0.0, (sum, t) => sum + t.montant);
      }
      final seuil = budget.seuilAlerte / 100;
      budget.statutAlerte = budget.pourcentage >= seuil;
      var modifie = budget.montantDepense != prevDepense;

      if (emitAlerts && alertProvider != null && userId != null) {
        final nom = budget.categorie?.nom ?? 'global';
        if (budget.pourcentage >= seuil && !budget.alerte80Envoyee) {
          budget.alerte80Envoyee = true;
          modifie = true;
          alertProvider.ajouter(
            type: 'budget_seuil',
            message: 'Attention : vous avez dépensé ${budget.seuilAlerte}% du budget $nom.',
            userId: userId,
            budgetId: budget.id,
          );
          NotificationService().showBudgetAlert(
            title: 'Alerte budget',
            body: '${budget.seuilAlerte}% du budget $nom atteint.',
          );
        }
        if (budget.estDepasse && !budget.alerte100Envoyee) {
          budget.alerte100Envoyee = true;
          modifie = true;
          alertProvider.ajouter(
            type: 'budget_depasse',
            message: 'Vous avez dépassé le budget $nom.',
            userId: userId,
            budgetId: budget.id,
          );
          NotificationService().showBudgetAlert(
            title: 'Budget dépassé',
            body: 'Vous avez dépassé le budget $nom.',
          );
        }
      }

      if (modifie) {
        budget.updatedAt = DateTime.now();
        _db.update('budgets', budget.toMap(), 'id = ?', [budget.id]);
        _sync.envoyer(() => _api.updateBudget(budget));
      }
    }
  }

  void rafraichirDepenses(TransactionViewModel txProvider,
      {AlertViewModel? alertProvider, String? userId, bool emitAlerts = false}) {
    _mettreAJourDepenses(txProvider,
        alertProvider: alertProvider, userId: userId, emitAlerts: emitAlerts);
    notifyListeners();
  }

  /// Montant déjà dépensé sur la période, affiché lors de la création d'un
  /// budget pour aider à fixer un montant réaliste.
  double dejaDepense(TransactionViewModel txProvider,
      {String? categorieId, required DateTime debut, required DateTime fin}) {
    if (categorieId != null) {
      return txProvider.getDepensesParCategorieId(categorieId, debut, fin);
    }
    return txProvider.transactions
        .where((t) => t.type == 'depense' && !t.dateTransaction.isBefore(debut) && !t.dateTransaction.isAfter(fin))
        .fold(0.0, (s, t) => s + t.montant);
  }

  Future<void> ajouter({
    required double montantAlloue,
    String periode = 'mensuel',
    required DateTime dateDebut,
    required DateTime dateFin,
    String? categorieId,
    int seuilAlerte = 80,
    required String userId,
    required CategoryViewModel catProvider,
  }) async {
    // Report du reliquat du budget mensuel précédent de la même catégorie.
    double report = 0;
    if (periode == 'mensuel') {
      final rows = await _db.rawQuery(
        '''
        SELECT * FROM budgets
        WHERE utilisateur_id = ?
          AND ${categorieId == null ? 'categorie_id IS NULL' : 'categorie_id = ?'}
          AND date_fin < ?
        ORDER BY date_fin DESC
        LIMIT 1
        ''',
        categorieId == null
            ? [userId, dateDebut.toIso8601String()]
            : [userId, categorieId, dateDebut.toIso8601String()],
      );
      if (rows.isNotEmpty) {
        final prev = Budget.fromMap(rows.first);
        report = prev.montantAlloue - prev.montantDepense;
        if (report < 0) report = 0;
      }
    }
    final b = Budget(
      id: _uuid.v4(),
      montantAlloue: montantAlloue + report,
      montantReporte: report,
      periode: periode,
      dateDebut: dateDebut,
      dateFin: dateFin,
      categorieId: categorieId,
      seuilAlerte: seuilAlerte,
      utilisateurId: userId,
      updatedAt: DateTime.now(),
    );
    b.categorie = categorieId != null ? catProvider.findById(categorieId) : null;
    await _db.insert('budgets', b.toMap());
    _budgets.insert(0, b);
    notifyListeners();
    await _sync.envoyer(() => _api.createBudget(b));
  }

  Future<void> supprimer(String id) async {
    await _db.delete('budgets', 'id = ?', [id]);
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();
    await _sync.supprimer('budgets', id, _api.deleteBudget);
  }

  Future<void> modifier(Budget budget) async {
    budget.updatedAt = DateTime.now();
    await _db.update('budgets', budget.toMap(), 'id = ?', [budget.id]);
    final idx = _budgets.indexWhere((b) => b.id == budget.id);
    if (idx >= 0) _budgets[idx] = budget;
    notifyListeners();
    await _sync.envoyer(() => _api.updateBudget(budget));
  }

  void reset() {
    _budgets = [];
    notifyListeners();
  }
}
