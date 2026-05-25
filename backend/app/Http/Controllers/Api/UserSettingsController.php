<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;

class UserSettingsController extends ApiController
{
    public function show(Request $request)
    {
        return $this->success(['user_settings' => $this->settings($request)]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'daily_budget' => ['sometimes', 'numeric', 'min:0'],
            'monthly_budget' => ['sometimes', 'numeric', 'min:0'],
            'currency' => ['sometimes', 'string', 'max:8'],
            'budget_warning_threshold' => ['sometimes', 'numeric', 'min:1', 'max:99'],
            'notification_enabled' => ['sometimes', 'boolean'],
            'location_enabled' => ['sometimes', 'boolean'],
        ]);

        $settings = $this->settings($request);
        $settings->update($validated);

        return $this->success(['user_settings' => $settings->fresh()], 'User settings updated');
    }

    private function settings(Request $request)
    {
        return $request->user()->userSetting()->firstOrCreate(
            ['user_id' => $request->user()->id],
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
}
