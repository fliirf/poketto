<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('budget_alerts', function (Blueprint $table) {
            if (! Schema::hasColumn('budget_alerts', 'alert_key')) {
                $table->string('alert_key')->nullable()->after('category_id');
            }
            if (! Schema::hasColumn('budget_alerts', 'title')) {
                $table->string('title')->nullable()->after('alert_type');
            }
            if (! Schema::hasColumn('budget_alerts', 'period_date')) {
                $table->date('period_date')->nullable()->after('current_value');
            }
            if (! Schema::hasColumn('budget_alerts', 'period_month')) {
                $table->string('period_month', 7)->nullable()->after('period_date');
            }
        });

        Schema::table('budget_alerts', function (Blueprint $table) {
            $table->unique(['user_id', 'alert_key'], 'budget_alerts_user_alert_key_unique');
        });
    }

    public function down(): void
    {
        Schema::table('budget_alerts', function (Blueprint $table) {
            $table->dropUnique('budget_alerts_user_alert_key_unique');
            $table->dropColumn(['alert_key', 'title', 'period_date', 'period_month']);
        });
    }
};
