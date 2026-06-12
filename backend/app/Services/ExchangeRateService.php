<?php

namespace App\Services;

use App\Models\ExchangeRate;
use Illuminate\Support\Facades\Http;

class ExchangeRateService
{
    private const BASE_CURRENCY = 'IDR';

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

    public function resolveDisplayCurrency(?string $preferredCurrency): array
    {
        $currency = strtoupper($preferredCurrency ?: self::BASE_CURRENCY);
        if ($currency === self::BASE_CURRENCY) {
            return ['currency' => self::BASE_CURRENCY, 'rate' => 1.0, 'converted' => true];
        }

        $rateRow = collect($this->getRates(self::BASE_CURRENCY))
            ->first(fn (array $item) => ($item['target_currency'] ?? null) === $currency);
        $rate = (float) ($rateRow['rate'] ?? 0);

        if (! is_finite($rate) || $rate <= 0) {
            return ['currency' => self::BASE_CURRENCY, 'rate' => 1.0, 'converted' => false];
        }

        return ['currency' => $currency, 'rate' => $rate, 'converted' => true];
    }
}
