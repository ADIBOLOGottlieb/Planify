import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:planify/models/models.dart';
import 'package:planify/utils/periode.dart';
import 'package:planify/utils/recommandations.dart';
import 'package:planify/viewmodels/objectif_viewmodel.dart';
import 'package:planify/viewmodels/recurrence_viewmodel.dart';
import 'package:planify/viewmodels/transaction_viewmodel.dart';

Transaction _tx(DateTime date, double montant, {String type = 'depense', String cat = 'cat_alimentation'}) =>
    Transaction(
      id: '${date.toIso8601String()}-$montant-$type-$cat',
      montant: montant,
      type: type,
      dateTransaction: date,
      categorieId: cat,
      utilisateurId: 'u1',
      dateCreation: date,
    );

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('Periode', () {
    test('semaine du lundi au dimanche', () {
      final p = Periode.contenant(TypePeriode.semaine, DateTime(2026, 9, 27)); // dimanche
      expect(p.debut, DateTime(2026, 9, 21));
      expect(p.fin.isBefore(DateTime(2026, 9, 28)), isTrue);
      expect(p.contient(DateTime(2026, 9, 27, 23, 59)), isTrue);
    });

    test('trimestre et période précédente', () {
      final p = Periode.contenant(TypePeriode.trimestre, DateTime(2026, 5, 10));
      expect(p.debut, DateTime(2026, 4, 1));
      expect(p.libelle, 'T2 2026');
      expect(p.precedente.debut, DateTime(2026, 1, 1));
      expect(p.suivante.debut, DateTime(2026, 7, 1));
    });

    test('même période de l\'année précédente', () {
      final p = Periode.contenant(TypePeriode.mois, DateTime(2026, 3, 15));
      expect(p.anneePrecedente.debut, DateTime(2025, 3, 1));
      expect(p.anneePrecedente.fin.month, 3);
    });

    test('libellé du mois en français', () {
      expect(Periode.contenant(TypePeriode.mois, DateTime(2026, 4, 2)).libelle, 'avril 2026');
    });
  });

  group('Statistiques', () {
    final vm = TransactionViewModel()
      ..transactionsPourTest = [
        _tx(DateTime(2026, 1, 5), 100000, type: 'revenu'),
        _tx(DateTime(2026, 1, 10), 30000),
        _tx(DateTime(2026, 2, 3), 50000),
        _tx(DateTime(2026, 2, 20), 20000, cat: 'cat_transport'),
      ];

    test('totaux sur une période', () {
      final t = vm.totauxSurPeriode(DateTime(2026, 2, 1), DateTime(2026, 2, 28, 23, 59));
      expect(t.depenses, 70000);
      expect(t.revenus, 0);
      expect(t.solde, -70000);
    });

    test('dépenses par catégorie', () {
      expect(vm.depensesParCategorieSurPeriode(DateTime(2026, 2, 1), DateTime(2026, 3, 1)),
          {'cat_alimentation': 50000, 'cat_transport': 20000});
    });

    test('solde cumulé mois par mois', () {
      final points = vm.soldeCumule(3, maintenant: DateTime(2026, 3, 15));
      expect(points.map((p) => p.solde), [70000, 0, 0]);
    });

    test('évolution sur 12 mois', () {
      final evo = vm.getEvolutionMensuelle(12, maintenant: DateTime(2026, 3, 15));
      expect(evo, hasLength(12));
      expect(evo.last['mois'], DateTime(2026, 3, 1));
      expect(evo[10]['depenses'], 70000);
    });
  });

  group('Recommandations', () {
    test('dépenses supérieures aux revenus', () {
      final r = genererRecommandations(const DonneesRecommandation(
        depenses: 120000,
        revenus: 100000,
        depensesPrecedentes: 0,
        parCategorie: {'Alimentation': 80000, 'Transport': 40000},
        parCategoriePrecedente: {},
        budgetsDepasses: [],
        devise: 'FCFA',
      ));
      expect(r.first, contains('dépassent vos revenus'));
      expect(r.first, contains('Alimentation'));
      expect(r.any((c) => c.contains('représente 67 %')), isTrue);
    });

    test('hausse d\'une catégorie et budget dépassé', () {
      final r = genererRecommandations(const DonneesRecommandation(
        depenses: 50000,
        revenus: 200000,
        depensesPrecedentes: 40000,
        parCategorie: {'Transport': 30000, 'Loisirs': 20000},
        parCategoriePrecedente: {'Transport': 15000, 'Loisirs': 25000},
        budgetsDepasses: ['Transport'],
        devise: 'FCFA',
      ));
      expect(r.first, contains('Bravo'));
      expect(r.any((c) => c.contains('« Transport » ont augmenté de 100 %')), isTrue);
      expect(r.any((c) => c.contains('Budget « Transport » dépassé')), isTrue);
    });

    test('aucune donnée : conseil par défaut', () {
      final r = genererRecommandations(const DonneesRecommandation(
        depenses: 0,
        revenus: 0,
        depensesPrecedentes: 0,
        parCategorie: {},
        parCategoriePrecedente: {},
        budgetsDepasses: [],
        devise: 'FCFA',
      ));
      expect(r.single, contains('Continuez'));
    });
  });

  group('Calculateur d\'épargne', () {
    Objectif obj(double cible, double actuel, DateTime echeance) => Objectif(
        id: 'o', nom: 'Moto', montantCible: cible, montantActuel: actuel,
        dateEcheance: echeance, utilisateurId: 'u1');

    test('répartit le reste sur les mois restants', () {
      final o = obj(300000, 60000, DateTime(2026, 12, 20));
      expect(ObjectifViewModel.epargneMensuelleNecessaire(o, maintenant: DateTime(2026, 9, 27)),
          80000); // 240 000 sur 3 versements : oct., nov., déc.
    });

    test('échéance dépassée : tout le reste ce mois-ci', () {
      final o = obj(100000, 40000, DateTime(2026, 1, 1));
      expect(ObjectifViewModel.epargneMensuelleNecessaire(o, maintenant: DateTime(2026, 9, 27)), 60000);
    });

    test('objectif atteint : rien à épargner', () {
      final o = obj(100000, 100000, DateTime(2027, 1, 1));
      expect(ObjectifViewModel.epargneMensuelleNecessaire(o), 0);
    });
  });

  group('Transactions récurrentes', () {
    test('échéances dues jusqu\'à aujourd\'hui', () {
      final vm = RecurrenceViewModel()
        ..recurrencesPourTest = [
          TransactionRecurrente(
            id: 'loyer',
            montant: 50000,
            type: 'depense',
            dateDebut: DateTime(2026, 7, 5),
            prochaineDate: DateTime(2026, 7, 5),
            periodicite: 'mensuel',
            categorieId: 'cat_logement',
            utilisateurId: 'u1',
          ),
          TransactionRecurrente(
            id: 'abonnement',
            montant: 5000,
            type: 'depense',
            dateDebut: DateTime(2026, 10, 1),
            prochaineDate: DateTime(2026, 10, 1),
            periodicite: 'mensuel',
            categorieId: 'cat_telecom',
            utilisateurId: 'u1',
          ),
        ];
      final dues = vm.echeancesDues(maintenant: DateTime(2026, 9, 27));
      expect(dues.map((d) => d.date),
          [DateTime(2026, 7, 5), DateTime(2026, 8, 5), DateTime(2026, 9, 5)]);
      expect(dues.every((d) => d.recurrence.id == 'loyer'), isTrue);
    });
  });
}
