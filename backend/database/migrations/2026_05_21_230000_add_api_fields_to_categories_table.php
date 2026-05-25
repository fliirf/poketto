<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            if (! Schema::hasColumn('categories', 'user_id')) {
                $table->foreignId('user_id')->nullable()->after('id')->constrained()->cascadeOnDelete();
            }

            if (! Schema::hasColumn('categories', 'monthly_budget')) {
                $table->decimal('monthly_budget', 15, 2)->default(0)->after('type');
            }
        });
    }

    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            if (Schema::hasColumn('categories', 'monthly_budget')) {
                $table->dropColumn('monthly_budget');
            }

            if (Schema::hasColumn('categories', 'user_id')) {
                $table->dropConstrainedForeignId('user_id');
            }
        });
    }
};
