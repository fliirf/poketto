<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use App\Models\UserSetting;
use App\Services\BudgetAlertService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BudgetAlertServiceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Carbon::setTestNow(Carbon::parse('2026-06-12 10:00:00'));
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    public function test_alerts_follow_current_monthly_budget(): void
    {
        [$user, $category] = $this->budgetFixture(monthlyBudget: 1000, categoryBudget: 500);

        Transaction::create([
            'user_id' => $user->id,
            'category_id' => $category->id,
            'type' => 'expense',
            'amount' => 850,
            'date' => Carbon::today(),
            'transaction_date' => Carbon::now(),
        ]);

        $service = app(BudgetAlertService::class);

        $this->assertNotEmpty($service->forUser($user)->all());

        $user->userSetting()->update(['monthly_budget' => 10000]);
        $category->update(['monthly_budget' => 10000]);

        $this->assertSame([], $service->forUser($user->fresh())->all());
    }

    public function test_alerts_disappear_after_transaction_delete(): void
    {
        [$user, $category] = $this->budgetFixture(monthlyBudget: 1000, categoryBudget: 1000);

        $transaction = Transaction::create([
            'user_id' => $user->id,
            'category_id' => $category->id,
            'type' => 'expense',
            'amount' => 1000,
            'date' => Carbon::today(),
            'transaction_date' => Carbon::now(),
        ]);

        $service = app(BudgetAlertService::class);

        $this->assertNotEmpty($service->forUser($user)->all());

        $transaction->delete();

        $this->assertSame([], $service->forUser($user)->all());
    }

    public function test_daily_monthly_and_category_alerts_are_created_without_duplicates(): void
    {
        [$user, $category] = $this->budgetFixture(monthlyBudget: 1000, categoryBudget: 500, dailyBudget: 100);

        Transaction::create([
            'user_id' => $user->id,
            'category_id' => $category->id,
            'type' => 'expense',
            'amount' => 500,
            'date' => Carbon::today(),
            'transaction_date' => Carbon::now(),
        ]);

        $service = app(BudgetAlertService::class);
        $alerts = $service->forUser($user);

        $this->assertEqualsCanonicalizing(
            ['daily_budget', 'category_budget'],
            $alerts->pluck('type')->all(),
        );

        $service->forUser($user);

        $this->assertDatabaseCount('budget_alerts', 2);

        Transaction::create([
            'user_id' => $user->id,
            'category_id' => $category->id,
            'type' => 'expense',
            'amount' => 500,
            'date' => Carbon::today(),
            'transaction_date' => Carbon::now(),
        ]);

        $alerts = $service->forUser($user->fresh());

        $this->assertEqualsCanonicalizing(
            ['daily_budget', 'monthly_budget', 'category_budget'],
            $alerts->pluck('type')->all(),
        );
        $this->assertDatabaseCount('budget_alerts', 3);
    }

    public function test_income_does_not_create_budget_alerts(): void
    {
        [$user, $category] = $this->budgetFixture(monthlyBudget: 1000, categoryBudget: 500, dailyBudget: 100);
        $incomeCategory = Category::create([
            'user_id' => $user->id,
            'name' => 'Gaji',
            'type' => 'income',
            'monthly_budget' => 0,
        ]);

        Transaction::create([
            'user_id' => $user->id,
            'category_id' => $incomeCategory->id,
            'type' => 'income',
            'amount' => 100000,
            'date' => Carbon::today(),
            'transaction_date' => Carbon::now(),
        ]);

        $this->assertSame([], app(BudgetAlertService::class)->forUser($user)->all());
    }

    public function test_notification_disabled_clears_alerts(): void
    {
        [$user, $category] = $this->budgetFixture(monthlyBudget: 1000, categoryBudget: 500, dailyBudget: 100);

        Transaction::create([
            'user_id' => $user->id,
            'category_id' => $category->id,
            'type' => 'expense',
            'amount' => 900,
            'date' => Carbon::today(),
            'transaction_date' => Carbon::now(),
        ]);

        $service = app(BudgetAlertService::class);
        $this->assertNotEmpty($service->forUser($user)->all());

        $user->userSetting()->update(['notification_enabled' => false]);

        $this->assertSame([], $service->forUser($user->fresh())->all());
        $this->assertDatabaseCount('budget_alerts', 0);
    }

    private function budgetFixture(float $monthlyBudget, float $categoryBudget, float $dailyBudget = 100000): array
    {
        $user = User::factory()->create();

        UserSetting::create([
            'user_id' => $user->id,
            'daily_budget' => $dailyBudget,
            'monthly_budget' => $monthlyBudget,
            'currency' => 'IDR',
            'budget_warning_threshold' => 80,
            'notification_enabled' => true,
            'location_enabled' => true,
        ]);

        $category = Category::create([
            'user_id' => $user->id,
            'name' => 'Belanja',
            'type' => 'expense',
            'monthly_budget' => $categoryBudget,
        ]);

        return [$user, $category];
    }
}
