<?php

namespace App\Services;

use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class BudgetAlertService
{
    public function forUser(
        User $user,
        ?Carbon $dailyStart = null,
        ?Carbon $dailyEnd = null,
        ?Carbon $categoryStart = null,
        ?Carbon $categoryEnd = null,
        array $filters = [],
    ): Collection
    {
        $alerts = collect();
        if (($filters['type'] ?? null) === 'income') {
            return $alerts;
        }

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
        $warningPercent = max(1, min(99, (float) ($settings->budget_warning_threshold ?? 80)));
        $warningLabel = rtrim(rtrim(number_format($warningPercent, 2, '.', ''), '0'), '.');
        $warningRatio = max(1, min(99, $warningPercent)) / 100;
        $dailyStart ??= Carbon::today()->startOfDay();
        $dailyEnd ??= Carbon::today()->endOfDay();
        $categoryStart ??= Carbon::now()->startOfMonth();
        $categoryEnd ??= Carbon::now()->endOfMonth();
        $periodExpense = $this->expenseSum($user->id, $categoryStart, $categoryEnd, $filters);
        $monthlyBudget = (float) $settings->monthly_budget;
        $monthlyBudgetIsStillSafe = $monthlyBudget > 0 && $periodExpense < ($monthlyBudget * $warningRatio);

        if ($monthlyBudgetIsStillSafe) {
            return $alerts;
        }

        if ($dailyStart->toDateString() === $dailyEnd->toDateString()) {
            $todayExpense = Transaction::query()
                ->where('user_id', $user->id)
                ->where('type', 'expense')
                ->when(! empty($filters['category_id']), fn ($query) => $query->where('category_id', $filters['category_id']))
                ->where(function ($query) use ($dailyStart, $dailyEnd) {
                    $query->whereBetween('transaction_date', [$dailyStart, $dailyEnd])
                        ->orWhere(function ($fallback) use ($dailyStart, $dailyEnd) {
                            $fallback->whereNull('transaction_date')
                                ->whereBetween('date', [$dailyStart->toDateString(), $dailyEnd->toDateString()]);
                        });
                })
                ->sum('amount');

            $dailyBudget = (float) $settings->daily_budget;
            if ($dailyBudget > 0 && $todayExpense >= $dailyBudget) {
                $alerts->push([
                    'id' => 0,
                    'user_id' => $user->id,
                    'category_id' => null,
                    'alert_type' => 'daily_budget',
                    'message' => 'Jangan belanja lagi! Budget harian sudah habis.',
                    'threshold_value' => (float) $settings->daily_budget,
                    'current_value' => (float) $todayExpense,
                    'is_read' => false,
                    'created_at' => now()->toISOString(),
                ]);
            } elseif ($dailyBudget > 0 && $todayExpense >= ($dailyBudget * $warningRatio)) {
                $alerts->push([
                    'id' => 0,
                    'user_id' => $user->id,
                    'category_id' => null,
                    'alert_type' => 'daily_budget_warning',
                    'message' => "Peringatan! Pengeluaran harian sudah mencapai {$warningLabel}% dari budget.",
                    'threshold_value' => $dailyBudget,
                    'current_value' => (float) $todayExpense,
                    'is_read' => false,
                    'created_at' => now()->toISOString(),
                ]);
            }
        }

        if ($monthlyBudget > 0 && $periodExpense >= $monthlyBudget) {
            $alerts->push([
                'id' => 0,
                'user_id' => $user->id,
                'category_id' => null,
                'alert_type' => 'monthly_budget',
                'message' => 'Jangan belanja lagi! Budget bulanan sudah habis.',
                'threshold_value' => $monthlyBudget,
                'current_value' => (float) $periodExpense,
                'is_read' => false,
                'created_at' => now()->toISOString(),
            ]);
        } elseif ($monthlyBudget > 0 && $periodExpense >= ($monthlyBudget * $warningRatio)) {
            $alerts->push([
                'id' => 0,
                'user_id' => $user->id,
                'category_id' => null,
                'alert_type' => 'monthly_budget_warning',
                'message' => "Peringatan! Pengeluaran bulanan sudah mencapai {$warningLabel}% dari budget.",
                'threshold_value' => $monthlyBudget,
                'current_value' => (float) $periodExpense,
                'is_read' => false,
                'created_at' => now()->toISOString(),
            ]);
        }

        Category::query()
            ->where('user_id', $user->id)
            ->where('type', 'expense')
            ->where('monthly_budget', '>', 0)
            ->when(! empty($filters['category_id']), fn ($query) => $query->where('id', $filters['category_id']))
            ->get()
            ->each(function (Category $category) use ($alerts, $categoryStart, $categoryEnd, $user, $warningRatio, $warningLabel): void {
                $spent = Transaction::query()
                    ->where('user_id', $user->id)
                    ->where('category_id', $category->id)
                    ->where('type', 'expense')
                    ->where(function ($query) use ($categoryStart, $categoryEnd) {
                        $query->whereBetween('transaction_date', [$categoryStart, $categoryEnd])
                            ->orWhere(function ($fallback) use ($categoryStart, $categoryEnd) {
                                $fallback->whereNull('transaction_date')
                                    ->whereBetween('date', [$categoryStart->toDateString(), $categoryEnd->toDateString()]);
                            });
                    })
                    ->sum('amount');

                $threshold = (float) $category->monthly_budget * $warningRatio;
                if ($spent >= $threshold) {
                    $alerts->push([
                        'id' => 0,
                        'user_id' => $user->id,
                        'category_id' => $category->id,
                        'alert_type' => 'category_budget',
                        'message' => "Peringatan! Pengeluaran kategori {$category->name} telah mencapai {$warningLabel}% dari budget bulanan.",
                        'threshold_value' => (float) $category->monthly_budget,
                        'current_value' => (float) $spent,
                        'is_read' => false,
                        'created_at' => now()->toISOString(),
                    ]);
                }
            });

        return $alerts->values();
    }

    private function expenseSum(int $userId, Carbon $start, Carbon $end, array $filters = []): float
    {
        if (($filters['type'] ?? null) === 'income') {
            return 0;
        }

        return (float) Transaction::query()
            ->where('user_id', $userId)
            ->where('type', 'expense')
            ->when(! empty($filters['category_id']), fn ($query) => $query->where('category_id', $filters['category_id']))
            ->where(function ($query) use ($start, $end) {
                $query->whereBetween('transaction_date', [$start, $end])
                    ->orWhere(function ($fallback) use ($start, $end) {
                        $fallback->whereNull('transaction_date')
                            ->whereBetween('date', [$start->toDateString(), $end->toDateString()]);
                    });
            })
            ->sum('amount');
    }
}
