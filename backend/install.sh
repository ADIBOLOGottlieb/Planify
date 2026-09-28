#!/usr/bin/env bash
# Installe l'API Planify (Laravel 10) dans backend/planify-api.
# Prérequis : PHP 8.2 (pdo_mysql, pdo_sqlite, openssl, mbstring, fileinfo,
# intl), Composer et MySQL 8.
set -euo pipefail
racine="$(cd "$(dirname "$0")" && pwd)"
projet="$racine/planify-api"

[ -d "$projet" ] || composer create-project laravel/laravel:^10.0 "$projet" --no-interaction

echo "Copie des fichiers Planify..."
cp -R "$racine/overlay/." "$projet/"

cd "$projet"
composer require laravel/sanctum:^3.3 --no-interaction   # expiration des jetons (24 h)
if [ ! -f .env ]; then
  cp .env.example .env
  php artisan key:generate
fi
php artisan storage:link

cat <<'FIN'

Renseignez la base MySQL dans .env puis lancez :
  php artisan migrate --seed
  php artisan planify:creer-admin admin@planify.tg
  php artisan test
  php artisan serve
FIN
