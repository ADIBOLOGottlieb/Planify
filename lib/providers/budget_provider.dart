import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/database_helper.dart';
import 'category_provider.dart';
import 'transaction_provider.dart';
import 'alert_provider.dart';
import '../utils/notification_service.dart';
import '../services/api_service.dart';
import '../utils/settings_service.dart';

class BudgetProvider extends ChangeNotifier {
  List<Budget> _budgets = [];
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  final _api = ApiService();
  final _settings = SettingsService();

  List<Budget> get budgets => _budgets;

  List<Budget> get budgetsDuMois {
    final now = DateTime.now();
    return _budgets.where((b) =>
      b.dateDebut.isBefore(now.add(const Duration(days: 1))) &&
      b.dateFin.isAfter(now.subtract(const Duration(days: 1)))
    ).toList();
  }

  Future<void> charger(String userId, CategoryProvider catProvider, TransactionProvider txProvider) async {
    final syncEnabled = await _settings.isSyncEnabled();
    if (syncEnabled) {
      try {
        await _syncWithRemote(userId);
        final results = await _db.query('budgets',
            where: 'utilisateur_id = ?', whereArgs: [userId], orderBy: 'date_debut DESC');
        _budgets = results.map((map) {
          final b = Budget.fromMap(map);
          b.categorie = b.categorieId != null ? catProvider.findById(b.categorieId!) : null;
          return b;
        }).toList();
        _mettreAJourDepenses(txProvider);
        notifyListeners();
        return;
      } catch (_) {}
    }
    final results = await _db.query('budgets', where: 'utilisateur_id = ?', whereArgs: [userId], orderBy: 'date_debut DESC');
    _budgets = results.map((map) {
      final b = Budget.fromMap(map);
      b.categorie = b.categorieId != null ? catProvider.findById(b.categorieId!) : null;
      return b;
    }).toList();
    _mettreAJourDepenses(txProvider);
    notifyListeners();
  }

  Future<void> _syncWithRemote(String userId) async {
    final remote = await _api.getBudgets();
    final localRows = await _db.query('budgets', where: 'utilisateur_id = ?', whereArgs: [userId]);
    final local = {
      for (final m in localRows) m['id'] as String: Budget.fromMap(m)
    };
    final remoteMap = {for (final b in remote) b.id: b};

    for (final entry in local.entries) {
      if (!remoteMap.containsKey(entry.key)) {
        try {
          await _api.createBudget(entry.value);
        } catch (_) {}
      }
    }

    for (final r in remote) {
      final l = local[r.id];
      if (l == null) {
        await _db.insert('budgets', r.toMap());
      } else {
        if (l.updatedAt.isAfter(r.updatedAt)) {
          try {
            await _api.updateBudget(l);
          } catch (_) {}
        } else if (r.updatedAt.isAfter(l.updatedAt)) {
          await _db.update('budgets', r.toMap(), 'id = ?', [r.id]);
        }
      }
    }
  }

  void _mettreAJourDepenses(TransactionProvider txProvider,
      {AlertProvider? alertProvider, String? userId, bool emitAlerts = false}) {
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
      budget.statutAlerte = budget.pourcentage >= 0.8;
      if (budget.montantDepense != prevDepense) {
        budget.updatedAt = DateTime.now();
        _db.update('budgets', {
          'montant_depense': budget.montantDepense,
          'updated_at': budget.updatedAt.toIso8601String(),
        }, 'id = ?', [budget.id]);
        _syncBudgetIfNeeded(budget);
      }

      if (emitAlerts && alertProvider != null && userId != null) {
        if (budget.pourcentage >= 0.8 && !budget.alerte80Envoyee) {
          budget.alerte80Envoyee = true;
          budget.updatedAt = DateTime.now();
          _db.update('budgets', {
            'alerte_80_envoyee': 1,
            'updated_at': budget.updatedAt.toIso8601String(),
          }, 'id = ?', [budget.id]);
          alertProvider.ajouter(
            type: 'budget_80',
            message:
                'Attention : vous avez dépensé 80% du budget ${budget.categorie?.nom ?? "global"}.',
            userId: userId,
            budgetId: budget.id,
          );
          NotificationService().showBudgetAlert(
            title: 'Alerte budget',
            body:
                '80% du budget ${budget.categorie?.nom ?? "global"} atteint.',
          );
        }
        if (budget.estDepasse && !budget.alerte100Envoyee) {
          budget.alerte100Envoyee = true;
          budget.updatedAt = DateTime.now();
          _db.update('budgets', {
            'alerte_100_envoyee': 1,
            'updated_at': budget.updatedAt.toIso8601String(),
          }, 'id = ?', [budget.id]);
          alertProvider.ajouter(
            type: 'budget_100',
            message:
                'Vous avez dépassé le budget ${budget.categorie?.nom ?? "global"}.',
            userId: userId,
            budgetId: budget.id,
          );
          NotificationService().showBudgetAlert(
            title: 'Budget dépassé',
            body:
                'Vous avez dépassé le budget ${budget.categorie?.nom ?? "global"}.',
          );
        }
        if (emitAlerts) {
          _syncBudgetIfNeeded(budget);
        }
      }
    }
  }

  void rafraichirDepenses(TransactionProvider txProvider,
      {AlertProvider? alertProvider, String? userId, bool emitAlerts = false}) {
    _mettreAJourDepenses(txProvider,
        alertProvider: alertProvider, userId: userId, emitAlerts: emitAlerts);
    notifyListeners();
  }

  Future<void> ajouter({
    required double montantAlloue,
    String periode = 'mensuel',
    required DateTime dateDebut,
    required DateTime dateFin,
    String? categorieId,
    required String userId,
    required CategoryProvider catProvider,
  }) async {
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
    final now = DateTime.now();
    final b = Budget(
      id: _uuid.v4(),
      montantAlloue: montantAlloue + report,
      montantReporte: report,
      periode: periode,
      dateDebut: dateDebut,
      dateFin: dateFin,
      categorieId: categorieId,
      utilisateurId: userId,
      updatedAt: now,
    );
    b.categorie = categorieId != null ? catProvider.findById(categorieId) : null;
    await _db.insert('budgets', b.toMap());
    _budgets.insert(0, b);
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        await _api.createBudget(b);
      } catch (_) {}
    }
  }

  Future<void> supprimer(String id) async {
    await _db.delete('budgets', 'id = ?', [id]);
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        await _api.deleteBudget(id);
      } catch (_) {}
    }
  }

  Future<void> modifier(Budget budget) async {
    budget.updatedAt = DateTime.now();
    await _db.update('budgets', budget.toMap(), 'id = ?', [budget.id]);
    final idx = _budgets.indexWhere((b) => b.id == budget.id);
    if (idx >= 0) _budgets[idx] = budget;
    notifyListeners();

    await _syncBudgetIfNeeded(budget);
  }

  Future<void> _syncBudgetIfNeeded(Budget budget) async {
    if (await _settings.isSyncEnabled()) {
      try {
        await _api.updateBudget(budget);
      } catch (_) {}
    }
  }

  void reset() {
    _budgets = [];
    notifyListeners();
  }
}
