<?php

namespace App\Http\Controllers;

use App\Models\Category;
use App\Services\PokettoApiClient;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CategoryController extends Controller
{
    public function index()
    {
        $categories = collect(app(PokettoApiClient::class)->get('/categories')['categories'] ?? [])
            ->map(fn ($category) => (object) $category);

        return view('categories.index', compact('categories'));
    }

    /**
     * Menyimpan kategori baru ke database.
     */
    public function store(Request $request)
    {
        // 1. Validasi input
        $request->validate([
            'name' => 'required|string|max:50',
            'type' => 'required|in:income,expense',
            'monthly_budget' => 'nullable|numeric|min:0',
        ]);

        // 2. Simpan ke database dengan user_id yang sedang login
        app(PokettoApiClient::class)->post('/categories', [
            'name' => $request->name,
            'type' => $request->type,
            'monthly_budget' => $request->monthly_budget ?? 0,
        ]);

        // 3. Redirect kembali ke halaman sebelumnya dengan pesan sukses
        return redirect()->back()->with('success', 'Kategori baru berhasil ditambahkan!');
    }

    public function edit(Category $category)
    {
        $this->authorizeCategory($category);

        return view('categories.edit', compact('category'));
    }

    public function update(Request $request, Category $category)
    {
        $this->authorizeCategory($category);

        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'type' => 'required|in:income,expense',
            'monthly_budget' => 'nullable|numeric|min:0',
        ]);

        app(PokettoApiClient::class)->put('/categories/'.$category->id, [
            'name' => $validated['name'],
            'type' => $validated['type'],
            'monthly_budget' => $validated['monthly_budget'] ?? 0,
        ]);

        return redirect()->route('categories.index')->with('success', 'Kategori berhasil diperbarui.');
    }

    public function destroy(Category $category)
    {
        $this->authorizeCategory($category);
        app(PokettoApiClient::class)->delete('/categories/'.$category->id);

        return redirect()->route('categories.index')->with('success', 'Kategori berhasil dihapus.');
    }

    private function authorizeCategory(Category $category): void
    {
        abort_if($category->user_id !== Auth::id(), 403);
    }
}
