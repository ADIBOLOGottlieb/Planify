import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import 'category_viewmodel.dart';

/// Dépenses et revenus récurrents (loyer, abonnements, salaire…).
class RecurrenceViewModel extends ChangeNotifier {
  List<TransactionRecurrente> _recurrences = [];
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  final _api = ApiService();
  final _sync = SyncService();

  List<TransactionRecurrente> get recurrences => _recurrences;

  Future<void> charger(String userId, CategoryViewModel catProvider) async {
    await _sync.synchroniser<TransactionRecurrente>(
      table: 'transactions_recurrentes',
      lignesLocales: await _db.query('transactions_recurrentes',
          where: 'utilisateur_id = ?', whereArgs: [userId]),
      lireDistant: _api.getRecurrences,
      creerDistant: _api.createRecurrence,
      modifierDistant: _api.updateRecurrence,
      supprimerDistant: _api.deleteRecurrence,
      fromMap: TransactionRecurrente.fromMap,
      toMap: (r) => r.toMap(),
      idDe: (r) => r.id,
      modifieLe: (r) => r.updatedAt,
    );
    final results = await _db.query(
      'transactions_recurrentes',
      where: 'utilisateur_id = ? AND actif = 1',
      whereArgs: [userId],
      orderBy: 'prochaine_date ASC',
    );
    _recurrences = results.map((map) {
      final r = TransactionRecurrente.fromMap(map);
      r.categorie = catProvider.findById(r.categorieId);
      return r;
    }).toList();
    notifyListeners();
  }

  Future<void> ajouter({
    required double montant,
    required String type,
    required DateTime dateDebut,
    required String periodicite,
    String? description,
    String modePaiement = 'especes',
    required String categorieId,
    required String userId,
    required CategoryViewModel catProvider,
  }) async {
    final r = TransactionRecurrente(
      id: _uuid.v4(),
      montant: montant,
      type: type,
      dateDebut: dateDebut,
      prochaineDate: dateDebut,
      periodicite: periodicite,
      description: description,
      modePaiement: modePaiement,
      categorieId: categorieId,
      utilisateurId: userId,
      updatedAt: DateTime.now(),
    );
    r.categorie = catProvider.findById(categorieId);
    await _db.insert('transactions_recurrentes', r.toMap());
    _recurrences.add(r);
    _recurrences.sort((a, b) => a.prochaineDate.compareTo(b.prochaineDate));
    notifyListeners();
    await _sync.envoyer(() => _api.createRecurrence(r));
  }

  Future<void> supprimer(String id) async {
    await _db.delete('transactions_recurrentes', 'id = ?', [id]);
    _recurrences.removeWhere((r) => r.id == id);
    notifyListeners();
    await _sync.supprimer('transactions_recurrentes', id, _api.deleteRecurrence);
  }

  /// Échéances arrivées à terme (date ≤ [maintenant]) pour chaque récurrence
  /// active, dans l'ordre chronologique.
  List<({TransactionRecurrente recurrence, DateTime date})> echeancesDues(
      {DateTime? maintenant}) {
    final now = maintenant ?? DateTime.now();
    final dues = <({TransactionRecurrente recurrence, DateTime date})>[];
    for (final r in _recurrences.where((r) => r.actif)) {
      var date = r.prochaineDate;
      while (!date.isAfter(now)) {
        dues.add((recurrence: r, date: date));
        date = _nextDate(date, r.periodicite);
      }
    }
    dues.sort((a, b) => a.date.compareTo(b.date));
    return dues;
  }

  /// Fait avancer la prochaine échéance après enregistrement des transactions.
  Future<void> avancerApres(TransactionRecurrente r, DateTime derniereEcheance) async {
    final idx = _recurrences.indexWhere((x) => x.id == r.id);
    if (idx < 0) return;
    final maj = TransactionRecurrente(
      id: r.id,
      montant: r.montant,
      type: r.type,
      dateDebut: r.dateDebut,
      prochaineDate: _nextDate(derniereEcheance, r.periodicite),
      periodicite: r.periodicite,
      description: r.description,
      modePaiement: r.modePaiement,
      categorieId: r.categorieId,
      compteId: r.compteId,
      utilisateurId: r.utilisateurId,
      actif: r.actif,
      categorie: r.categorie,
      updatedAt: DateTime.now(),
    );
    _recurrences[idx] = maj;
    await _db.update('transactions_recurrentes', maj.toMap(), 'id = ?', [maj.id]);
    notifyListeners();
    await _sync.envoyer(() => _api.updateRecurrence(maj));
  }

  double montantPrevuSurPeriode(DateTime debut, DateTime fin) {
    double total = 0;
    for (final r in _recurrences.where((r) => r.actif)) {
      var date = r.prochaineDate;
      while (!date.isAfter(fin)) {
        if (!date.isBefore(debut)) {
          total += r.type == 'depense' ? r.montant : -r.montant;
        }
        date = _nextDate(date, r.periodicite);
      }
    }
    return total;
  }

  Map<DateTime, List<TransactionRecurrente>> occurrencesForMonth(
      DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final map = <DateTime, List<TransactionRecurrente>>{};

    for (final r in _recurrences.where((r) => r.actif)) {
      var date = r.prochaineDate;
      while (!date.isAfter(last)) {
        if (!date.isBefore(first)) {
          final key = DateTime(date.year, date.month, date.day);
          map.putIfAbsent(key, () => []).add(r);
        }
        date = _nextDate(date, r.periodicite);
      }
    }
    return map;
  }

  static DateTime _nextDate(DateTime date, String periodicite) {
    if (periodicite == 'hebdomadaire') {
      return date.add(const Duration(days: 7));
    }
    if (periodicite == 'annuel') {
      return DateTime(date.year + 1, date.month, date.day);
    }
    return DateTime(date.year, date.month + 1, date.day);
  }

  @visibleForTesting
  set recurrencesPourTest(List<TransactionRecurrente> value) => _recurrences = value;

  void reset() {
    _recurrences = [];
    notifyListeners();
  }
}
