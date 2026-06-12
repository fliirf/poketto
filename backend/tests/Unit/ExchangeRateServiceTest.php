<?php

namespace Tests\Unit;

use App\Models\ExchangeRate;
use App\Services\ExchangeRateService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExchangeRateServiceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config(['services.exchange_rate.key' => null]);
    }

    public function test_resolves_stored_foreign_currency_rate(): void
    {
        ExchangeRate::create([
            'base_currency' => 'IDR',
            'target_currency' => 'USD',
            'rate' => 0.000061,
            'fetched_at' => now(),
        ]);

        $resolved = app(ExchangeRateService::class)->resolveDisplayCurrency('USD');

        $this->assertSame('USD', $resolved['currency']);
        $this->assertSame(0.000061, $resolved['rate']);
        $this->assertTrue($resolved['converted']);
    }

    public function test_falls_back_to_idr_when_requested_rate_is_missing(): void
    {
        $resolved = app(ExchangeRateService::class)->resolveDisplayCurrency('USD');

        $this->assertSame('IDR', $resolved['currency']);
        $this->assertSame(1.0, $resolved['rate']);
        $this->assertFalse($resolved['converted']);
    }
}
