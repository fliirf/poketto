<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            // Menghubungkan ke user yang login
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            // Menghubungkan ke kategori
            $table->foreignId('category_id')->constrained()->onDelete('cascade');
        
            $table->decimal('amount', 15, 2); // Nilai uang (maks 99 triliun)
            $table->string('description')->nullable(); // Catatan opsional
            $table->date('date'); // Tanggal transaksi
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
