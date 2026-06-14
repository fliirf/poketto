<?php

namespace App\Services;

use App\Models\BudgetAlert;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use App\Models\UserSetting;
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
        $activeAlerts = $this->checkBudgetNotifications($user);
        $activeKeys = $activeAlerts->pluck('alert_key')->all();

        BudgetAlert::query()
            ->where('user_id', $user->id)
            ->when(
                $activeKeys !== [],
                fn ($query) => $query->whereNotIn('alert_key', $activeKeys),
            )
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

    public function checkBudgetNotifications(User $user): Collection
    {
        $settings = $this->settingsFor($user);

        if (! $settings->notification_enabled) {
            BudgetAlert::query()->where('user_id', $user->id)->delete();

            return collect();
        }

        $now = Carbon::now('Asia/Jakarta');

        return collect()
            ->merge($this->checkDailyBudget($user, $settings, $now))
            ->merge($this->checkMonthlyBudget($user, $settings, $now))
            ->merge($this->checkCategoryBudgets($user, $settings, $now));
    }

    private function checkDailyBudget(User $user, UserSetting $settings, Carbon $now): Collection
    {
        $today = $now->copy()->startOfDay();
        $dailyBudget = (float) $settings->daily_budget;

        if ($dailyBudget <= 0) {
            return collect();
        }

        $todayExpense = $this->expenseSum($user->id, $today, $today->copy()->endOfDay());
        $thresholdPercent = $this->thresholdPercent($settings);
        $thresholdAmount = $this->thresholdAmount($dailyBudget, $thresholdPercent);

        if ($todayExpense < $thresholdAmount) {
            return collect();
        }

        $overLimit = $todayExpense >= $dailyBudget;

        return collect([
            $this->definition(
                user: $user,
                key: 'daily_budget:'.$today->toDateString(),
                type: 'daily_budget',
                title: $overLimit ? 'Daily budget habis' : 'Daily budget hampir habis',
                message: $overLimit
                    ? 'Daily budget kamu sudah mencapai limit.'
                    : 'Pengeluaran harian kamu sudah mencapai '.$this->formatPercent($thresholdPercent).' dari daily budget.',
                threshold: $thresholdAmount,
                current: $todayExpense,
                periodDate: $today,
            ),
        ]);
    }

    private function checkMonthlyBudget(User $user, UserSetting $settings, Carbon $now): Collection
    {
        $month = $now->format('Y-m');
        $monthStart = $now->copy()->startOfMonth();
        $monthEnd = $now->copy()->endOfMonth();
        $monthlyBudget = (float) $settings->monthly_budget;

        if ($monthlyBudget <= 0) {
            return collect();
        }

        $monthExpense = $this->expenseSum($user->id, $monthStart, $monthEnd);
        $thresholdPercent = $this->thresholdPercent($settings);
        $thresholdAmount = $this->thresholdAmount($monthlyBudget, $thresholdPercent);

        if ($monthExpense < $thresholdAmount) {
            return collect();
        }

        $overLimit = $monthExpense >= $monthlyBudget;

        return collect([
            $this->definition(
                user: $user,
                key: 'monthly_budget:'.$month,
                type: 'monthly_budget',
                title: $overLimit ? 'Monthly budget habis' : 'Monthly budget hampir habis',
                message: $overLimit
                    ? 'Monthly budget kamu sudah mencapai limit.'
                    : 'Pengeluaran bulan ini sudah mencapai '.$this->formatPercent($thresholdPercent).' dari monthly budget.',
                threshold: $thresholdAmount,
                current: $monthExpense,
                periodMonth: $month,
            ),
        ]);
    }

    private function checkCategoryBudgets(User $user, UserSetting $settings, Carbon $now): Collection
    {
        $month = $now->format('Y-m');
        $monthStart = $now->copy()->startOfMonth();
        $monthEnd = $now->copy()->endOfMonth();
        $thresholdPercent = $this->thresholdPercent($settings);

        return Category::query()
            ->where('user_id', $user->id)
            ->where('type', 'expense')
            ->where('monthly_budget', '>', 0)
            ->get()
            ->map(function (Category $category) use ($user, $monthStart, $monthEnd, $month, $thresholdPercent): ?array {
                $budget = (float) $category->monthly_budget;
                $spent = $this->expenseSum($user->id, $monthStart, $monthEnd, $category->id);
                $thresholdAmount = $this->thresholdAmount($budget, $thresholdPercent);

                if ($spent < $thresholdAmount) {
                    return null;
                }

                $overLimit = $spent >= $budget;
                $overBudget = max(0, $spent - $budget);
                return $this->definition(
                    user: $user,
                    key: "category_budget:{$category->id}:{$month}",
                    type: 'category_budget',
                    title: $overLimit ? 'Budget kategori habis' : 'Budget kategori hampir habis',
                    message: $overBudget > 0
                        ? "Budget kategori {$category->name} sudah melebihi budget sebesar Rp ".number_format($overBudget, 0, ',', '.').'.'
                        : ($overLimit
                            ? "Budget kategori {$category->name} sudah mencapai limit."
                            : "Budget kategori {$category->name} sudah mencapai ".$this->formatPercent($thresholdPercent).'.'),
                    threshold: $thresholdAmount,
                    current: $spent,
                    categoryId: $category->id,
                    periodMonth: $month,
                );
            })
            ->filter()
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

    private function settingsFor(User $user): UserSetting
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

    private function thresholdPercent(UserSetting $settings): float
    {
        return min(100, max(1, (float) ($settings->budget_warning_threshold ?? 80)));
    }

    private function thresholdAmount(float $budget, float $thresholdPercent): float
    {
        return $budget * ($thresholdPercent / 100);
    }

    private function formatPercent(float $percent): string
    {
        return rtrim(rtrim(number_format($percent, 2, ',', '.'), '0'), ',').'%';
    }
}
