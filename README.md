# Planify - Application de Planification de Dépenses

Application Flutter complète de gestion financière personnelle, inspirée du mémoire d'ADIBOLO Yawo Andréas Gottlieb.

## Fonctionnalités

### 🔐 Authentification
- Inscription avec nom, prénom, email et mot de passe
- Connexion sécurisée
- Modification du profil et changement de mot de passe

### 💰 Gestion des Transactions
- Saisie de dépenses et revenus
- Catégorisation par type (Alimentation, Transport, Santé, Salaire, etc.)
- Modes de paiement : Espèces, Mobile Money, Virement, Carte
- Recherche et filtrage
- Glisser pour supprimer

### 📊 Budgets
- Création de budgets globaux ou par catégorie
- Suivi en temps réel de la consommation
- Alertes visuelles à 80% et dépassement
- Périodes : hebdomadaire, mensuel, annuel

### 📈 Rapports & Analyses
- Tableau de bord avec solde, revenus et dépenses du mois
- Graphiques circulaires de répartition des dépenses
- Histogramme d'évolution sur 6 mois
- Sélecteur de mois pour l'analyse historique

### 🎯 Objectifs d'Épargne
- Création d'objectifs avec montant cible et date d'échéance
- Alimentation progressive des objectifs
- Suivi visuel de la progression

### 👤 Profil
- Gestion du compte utilisateur
- Choix de devise (FCFA, EUR, USD, GBP, XOF)
- Déconnexion

## Stack Technique

- **Framework** : Flutter / Dart
- **Base de données** : SQLite (sqflite)
- **State Management** : Provider
- **Graphiques** : fl_chart
- **Polices** : Google Fonts (Manrope)
- **Stockage** : SharedPreferences
- **Internationalisation** : intl + flutter_localizations

## Installation

### Prérequis
- Flutter SDK >= 3.0.0
- Android Studio ou VS Code
- Un émulateur Android ou appareil physique

### Étapes

```bash
# Cloner le projet
git clone <repo-url>
cd planification_depense

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

### Build APK

```bash
flutter build apk --release
```

## Structure du Projet

```
lib/
├── main.dart                    # Point d'entrée
├── models/
│   └── models.dart              # Modèles de données
├── providers/
│   ├── auth_provider.dart       # Authentification
│   ├── transaction_provider.dart
│   ├── budget_provider.dart
│   ├── category_provider.dart
│   └── objectif_provider.dart
├── screens/
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   ├── main_screen.dart
│   │   └── dashboard_screen.dart
│   ├── transactions/
│   │   ├── transactions_screen.dart
│   │   └── add_transaction_screen.dart
│   ├── budgets/
│   │   └── budgets_screen.dart
│   ├── rapports/
│   │   └── rapports_screen.dart
│   └── profil/
│       └── profil_screen.dart
└── utils/
    ├── database_helper.dart
    └── app_constants.dart
```

## Auteur

Inspiré du mémoire de **ADIBOLO Yawo Andréas Gottlieb**  
Institut FORMATEC - Licence Professionnelle, Développement d'Applications  
Année académique 2024-2025
