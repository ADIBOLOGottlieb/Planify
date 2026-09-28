import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import 'category_viewmodel.dart';
import 'compte_viewmodel.dart';

/// Critères de recherche et de filtrage des transactions.
class FiltreTransactions {
  final String? type;
  final String? categorieId;
  final String? modePaiement;
  final DateTime? debut;
  final DateTime? fin;
  final double? montantMin;
  final double? montantMax;
  final String? recherche;

  const FiltreTransactions({
    this.type,
    this.categorieId,
    this.modePaiement,
    this.debut,
    this.fin,
    this.montantMin,
    this.montantMax,
    this.recherche,
  });

  bool get estVide =>
      categorieId == null &&
      modePaiement == null &&
      debut == null &&
      fin == null &&
      montantMin == null &&
      montantMax == null;
}

/// Totaux d'une période (tableau de bord et rapports).
class TotauxPeriode {
  final double depenses;
  final double revenus;
  const TotauxPeriode(this.depenses, this.revenus);
  double get solde => revenus - depenses;
}

class TransactionViewModel extends ChangeNotifier {
  List<Transaction> _transactions = [];
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  final _api = ApiService();
  final _sync = SyncService();

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

  Future<void> charger(String userId, CategoryViewModel catProvider) async {
    await _sync.synchroniser<Transaction>(
      table: 'transactions',
      lignesLocales: await _db.query('transactions',
          where: 'utilisateur_id = ?', whereArgs: [userId]),
      lireDistant: _api.getTransactions,
      creerDistant: _api.createTransaction,
      modifierDistant: _api.updateTransaction,
      supprimerDistant: _api.deleteTransaction,
      fromMap: Transaction.fromMap,
      toMap: (t) => t.toMap(),
      idDe: (t) => t.id,
      modifieLe: (t) => t.updatedAt,
      preparerEnvoi: _avecRecuEnLigne,
    );
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

  /// Téléverse la photo du reçu avant d'envoyer la transaction au serveur et
  /// enregistre l'URL obtenue localement. Renvoie null (envoi différé) si le
  /// téléversement échoue, pour ne pas perdre le reçu.
  Future<Transaction?> _avecRecuEnLigne(Transaction t) async {
    final recu = t.justificatif;
    if (recu == null || recu.isEmpty || recu.startsWith('http')) return t;
    try {
      final url = await _api.uploadReceipt(recu);
      final maj = t.copyWith(justificatif: url);
      await _db.update('transactions', {'justificatif': url}, 'id = ?', [t.id]);
      final idx = _transactions.indexWhere((x) => x.id == t.id);
      if (idx >= 0) _transactions[idx] = maj;
      return maj;
    } catch (_) {
      return null;
    }
  }

  Future<void> _envoyer(Transaction t, Future<void> Function(Transaction) action) =>
      _sync.envoyer(() async {
        final aEnvoyer = await _avecRecuEnLigne(t);
        if (aEnvoyer != null) await action(aEnvoyer);
      });

  Future<Transaction> ajouter({
    required double montant,
    required String type,
    required DateTime date,
    String? description,
    String modePaiement = 'especes',
    String? justificatif,
    required String categorieId,
    String? compteId,
    required String userId,
    required CategoryViewModel catProvider,
    CompteViewModel? compteProvider,
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

    if (compteProvider != null && compteId != null) {
      await compteProvider.ajusterSolde(compteId, type == 'depense' ? -montant : montant);
    }

    _transactions.insert(0, t);
    _transactions.sort((a, b) => b.dateTransaction.compareTo(a.dateTransaction));
    notifyListeners();
    await _envoyer(t, _api.createTransaction);
    return t;
  }

  Future<void> modifier(Transaction transaction, {CompteViewModel? compteProvider}) async {
    final idx = _transactions.indexWhere((t) => t.id == transaction.id);
    final updated = transaction.copyWith(updatedAt: DateTime.now());
    await _db.update('transactions', updated.toMap(), 'id = ?', [transaction.id]);

    // Annule l'effet de l'ancienne version sur le solde puis applique la nouvelle.
    if (compteProvider != null && idx >= 0) {
      final ancien = _transactions[idx];
      if (ancien.compteId != null) {
        await compteProvider.ajusterSolde(
            ancien.compteId!, ancien.type == 'depense' ? ancien.montant : -ancien.montant);
      }
      if (updated.compteId != null) {
        await compteProvider.ajusterSolde(
            updated.compteId!, updated.type == 'depense' ? -updated.montant : updated.montant);
      }
    }

    if (idx >= 0) _transactions[idx] = updated;
    notifyListeners();
    await _envoyer(updated, _api.updateTransaction);
  }

  Future<void> supprimer(String id, {CompteViewModel? compteProvider}) async {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx >= 0 && compteProvider != null) {
      final t = _transactions[idx];
      if (t.compteId != null) {
        await compteProvider.ajusterSolde(t.compteId!, t.type == 'depense' ? t.montant : -t.montant);
      }
    }
    await _db.delete('transactions', 'id = ?', [id]);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    await _sync.supprimer('transactions', id, _api.deleteTransaction);
  }

  // ------------------------------------------------------ Recherche / filtres

  List<Transaction> rechercher(FiltreTransactions f) {
    final q = f.recherche?.trim().toLowerCase() ?? '';
    return _transactions.where((t) {
      if (f.type != null && t.type != f.type) return false;
      if (f.categorieId != null && t.categorieId != f.categorieId) return false;
      if (f.modePaiement != null && t.modePaiement != f.modePaiement) return false;
      if (f.debut != null && t.dateTransaction.isBefore(f.debut!)) return false;
      if (f.fin != null && t.dateTransaction.isAfter(f.fin!)) return false;
      if (f.montantMin != null && t.montant < f.montantMin!) return false;
      if (f.montantMax != null && t.montant > f.montantMax!) return false;
      if (q.isNotEmpty) {
        final dansDescription = t.description?.toLowerCase().contains(q) ?? false;
        final dansCategorie = t.categorie?.nom.toLowerCase().contains(q) ?? false;
        if (!dansDescription && !dansCategorie) return false;
      }
      return true;
    }).toList();
  }

  List<Transaction> filtrer({String? type, String? categorieId, DateTime? debut, DateTime? fin, String? recherche}) =>
      rechercher(FiltreTransactions(
          type: type, categorieId: categorieId, debut: debut, fin: fin, recherche: recherche));

  // ------------------------------------------------------------ Statistiques

  bool _dansPeriode(Transaction t, DateTime debut, DateTime fin) =>
      !t.dateTransaction.isBefore(debut) && !t.dateTransaction.isAfter(fin);

  TotauxPeriode totauxSurPeriode(DateTime debut, DateTime fin) {
    double dep = 0, rev = 0;
    for (final t in _transactions) {
      if (!_dansPeriode(t, debut, fin)) continue;
      if (t.type == 'depense') {
        dep += t.montant;
      } else {
        rev += t.montant;
      }
    }
    return TotauxPeriode(dep, rev);
  }

  /// Dépenses par catégorie sur la période, indexées par identifiant.
  Map<String, double> depensesParCategorieSurPeriode(DateTime debut, DateTime fin) {
    final result = <String, double>{};
    for (final t in _transactions) {
      if (t.type == 'depense' && _dansPeriode(t, debut, fin)) {
        result[t.categorieId] = (result[t.categorieId] ?? 0) + t.montant;
      }
    }
    return result;
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

  List<Map<String, dynamic>> getEvolutionMensuelle(int nbMois, {DateTime? maintenant}) {
    final result = <Map<String, dynamic>>[];
    final now = maintenant ?? DateTime.now();
    for (int i = nbMois - 1; i >= 0; i--) {
      final mois = DateTime(now.year, now.month - i, 1);
      final totaux = totauxSurPeriode(mois, DateTime(mois.year, mois.month + 1, 1)
          .subtract(const Duration(microseconds: 1)));
      result.add({'mois': mois, 'depenses': totaux.depenses, 'revenus': totaux.revenus});
    }
    return result;
  }

  /// Solde cumulé (revenus − dépenses depuis le début) à la fin de chacun des
  /// [nbMois] derniers mois.
  List<({DateTime mois, double solde})> soldeCumule(int nbMois, {DateTime? maintenant}) {
    final now = maintenant ?? DateTime.now();
    final premier = DateTime(now.year, now.month - nbMois + 1, 1);
    var cumul = _transactions
        .where((t) => t.dateTransaction.isBefore(premier))
        .fold(0.0, (s, t) => s + (t.type == 'depense' ? -t.montant : t.montant));
    final points = <({DateTime mois, double solde})>[];
    for (final m in getEvolutionMensuelle(nbMois, maintenant: now)) {
      cumul += (m['revenus'] as double) - (m['depenses'] as double);
      points.add((mois: m['mois'] as DateTime, solde: cumul));
    }
    return points;
  }

  /// Prévision de la dépense mensuelle par moyenne mobile sur les [fenetre]
  /// derniers mois complets. Les mois sans aucune transaction (application
  /// pas encore utilisée) sont ignorés pour ne pas tirer la moyenne vers 0.
  /// Sans mois complet disponible, le mois en cours est extrapolé au prorata
  /// des jours écoulés.
  double previsionDepensesMensuelles(int fenetre, {DateTime? maintenant}) {
    final now = maintenant ?? DateTime.now();
    final totaux = <double>[];
    for (var i = 1; i <= fenetre; i++) {
      final mois = DateTime(now.year, now.month - i, 1);
      final txMois = _transactions.where((t) =>
          t.dateTransaction.year == mois.year && t.dateTransaction.month == mois.month);
      if (txMois.isEmpty) continue;
      totaux.add(txMois
          .where((t) => t.type == 'depense')
          .fold(0.0, (sum, t) => sum + t.montant));
    }
    if (totaux.isNotEmpty) {
      return totaux.reduce((a, b) => a + b) / totaux.length;
    }

    final depensesEnCours = _transactions
        .where((t) =>
            t.type == 'depense' &&
            t.dateTransaction.year == now.year &&
            t.dateTransaction.month == now.month &&
            !t.dateTransaction.isAfter(now))
        .fold(0.0, (sum, t) => sum + t.montant);
    final joursDansMois = DateTime(now.year, now.month + 1, 0).day;
    return depensesEnCours / now.day * joursDansMois;
  }

  /// Prévision du revenu mensuel (même méthode que les dépenses).
  double previsionRevenusMensuels(int fenetre, {DateTime? maintenant}) {
    final now = maintenant ?? DateTime.now();
    final totaux = <double>[];
    for (var i = 1; i <= fenetre; i++) {
      final mois = DateTime(now.year, now.month - i, 1);
      final txMois = _transactions.where((t) =>
          t.dateTransaction.year == mois.year && t.dateTransaction.month == mois.month);
      if (txMois.isEmpty) continue;
      totaux.add(txMois
          .where((t) => t.type == 'revenu')
          .fold(0.0, (sum, t) => sum + t.montant));
    }
    return totaux.isEmpty ? 0 : totaux.reduce((a, b) => a + b) / totaux.length;
  }

  /// Remplace la liste en mémoire ; réservé aux tests.
  @visibleForTesting
  set transactionsPourTest(List<Transaction> value) => _transactions = value;

  double getDepensesParCategorieId(String categorieId, DateTime debut, DateTime fin) {
    return _transactions
      .where((t) => t.type == 'depense' && t.categorieId == categorieId && _dansPeriode(t, debut, fin))
      .fold(0.0, (sum, t) => sum + t.montant);
  }

  void reset() {
    _transactions = [];
    notifyListeners();
  }
}
