import 'package:flutter/material.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/database_helper.dart';
import 'category_provider.dart';
import '../services/api_service.dart';
import '../utils/settings_service.dart';
import 'compte_provider.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  final _api = ApiService();
  final _settings = SettingsService();

  List<Transaction> get transactions => _transactions;

  double get totalDepenses => _transactions.where((t) => t.type == 'depense').fold(0, (sum, t) => sum + t.montant);
  double get totalRevenus => _transactions.where((t) => t.type == 'revenu').fold(0, (sum, t) => sum + t.montant);
  double get solde => totalRevenus - totalDepenses;

  List<Transaction> get transactionsDuMois {
    final now = DateTime.now();
    return _transactions.where((t) => t.dateTransaction.month == now.month && t.dateTransaction.year == now.year).toList();
  }

  double get depensesDuMois => transactionsDuMois.where((t) => t.type == 'depense').fold(0, (sum, t) => sum + t.montant);
  double get revenusDuMois => transactionsDuMois.where((t) => t.type == 'revenu').fold(0, (sum, t) => sum + t.montant);
  double get soldeDuMois => revenusDuMois - depensesDuMois;

  Future<void> charger(String userId, CategoryProvider catProvider) async {
    final syncEnabled = await _settings.isSyncEnabled();
    if (syncEnabled) {
      try {
        await _syncWithRemote(userId, catProvider);
        return;
      } catch (_) {}
    }
    await _loadLocal(userId, catProvider);
  }

  Future<void> _loadLocal(String userId, CategoryProvider catProvider) async {
    final results = await _db.query(
      'transactions',
      where: 'utilisateur_id = ?',
      whereArgs: [userId],
      orderBy: 'date_transaction DESC',
    );
    _transactions = results.map((map) {
      final t = Transaction.fromMap(map);
      t.categorie = catProvider.findById(t.categorieId);
      return t;
    }).toList();
    notifyListeners();
  }

  Future<void> _syncWithRemote(
      String userId, CategoryProvider catProvider) async {
    final remote = await _api.getTransactions();
    final localRows = await _db.query(
      'transactions',
      where: 'utilisateur_id = ?',
      whereArgs: [userId],
    );
    final local = {
      for (final m in localRows) m['id'] as String: Transaction.fromMap(m)
    };
    final remoteMap = {for (final t in remote) t.id: t};

    // Push local missing remotely
    for (final entry in local.entries) {
      if (!remoteMap.containsKey(entry.key)) {
        final toSend = await _ensureReceiptUploaded(entry.value);
        final localHasReceipt = entry.value.justificatif != null &&
            !entry.value.justificatif!.startsWith('http');
        if (localHasReceipt && toSend.justificatif == null) {
          continue;
        }
        try {
          await _api.createTransaction(toSend);
        } catch (_) {}
      }
    }

    // Merge remote
    for (final r in remote) {
      final l = local[r.id];
      if (l == null) {
        await _db.insert('transactions', r.toMap());
      } else {
        if (l.updatedAt.isAfter(r.updatedAt)) {
          final toSend = await _ensureReceiptUploaded(l);
          final localHasReceipt =
              l.justificatif != null && !l.justificatif!.startsWith('http');
          if (localHasReceipt && toSend.justificatif == null) {
            continue;
          }
          try {
            await _api.updateTransaction(toSend);
          } catch (_) {}
        } else if (r.updatedAt.isAfter(l.updatedAt)) {
          await _db.update('transactions', r.toMap(), 'id = ?', [r.id]);
        }
      }
    }

    await _loadLocal(userId, catProvider);
  }

  Future<Transaction> _ensureReceiptUploaded(Transaction t) async {
    final justificatif = t.justificatif;
    if (justificatif == null || justificatif.isEmpty) return t;
    if (justificatif.startsWith('http')) return t;
    try {
      final url = await _api.uploadReceipt(File(justificatif));
      return Transaction(
        id: t.id,
        montant: t.montant,
        type: t.type,
        dateTransaction: t.dateTransaction,
        description: t.description,
        modePaiement: t.modePaiement,
        justificatif: url,
        categorieId: t.categorieId,
        utilisateurId: t.utilisateurId,
        dateCreation: t.dateCreation,
        updatedAt: DateTime.now(),
      );
    } catch (_) {
      return Transaction(
        id: t.id,
        montant: t.montant,
        type: t.type,
        dateTransaction: t.dateTransaction,
        description: t.description,
        modePaiement: t.modePaiement,
        justificatif: null,
        categorieId: t.categorieId,
        utilisateurId: t.utilisateurId,
        dateCreation: t.dateCreation,
        updatedAt: t.updatedAt,
      );
    }
  }

  Future<void> ajouter({
    required double montant,
    required String type,
    required DateTime date,
    String? description,
    String modePaiement = 'especes',
    String? justificatif,
    required String categorieId,
    String? compteId,
    required String userId,
    required CategoryProvider catProvider,
    CompteProvider? compteProvider,
  }) async {
    final now = DateTime.now();
    final t = Transaction(
      id: _uuid.v4(),
      montant: montant,
      type: type,
      dateTransaction: date,
      description: description,
      modePaiement: modePaiement,
      justificatif: justificatif,
      categorieId: categorieId,
      compteId: compteId,
      utilisateurId: userId,
      dateCreation: now,
      updatedAt: now,
    );
    t.categorie = catProvider.findById(categorieId);
    await _db.insert('transactions', t.toMap());

    // Ajuster le solde du compte
    if (compteProvider != null && compteId != null) {
      final delta = type == 'depense' ? -montant : montant;
      await compteProvider.ajusterSolde(compteId, delta);
    }

    _transactions.insert(0, t);
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        final toSend = await _ensureReceiptUploaded(t);
        final localHasReceipt =
            t.justificatif != null && !t.justificatif!.startsWith('http');
        if (localHasReceipt && toSend.justificatif == null) {
          return;
        }
        await _api.createTransaction(toSend);
        if (toSend.justificatif != null &&
            toSend.justificatif != t.justificatif &&
            toSend.justificatif!.startsWith('http')) {
          await _db.update('transactions', toSend.toMap(), 'id = ?', [t.id]);
          final idx = _transactions.indexWhere((x) => x.id == t.id);
          if (idx >= 0) _transactions[idx] = toSend;
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  Future<void> modifier(Transaction transaction, {CompteProvider? compteProvider}) async {
    final updated = Transaction(
      id: transaction.id,
      montant: transaction.montant,
      type: transaction.type,
      dateTransaction: transaction.dateTransaction,
      description: transaction.description,
      modePaiement: transaction.modePaiement,
      justificatif: transaction.justificatif,
      categorieId: transaction.categorieId,
      utilisateurId: transaction.utilisateurId,
      dateCreation: transaction.dateCreation,
      updatedAt: DateTime.now(),
    );
    await _db.update('transactions', updated.toMap(), 'id = ?', [transaction.id]);
    final idx = _transactions.indexWhere((t) => t.id == transaction.id);
    
    // Ajuster les soldes si le compte ou le montant a changé
    if (compteProvider != null) {
      final oldT = _transactions[idx];
      // Restaurer l'ancien
      if (oldT.compteId != null) {
        final oldDelta = oldT.type == 'depense' ? oldT.montant : -oldT.montant;
        await compteProvider.ajusterSolde(oldT.compteId!, oldDelta);
      }
      // Appliquer le nouveau
      if (updated.compteId != null) {
        final newDelta = updated.type == 'depense' ? -updated.montant : updated.montant;
        await compteProvider.ajusterSolde(updated.compteId!, newDelta);
      }
    }

    if (idx >= 0) _transactions[idx] = updated;
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        final toSend = await _ensureReceiptUploaded(updated);
        final localHasReceipt = updated.justificatif != null &&
            !updated.justificatif!.startsWith('http');
        if (localHasReceipt && toSend.justificatif == null) {
          return;
        }
        await _api.updateTransaction(toSend);
        if (toSend.justificatif != null &&
            toSend.justificatif != updated.justificatif &&
            toSend.justificatif!.startsWith('http')) {
          await _db.update('transactions', toSend.toMap(), 'id = ?', [updated.id]);
          if (idx >= 0) _transactions[idx] = toSend;
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  Future<void> supprimer(String id, {CompteProvider? compteProvider}) async {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx >= 0 && compteProvider != null) {
      final t = _transactions[idx];
      if (t.compteId != null) {
        final delta = t.type == 'depense' ? t.montant : -t.montant;
        await compteProvider.ajusterSolde(t.compteId!, delta);
      }
    }
    await _db.delete('transactions', 'id = ?', [id]);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();

    if (await _settings.isSyncEnabled()) {
      try {
        await _api.deleteTransaction(id);
      } catch (_) {}
    }
  }

  List<Transaction> filtrer({String? type, String? categorieId, DateTime? debut, DateTime? fin, String? recherche}) {
    return _transactions.where((t) {
      if (type != null && t.type != type) return false;
      if (categorieId != null && t.categorieId != categorieId) return false;
      if (debut != null && t.dateTransaction.isBefore(debut)) return false;
      if (fin != null && t.dateTransaction.isAfter(fin)) return false;
      if (recherche != null && recherche.isNotEmpty) {
        final q = recherche.toLowerCase();
        if (!(t.description?.toLowerCase().contains(q) ?? false) && !(t.categorie?.nom.toLowerCase().contains(q) ?? false)) return false;
      }
      return true;
    }).toList();
  }

  Map<String, double> getDepensesParCategorie(DateTime mois) {
    final result = <String, double>{};
    for (final t in _transactions) {
      if (t.type == 'depense' && t.dateTransaction.month == mois.month && t.dateTransaction.year == mois.year) {
        final catNom = t.categorie?.nom ?? 'Autre';
        result[catNom] = (result[catNom] ?? 0) + t.montant;
      }
    }
    return result;
  }

  List<Map<String, dynamic>> getEvolutionMensuelle(int nbMois) {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = nbMois - 1; i >= 0; i--) {
      final mois = DateTime(now.year, now.month - i, 1);
      final dep = _transactions.where((t) => t.type == 'depense' && t.dateTransaction.month == mois.month && t.dateTransaction.year == mois.year).fold(0.0, (sum, t) => sum + t.montant);
      final rev = _transactions.where((t) => t.type == 'revenu' && t.dateTransaction.month == mois.month && t.dateTransaction.year == mois.year).fold(0.0, (sum, t) => sum + t.montant);
      result.add({'mois': mois, 'depenses': dep, 'revenus': rev});
    }
    return result;
  }

  double getDepensesParCategorieId(String categorieId, DateTime debut, DateTime fin) {
    return _transactions
      .where((t) => t.type == 'depense' && t.categorieId == categorieId && !t.dateTransaction.isBefore(debut) && !t.dateTransaction.isAfter(fin))
      .fold(0.0, (sum, t) => sum + t.montant);
  }

  void reset() {
    _transactions = [];
    notifyListeners();
  }
}
