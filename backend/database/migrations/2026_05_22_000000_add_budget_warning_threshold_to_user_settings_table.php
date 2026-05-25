<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_settings', function (Blueprint $table) {
            if (! Schema::hasColumn('user_settings', 'budget_warning_threshold')) {
                $table->decimal('budget_warning_threshold', 5, 2)->default(80)->after('currency');
            }
        });
    }

    public function down(): void
    {
        Schema::table('user_settings', function (Blueprint $table) {
            if (Schema::hasColumn('user_settings', 'budget_warning_threshold')) {
                $table->dropColumn('budget_warning_threshold');
            }
        });
    }
};
