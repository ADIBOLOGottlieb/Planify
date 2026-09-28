# API Planify — Laravel 10 / PHP 8.2 / MySQL 8

Back-end de l'application mobile Planify : API REST sécurisée par Laravel Sanctum, envoi des notifications push (Firebase Cloud Messaging), tâches planifiées et interface web d'administration (Laravel + Bootstrap).

Le dossier `overlay/` contient uniquement les fichiers propres à Planify. Ils se copient dans un projet Laravel 10 standard, ce que fait le script d'installation.

## Installation (développement)

Prérequis : PHP 8.2 (extensions `pdo_mysql`, `pdo_sqlite`, `openssl`, `mbstring`, `fileinfo`, `intl`), Composer, MySQL 8.

```powershell
powershell -ExecutionPolicy Bypass -File backend\install.ps1   # Windows
bash backend/install.sh                                        # Linux / macOS
```

Ensuite, dans `backend/planify-api` :

1. Dans `.env`, renseignez `DB_DATABASE`, `DB_USERNAME` et `DB_PASSWORD`. En local, mettez `MAIL_MAILER=log` : les emails sont alors écrits dans `storage/logs/laravel.log`.
2. Lancez :

```bash
php artisan migrate --seed                        # tables + catégories système
php artisan planify:creer-admin admin@planify.tg  # compte de l'interface d'administration
php artisan test                                  # tests Feature (SQLite en mémoire)
php artisan serve --host 0.0.0.0                  # http://<ip-du-pc>:8000
```

3. Lancez l'application mobile en lui indiquant l'API :

```bash
flutter run --dart-define=API_URL=http://<ip-du-pc>:8000
```

## Endpoints

Toutes les routes sont préfixées par `/api` et renvoient du JSON. Les routes protégées exigent l'en-tête `Authorization: Bearer <jeton>`.

| Méthode | Route | Rôle |
|---|---|---|
| POST | `/register` | Inscription (envoie l'email de vérification) → `{token, user}` |
| POST | `/login` | Connexion → `{token, user}` ; jeton valable 24 h ; blocage 15 min après 5 échecs |
| POST | `/forgot-password`, `/reset-password` | Code à 6 chiffres envoyé par email (15 min) |
| GET / PUT / DELETE | `/user` | Profil, modification, suppression du compte et de toutes ses données |
| PUT | `/user/password` | Changement de mot de passe (révoque les autres sessions) |
| POST | `/logout`, `/email/resend`, `/device-token` | Déconnexion, renvoi de l'email de vérification, jeton FCM |
| CRUD | `/transactions`, `/categories`, `/budgets`, `/objectifs`, `/alertes`, `/recurrences`, `/comptes` | Données synchronisées |
| POST | `/receipts` | Photo de reçu (image ≤ 5 Mo) → `{url}` |
| POST | `/signalements` | Signalement d'un problème à l'administrateur |

Principes de la synchronisation :
- **Identifiants.** Ils sont générés par l'application (UUID), ce qui permet de saisir hors ligne. `POST` sur un identifiant existant le met à jour : l'envoi est idempotent.
- **Conflits.** `updated_at` (au milliseconde près) est celui du client. La version la plus récente gagne.
- **Isolation des données.** Chaque utilisateur n'accède qu'à ses données (Policies) ; les catégories système sont en lecture seule.

## Sécurité

- **Mots de passe.** Hachés en bcrypt (cast `hashed`) ; au moins 8 caractères, avec une majuscule et un chiffre.
- **Jetons.** Laravel Sanctum délivre des jetons qui expirent au bout de 24 h ; ils sont purgés chaque jour et révoqués à la réinitialisation du mot de passe.
- **Validation et accès.** Les entrées sont validées par des `FormRequest`, l'accès est contrôlé par des Policies, et Eloquent utilise des requêtes paramétrées, ce qui protège de l'injection SQL.
- **Limitation de débit.** Elle s'applique à la connexion, à l'inscription, au mot de passe oublié et à la connexion admin.
- **Email.** Le lien de vérification est signé et expire après 60 minutes.

## Tâches planifiées

Une seule entrée cron suffit :

```
* * * * * cd /var/www/planify-api && php artisan schedule:run >> /dev/null 2>&1
```

| Commande | Fréquence | Rôle |
|---|---|---|
| `planify:rapports-hebdomadaires` | lundi 8 h | Bilan de la semaine par notification push |
| `planify:relancer-inactifs` | chaque jour 19 h | Rappel de saisie après 3 jours sans transaction |
| `planify:nettoyer` | chaque jour 3 h | Codes expirés, anciennes alertes lues |
| `sanctum:prune-expired` | chaque jour | Jetons expirés |

## Notifications push (FCM)

1. Dans la console Firebase, créez un projet et ajoutez une application Android `com.planify.app`.
2. Dans *Paramètres du projet > Comptes de service*, générez une clé privée (JSON), puis dans `.env` :
   `FCM_PROJECT_ID=<id du projet>` et `FCM_CREDENTIALS=<chemin du JSON>`.
3. Compilez l'application avec les identifiants Firebase :
   `--dart-define=FIREBASE_API_KEY=… --dart-define=FIREBASE_APP_ID=… --dart-define=FIREBASE_SENDER_ID=… --dart-define=FIREBASE_PROJECT_ID=…`

## Interface d'administration

Elle est accessible sur `/admin`, ou sur le sous-domaine défini par `ADMIN_DOMAIN`. Réservée aux comptes `is_admin`, elle propose :
- des statistiques globales anonymisées ;
- la gestion des catégories système ;
- le traitement des signalements.

## Déploiement (VPS Ubuntu 22.04)

```bash
sudo apt install nginx mysql-server php8.2-fpm php8.2-{mysql,mbstring,xml,curl,intl,zip,sqlite3} composer certbot python3-certbot-nginx
sudo ufw allow OpenSSH && sudo ufw allow 'Nginx Full' && sudo ufw enable
# code dans /var/www/planify-api, puis :
composer install --no-dev --optimize-autoloader
php artisan migrate --seed --force && php artisan config:cache && php artisan route:cache
sudo cp backend/deploiement/nginx-planify.conf /etc/nginx/sites-available/planify
sudo ln -s /etc/nginx/sites-available/planify /etc/nginx/sites-enabled/
sudo certbot --nginx -d api.planify.tg -d admin.planify.tg   # certificat SSL Let's Encrypt
```

Sauvegarde quotidienne de la base (cron) :

```
0 2 * * * mysqldump planify | gzip > /var/backups/planify-$(date +\%F).sql.gz
```
