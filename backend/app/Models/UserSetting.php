<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserSetting extends Model
{
    protected $fillable = [
        'user_id',
        'daily_budget',
        'monthly_budget',
        'currency',
        'budget_warning_threshold',
        'notification_enabled',
        'location_enabled',
    ];

    protected $casts = [
        'daily_budget' => 'decimal:2',
        'monthly_budget' => 'decimal:2',
        'budget_warning_threshold' => 'decimal:2',
        'notification_enabled' => 'boolean',
        'location_enabled' => 'boolean',
    ];

    public function setNotificationEnabledAttribute($value): void
    {
        $this->attributes['notification_enabled'] = $this->booleanForDatabase($value);
    }

    public function setLocationEnabledAttribute($value): void
    {
        $this->attributes['location_enabled'] = $this->booleanForDatabase($value);
    }

    private function booleanForDatabase($value): string
    {
        return filter_var($value, FILTER_VALIDATE_BOOLEAN) ? 'true' : 'false';
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
