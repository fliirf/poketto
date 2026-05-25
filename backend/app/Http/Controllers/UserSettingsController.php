<?php

namespace App\Http\Controllers;

use App\Services\PokettoApiClient;
use Illuminate\Http\Request;

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
        ]);

        app(PokettoApiClient::class)->put('/user-settings', [
            'daily_budget' => $validated['daily_budget'],
            'monthly_budget' => $validated['monthly_budget'],
            'currency' => strtoupper($validated['currency']),
            'notification_enabled' => $request->boolean('notification_enabled'),
            'location_enabled' => $request->boolean('location_enabled'),
        ]);

        return redirect()->route('settings.edit')->with('success', 'Settings berhasil disimpan.');
    }
}
