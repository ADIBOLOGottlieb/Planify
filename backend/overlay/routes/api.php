<?php

use App\Http\Controllers\Api\AlerteController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BudgetController;
use App\Http\Controllers\Api\CategorieController;
use App\Http\Controllers\Api\CompteController;
use App\Http\Controllers\Api\ObjectifController;
use App\Http\Controllers\Api\ReceiptController;
use App\Http\Controllers\Api\RecurrenceController;
use App\Http\Controllers\Api\SignalementController;
use App\Http\Controllers\Api\TransactionController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API REST de Planify (préfixe /api, JSON)
|--------------------------------------------------------------------------
| Authentification par jeton Bearer Laravel Sanctum (expiration 24 h).
*/

Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:10,60');
Route::post('/login', [AuthController::class, 'login']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:5,15');
Route::post('/reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:10,15');

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'me']);
    Route::put('/user', [AuthController::class, 'update']);
    Route::put('/user/password', [AuthController::class, 'changePassword']);
    Route::delete('/user', [AuthController::class, 'destroy']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/email/resend', [AuthController::class, 'resendVerification'])->middleware('throttle:3,10');
    Route::post('/device-token', [AuthController::class, 'deviceToken']);

    Route::apiResource('transactions', TransactionController::class)->parameters(['transactions' => 'id']);
    Route::apiResource('categories', CategorieController::class)->parameters(['categories' => 'id']);
    Route::apiResource('budgets', BudgetController::class)->parameters(['budgets' => 'id']);
    Route::apiResource('objectifs', ObjectifController::class)->parameters(['objectifs' => 'id']);
    Route::apiResource('alertes', AlerteController::class)->parameters(['alertes' => 'id']);
    Route::apiResource('recurrences', RecurrenceController::class)->parameters(['recurrences' => 'id']);
    Route::apiResource('comptes', CompteController::class)->parameters(['comptes' => 'id']);

    Route::post('/receipts', [ReceiptController::class, 'store']);
    Route::post('/signalements', [SignalementController::class, 'store'])->middleware('throttle:5,60');
});
