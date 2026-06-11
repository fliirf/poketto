<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\TransactionController;
use App\Http\Controllers\UserSettingsController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Next.js in /.web is now the user-facing web UI. These GET routes keep old
| Laravel web URLs discoverable by redirecting them to the matching Next.js
| pages. Legacy form actions and PDF export stay available for fallback use.
|
*/

if (! function_exists('next_web_url')) {
    function next_web_url(string $path = ''): string
    {
        $baseUrl = rtrim((string) config('app.frontend_url'), '/');
        $path = '/'.ltrim($path, '/');

        return $baseUrl.($path === '/' ? '' : $path);
    }
}

Route::get('/', fn () => redirect()->away(next_web_url('/')));
Route::get('/login', fn () => redirect()->away(next_web_url('/login')))->name('login');
Route::get('/register', fn () => redirect()->away(next_web_url('/register')))->name('register');
Route::get('/dashboard', fn () => redirect()->away(next_web_url('/dashboard')))->name('dashboard');
Route::get('/transactions', fn () => redirect()->away(next_web_url('/transactions')))->name('transactions.index');
Route::get('/transactions/create', fn () => redirect()->away(next_web_url('/transactions/new')))->name('transactions.create');
Route::get('/transactions/{transaction}/edit', fn ($transaction) => redirect()->away(next_web_url("/transactions/{$transaction}/edit")))->name('transactions.edit');
Route::get('/categories', fn () => redirect()->away(next_web_url('/categories')))->name('categories.index');
Route::get('/categories/{category}/edit', fn ($category) => redirect()->away(next_web_url("/categories/{$category}/edit")))->name('categories.edit');
Route::get('/settings', fn () => redirect()->away(next_web_url('/settings')))->name('settings.edit');

Route::middleware(['guest'])->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
});

Route::middleware(['auth'])->group(function () {
    Route::post('/transactions', [TransactionController::class, 'store'])->name('transactions.store');
    Route::put('/transactions/{transaction}', [TransactionController::class, 'update'])->name('transactions.update');
    Route::delete('/transactions/{transaction}', [TransactionController::class, 'destroy'])->name('transactions.destroy');

    Route::post('/categories', [CategoryController::class, 'store'])->name('categories.store');
    Route::put('/categories/{category}', [CategoryController::class, 'update'])->name('categories.update');
    Route::delete('/categories/{category}', [CategoryController::class, 'destroy'])->name('categories.destroy');

    Route::put('/settings', [UserSettingsController::class, 'update'])->name('settings.update');
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

    Route::get('/transactions/export-pdf', [TransactionController::class, 'exportPdf'])->name('transactions.export_pdf');
});
