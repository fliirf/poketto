<?php

namespace App\Http\Controllers\Api;

use App\Models\Category;
use App\Models\Transaction;
use App\Services\BudgetAlertService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class DashboardController extends ApiController
{
    public function summary(Request $request, BudgetAlertService $budgetAlertService)
    {
        $user = $request->user();
        $filters = $request->validate([
            'start_date' => ['nullable', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'month' => ['nullable', 'date_format:Y-m'],
            'type' => ['nullable', Rule::in(['income', 'expense'])],
            'category_id' => ['nullable', 'integer', 'exists:categories,id'],
        ]);
        $settings = $user->userSetting()->firstOrCreate(
            ['user_id' => $user->id],
            [
                'daily_budget' => 100000,
                'monthly_budget' => 2500000,
                'currency' => 'IDR',
                'budget_warning_threshold' => 80,
                'notification_enabled' => true,
                'location_enabled' => true,
            ],
        );

        $baseQuery = $this->applyFilters(Transaction::query()->where('user_id', $user->id), $filters, $user->id);
        $totalIncome = (clone $baseQuery)->where('type', 'income')->sum('amount');
        $totalExpense = (clone $baseQuery)->where('type', 'expense')->sum('amount');
        $period = $this->resolvePeriod($filters);
        $budgetPeriod = $this->resolveBudgetPeriod($filters);
        $expenseTrend = $this->expenseTrend($user->id, $period['start'], $period['end'], $filters);
        $categoryBreakdown = $this->categoryBreakdown($user->id, $period['start'], $period['end'], $filters);
        $categoryBudgets = $this->categoryBudgets($user->id, $budgetPeriod['start'], $budgetPeriod['end'], $filters);
        $today = Carbon::now('Asia/Jakarta')->startOfDay();
        $todayExpense = $this->expenseForRange($user->id, $today, $today->copy()->endOfDay());
        $monthExpense = $this->expenseForRange($user->id, $today->copy()->startOfMonth(), $today->copy()->endOfMonth());
        $dailyBudget = (float) $settings->daily_budget;
        $monthlyBudget = (float) $settings->monthly_budget;
        $recent = $this->applyFilters(
            Transaction::with('category')->where('user_id', $user->id),
            $filters,
            $user->id,
        )
            ->latest('transaction_date')
            ->latest()
            ->limit(5)
            ->get()
            ->map(fn (Transaction $transaction) => [
                'id' => $transaction->id,
                'user_id' => $transaction->user_id,
                'category_id' => $transaction->category_id,
                'category_name' => $transaction->category?->name,
                'type' => $transaction->type ?: $transaction->category?->type,
                'amount' => (float) $transaction->amount,
                'description' => $transaction->description,
                'transaction_date' => optional($transaction->transaction_date)->toISOString() ?? optional($transaction->date)->toDateString(),
                'date' => optional($transaction->date)->toDateString() ?? optional($transaction->transaction_date)->toDateString(),
                'location_lat' => $transaction->location_lat === null ? null : (float) $transaction->location_lat,
                'location_lng' => $transaction->location_lng === null ? null : (float) $transaction->location_lng,
                'location_name' => $transaction->location_name,
                'category' => $transaction->category,
            ]);

        return $this->success([
            'total_income' => (float) $totalIncome,
            'total_expense' => (float) $totalExpense,
            'balance' => (float) $totalIncome - (float) $totalExpense,
            'daily_budget' => $dailyBudget,
            'daily_expense' => (float) $todayExpense,
            'daily_budget_remaining' => max(0, $dailyBudget - (float) $todayExpense),
            'daily_budget_percentage' => $dailyBudget > 0 ? min(100, ((float) $todayExpense / $dailyBudget) * 100) : 0,
            'monthly_budget' => $monthlyBudget,
            'monthly_expense' => (float) $monthExpense,
            'monthly_budget_remaining' => max(0, $monthlyBudget - (float) $monthExpense),
            'monthly_budget_percentage' => $monthlyBudget > 0 ? min(100, ((float) $monthExpense / $monthlyBudget) * 100) : 0,
            'currency' => $settings->currency ?? 'IDR',
            'period' => [
                'start_date' => $period['start']->toDateString(),
                'end_date' => $period['end']->toDateString(),
                'label' => $this->periodLabel($period['start'], $period['end'], $filters),
            ],
            'budget_warning_threshold' => (float) ($settings->budget_warning_threshold ?? 80),
            'expense_trend' => $expenseTrend,
            'category_breakdown' => $categoryBreakdown,
            'category_budgets' => $categoryBudgets,
            'recent_transactions' => $recent,
            'alerts' => $budgetAlertService->forUser($user),
        ]);
    }

    private function expenseForRange(int $userId, Carbon $start, Carbon $end): float
    {
        return (float) Transaction::query()
            ->where('user_id', $userId)
            ->where('type', 'expense')
            ->where(function ($query) use ($start, $end) {
                $query->where(function ($dated) use ($start, $end) {
                    $dated->whereNotNull('date')
                        ->whereDate('date', '>=', $start->toDateString())
                        ->whereDate('date', '<=', $end->toDateString());
                })
                    ->orWhere(function ($fallback) use ($start, $end) {
                        $fallback->whereNull('date')
                            ->whereDate('transaction_date', '>=', $start->toDateString())
                            ->whereDate('transaction_date', '<=', $end->toDateString());
                    });
            })
            ->sum('amount');
    }

    private function categoryBudgets(int $userId, Carbon $start, Carbon $end, array $filters): array
    {
        if (($filters['type'] ?? null) === 'income') {
            return [];
        }

        return Category::query()
            ->where('user_id', $userId)
            ->where('type', 'expense')
            ->when(! empty($filters['category_id']), fn ($query) => $query->where('id', $filters['category_id']))
            ->get()
            ->map(function (Category $category) use ($userId, $start, $end) {
                $budget = (float) ($category->monthly_budget ?? 0);
                $spent = Transaction::query()
                    ->where('user_id', $userId)
                    ->where('type', 'expense')
                    ->where('category_id', $category->id)
                    ->where(function ($query) use ($start, $end) {
                        $query->whereBetween('date', [$start->toDateString(), $end->toDateString()])
                            ->orWhere(function ($fallback) use ($start, $end) {
                                $fallback->whereNull('date')
                                    ->whereBetween('transaction_date', [$start, $end]);
                            });
                    })
                    ->sum('amount');
                $percentage = $budget > 0 ? min(100, ((float) $spent / $budget) * 100) : 0;

                return [
                    'category_id' => $category->id,
                    'category_name' => $category->name,
                    'monthly_budget' => $budget,
                    'spent' => (float) $spent,
                    'percentage' => (float) $percentage,
                ];
            })
            ->values()
            ->all();
    }

    private function expenseTrend(int $userId, Carbon $start, Carbon $end, array $filters): array
    {
        $days = (int) max(0, $start->diffInDays($end));

        return collect(range(0, $days))->map(function (int $offset) use ($userId, $start, $filters) {
            $date = $start->copy()->addDays($offset);
            if (($filters['type'] ?? null) === 'income') {
                return [
                    'date' => $date->toDateString(),
                    'label' => $date->format('D'),
                    'total' => 0,
                ];
            }

            $total = Transaction::query()
                ->where('user_id', $userId)
                ->where('type', 'expense')
                ->when(! empty($filters['category_id']), fn ($query) => $query->where('category_id', $filters['category_id']))
                ->where(function ($query) use ($date) {
                    $query->whereDate('date', $date->toDateString())
                        ->orWhere(function ($fallback) use ($date) {
                            $fallback->whereNull('date')->whereDate('transaction_date', $date->toDateString());
                        });
                })
                ->sum('amount');

            return [
                'date' => $date->toDateString(),
                'label' => $date->format('D'),
                'total' => (float) $total,
            ];
        })->values()->all();
    }

    private function categoryBreakdown(int $userId, Carbon $start, Carbon $end, array $filters): array
    {
        if (($filters['type'] ?? null) === 'income') {
            return [];
        }

        return Transaction::query()
            ->with('category')
            ->where('user_id', $userId)
            ->where('type', 'expense')
            ->when(! empty($filters['category_id']), fn ($query) => $query->where('category_id', $filters['category_id']))
            ->where(function ($query) use ($start, $end) {
                $query->whereBetween('date', [$start->toDateString(), $end->toDateString()])
                    ->orWhere(function ($fallback) use ($start, $end) {
                        $fallback->whereNull('date')->whereBetween('transaction_date', [$start, $end]);
                    });
            })
            ->get()
            ->groupBy(fn (Transaction $transaction) => $transaction->category?->name ?? 'Lainnya')
            ->map(fn ($items, string $category) => [
                'category' => $category,
                'total' => (float) $items->sum('amount'),
            ])
            ->values()
            ->all();
    }

    private function applyFilters($query, array $filters, int $userId)
    {
        if (! empty($filters['month'])) {
            $query->where(function ($dateQuery) use ($filters) {
                $dateQuery->where('date', 'like', $filters['month'].'%')
                    ->orWhere(function ($fallback) use ($filters) {
                        $fallback->whereNull('date')->where('transaction_date', 'like', $filters['month'].'%');
                    });
            });
        }

        if (! empty($filters['start_date'])) {
            $query->where(function ($dateQuery) use ($filters) {
                $dateQuery->whereDate('date', '>=', $filters['start_date'])
                    ->orWhere(function ($fallback) use ($filters) {
                        $fallback->whereNull('date')->whereDate('transaction_date', '>=', $filters['start_date']);
                    });
            });
        }

        if (! empty($filters['end_date'])) {
            $query->where(function ($dateQuery) use ($filters) {
                $dateQuery->whereDate('date', '<=', $filters['end_date'])
                    ->orWhere(function ($fallback) use ($filters) {
                        $fallback->whereNull('date')->whereDate('transaction_date', '<=', $filters['end_date']);
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

    private function resolvePeriod(array $filters): array
    {
        if (! empty($filters['start_date']) || ! empty($filters['end_date'])) {
            $start = ! empty($filters['start_date'])
                ? Carbon::parse($filters['start_date'])->startOfDay()
                : Carbon::parse($filters['end_date'])->subDays(6)->startOfDay();
            $end = ! empty($filters['end_date'])
                ? Carbon::parse($filters['end_date'])->endOfDay()
                : $start->copy()->addDays(6)->endOfDay();

            return ['start' => $start, 'end' => $end];
        }

        if (! empty($filters['month'])) {
            $start = Carbon::createFromFormat('Y-m', $filters['month'])->startOfMonth();
            return ['start' => $start, 'end' => $start->copy()->endOfMonth()];
        }

        return [
            'start' => Carbon::today()->subDays(6)->startOfDay(),
            'end' => Carbon::today()->endOfDay(),
        ];
    }

    private function resolveBudgetPeriod(array $filters): array
    {
        if (! empty($filters['month'])) {
            $start = Carbon::createFromFormat('Y-m', $filters['month'])->startOfMonth();
            return ['start' => $start, 'end' => $start->copy()->endOfMonth()];
        }

        if (! empty($filters['start_date']) || ! empty($filters['end_date'])) {
            return $this->resolvePeriod($filters);
        }

        return [
            'start' => Carbon::today()->startOfMonth(),
            'end' => Carbon::today()->endOfMonth(),
        ];
    }

    private function periodLabel(Carbon $start, Carbon $end, array $filters): string
    {
        if (! empty($filters['month'])) {
            return $start->translatedFormat('F Y');
        }

        return $start->toDateString() === $end->toDateString()
            ? $start->translatedFormat('d M Y')
            : $start->translatedFormat('d M Y').' - '.$end->translatedFormat('d M Y');
    }
}
