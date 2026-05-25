<?php

namespace App\Http\Controllers\Api;

use App\Services\ExchangeRateService;
use Illuminate\Http\Request;

class ExchangeRateController extends ApiController
{
    public function index(Request $request, ExchangeRateService $exchangeRateService)
    {
        return $this->success([
            'exchange_rates' => $exchangeRateService->getRates($request->query('base', 'IDR')),
        ]);
    }
}
