<?php

namespace App\Http\Controllers\Api;

use App\Services\BudgetAlertService;
use Illuminate\Http\Request;

class BudgetAlertController extends ApiController
{
    public function index(Request $request, BudgetAlertService $budgetAlertService)
    {
        return $this->success([
            'alerts' => $budgetAlertService->forUser($request->user()),
        ]);
    }
}
