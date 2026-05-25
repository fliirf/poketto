@extends('layouts.app')

@section('content')
<div class="container" style="max-width: 640px;">
    <div class="card border-0 shadow-sm" style="border-radius: 16px;">
        <div class="card-body p-4">
            <div class="d-flex align-items-center mb-4">
                <a href="{{ route('categories.index') }}" class="btn btn-light rounded-circle me-3">
                    <i class="bi bi-arrow-left"></i>
                </a>
                <h4 class="fw-bold mb-0">Edit Kategori</h4>
            </div>

            <form action="{{ route('categories.update', $category->id) }}" method="POST">
                @csrf
                @method('PUT')
                <div class="mb-3">
                    <label class="form-label fw-semibold">Nama</label>
                    <input type="text" name="name" class="form-control rounded-pill" value="{{ old('name', $category->name) }}" required>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Tipe</label>
                    <select name="type" class="form-select rounded-pill" required>
                        <option value="expense" {{ old('type', $category->type) === 'expense' ? 'selected' : '' }}>Pengeluaran</option>
                        <option value="income" {{ old('type', $category->type) === 'income' ? 'selected' : '' }}>Pemasukan</option>
                    </select>
                </div>
                <div class="mb-4">
                    <label class="form-label fw-semibold">Budget Bulanan</label>
                    <input type="number" name="monthly_budget" class="form-control rounded-pill" value="{{ old('monthly_budget', $category->monthly_budget ?? 0) }}" min="0" step="1">
                </div>
                <button type="submit" class="btn btn-dark rounded-pill px-4">Simpan Perubahan</button>
            </form>
        </div>
    </div>
</div>
@endsection
