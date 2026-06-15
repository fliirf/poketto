<?php

namespace App\Http\Controllers\Api;

use App\Models\Category;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends ApiController
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => [
                'required',
                'string',
                'min:8',
                'regex:/[A-Z]/',
                'regex:/[a-z]/',
                'regex:/[0-9]/',
                'regex:/[^A-Za-z0-9]/',
                'confirmed',
            ],
        ]);

        [$user, $token] = DB::transaction(function () use ($validated) {
            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
            ]);

            $this->createDefaultUserData($user);
            $token = $user->createToken('poketto-api')->plainTextToken;

            return [$user, $token];
        });

        return $this->success([
            'user' => $user,
            'token' => $token,
        ], 'Registered', 201);
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $credentials['email'])->first();
        if (! $user || ! Hash::check($credentials['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau password salah.'],
            ]);
        }

        $token = $user->createToken('poketto-api')->plainTextToken;

        return $this->success([
            'user' => $user,
            'token' => $token,
        ], 'Logged in');
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return $this->success(null, 'Logged out');
    }

    public function me(Request $request)
    {
        return $this->success(['user' => $request->user()]);
    }

    private function createDefaultUserData(User $user): void
    {
        $user->userSetting()->create([
            'daily_budget' => 100000,
            'monthly_budget' => 2500000,
            'currency' => 'IDR',
            'budget_warning_threshold' => 80,
            'notification_enabled' => true,
            'location_enabled' => true,
        ]);

        $defaultCategories = [
            ['name' => 'Makanan & Minuman', 'type' => 'expense', 'monthly_budget' => 500000],
            ['name' => 'Transportasi', 'type' => 'expense', 'monthly_budget' => 300000],
            ['name' => 'Belanja', 'type' => 'expense', 'monthly_budget' => 500000],
            ['name' => 'Kesehatan', 'type' => 'expense', 'monthly_budget' => 250000],
            ['name' => 'Gaji', 'type' => 'income', 'monthly_budget' => 0],
            ['name' => 'Bonus', 'type' => 'income', 'monthly_budget' => 0],
        ];

        foreach ($defaultCategories as $category) {
            Category::create([...$category, 'user_id' => $user->id]);
        }
    }
}
