# Mise à jour du mémoire pour qu'il corresponde à l'application

L'application respecte désormais les technologies et fonctionnalités du mémoire. Certains passages du document restent pourtant inexacts, ou contradictoires entre eux. Ce document les liste section par section, avec une proposition de texte.

Légende : ✏️ texte à modifier · 🖼️ figure à refaire · ⚠️ affirmation à vérifier ou à retirer.

---

## Partout dans le document

- ✏️ **Nom de l'application : « Planify »**, pas « FinanceApp ». Il apparaît au §3-3-1, dans la fig. 1-5 et au §3-2-2 (`flutter create financeapp`).
- ✏️ **Opérateurs Mobile Money.** Écrire de façon uniforme « TMoney / Mixx by Yas (Yas Togo) » et « Flooz (Moov Africa Togo) ». L'introduction dit « T-Money ou Flooz », le §2-2-4 « TMoney (Yas Togo) », le §3-7-2 « Mixx by yas ».

## Chapitre 1

- ✏️ **Fig. 1-2.** L'acronyme MERISE y est développé en « … par les Sous-Ensembles ». Mettre la même définition que dans le texte : « Méthode d'Étude et de Réalisation Informatique pour les Systèmes d'Entreprise ».
- ✏️ **§1-1-4 (UML) et fig. 1-3.** Le texte dit « nous utilisons des diagrammes de cas d'utilisation, de séquence et d'activité », et la figure renvoie à des « Figure 7 » et « Figures 11-12 » qui n'existent pas. Or la méthode retenue est MERISE. Proposition :
  > « UML est présenté ici à titre de comparaison ; la conception de Planify repose sur MERISE (MCD, MCT, MLD, MPD). »

  Retirez aussi l'encadré « Diagrammes utilisés dans cette étude » de la fig. 1-3.
- 🖼️ **Fig. 1-5 et 3-4 (packages utilisés).** Remplacer « Hive (cache) » par **« SQLite (sqflite) »**. Le §1-2-3 et le §1-2-4 parlent déjà de SQLite. Garder Provider, **Dio (HTTP)**, fl_chart, Lottie, Flutter Secure Storage.
- ✏️ **§1-2-3.** « L'authentification est gérée par des tokens JWT » : Laravel Sanctum délivre des **jetons d'accès personnels (Bearer)**, pas des JWT. Proposition :
  > « L'authentification repose sur des jetons d'accès Laravel Sanctum, transmis dans l'en-tête `Authorization: Bearer` et valables 24 heures. »

  Faire la même correction au §3-1-4, au §3-2-4 et au §3-5-3, ainsi que dans « Liste des abréviations » (JWT).
- ✏️ **§1-2-4.** Préciser que les **alertes budgétaires et le rappel quotidien** sont des notifications locales, qui fonctionnent hors ligne. FCM envoie le **rapport hebdomadaire** et la **relance après 3 jours sans saisie**.

## Chapitre 2

- ⚠️ **§2-1-3-2 (limites).** Le texte dit que l'intégration Mobile Money n'est pas implémentée. Or l'application gère des **comptes Mobile Money avec solde** et lance les **codes USSD** (achat de crédit, transfert). Proposition :
  > « L'intégration Mobile Money est partielle : l'application tient le solde des comptes TMoney/Mixx et Flooz et lance les codes USSD de l'opérateur, mais la récupération automatique des transactions (API des opérateurs) n'est pas implémentée. »
- ⚠️ **§2-3-5 (déploiement).** N'écrivez « a été provisionné », « a nécessité la création d'un compte développeur Google » ou « un système de monitoring a été mis en place » **que si c'est vrai**. Sinon, passez au conditionnel ou à la procédure :
  > « Le déploiement prévu repose sur… »

  La procédure réelle figure dans `backend/README.md` : Nginx, PHP-FPM, Let's Encrypt, UFW, cron, sauvegarde `mysqldump`. Le §2-3-5 cite LAMP/Apache alors que la fig. 3-4 cite Nginx : choisissez **Nginx**.

## Chapitre 3

### §3-1-5 Modélisation (MCD, MLD, dictionnaire)

L'application et l'API ont **9 tables métier**, toutes gérées dans l'application :

| Table | Rôle |
|---|---|
| utilisateurs (`users`) | comptes (email unique, mot de passe haché, devise, photo, `token_fcm`, `is_admin`) |
| categories | catégories système ou personnelles (`est_systeme`, `est_archivee`) |
| transactions | dépenses et revenus (`mode_paiement`, `justificatif`, `compte_id`) |
| budgets | budgets par période (`seuil_alerte`, `montant_reporte`, alertes envoyées) |
| alertes | notifications (table ALERTE / NOTIFICATION du MCD) |
| objectifs | objectifs d'épargne |
| transactions_recurrentes | dépenses et revenus récurrents |
| comptes | comptes de paiement Mobile Money / espèces et leur solde |
| signalements | problèmes signalés à l'administrateur (serveur) |

- 🖼️ **MCD (fig. 3-1)**
  - Ajoutez OBJECTIF, COMPTE et TRANSACTION_RECURRENTE.
  - Unifiez ALERTE / NOTIFICATION : le texte dit ALERTE, la figure dit NOTIFICATION.
  - Retirez `est_recurrente` et `statut_sync` de TRANSACTION, qui ne sont pas utilisés : la récurrence a sa propre entité et la synchronisation se fait par `updated_at`.
  - Renommez `photo_recu` en **`justificatif`**.
- 🖼️ **MLD (fig. 3-3)**
  - Les identifiants sont des **UUID (VARCHAR(36/64))** générés par l'application, et non `INT AUTO_INCREMENT`. Justification à ajouter :
    > « Les identifiants sont générés par l'application (UUID) afin de pouvoir créer des données hors ligne, puis les synchroniser sans conflit de clé. »
  - Chaque table a une colonne `updated_at DATETIME(3)`, utilisée pour résoudre les conflits de synchronisation (la version la plus récente l'emporte).
- ✏️ **Tableau 3-1**
  - `id_transaction` : BIGINT → **VARCHAR(64), UUID**.
  - `utilisateur_id` : BIGINT → **CHAR(36), UUID** (même correction pour `categorie_id`).
  - `mode_paiement` : ENUM (especes, mobile_money, virement, carte).
  - Ajoutez `seuil_alerte` TINYINT (% du budget, 80 par défaut).

### §3-1-4 et §3-5-3 Sécurité

Formulations correspondant à l'implémentation :

- **Mots de passe.** Ils sont hachés en **bcrypt côté serveur** (Laravel) et en **PBKDF2-HMAC-SHA256** (20 000 itérations, sel aléatoire) sur le téléphone, pour la connexion hors ligne.
- **Force brute.** Après **5 échecs**, la connexion est **bloquée 15 minutes**, sur le serveur comme sur le téléphone.
- **Mot de passe oublié.** Un **code à 6 chiffres envoyé par email**, valable 15 min, est limité à 5 essais. Hors ligne, la réinitialisation passe par une **question de sécurité** dont la réponse est hachée.
- **Email.** Une **vérification d'adresse** est envoyée à l'inscription, avec un lien signé valable 60 min.
- **Jetons.** Le jeton Sanctum, valable 24 h, est stocké dans Flutter Secure Storage (Android Keystore / iOS Keychain).
- **Accès aux données.** Il est contrôlé par des **Policies Laravel** : un utilisateur ne peut ni lire, ni modifier, ni écraser les données d'un autre.
- ⚠️ La phrase « Les données sensibles doivent être chiffrées dans la base de données » (§3-1-4) n'est **pas implémentée**, car la base SQLite locale n'est pas chiffrée. Retirez-la, ou présentez-la comme une perspective (SQLCipher).

### §3-2-2 Structure du projet

Elle correspond maintenant au texte : `lib/models`, `lib/views`, `lib/viewmodels`, `lib/services`, `lib/utils`, `lib/widgets`. Le back-end est dans `backend/` (fichiers Laravel dans `backend/overlay/`).

### §3-2-3 Tests

- ⚠️ « Approche test-driven, tests écrits avant le code » : c'est à retirer si ce n'est pas ce que vous avez fait. Formulation exacte :
  > « Des tests unitaires automatisés (52 tests Flutter, `flutter test`) et des tests Feature Laravel (`php artisan test`) couvrent l'authentification, la sécurité, la synchronisation, les calculs financiers et le contrôle d'accès. »

### §3-3 Présentation de l'application

- 🖼️ **Refaire les captures 3-5 à 3-10.** Les anciennes montrent des bugs aujourd'hui corrigés : texte invisible, double bouton « + », « RIGHT OVERFLOWED », prévisions incohérentes.
- ✏️ **§3-3-1.**
  - Le fond est ardoise foncée avec un logo vert, pas un « dégradé bleu ». Le thème clair est aussi disponible.
  - La page de démarrage vérifie la **session enregistrée** et rafraîchit le profil si le serveur est joignable.
- ✏️ **§3-3-2.**
  - « Deux onglets Connexion / Inscription » : ce sont **deux écrans** reliés par un lien. Soit vous corrigez le texte, soit vous me demandez de passer en onglets.
  - « La figure 3-16 » → **3-6**.
- ✏️ **§3-3-3.** Les trois indicateurs (solde, revenus, dépenses) sont dans **une carte de synthèse**. L'anneau des dépenses du mois est cliquable ; la saisie s'ouvre en feuille modale.
- ✏️ **§3-3-4.** L'alerte se déclenche au **seuil choisi pour chaque budget** (80 % par défaut, réglable).
- ✏️ **§3-3-6.** Les catégories système peuvent être **archivées ou personnalisées, mais pas supprimées** ; les catégories personnelles peuvent être supprimées.

### §3-5 Tests de validation

- ⚠️ **Tableaux 3-3 et 3-4, SUS 78,5, 10 testeurs, 5 appareils.** Ne gardez que des chiffres **réellement mesurés**. Pour les performances, mesurez avec l'APK release et Flutter DevTools, puis reportez les valeurs obtenues. La ligne « 50 utilisateurs simultanés » suppose un test de charge sur l'API déployée.
- ✏️ **Taux de réussite.** Il vaut 88 % au §3-5-4 et 89 % au §3-7-1 : 44/50 = **88 %**.
- ✏️ **Ligne « Inscription — Compte créé, email envoyé ».** Elle est maintenant vérifiée par le test automatisé `AuthApiTest::test_inscription_renvoie_un_jeton_et_envoie_l_email_de_verification`.

### §3-6 Étude financière

- ✏️ **Tableau 3-5.**
  - Le texte dit « sans rémunération de main-d'œuvre », mais le tableau contient 500 000 et 700 000 FCFA de développement. Soit vous retirez ces lignes, soit vous changez la phrase (« en valorisant le temps de développement »).
  - La ligne « Développement backend » n'a pas de coût unitaire.
- ✏️ **Tableau 3-6.** « Publication mobile 15 000 FCFA » : le compte Google Play coûte 25 USD (≈ 15 000 FCFA), **payés une seule fois**, pas chaque année.

### §3-7 Discussion et conclusion

- ✏️ **Modèle freemium.** Il est cité au §3-7-2 sans avoir été présenté avant : présentez-le ou retirez-le.
- ✏️ **Version iOS en perspective.** Le code Flutter est multiplateforme, mais l'application n'a été **compilée et testée que sur Android**. Formulation :
  > « La publication et la validation sur iOS restent à réaliser. »
- ✏️ **Résultats à ajouter**, puisqu'ils existent désormais :
  - synchronisation hors ligne avec gestion des conflits ;
  - interface d'administration (statistiques anonymisées, catégories système, signalements) ;
  - rapports hebdomadaires par notification push ;
  - recommandations personnalisées ;
  - calculateur d'épargne.
