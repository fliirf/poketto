<?php

namespace App\Services;

use App\Models\BudgetAlert;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class BudgetAlertService
{
    public function forUser(User $user): Collection
    {
        return $this->syncForUser($user);
    }

    public function syncForUser(User $user): Collection
    {
        $settings = $this->settingsFor($user);

        if (! $settings->notification_enabled) {
            BudgetAlert::query()->where('user_id', $user->id)->delete();

            return collect();
        }

        $today = Carbon::today();
        $month = Carbon::now()->format('Y-m');
        $monthStart = Carbon::now()->startOfMonth();
        $monthEnd = Carbon::now()->endOfMonth();
        $warningPercent = max(1, min(100, (float) ($settings->budget_warning_threshold ?? 100)));
        $warningRatio = $warningPercent / 100;
        $activeAlerts = collect();

        $dailyBudget = (float) $settings->daily_budget;
        $todayExpense = $this->expenseSum($user->id, $today->copy()->startOfDay(), $today->copy()->endOfDay());
        if ($dailyBudget > 0 && $todayExpense >= ($dailyBudget * $warningRatio)) {
            $activeAlerts->push($this->definition(
                user: $user,
                key: 'daily_budget:'.$today->toDateString(),
                type: 'daily_budget',
                title: $todayExpense >= $dailyBudget ? 'Daily budget habis' : 'Daily budget mendekati batas',
                message: $todayExpense >= $dailyBudget
                    ? 'Daily budget kamu sudah mencapai limit.'
                    : "Daily budget kamu sudah mencapai {$warningPercent}% dari limit.",
                threshold: $dailyBudget,
                current: $todayExpense,
                periodDate: $today,
            ));
        }

        $monthlyBudget = (float) $settings->monthly_budget;
        $monthExpense = $this->expenseSum($user->id, $monthStart, $monthEnd);
        if ($monthlyBudget > 0 && $monthExpense >= ($monthlyBudget * $warningRatio)) {
            $activeAlerts->push($this->definition(
                user: $user,
                key: 'monthly_budget:'.$month,
                type: 'monthly_budget',
                title: $monthExpense >= $monthlyBudget ? 'Monthly budget habis' : 'Monthly budget mendekati batas',
                message: $monthExpense >= $monthlyBudget
                    ? 'Monthly budget kamu sudah mencapai limit.'
                    : "Monthly budget kamu sudah mencapai {$warningPercent}% dari limit.",
                threshold: $monthlyBudget,
                current: $monthExpense,
                periodMonth: $month,
            ));
        }

        Category::query()
            ->where('user_id', $user->id)
            ->where('type', 'expense')
            ->where('monthly_budget', '>', 0)
            ->get()
            ->each(function (Category $category) use ($activeAlerts, $user, $monthStart, $monthEnd, $month, $warningRatio, $warningPercent): void {
                $budget = (float) $category->monthly_budget;
                $spent = $this->expenseSum($user->id, $monthStart, $monthEnd, $category->id);

                if ($spent < ($budget * $warningRatio)) {
                    return;
                }

                $activeAlerts->push($this->definition(
                    user: $user,
                    key: "category_budget:{$category->id}:{$month}",
                    type: 'category_budget',
                    title: $spent >= $budget ? 'Budget kategori habis' : 'Budget kategori mendekati batas',
                    message: $spent >= $budget
                        ? "Budget kategori {$category->name} sudah mencapai limit."
                        : "Budget kategori {$category->name} sudah mencapai {$warningPercent}% dari limit.",
                    threshold: $budget,
                    current: $spent,
                    categoryId: $category->id,
                    periodMonth: $month,
                ));
            });

        $activeKeys = $activeAlerts->pluck('alert_key')->all();
        BudgetAlert::query()
            ->where('user_id', $user->id)
            ->when($activeKeys !== [], fn ($query) => $query->whereNotIn('alert_key', $activeKeys))
            ->delete();

        $activeAlerts->each(function (array $alert): void {
            BudgetAlert::query()->updateOrCreate(
                ['user_id' => $alert['user_id'], 'alert_key' => $alert['alert_key']],
                collect($alert)->except(['user_id', 'alert_key'])->all(),
            );
        });

        return BudgetAlert::query()
            ->with('category')
            ->where('user_id', $user->id)
            ->whereIn('alert_key', $activeKeys)
            ->latest()
            ->get()
            ->map(fn (BudgetAlert $alert) => $this->serialize($alert))
            ->values();
    }

    public function markAsRead(User $user, BudgetAlert $alert): BudgetAlert
    {
        abort_if($alert->user_id !== $user->id, 404);

        $alert->forceFill(['is_read' => true])->save();

        return $alert->fresh();
    }

    private function definition(
        User $user,
        string $key,
        string $type,
        string $title,
        string $message,
        float $threshold,
        float $current,
        ?int $categoryId = null,
        ?Carbon $periodDate = null,
        ?string $periodMonth = null,
    ): array {
        return [
            'user_id' => $user->id,
            'category_id' => $categoryId,
            'alert_key' => $key,
            'alert_type' => $type,
            'title' => $title,
            'message' => $message,
            'threshold_value' => $threshold,
            'current_value' => $current,
            'period_date' => $periodDate?->toDateString(),
            'period_month' => $periodMonth,
        ];
    }

    private function serialize(BudgetAlert $alert): array
    {
        return [
            'id' => $alert->id,
            'user_id' => $alert->user_id,
            'category_id' => $alert->category_id,
            'type' => $alert->alert_type,
            'alert_type' => $alert->alert_type,
            'title' => $alert->title,
            'message' => $alert->message,
            'threshold_value' => (float) $alert->threshold_value,
            'current_value' => (float) $alert->current_value,
            'period_date' => $alert->period_date?->toDateString(),
            'period_month' => $alert->period_month,
            'is_read' => (bool) $alert->is_read,
            'created_at' => optional($alert->created_at)->toISOString(),
            'updated_at' => optional($alert->updated_at)->toISOString(),
        ];
    }

    private function settingsFor(User $user)
    {
        return $user->userSetting()->firstOrCreate(
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
    }

    private function expenseSum(int $userId, Carbon $start, Carbon $end, ?int $categoryId = null): float
    {
        return (float) Transaction::query()
            ->where('user_id', $userId)
            ->where('type', 'expense')
            ->when($categoryId, fn ($query) => $query->where('category_id', $categoryId))
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
