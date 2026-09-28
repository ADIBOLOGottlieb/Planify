<?php

use App\Http\Controllers\Admin\CategorieController;
use App\Http\Controllers\Admin\ConnexionController;
use App\Http\Controllers\Admin\SignalementController;
use App\Http\Controllers\Admin\TableauDeBordController;
use App\Http\Controllers\VerifyEmailController;
use App\Http\Middleware\EnsureUserIsAdmin;
use Illuminate\Support\Facades\Route;

Route::redirect('/', '/admin');

// Lien de vérification envoyé par email après l'inscription (lien signé).
Route::get('/email/verify/{id}/{hash}', VerifyEmailController::class)
    ->middleware(['signed', 'throttle:6,1'])
    ->name('verification.verify');

/*
|--------------------------------------------------------------------------
| Interface web d'administration (Laravel + Bootstrap)
|--------------------------------------------------------------------------
| En production, elle est servie sur un sous-domaine dédié (ADMIN_DOMAIN,
| ex. admin.planify.tg) protégé par HTTPS.
*/
$admin = Route::prefix('admin');
if ($domaine = config('services.admin.domain')) {
    $admin = Route::domain($domaine)->prefix('admin');
}

$admin->group(function () {
    Route::get('/connexion', [ConnexionController::class, 'formulaire'])->name('login');
    Route::post('/connexion', [ConnexionController::class, 'connecter']);

    Route::middleware(['auth', EnsureUserIsAdmin::class])->name('admin.')->group(function () {
        Route::get('/', TableauDeBordController::class)->name('tableau');
        Route::resource('categories', CategorieController::class)
            ->except('show')
            ->parameters(['categories' => 'categorie']);
        Route::get('/signalements', [SignalementController::class, 'index'])->name('signalements');
        Route::patch('/signalements/{signalement}', [SignalementController::class, 'basculer'])
            ->name('signalements.basculer');
        Route::post('/deconnexion', [ConnexionController::class, 'deconnecter'])->name('deconnexion');
    });
});
