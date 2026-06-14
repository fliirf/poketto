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

    public function getNotificationEnabledAttribute($value): bool
    {
        return $this->booleanFromDatabase($value);
    }

    public function setLocationEnabledAttribute($value): void
    {
        $this->attributes['location_enabled'] = $this->booleanForDatabase($value);
    }

    public function getLocationEnabledAttribute($value): bool
    {
        return $this->booleanFromDatabase($value);
    }

    private function booleanForDatabase($value): bool|string
    {
        $boolean = $this->booleanFromDatabase($value);

        if ($this->getConnection()->getDriverName() === 'pgsql') {
            return $boolean ? 'true' : 'false';
        }

        return $boolean;
    }

    private function booleanFromDatabase($value): bool
    {
        if (is_bool($value)) {
            return $value;
        }

        if (is_int($value)) {
            return $value === 1;
        }

        if (is_string($value)) {
            $normalized = strtolower(trim($value));

            if (in_array($normalized, ['1', 'true', 't', 'yes', 'on'], true)) {
                return true;
            }

            if (in_array($normalized, ['0', 'false', 'f', 'no', 'off', ''], true)) {
                return false;
            }
        }

        return (bool) $value;
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
