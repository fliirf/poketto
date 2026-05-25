<?php

namespace App\Http\Controllers;

use App\Models\Category;
use App\Models\Transaction;
use App\Services\PokettoApiClient;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Barryvdh\DomPDF\Facade\Pdf;

class TransactionController extends Controller
{
    public function create()
    {
        $categories = collect(app(PokettoApiClient::class)->get('/categories')['categories'] ?? [])
            ->map(fn ($category) => (object) $category);
        return view('transactions.create', compact('categories'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'category_id' => 'required|exists:categories,id',
            'amount' => 'required|numeric|min:1',
            'type' => 'required|in:income,expense',
            'transaction_date' => 'required|date',
            'description' => 'nullable|string|max:255',
        ]);

        app(PokettoApiClient::class)->post('/transactions', [
            'type' => $validated['type'],
            'category_id' => $validated['category_id'],
            'amount' => $validated['amount'],
            'transaction_date' => $validated['transaction_date'],
            'description' => $validated['description'] ?? null,
        ]);

        return redirect()->route('dashboard')->with('success', 'Mantap! Transaksi kamu berhasil dicatat.');
    }

    public function index(Request $request)
    {
        $filters = $this->filterParams($request);
        $summary = app(PokettoApiClient::class)->get('/dashboard/summary', $filters);
        $totalIncome = $summary['total_income'] ?? 0;
        $totalExpense = $summary['total_expense'] ?? 0;
        $totalBalance = $summary['balance'] ?? ($totalIncome - $totalExpense);
        $monthlyExpense = $totalExpense;
        $alerts = $summary['alerts'] ?? [];
        $expenseTrend = $summary['expense_trend'] ?? [];
        $categoryBreakdown = $summary['category_breakdown'] ?? [];
        $healthStatus = 'Stabil';
        if ($totalIncome > 0 && ($totalExpense / max($totalIncome, 1)) > 0.8) {
            $healthStatus = 'Bahaya';
        } elseif ($totalIncome == 0 && $totalExpense > 0) {
            $healthStatus = 'Kritis';
        }

        $recentTransactions = collect($summary['recent_transactions'] ?? [])
            ->map(fn ($transaction) => $this->webTransaction($transaction));

        $days = collect($expenseTrend)->map(fn ($item) => $item['label'] ?? $item['date'] ?? '')->all();
        $totals = collect($expenseTrend)->map(fn ($item) => (float) ($item['total'] ?? 0))->all();

        $categories = collect(app(PokettoApiClient::class)->get('/categories')['categories'] ?? [])
            ->map(fn ($category) => (object) $category);

        return view('dashboard', compact(
            'totalBalance', 'monthlyExpense', 'healthStatus', 
            'recentTransactions', 'days', 'totals', 'alerts', 'expenseTrend', 'categoryBreakdown', 'categories', 'filters'
        ));
    }

    public function destroy(Transaction $transaction)
    {
        // Security check: Pastikan transaksi ini milik user yang login
        if ($transaction->user_id !== auth()->id()) {
            abort(403);
        }

        app(PokettoApiClient::class)->delete('/transactions/'.$transaction->id);

        return redirect()->route('dashboard')->with('success', 'Transaksi berhasil dihapus!');
    }

    public function edit(Transaction $transaction)
    {
        if ($transaction->user_id !== auth()->id()) { abort(403); }

        $categories = collect(app(PokettoApiClient::class)->get('/categories')['categories'] ?? [])
            ->map(fn ($category) => (object) $category);
        return view('transactions.edit', compact('transaction', 'categories'));
    }

    public function update(Request $request, Transaction $transaction)
    {
        if ($transaction->user_id !== auth()->id()) { abort(403); }

        $request->validate([
            'amount' => 'required|numeric',
            'category_id' => 'required|exists:categories,id',
            'type' => 'required|in:income,expense',
            'transaction_date' => 'required|date',
            'description' => 'nullable|string|max:255',
        ]);

        app(PokettoApiClient::class)->put('/transactions/'.$transaction->id, [
            'type' => $request->type,
            'category_id' => $request->category_id,
            'amount' => $request->amount,
            'transaction_date' => $request->transaction_date,
            'description' => $request->description,
        ]);

        return redirect()->route('dashboard')->with('success', 'Transaksi berhasil diperbarui!');
    }

public function report(Request $request)
{
    $filters = $this->filterParams($request);
    $transactions = collect(app(PokettoApiClient::class)->get('/transactions', $filters)['transactions'] ?? [])
        ->map(fn ($transaction) => $this->webTransaction($transaction));

    $monthlyIncome = $transactions->where('category.type', 'income')->sum('amount');
    $monthlyExpense = $transactions->where('category.type', 'expense')->sum('amount');
    $categories = collect(app(PokettoApiClient::class)->get('/categories')['categories'] ?? [])
        ->map(fn ($category) => (object) $category);

    return view('transactions.index', compact(
        'transactions', 
        'monthlyIncome', 
        'monthlyExpense',
        'categories',
        'filters'
    ));
}

public function exportPdf(Request $request)
{
    $userId = auth()->id();
    $month = $request->get('month', date('m'));
    $year = $request->get('year', date('Y'));

    $transactions = Transaction::with('category')
        ->where('user_id', $userId)
        ->whereMonth('date', $month)
        ->whereYear('date', $year)
        ->orderBy('date', 'asc')
        ->get();

    $income = $transactions->where('category.type', 'income')->sum('amount');
    $expense = $transactions->where('category.type', 'expense')->sum('amount');
    $monthName = date('F', mktime(0, 0, 0, $month, 1));

    // Menghasilkan PDF dari view khusus
    $pdf = Pdf::loadView('transactions.pdf', compact('transactions', 'monthName', 'year', 'income', 'expense'));
    
    return $pdf->download("Laporan_Poketto_{$monthName}_{$year}.pdf");
}

private function webTransaction(array $transaction): object
{
    $category = (object) ($transaction['category'] ?? [
        'name' => $transaction['category_name'] ?? 'Lainnya',
        'type' => $transaction['type'] ?? 'expense',
    ]);

    return (object) [
        'id' => $transaction['id'] ?? null,
        'category_id' => $transaction['category_id'] ?? null,
        'amount' => $transaction['amount'] ?? 0,
        'description' => $transaction['description'] ?? null,
        'date' => $transaction['date'] ?? $transaction['transaction_date'] ?? null,
        'location_lat' => $transaction['location_lat'] ?? null,
        'location_lng' => $transaction['location_lng'] ?? null,
        'location_name' => $transaction['location_name'] ?? null,
        'category' => $category,
    ];
}

private function filterParams(Request $request): array
{
    return collect($request->only([
        'start_date',
        'end_date',
        'month',
        'type',
        'category_id',
    ]))->filter(fn ($value) => $value !== null && $value !== '')->all();
}
}
