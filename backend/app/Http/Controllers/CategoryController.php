<?php

namespace App\Http\Controllers;

use App\Models\Category;
use App\Services\PokettoApiClient;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Throwable;

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
        $validated = $request->validate($this->categoryRules(maxName: 50), $this->categoryMessages());

        // 2. Simpan ke database dengan user_id yang sedang login
        try {
            app(PokettoApiClient::class)->post('/categories', [
                'name' => $validated['name'],
                'type' => $validated['type'],
                'monthly_budget' => $validated['monthly_budget'] ?? 0,
            ]);
        } catch (Throwable $exception) {
            report($exception);

            return back()
                ->withInput()
                ->with('error', 'Kategori gagal disimpan. Periksa kembali data yang diisi.');
        }

        // 3. Redirect kembali ke halaman sebelumnya dengan pesan sukses
        return redirect()->back()->with('success', 'Kategori berhasil ditambahkan.');
    }

    public function edit(Category $category)
    {
        $this->authorizeCategory($category);

        return view('categories.edit', compact('category'));
    }

    public function update(Request $request, Category $category)
    {
        $this->authorizeCategory($category);

        $validated = $request->validate($this->categoryRules(), $this->categoryMessages());

        try {
            app(PokettoApiClient::class)->put('/categories/'.$category->id, [
                'name' => $validated['name'],
                'type' => $validated['type'],
                'monthly_budget' => $validated['monthly_budget'] ?? 0,
            ]);
        } catch (Throwable $exception) {
            report($exception);

            return back()
                ->withInput()
                ->with('error', 'Kategori gagal disimpan. Periksa kembali data yang diisi.');
        }

        return redirect()->route('categories.index')->with('success', 'Kategori berhasil diperbarui.');
    }

    public function destroy(Category $category)
    {
        $this->authorizeCategory($category);
        try {
            app(PokettoApiClient::class)->delete('/categories/'.$category->id);
        } catch (Throwable $exception) {
            report($exception);

            return back()->with('error', 'Kategori gagal dihapus. Coba lagi nanti.');
        }

        return redirect()->route('categories.index')->with('success', 'Kategori berhasil dihapus.');
    }

    private function authorizeCategory(Category $category): void
    {
        abort_if($category->user_id !== Auth::id(), 403);
    }

    private function categoryRules(int $maxName = 100): array
    {
        return [
            'name' => 'required|string|max:'.$maxName,
            'type' => 'required|in:income,expense',
            'monthly_budget' => 'nullable|numeric|min:0',
        ];
    }

    private function categoryMessages(): array
    {
        return [
            'name.required' => 'Nama kategori wajib diisi.',
            'name.max' => 'Nama kategori terlalu panjang.',
            'type.required' => 'Tipe kategori wajib dipilih.',
            'type.in' => 'Tipe kategori tidak valid.',
            'monthly_budget.numeric' => 'Budget bulanan harus berupa angka.',
            'monthly_budget.min' => 'Budget bulanan tidak boleh negatif.',
        ];
    }
}
