import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/database_helper.dart';
import 'category_provider.dart';
import '../services/api_service.dart';
import '../utils/settings_service.dart';

class RecurrenceProvider extends ChangeNotifier {
  List<TransactionRecurrente> _recurrences = [];
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  final _api = ApiService();
  final _settings = SettingsService();

  List<TransactionRecurrente> get recurrences => _recurrences;

  Future<void> charger(String userId, CategoryProvider catProvider) async {
    final syncEnabled = await _settings.isSyncEnabled();
    if (syncEnabled) {
      try {
        await _syncWithRemote(userId, catProvider);
        return;
      } catch (_) {}
    }
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

  Future<void> _syncWithRemote(
      String userId, CategoryProvider catProvider) async {
    final remote = await _api.getRecurrences();
    final localRows = await _db.query(
      'transactions_recurrentes',
      where: 'utilisateur_id = ?',
      whereArgs: [userId],
    );
    final local = {
      for (final m in localRows) m['id'] as String: TransactionRecurrente.fromMap(m)
    };
    final remoteMap = {for (final r in remote) r.id: r};

    for (final entry in local.entries) {
      if (!remoteMap.containsKey(entry.key)) {
        try {
          await _api.createRecurrence(entry.value);
        } catch (_) {}
      }
    }

    for (final r in remote) {
      final l = local[r.id];
      if (l == null) {
        await _db.insert('transactions_recurrentes', r.toMap());
      } else {
        if (l.updatedAt.isAfter(r.updatedAt)) {
          try {
            await _api.updateRecurrence(l);
          } catch (_) {}
        } else if (r.updatedAt.isAfter(l.updatedAt)) {
          await _db.update('transactions_recurrentes', r.toMap(), 'id = ?', [r.id]);
        }
      }
    }

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
    required CategoryProvider catProvider,
  }) async {
    final now = DateTime.now();
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
      updatedAt: now,
    );
    r.categorie = catProvider.findById(categorieId);
    await _db.insert('transactions_recurrentes', r.toMap());
    _recurrences.add(r);
    _recurrences.sort((a, b) => a.prochaineDate.compareTo(b.prochaineDate));
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        await _api.createRecurrence(r);
      } catch (_) {}
    }
  }

  Future<void> supprimer(String id) async {
    await _db.delete('transactions_recurrentes', 'id = ?', [id]);
    _recurrences.removeWhere((r) => r.id == id);
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        await _api.deleteRecurrence(id);
      } catch (_) {}
    }
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

    return DateTime(date.year, date.month + 1, date.day);
  }

  void reset() {
    _recurrences = [];
    notifyListeners();
  }
}
