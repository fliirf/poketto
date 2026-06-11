<?php

namespace App\Http\Controllers;

use App\Models\Category;
use App\Models\Transaction;
use App\Services\PokettoApiClient;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Barryvdh\DomPDF\Facade\Pdf;
use Throwable;

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
        $validated = $request->validate($this->transactionRules(), $this->transactionMessages());

        try {
            app(PokettoApiClient::class)->post('/transactions', [
                'type' => $validated['type'],
                'category_id' => $validated['category_id'],
                'amount' => $validated['amount'],
                'transaction_date' => $validated['transaction_date'],
                'description' => $validated['description'] ?? null,
            ]);
        } catch (Throwable $exception) {
            report($exception);

            return back()
                ->withInput()
                ->with('error', 'Gagal menyimpan transaksi. Periksa kembali data yang diisi.');
        }

        $message = $validated['type'] === 'income'
            ? 'Berhasil tambah pemasukan.'
            : 'Berhasil tambah pengeluaran.';

        return redirect()->route('dashboard')->with('success', $message);
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

        try {
            app(PokettoApiClient::class)->delete('/transactions/'.$transaction->id);
        } catch (Throwable $exception) {
            report($exception);

            return back()->with('error', 'Transaksi gagal dihapus. Coba lagi nanti.');
        }

        return redirect()->route('dashboard')->with('success', 'Transaksi berhasil dihapus.');
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

        $validated = $request->validate($this->transactionRules(), $this->transactionMessages());

        try {
            app(PokettoApiClient::class)->put('/transactions/'.$transaction->id, [
                'type' => $validated['type'],
                'category_id' => $validated['category_id'],
                'amount' => $validated['amount'],
                'transaction_date' => $validated['transaction_date'],
                'description' => $validated['description'] ?? null,
            ]);
        } catch (Throwable $exception) {
            report($exception);

            return back()
                ->withInput()
                ->with('error', 'Gagal menyimpan transaksi. Periksa kembali data yang diisi.');
        }

        return redirect()->route('dashboard')->with('success', 'Transaksi berhasil diperbarui.');
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

    $incomeTransactions = $transactions->filter(fn (Transaction $transaction) => ($transaction->type ?: $transaction->category?->type) === 'income');
    $expenseTransactions = $transactions->filter(fn (Transaction $transaction) => ($transaction->type ?: $transaction->category?->type) === 'expense');
    $income = $incomeTransactions->sum('amount');
    $expense = $expenseTransactions->sum('amount');
    $monthName = date('F', mktime(0, 0, 0, $month, 1));
    $currency = 'IDR';
    $categoryBreakdown = $expenseTransactions
        ->groupBy(fn (Transaction $transaction) => $transaction->category?->name ?? 'Tanpa kategori')
        ->map(fn ($items, string $category) => [
            'category' => $category,
            'total' => (float) $items->sum('amount'),
        ])
        ->sortByDesc('total')
        ->values();
    $dailyTrend = $expenseTransactions
        ->groupBy(fn (Transaction $transaction) => Carbon::parse($transaction->transaction_date ?? $transaction->date ?? now())->format('Y-m-d'))
        ->map(fn ($items, string $date) => [
            'date' => $date,
            'label' => Carbon::parse($date)->format('d M'),
            'total' => (float) $items->sum('amount'),
        ])
        ->sortBy('date')
        ->values();

    $pdf = Pdf::loadView('transactions.pdf', [
        'transactions' => $transactions,
        'monthName' => $monthName,
        'year' => $year,
        'income' => $income,
        'expense' => $expense,
        'currency' => $currency,
        'categoryBreakdown' => $categoryBreakdown,
        'dailyTrend' => $dailyTrend,
        'logoPath' => public_path('MASCOT.jpg'),
    ]);
    
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

private function transactionRules(): array
{
    return [
        'category_id' => 'required|exists:categories,id',
        'amount' => 'required|numeric|min:1',
        'type' => 'required|in:income,expense',
        'transaction_date' => 'required|date',
        'description' => 'nullable|string|max:255',
    ];
}

private function transactionMessages(): array
{
    return [
        'amount.required' => 'Nominal wajib diisi.',
        'amount.numeric' => 'Nominal harus berupa angka.',
        'amount.min' => 'Nominal harus lebih dari 0.',
        'category_id.required' => 'Kategori wajib dipilih.',
        'category_id.exists' => 'Kategori yang dipilih tidak valid.',
        'transaction_date.required' => 'Tanggal transaksi wajib diisi.',
        'transaction_date.date' => 'Tanggal transaksi tidak valid.',
        'type.required' => 'Tipe transaksi wajib dipilih.',
        'type.in' => 'Tipe transaksi tidak valid.',
        'description.max' => 'Catatan maksimal 255 karakter.',
    ];
}
}
