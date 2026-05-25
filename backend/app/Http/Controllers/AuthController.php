<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use App\Models\Category;

class AuthController extends Controller
{
    // Menampilkan halaman register
    public function showRegister() {
        return view('auth.register');
    }

    // Memproses data register
    public function register(Request $request) {
        $request->validate([
            'name' => 'required',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6|confirmed',
        ]);

        // 1. Buat User baru
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        // 2. DAFTAR KATEGORI DEFAULT
        $defaultCategories = [
            ['name' => 'Makanan & Minuman', 'type' => 'expense'],
            ['name' => 'Transportasi', 'type' => 'expense'],
            ['name' => 'Belanja', 'type' => 'expense'],
            ['name' => 'Kesehatan', 'type' => 'expense'],
            ['name' => 'Gaji', 'type' => 'income'],
            ['name' => 'Bonus', 'type' => 'income'],
        ];

        // 3. Simpan kategori ke database untuk user tersebut
        foreach ($defaultCategories as $category) {
            Category::create([
                'user_id' => $user->id,
                'name' => $category['name'],
                'type' => $category['type'],
                'monthly_budget' => $category['type'] === 'expense' ? 500000 : 0,
            ]);
        }

        $user->userSetting()->create([
            'daily_budget' => 100000,
            'monthly_budget' => 2500000,
            'currency' => 'IDR',
            'budget_warning_threshold' => 80,
            'notification_enabled' => true,
            'location_enabled' => true,
        ]);

        // 4. Langsung login
        Auth::login($user);
        $request->session()->put('api_token', $user->createToken('poketto-web')->plainTextToken);

        return redirect('/dashboard')->with('success', 'Selamat datang di Poketto! Kategori default telah disiapkan untukmu.');
    }

    // Menampilkan halaman login
public function showLogin() {
    return view('auth.login');
}

// Memproses login
public function login(Request $request) {
    // Validasi input
    $credentials = $request->validate([
        'email' => ['required', 'email'],
        'password' => ['required'],
    ]);

    // Coba mencocokkan email & password di database
    if (Auth::attempt($credentials)) {
        $request->session()->regenerate(); // Untuk keamanan session
        $request->session()->put('api_token', Auth::user()->createToken('poketto-web')->plainTextToken);

        // Redirect ke dashboard (nanti kita buat dashboard-nya)
        return redirect()->intended('/dashboard');
    }

    // Jika gagal, balikkan ke login dengan pesan error
    return back()->withErrors([
        'email' => 'Email atau password salah.',
    ])->onlyInput('email');
}

// Fitur Logout
public function logout(Request $request) {
    if ($request->user()) {
        $request->user()->tokens()->where('name', 'poketto-web')->delete();
    }
    Auth::logout();
    $request->session()->invalidate();
    $request->session()->regenerateToken();
    return redirect('/login');
}
}
