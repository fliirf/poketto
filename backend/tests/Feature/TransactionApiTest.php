<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TransactionApiTest extends TestCase
{
    use RefreshDatabase;

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
}
