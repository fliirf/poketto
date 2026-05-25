<?php

namespace App\Http\Controllers\Api;

use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CategoryController extends ApiController
{
    public function index(Request $request)
    {
        $categories = Category::query()
            ->where('user_id', $request->user()->id)
            ->orderBy('type')
            ->orderBy('name')
            ->get();

        return $this->success(['categories' => $categories]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'type' => ['nullable', Rule::in(['income', 'expense'])],
            'monthly_budget' => ['nullable', 'numeric', 'min:0'],
        ]);

        $category = Category::create([
            'user_id' => $request->user()->id,
            'name' => $validated['name'],
            'type' => $validated['type'] ?? 'expense',
            'monthly_budget' => $validated['monthly_budget'] ?? 0,
        ]);

        return $this->success(['category' => $category], 'Category created', 201);
    }

    public function show(Request $request, Category $category)
    {
        $this->authorizeCategory($request, $category);

        return $this->success(['category' => $category]);
    }

    public function update(Request $request, Category $category)
    {
        $this->authorizeCategory($request, $category);

        $validated = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:100'],
            'type' => ['sometimes', 'required', Rule::in(['income', 'expense'])],
            'monthly_budget' => ['sometimes', 'nullable', 'numeric', 'min:0'],
        ]);

        $category->update($validated);

        return $this->success(['category' => $category->fresh()], 'Category updated');
    }

    public function destroy(Request $request, Category $category)
    {
        $this->authorizeCategory($request, $category);
        $category->delete();

        return $this->success(null, 'Category deleted');
    }

    private function authorizeCategory(Request $request, Category $category): void
    {
        abort_if($category->user_id !== $request->user()->id, 404);
    }
}
