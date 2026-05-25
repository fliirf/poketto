<?php

namespace App\Services;

use App\Models\ExchangeRate;
use Illuminate\Support\Facades\Http;

class ExchangeRateService
{
    public function getRates(string $base = 'IDR'): array
    {
        $base = strtoupper($base);
        $apiKey = config('services.exchange_rate.key');

        if ($apiKey) {
            try {
                $response = Http::timeout(8)->get('https://v6.exchangerate-api.com/v6/'.$apiKey.'/latest/'.$base);
                if ($response->successful() && $response->json('result') === 'success') {
                    $rates = $response->json('conversion_rates', []);
                    foreach (['USD', 'EUR', 'SGD', 'JPY'] as $target) {
                        if (isset($rates[$target])) {
                            ExchangeRate::updateOrCreate(
                                ['base_currency' => $base, 'target_currency' => $target],
                                ['rate' => $rates[$target], 'fetched_at' => now()],
                            );
                        }
                    }
                }
            } catch (\Throwable) {
                // Exchange rates are optional; stale/local data is acceptable for demo mode.
            }
        }

        $stored = ExchangeRate::query()
            ->where('base_currency', $base)
            ->orderBy('target_currency')
            ->get();

        if ($stored->isNotEmpty()) {
            return $stored->toArray();
        }

        return [];
    }
}
