<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $fillable = [
        'user_id',
        'category_id',
        'type',
        'amount',
        'description',
        'date',
        'transaction_date',
        'location_lat',
        'location_lng',
        'location_name',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'date' => 'date',
        'transaction_date' => 'datetime',
        'location_lat' => 'decimal:8',
        'location_lng' => 'decimal:8',
    ];

    public function category() {
        return $this->belongsTo(Category::class);
    }

    public function user() {
        return $this->belongsTo(User::class);
    }
}
