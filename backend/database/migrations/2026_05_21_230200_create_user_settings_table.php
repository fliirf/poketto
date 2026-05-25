<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->decimal('daily_budget', 15, 2)->default(100000);
            $table->decimal('monthly_budget', 15, 2)->default(2500000);
            $table->string('currency', 8)->default('IDR');
            $table->boolean('notification_enabled')->default(true);
            $table->boolean('location_enabled')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_settings');
    }
};
