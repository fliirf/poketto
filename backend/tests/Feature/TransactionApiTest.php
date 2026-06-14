<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\BudgetAlert;
use App\Models\Transaction;
use App\Models\User;
use App\Models\UserSetting;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TransactionApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Carbon::setTestNow(Carbon::parse('2026-06-14 10:00:00', 'Asia/Jakarta'));
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    public function test_cannot_create_transaction_with_another_users_category(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $otherCategory = Category::create([
            'user_id' => $otherUser->id,
            'name' => 'Belanja orang lain',
            'type' => 'expense',
            'monthly_budget' => 100000,
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/transactions', [
            'type' => 'expense',
            'category_id' => $otherCategory->id,
            'amount' => 10000,
            'transaction_date' => now()->toDateString(),
        ]);

        $response->assertStatus(422);
        $this->assertDatabaseCount('transactions', 0);
    }

    public function test_cannot_update_transaction_to_another_users_category(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $ownCategory = Category::create([
            'user_id' => $user->id,
            'name' => 'Makan',
            'type' => 'expense',
            'monthly_budget' => 100000,
        ]);
        $otherCategory = Category::create([
            'user_id' => $otherUser->id,
            'name' => 'Belanja orang lain',
            'type' => 'expense',
            'monthly_budget' => 100000,
        ]);
        $transaction = Transaction::create([
            'user_id' => $user->id,
            'category_id' => $ownCategory->id,
            'type' => 'expense',
            'amount' => 10000,
            'date' => now()->toDateString(),
            'transaction_date' => now(),
        ]);

        $response = $this->actingAs($user, 'sanctum')->putJson("/api/transactions/{$transaction->id}", [
            'type' => 'expense',
            'category_id' => $otherCategory->id,
            'amount' => 12000,
            'transaction_date' => now()->toDateString(),
        ]);

        $response->assertStatus(422);
        $this->assertSame($ownCategory->id, $transaction->fresh()->category_id);
    }

    public function test_cannot_use_income_category_for_expense_transaction(): void
    {
        $user = User::factory()->create();
        $incomeCategory = Category::create([
            'user_id' => $user->id,
            'name' => 'Gaji',
            'type' => 'income',
            'monthly_budget' => 0,
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/transactions', [
            'type' => 'expense',
            'category_id' => $incomeCategory->id,
            'amount' => 10000,
            'transaction_date' => now()->toDateString(),
        ]);

        $response->assertStatus(422);
        $this->assertDatabaseCount('transactions', 0);
    }

    public function test_creating_expense_triggers_budget_notifications(): void
    {
        $user = User::factory()->create();
        UserSetting::create([
            'user_id' => $user->id,
            'daily_budget' => 100000,
            'monthly_budget' => 100000,
            'currency' => 'IDR',
            'budget_warning_threshold' => 80,
            'notification_enabled' => true,
            'location_enabled' => true,
        ]);
        $category = Category::create([
            'user_id' => $user->id,
            'name' => 'Belanja',
            'type' => 'expense',
            'monthly_budget' => 100000,
        ]);

        $this->actingAs($user, 'sanctum')->postJson('/api/transactions', [
            'type' => 'expense',
            'category_id' => $category->id,
            'amount' => 100000,
            'transaction_date' => Carbon::now('Asia/Jakarta')->toDateString(),
        ])->assertCreated();

        $this->assertEqualsCanonicalizing(
            ['daily_budget', 'monthly_budget', 'category_budget'],
            BudgetAlert::where('user_id', $user->id)->pluck('alert_type')->all(),
        );
    }

    public function test_daily_budget_notification_does_not_wait_for_monthly_budget(): void
    {
        [$user, $category] = $this->notificationFixture(
            dailyBudget: 400000,
            monthlyBudget: 10000000,
            categoryBudget: 10000000,
        );

        $this->actingAs($user, 'sanctum')->postJson('/api/transactions', [
            'type' => 'expense',
            'category_id' => $category->id,
            'amount' => 400000,
            'transaction_date' => Carbon::now('Asia/Jakarta')->toDateString(),
        ])->assertCreated();

        $this->assertEqualsCanonicalizing(
            ['daily_budget'],
            BudgetAlert::where('user_id', $user->id)->pluck('alert_type')->all(),
        );
    }

    public function test_category_budget_notification_does_not_wait_for_monthly_budget(): void
    {
        [$user, $category] = $this->notificationFixture(
            dailyBudget: 10000000,
            monthlyBudget: 10000000,
            categoryBudget: 500000,
        );

        $this->actingAs($user, 'sanctum')->postJson('/api/transactions', [
            'type' => 'expense',
            'category_id' => $category->id,
            'amount' => 500000,
            'transaction_date' => Carbon::now('Asia/Jakarta')->toDateString(),
        ])->assertCreated();

        $this->assertEqualsCanonicalizing(
            ['category_budget'],
            BudgetAlert::where('user_id', $user->id)->pluck('alert_type')->all(),
        );
    }

    public function test_monthly_budget_notification_is_independent_from_daily_and_category_budget(): void
    {
        [$user, $category] = $this->notificationFixture(
            dailyBudget: 10000000,
            monthlyBudget: 1000000,
            categoryBudget: 10000000,
        );

        $this->actingAs($user, 'sanctum')->postJson('/api/transactions', [
            'type' => 'expense',
            'category_id' => $category->id,
            'amount' => 1000000,
            'transaction_date' => Carbon::now('Asia/Jakarta')->toDateString(),
        ])->assertCreated();

        $this->assertEqualsCanonicalizing(
            ['monthly_budget'],
            BudgetAlert::where('user_id', $user->id)->pluck('alert_type')->all(),
        );
    }

    public function test_updating_income_to_expense_triggers_independent_budget_notification(): void
    {
        [$user, $expenseCategory] = $this->notificationFixture(
            dailyBudget: 400000,
            monthlyBudget: 10000000,
            categoryBudget: 10000000,
        );
        $incomeCategory = Category::create([
            'user_id' => $user->id,
            'name' => 'Gaji',
            'type' => 'income',
            'monthly_budget' => 0,
        ]);
        $transaction = Transaction::create([
            'user_id' => $user->id,
            'category_id' => $incomeCategory->id,
            'type' => 'income',
            'amount' => 400000,
            'date' => Carbon::now('Asia/Jakarta')->toDateString(),
            'transaction_date' => Carbon::now('Asia/Jakarta'),
        ]);

        $this->actingAs($user, 'sanctum')->putJson("/api/transactions/{$transaction->id}", [
            'type' => 'expense',
            'category_id' => $expenseCategory->id,
            'amount' => 400000,
            'transaction_date' => Carbon::now('Asia/Jakarta')->toDateString(),
        ])->assertOk();

        $this->assertEqualsCanonicalizing(
            ['daily_budget'],
            BudgetAlert::where('user_id', $user->id)->pluck('alert_type')->all(),
        );
    }

    public function test_dashboard_daily_budget_uses_today_even_when_dashboard_filter_is_different(): void
    {
        $user = User::factory()->create();
        UserSetting::create([
            'user_id' => $user->id,
            'daily_budget' => 100000,
            'monthly_budget' => 500000,
            'currency' => 'IDR',
            'budget_warning_threshold' => 80,
            'notification_enabled' => true,
            'location_enabled' => true,
        ]);
        $category = Category::create([
            'user_id' => $user->id,
            'name' => 'Belanja',
            'type' => 'expense',
            'monthly_budget' => 500000,
        ]);
        Transaction::create([
            'user_id' => $user->id,
            'category_id' => $category->id,
            'type' => 'expense',
            'amount' => 75000,
            'date' => Carbon::now('Asia/Jakarta')->toDateString(),
            'transaction_date' => Carbon::now('Asia/Jakarta'),
        ]);

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/dashboard/summary?start_date=2026-05-01&end_date=2026-05-31')
            ->assertOk()
            ->assertJsonPath('data.daily_expense', 75000)
            ->assertJsonPath('data.daily_budget_remaining', 25000)
            ->assertJsonPath('data.daily_budget_percentage', 75);
    }

    public function test_dashboard_daily_budget_prefers_transaction_date_column_date_over_shifted_datetime(): void
    {
        $user = User::factory()->create();
        UserSetting::create([
            'user_id' => $user->id,
            'daily_budget' => 100000,
            'monthly_budget' => 500000,
            'currency' => 'IDR',
            'budget_warning_threshold' => 80,
            'notification_enabled' => true,
            'location_enabled' => true,
        ]);
        $category = Category::create([
            'user_id' => $user->id,
            'name' => 'Belanja',
            'type' => 'expense',
            'monthly_budget' => 500000,
        ]);
        Transaction::create([
            'user_id' => $user->id,
            'category_id' => $category->id,
            'type' => 'expense',
            'amount' => 60000,
            'date' => '2026-06-14',
            'transaction_date' => '2026-06-13 17:00:00',
        ]);

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/dashboard/summary')
            ->assertOk()
            ->assertJsonPath('data.daily_expense', 60000)
            ->assertJsonPath('data.daily_budget_remaining', 40000)
            ->assertJsonPath('data.expense_trend.6.total', 60000);
    }

    private function notificationFixture(float $dailyBudget, float $monthlyBudget, float $categoryBudget): array
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
