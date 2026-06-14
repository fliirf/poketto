<?php

namespace App\Http\Controllers\Api;

use App\Models\BudgetAlert;
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

    public function markAsRead(Request $request, BudgetAlert $notification, BudgetAlertService $budgetAlertService)
    {
        $alert = $budgetAlertService->markAsRead($request->user(), $notification);

        return $this->success([
            'notification' => [
                'id' => $alert->id,
                'is_read' => (bool) $alert->is_read,
            ],
        ], 'Notifikasi ditandai sudah dibaca.');
    }
}
