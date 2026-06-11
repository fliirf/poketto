<?php

namespace App\Http\Controllers;

use App\Services\PokettoApiClient;
use Illuminate\Http\Request;
use Throwable;

class UserSettingsController extends Controller
{
    public function edit()
    {
        $settings = (object) (app(PokettoApiClient::class)->get('/user-settings')['user_settings'] ?? []);

        return view('settings.edit', compact('settings'));
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'daily_budget' => 'required|numeric|min:0',
            'monthly_budget' => 'required|numeric|min:0',
            'currency' => 'required|string|max:8',
            'notification_enabled' => 'nullable|boolean',
            'location_enabled' => 'nullable|boolean',
        ], [
            'daily_budget.required' => 'Budget harian wajib diisi.',
            'daily_budget.numeric' => 'Budget harian harus berupa angka.',
            'daily_budget.min' => 'Budget harian tidak boleh negatif.',
            'monthly_budget.required' => 'Budget bulanan wajib diisi.',
            'monthly_budget.numeric' => 'Budget bulanan harus berupa angka.',
            'monthly_budget.min' => 'Budget bulanan tidak boleh negatif.',
            'currency.required' => 'Mata uang wajib diisi.',
            'currency.max' => 'Mata uang maksimal 8 karakter.',
        ]);

        try {
            app(PokettoApiClient::class)->put('/user-settings', [
                'daily_budget' => $validated['daily_budget'],
                'monthly_budget' => $validated['monthly_budget'],
                'currency' => strtoupper($validated['currency']),
                'notification_enabled' => $request->boolean('notification_enabled'),
                'location_enabled' => $request->boolean('location_enabled'),
            ]);
        } catch (Throwable $exception) {
            report($exception);

            return back()
                ->withInput()
                ->with('error', 'Settings gagal disimpan. Coba lagi nanti.');
        }

        return redirect()->route('settings.edit')->with('success', 'Settings berhasil disimpan.');
    }
}
