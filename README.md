# Planify — application mobile de planification des dépenses (Togo)

Application réalisée dans le cadre du mémoire de Licence Professionnelle « Développeur d'applications » d'ADIBOLO Y. A. Gottlieb (Institut FORMATEC, Lomé) : *Conception et réalisation d'une application mobile de planification de dépense — cas du Togo*.

| Couche | Technologies |
|---|---|
| Mobile | Flutter 3 / Dart, architecture MVVM (Provider / ChangeNotifier), SQLite (sqflite) hors ligne, Dio (HTTP), Flutter Secure Storage, fl_chart, Lottie |
| Serveur | Laravel 10 / PHP 8.2, API REST, Laravel Sanctum (jetons 24 h), MySQL 8 — voir [backend/](backend/README.md) |
| Notifications | Firebase Cloud Messaging (push) + notifications locales (alertes budget, rappel quotidien) |
| Administration | Interface web Laravel + Bootstrap |

## Fonctionnalités

- **Compte.** Inscription avec email de vérification ; connexion avec l'option « Rester connecté » et un blocage de 15 min après 5 échecs ; mot de passe oublié par code email, ou par question de sécurité hors ligne ; photo de profil ; suppression du compte.
- **Transactions.**
  - Saisie en feuille modale : montant, type, catégorie, date, mode de paiement (espèces, Mobile Money, virement, carte), description, photo de reçu (appareil photo ou galerie).
  - Recherche multicritère : catégorie, mode de paiement, période, montant.
  - Transactions récurrentes enregistrées automatiquement à leur échéance.
- **Mobile Money.** Comptes TMoney / Mixx by Yas et Flooz avec leur solde ; lancement des codes USSD (achat de crédit, transfert).
- **Budgets.**
  - Budget global ou par catégorie, hebdomadaire, mensuel ou annuel ; seuil d'alerte réglable (80 % par défaut).
  - Le montant déjà dépensé est affiché à la création ; le reliquat d'un mois est reporté sur le mois suivant.
  - Barres vertes, orange ou rouges selon la consommation ; calendrier des échéances.
- **Tableau de bord.** Solde, dépenses et revenus du mois ; graphique en anneau cliquable par catégorie ; alertes ; transactions récentes ; objectifs.
- **Rapports.**
  - Période au choix : semaine, mois, trimestre ou année.
  - Comparaisons avec la période précédente et avec la même période de l'année précédente.
  - Graphiques : histogramme sur 12 mois, courbe du solde cumulé.
  - Écart entre budget prévu et dépenses réelles ; prévisions par moyenne mobile ; trajectoire à 3, 6 et 12 mois ; recommandations personnalisées ; export PDF.
- **Objectifs d'épargne.** Suivi de la progression et calculateur du montant mensuel à épargner.
- **Paramètres.**
  - Notifications : alertes budgétaires, seuil par défaut, rappel quotidien.
  - Apparence : thème clair, sombre ou système, et couleur d'accent.
  - Données : export CSV / PDF, sauvegarde et synchronisation.
  - À propos : version, confidentialité, mentions légales, signalement d'un problème.
- **Hors ligne.** Tout fonctionne sans connexion. La synchronisation bidirectionnelle gère les conflits et les suppressions en attente.

## Structure (MVVM)

```
lib/
├── main.dart            # point d'entrée, thème, injection des ViewModels
├── models/              # Utilisateur, Transaction, Categorie, Budget, Alerte, Objectif, Compte…
├── views/               # écrans (auth, home, transactions, budgets, rapports, profil…)
├── viewmodels/          # logique de présentation et état (ChangeNotifier + Provider)
├── services/            # API (Dio), SQLite, synchronisation, notifications, FCM, export, USSD
├── utils/               # constantes, thème, validateurs, hachage, périodes, recommandations
└── widgets/             # composants réutilisables (graphique en anneau, force du mot de passe)
backend/                 # API Laravel 10 (voir backend/README.md)
test/                    # tests unitaires et de widgets
```

## Lancer l'application

```bash
flutter pub get
flutter run                                                   # mode local (sans serveur)
flutter run --dart-define=API_URL=http://192.168.1.10:8000    # avec l'API Laravel
```

Pour activer les notifications push, voir la section FCM de [backend/README.md](backend/README.md).

## Tests

```bash
flutter test          # 52 tests : hachage, authentification, migrations SQLite, synchronisation,
                      # client API, statistiques, prévisions, recommandations, validateurs
cd backend/planify-api && php artisan test   # tests Feature de l'API et de l'administration
```

## Build

```bash
flutter build apk --release --dart-define=API_URL=https://api.planify.tg
```
