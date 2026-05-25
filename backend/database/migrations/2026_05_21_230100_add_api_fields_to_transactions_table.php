<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            if (! Schema::hasColumn('transactions', 'type')) {
                $table->enum('type', ['income', 'expense'])->default('expense')->after('category_id');
            }

            if (! Schema::hasColumn('transactions', 'transaction_date')) {
                $table->dateTime('transaction_date')->nullable()->after('date');
            }

            if (! Schema::hasColumn('transactions', 'location_lat')) {
                $table->decimal('location_lat', 10, 8)->nullable()->after('transaction_date');
            }

            if (! Schema::hasColumn('transactions', 'location_lng')) {
                $table->decimal('location_lng', 11, 8)->nullable()->after('location_lat');
            }

            if (! Schema::hasColumn('transactions', 'location_name')) {
                $table->string('location_name')->nullable()->after('location_lng');
            }
        });

        if (Schema::hasColumn('transactions', 'date') && Schema::hasColumn('transactions', 'transaction_date')) {
            DB::table('transactions')
                ->whereNull('transaction_date')
                ->update(['transaction_date' => DB::raw('date')]);
        }

        if (Schema::hasColumn('categories', 'type') && Schema::hasColumn('transactions', 'type')) {
            DB::statement('UPDATE transactions SET type = (SELECT categories.type FROM categories WHERE categories.id = transactions.category_id) WHERE category_id IS NOT NULL');
        }
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            foreach (['location_name', 'location_lng', 'location_lat', 'transaction_date', 'type'] as $column) {
                if (Schema::hasColumn('transactions', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
