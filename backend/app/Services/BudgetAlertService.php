<?php

namespace App\Services;

use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class BudgetAlertService
{
    public function forUser(User $user): Collection
    {
        $alerts = collect();
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

        $todayExpense = Transaction::query()
            ->where('user_id', $user->id)
            ->where('type', 'expense')
            ->whereDate('transaction_date', Carbon::today())
            ->sum('amount');

        if ((float) $settings->daily_budget > 0 && $todayExpense >= (float) $settings->daily_budget) {
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
        }

        $monthStart = Carbon::now()->startOfMonth();
        $monthEnd = Carbon::now()->endOfMonth();

        Category::query()
            ->where('user_id', $user->id)
            ->where('type', 'expense')
            ->where('monthly_budget', '>', 0)
            ->get()
            ->each(function (Category $category) use ($alerts, $monthStart, $monthEnd, $user): void {
                $spent = Transaction::query()
                    ->where('user_id', $user->id)
                    ->where('category_id', $category->id)
                    ->where('type', 'expense')
                    ->whereBetween('transaction_date', [$monthStart, $monthEnd])
                    ->sum('amount');

                $threshold = (float) $category->monthly_budget * 0.8;
                if ($spent >= $threshold) {
                    $alerts->push([
                        'id' => 0,
                        'user_id' => $user->id,
                        'category_id' => $category->id,
                        'alert_type' => 'category_budget',
                        'message' => "Peringatan! Pengeluaran kategori {$category->name} telah mencapai 80% dari budget bulanan.",
                        'threshold_value' => (float) $category->monthly_budget,
                        'current_value' => (float) $spent,
                        'is_read' => false,
                        'created_at' => now()->toISOString(),
                    ]);
                }
            });

        return $alerts->merge(
            $user->budgetAlerts()
                ->with('category')
                ->latest()
                ->get()
                ->map(fn ($alert) => $alert->toArray()),
        )->values();
    }
}
