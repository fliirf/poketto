<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BudgetAlertController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\ExchangeRateController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\UserSettingsController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->name('api.')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    Route::get('/dashboard/summary', [DashboardController::class, 'summary']);

    Route::get('/transactions/export-pdf', [TransactionController::class, 'exportPdf']);
    Route::apiResource('transactions', TransactionController::class);
    Route::apiResource('categories', CategoryController::class);

    Route::get('/user-settings', [UserSettingsController::class, 'show']);
    Route::put('/user-settings', [UserSettingsController::class, 'update']);

    Route::get('/budget-alerts', [BudgetAlertController::class, 'index']);
    Route::get('/notifications', [BudgetAlertController::class, 'index']);
    Route::patch('/notifications/{notification}/read', [BudgetAlertController::class, 'markAsRead']);
    Route::get('/exchange-rates', [ExchangeRateController::class, 'index']);
});
