<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\User;
use App\Models\UserSetting;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ApiRegisterTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_from_api(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Bowo',
            'email' => 'bowo@example.com',
            'password' => 'secret1',
            'password_confirmation' => 'secret1',
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'user' => ['id', 'name', 'email'],
                    'token',
                ],
            ]);

        $user = User::where('email', 'bowo@example.com')->firstOrFail();

        $this->assertSame('Bowo', $user->name);
        $this->assertSame(6, Category::where('user_id', $user->id)->count());
        $this->assertTrue(UserSetting::where('user_id', $user->id)->exists());
        $this->assertNotEmpty($response->json('data.token'));
    }
}
