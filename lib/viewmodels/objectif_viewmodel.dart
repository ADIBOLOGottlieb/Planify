import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';

class ObjectifViewModel extends ChangeNotifier {
  List<Objectif> _objectifs = [];
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  final _api = ApiService();
  final _sync = SyncService();

  List<Objectif> get objectifs => _objectifs;
  List<Objectif> get objectifsEnCours => _objectifs.where((o) => o.statut == 'en_cours').toList();

  /// Calculateur d'épargne : montant à mettre de côté chaque mois pour
  /// atteindre l'objectif à son échéance (au moins un mois est compté).
  static double epargneMensuelleNecessaire(Objectif o, {DateTime? maintenant}) {
    final now = maintenant ?? DateTime.now();
    if (o.restant <= 0) return 0;
    var mois = (o.dateEcheance.year - now.year) * 12 + o.dateEcheance.month - now.month;
    if (o.dateEcheance.day > now.day) mois += 1;
    return o.restant / (mois < 1 ? 1 : mois);
  }

  Future<List<Map<String, dynamic>>> _lignes(String userId) => _db.query('objectifs',
      where: 'utilisateur_id = ?', whereArgs: [userId], orderBy: 'date_echeance ASC');

  Future<void> charger(String userId) async {
    await _sync.synchroniser<Objectif>(
      table: 'objectifs',
      lignesLocales: await _lignes(userId),
      lireDistant: _api.getObjectifs,
      creerDistant: _api.createObjectif,
      modifierDistant: _api.updateObjectif,
      supprimerDistant: _api.deleteObjectif,
      fromMap: Objectif.fromMap,
      toMap: (o) => o.toMap(),
      idDe: (o) => o.id,
      modifieLe: (o) => o.updatedAt,
    );
    _objectifs = (await _lignes(userId)).map(Objectif.fromMap).toList();
    notifyListeners();
  }

  Future<void> ajouter({required String nom, required double montantCible, required DateTime dateEcheance, required String userId}) async {
    final obj = Objectif(
      id: _uuid.v4(),
      nom: nom,
      montantCible: montantCible,
      dateEcheance: dateEcheance,
      utilisateurId: userId,
      updatedAt: DateTime.now(),
    );
    await _db.insert('objectifs', obj.toMap());
    _objectifs.add(obj);
    notifyListeners();
    await _sync.envoyer(() => _api.createObjectif(obj));
  }

  Future<void> alimenter(String id, double montant) async {
    final idx = _objectifs.indexWhere((o) => o.id == id);
    if (idx < 0) return;
    final o = _objectifs[idx];
    final actuel = (o.montantActuel + montant).clamp(0, o.montantCible).toDouble();
    final maj = Objectif(
      id: o.id,
      nom: o.nom,
      montantCible: o.montantCible,
      montantActuel: actuel,
      dateEcheance: o.dateEcheance,
      statut: actuel >= o.montantCible ? 'atteint' : o.statut,
      utilisateurId: o.utilisateurId,
      updatedAt: DateTime.now(),
    );
    _objectifs[idx] = maj;
    await _db.update('objectifs', maj.toMap(), 'id = ?', [id]);
    notifyListeners();
    await _sync.envoyer(() => _api.updateObjectif(maj));
  }

  Future<void> supprimer(String id) async {
    await _db.delete('objectifs', 'id = ?', [id]);
    _objectifs.removeWhere((o) => o.id == id);
    notifyListeners();
    await _sync.supprimer('objectifs', id, _api.deleteObjectif);
  }

  void reset() {
    _objectifs = [];
    notifyListeners();
  }
}
