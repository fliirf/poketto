<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BudgetAlert extends Model
{
    protected $fillable = [
        'user_id',
        'category_id',
        'alert_key',
        'alert_type',
        'title',
        'message',
        'threshold_value',
        'current_value',
        'period_date',
        'period_month',
        'is_read',
    ];

    protected $casts = [
        'threshold_value' => 'decimal:2',
        'current_value' => 'decimal:2',
        'period_date' => 'date',
        'is_read' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}
