<?php

namespace App\Http\Controllers\Api;

use App\Models\Category;
use App\Models\Transaction;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class TransactionController extends ApiController
{
    public function index(Request $request)
    {
        $filters = $request->validate([
            'start_date' => ['nullable', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'month' => ['nullable', 'date_format:Y-m'],
            'type' => ['nullable', Rule::in(['income', 'expense'])],
            'category_id' => ['nullable', 'integer', 'exists:categories,id'],
        ]);

        $transactions = $this->applyFilters(
            Transaction::with('category')->where('user_id', $request->user()->id),
            $filters,
            $request->user()->id,
        )
            ->latest('transaction_date')
            ->latest()
            ->get()
            ->map(fn (Transaction $transaction) => $this->serializeTransaction($transaction));

        return $this->success(['transactions' => $transactions]);
    }

    public function store(Request $request)
    {
        $validated = $this->validateTransaction($request);
        $category = $this->resolveCategory($request, $validated);

        $transaction = Transaction::create([
            'user_id' => $request->user()->id,
            'category_id' => $category?->id,
            'type' => $validated['type'],
            'amount' => $validated['amount'],
            'description' => $validated['description'] ?? null,
            'date' => substr($validated['transaction_date'], 0, 10),
            'transaction_date' => $validated['transaction_date'],
            'location_lat' => $validated['location_lat'] ?? $request->input('latitude') ?? $request->input('lat'),
            'location_lng' => $validated['location_lng'] ?? $request->input('longitude') ?? $request->input('lng'),
            'location_name' => $validated['location_name'] ?? $request->input('address'),
        ]);

        $typeMessage = $validated['type'] === 'income'
            ? 'Berhasil tambah pemasukan.'
            : 'Berhasil tambah pengeluaran.';

        return $this->success([
            'transaction' => $this->serializeTransaction($transaction->load('category')),
        ], $typeMessage, 201);
    }

    public function show(Request $request, Transaction $transaction)
    {
        $this->authorizeTransaction($request, $transaction);

        return $this->success([
            'transaction' => $this->serializeTransaction($transaction->load('category')),
        ]);
    }

    public function update(Request $request, Transaction $transaction)
    {
        $this->authorizeTransaction($request, $transaction);
        $validated = $this->validateTransaction($request, true);
        $category = $this->resolveCategory($request, $validated, required: false);

        $payload = $validated;
        if ($category) {
            $payload['category_id'] = $category->id;
        }
        if (isset($validated['transaction_date'])) {
            $payload['date'] = substr($validated['transaction_date'], 0, 10);
        }
        $payload['location_lat'] = $request->input('location_lat', $request->input('latitude', $request->input('lat', $transaction->location_lat)));
        $payload['location_lng'] = $request->input('location_lng', $request->input('longitude', $request->input('lng', $transaction->location_lng)));
        $payload['location_name'] = $request->input('location_name', $request->input('address', $transaction->location_name));

        $transaction->update($payload);

        return $this->success([
            'transaction' => $this->serializeTransaction($transaction->fresh()->load('category')),
        ], 'Transaksi berhasil diperbarui.');
    }

    public function destroy(Request $request, Transaction $transaction)
    {
        $this->authorizeTransaction($request, $transaction);
        $transaction->delete();

        return $this->success(null, 'Transaksi berhasil dihapus.');
    }

    public function exportPdf(Request $request)
    {
        $filters = $request->validate([
            'start_date' => ['nullable', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'month' => ['nullable', 'date_format:Y-m'],
            'type' => ['nullable', Rule::in(['income', 'expense'])],
            'category_id' => ['nullable', 'integer', 'exists:categories,id'],
        ]);

        $transactions = $this->applyFilters(
            Transaction::with('category')->where('user_id', $request->user()->id),
            $filters,
            $request->user()->id,
        )
            ->orderBy('transaction_date')
            ->orderBy('date')
            ->get();

        $income = $transactions->where('type', 'income')->sum('amount');
        $expense = $transactions->where('type', 'expense')->sum('amount');
        $period = $this->pdfPeriod($filters);
        $settings = $request->user()->userSetting;
        $currency = $settings?->currency ?? 'IDR';
        $categoryBreakdown = $transactions
            ->filter(fn (Transaction $transaction) => ($transaction->type ?: $transaction->category?->type) === 'expense')
            ->groupBy(fn (Transaction $transaction) => $transaction->category?->name ?? 'Tanpa kategori')
            ->map(fn ($items, string $category) => [
                'category' => $category,
                'total' => (float) $items->sum('amount'),
            ])
            ->sortByDesc('total')
            ->values();

        $pdf = Pdf::loadView('transactions.pdf', [
            'transactions' => $transactions,
            'monthName' => $period['label'],
            'year' => $period['year'],
            'income' => $income,
            'expense' => $expense,
            'currency' => $currency,
            'categoryBreakdown' => $categoryBreakdown,
        ]);

        return $pdf->download($period['filename']);
    }

    private function validateTransaction(Request $request, bool $partial = false): array
    {
        $required = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'type' => [$required, Rule::in(['income', 'expense'])],
            'category_id' => [$required, 'integer', 'exists:categories,id'],
            'amount' => [$required, 'numeric', 'min:0.01'],
            'description' => ['nullable', 'string', 'max:255'],
            'transaction_date' => [$required, 'date'],
            'location_lat' => ['nullable', 'numeric', 'between:-90,90'],
            'location_lng' => ['nullable', 'numeric', 'between:-180,180'],
            'location_name' => ['nullable', 'string', 'max:255'],
        ], [
            'type.required' => 'Tipe transaksi wajib dipilih.',
            'type.in' => 'Tipe transaksi tidak valid.',
            'category_id.required' => 'Kategori wajib dipilih.',
            'category_id.exists' => 'Kategori yang dipilih tidak valid.',
            'amount.required' => 'Nominal wajib diisi.',
            'amount.numeric' => 'Nominal harus berupa angka.',
            'amount.min' => 'Nominal harus lebih dari 0.',
            'transaction_date.required' => 'Tanggal transaksi wajib diisi.',
            'transaction_date.date' => 'Tanggal transaksi tidak valid.',
            'description.max' => 'Catatan maksimal 255 karakter.',
            'location_lat.numeric' => 'Latitude lokasi tidak valid.',
            'location_lat.between' => 'Latitude lokasi tidak valid.',
            'location_lng.numeric' => 'Longitude lokasi tidak valid.',
            'location_lng.between' => 'Longitude lokasi tidak valid.',
            'location_name.max' => 'Nama lokasi maksimal 255 karakter.',
        ]);
    }

    private function applyFilters($query, array $filters, int $userId)
    {
        if (! empty($filters['month'])) {
            $query->where(function ($dateQuery) use ($filters) {
                $dateQuery->where('transaction_date', 'like', $filters['month'].'%')
                    ->orWhere(function ($fallback) use ($filters) {
                        $fallback->whereNull('transaction_date')->where('date', 'like', $filters['month'].'%');
                    });
            });
        }

        if (! empty($filters['start_date'])) {
            $query->where(function ($dateQuery) use ($filters) {
                $dateQuery->whereDate('transaction_date', '>=', $filters['start_date'])
                    ->orWhere(function ($fallback) use ($filters) {
                        $fallback->whereNull('transaction_date')->whereDate('date', '>=', $filters['start_date']);
                    });
            });
        }

        if (! empty($filters['end_date'])) {
            $query->where(function ($dateQuery) use ($filters) {
                $dateQuery->whereDate('transaction_date', '<=', $filters['end_date'])
                    ->orWhere(function ($fallback) use ($filters) {
                        $fallback->whereNull('transaction_date')->whereDate('date', '<=', $filters['end_date']);
                    });
            });
        }

        if (! empty($filters['type'])) {
            $query->where('type', $filters['type']);
        }

        if (! empty($filters['category_id'])) {
            $category = Category::where('user_id', $userId)->find($filters['category_id']);
            abort_if(! $category, 422, 'Kategori tidak valid.');
            $query->where('category_id', $filters['category_id']);
        }

        return $query;
    }

    private function resolveCategory(Request $request, array $validated, bool $required = true): ?Category
    {
        if ($required && empty($validated['category_id'])) {
            abort(422, 'category_id wajib diisi.');
        }

        if (empty($validated['category_id'])) {
            return null;
        }

        $category = Category::where('user_id', $request->user()->id)->find($validated['category_id']);
        abort_if(! $category && $required, 422, 'Kategori tidak valid.');

        return $category;
    }

    private function authorizeTransaction(Request $request, Transaction $transaction): void
    {
        abort_if($transaction->user_id !== $request->user()->id, 404);
    }

    private function pdfPeriod(array $filters): array
    {
        if (! empty($filters['month'])) {
            $start = Carbon::createFromFormat('Y-m', $filters['month']);

            return [
                'label' => $start->translatedFormat('F'),
                'year' => $start->format('Y'),
                'filename' => 'Laporan_Poketto_'.$start->format('Y_m').'.pdf',
            ];
        }

        if (! empty($filters['start_date']) || ! empty($filters['end_date'])) {
            $start = ! empty($filters['start_date']) ? Carbon::parse($filters['start_date']) : null;
            $end = ! empty($filters['end_date']) ? Carbon::parse($filters['end_date']) : null;
            $label = trim(($start?->format('d M Y') ?? 'Awal').' - '.($end?->format('d M Y') ?? 'Sekarang'));

            return [
                'label' => $label,
                'year' => '',
                'filename' => 'Laporan_Poketto_Filtered.pdf',
            ];
        }

        $now = now();

        return [
            'label' => $now->translatedFormat('F'),
            'year' => $now->format('Y'),
            'filename' => 'Laporan_Poketto_'.$now->format('Y_m').'.pdf',
        ];
    }

    private function serializeTransaction(Transaction $transaction): array
    {
        return [
            'id' => $transaction->id,
            'user_id' => $transaction->user_id,
            'category_id' => $transaction->category_id,
            'category_name' => $transaction->category?->name,
            'type' => $transaction->type ?: $transaction->category?->type,
            'amount' => (float) $transaction->amount,
            'description' => $transaction->description,
            'transaction_date' => optional($transaction->transaction_date)->toISOString() ?? optional($transaction->date)->toDateString(),
            'date' => optional($transaction->transaction_date)->toDateString() ?? optional($transaction->date)->toDateString(),
            'location_lat' => $transaction->location_lat === null ? null : (float) $transaction->location_lat,
            'location_lng' => $transaction->location_lng === null ? null : (float) $transaction->location_lng,
            'location_name' => $transaction->location_name,
            'category' => $transaction->category,
            'created_at' => optional($transaction->created_at)->toISOString(),
            'updated_at' => optional($transaction->updated_at)->toISOString(),
        ];
    }
}
