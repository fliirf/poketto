<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

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
            'currency' => ['sometimes', 'string', Rule::in(['IDR', 'USD', 'EUR', 'SGD', 'JPY'])],
            'budget_warning_threshold' => ['sometimes', 'numeric', 'min:1', 'max:99'],
        ], [
            'daily_budget.numeric' => 'Budget harian harus berupa angka.',
            'daily_budget.min' => 'Budget harian tidak boleh negatif.',
            'monthly_budget.numeric' => 'Budget bulanan harus berupa angka.',
            'monthly_budget.min' => 'Budget bulanan tidak boleh negatif.',
            'currency.in' => 'Mata uang tidak tersedia.',
            'budget_warning_threshold.numeric' => 'Batas peringatan harus berupa angka.',
            'budget_warning_threshold.min' => 'Batas peringatan minimal 1%.',
            'budget_warning_threshold.max' => 'Batas peringatan maksimal 99%.',
        ]);

        $validated['notification_enabled'] = true;
        $validated['location_enabled'] = true;

        $settings = $this->settings($request);
        $settings->update($validated);

        return $this->success(['user_settings' => $settings->fresh()], 'Settings berhasil disimpan.');
    }

    private function settings(Request $request)
    {
        $settings = $request->user()->userSetting()->firstOrCreate(
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

        if (! $settings->notification_enabled || ! $settings->location_enabled) {
            $settings->forceFill([
                'notification_enabled' => true,
                'location_enabled' => true,
            ])->save();
        }

        return $settings->fresh();
    }
}
