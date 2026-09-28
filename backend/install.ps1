# Installe l'API Planify (Laravel 10) dans backend/planify-api.
# Prérequis : PHP 8.2 (extensions pdo_mysql, pdo_sqlite, openssl, mbstring,
# fileinfo, intl), Composer et MySQL 8.
#   powershell -ExecutionPolicy Bypass -File backend\install.ps1
$ErrorActionPreference = 'Stop'
$racine = $PSScriptRoot
$projet = Join-Path $racine 'planify-api'

if (-not (Test-Path $projet)) {
    composer create-project laravel/laravel:^10.0 $projet --no-interaction
}

Write-Host 'Copie des fichiers Planify...'
Copy-Item -Path (Join-Path $racine 'overlay\*') -Destination $projet -Recurse -Force
Copy-Item -Path (Join-Path $racine 'overlay\.env.example') -Destination $projet -Force

Push-Location $projet
try {
    # Sanctum >= 3.3 : expiration des jetons (24 h)
    composer require laravel/sanctum:^3.3 --no-interaction
    if (-not (Test-Path '.env')) {
        Copy-Item '.env.example' '.env'
        php artisan key:generate
    }
    php artisan storage:link
    Write-Host ''
    Write-Host 'Renseignez la base MySQL dans .env puis lancez :'
    Write-Host '  php artisan migrate --seed'
    Write-Host '  php artisan planify:creer-admin admin@planify.tg'
    Write-Host '  php artisan test'
    Write-Host '  php artisan serve'
}
finally {
    Pop-Location
}
