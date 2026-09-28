import 'package:flutter_test/flutter_test.dart';
import 'package:planify/models/models.dart';
import 'package:planify/viewmodels/transaction_viewmodel.dart';

Transaction _tx(DateTime date, double montant, {String type = 'depense'}) => Transaction(
      id: '${date.toIso8601String()}-$montant-$type',
      montant: montant,
      type: type,
      dateTransaction: date,
      categorieId: 'cat_alimentation',
      utilisateurId: 'u1',
      dateCreation: date,
    );

void main() {
  final maintenant = DateTime(2026, 4, 15);

  test('moyenne sur les mois complets, mois vides ignorés', () {
    final p = TransactionViewModel()
      ..transactionsPourTest = [
        _tx(DateTime(2026, 3, 10), 30000), // mars
        _tx(DateTime(2026, 2, 5), 10000), // février
        // janvier : aucune transaction -> ignoré
        _tx(DateTime(2026, 4, 2), 99999), // mois en cours -> ignoré
      ];
    expect(p.previsionDepensesMensuelles(3, maintenant: maintenant), 20000);
  });

  test('un mois avec seulement des revenus compte comme 0 dépense', () {
    final p = TransactionViewModel()
      ..transactionsPourTest = [
        _tx(DateTime(2026, 3, 10), 30000),
        _tx(DateTime(2026, 2, 5), 50000, type: 'revenu'),
      ];
    expect(p.previsionDepensesMensuelles(3, maintenant: maintenant), 15000);
  });

  test('sans mois complet : extrapolation du mois en cours', () {
    // 7 500 FCFA dépensés en 15 jours sur un mois de 30 jours -> 15 000.
    final p = TransactionViewModel()
      ..transactionsPourTest = [
        _tx(DateTime(2026, 4, 2), 2500),
        _tx(DateTime(2026, 4, 13), 5000),
        _tx(DateTime(2026, 4, 13), 30000, type: 'revenu'),
      ];
    expect(p.previsionDepensesMensuelles(3, maintenant: maintenant), 15000);
  });

  test('aucune donnée : prévision nulle', () {
    expect(TransactionViewModel().previsionDepensesMensuelles(12, maintenant: maintenant), 0);
  });
}
