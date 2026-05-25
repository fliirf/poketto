<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category; // Wajib di-import

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            // Kategori Pengeluaran
            ['name' => 'Makanan & Minuman', 'type' => 'expense'],
            ['name' => 'Transportasi', 'type' => 'expense'],
            ['name' => 'Hiburan', 'type' => 'expense'],
            ['name' => 'Belanja', 'type' => 'expense'],
            
            // Kategori Pemasukan
            ['name' => 'Gaji', 'type' => 'income'],
            ['name' => 'Transfer Masuk', 'type' => 'income'],
            ['name' => 'Bonus', 'type' => 'income'],
        ];

        foreach ($categories as $category) {
            Category::create($category);
        }
    }
}