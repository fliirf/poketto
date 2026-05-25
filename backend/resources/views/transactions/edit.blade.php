@extends('layouts.app')

@section('content')
<div class="container" style="max-width: 600px;">
    <div class="card border-0 shadow-sm" style="border-radius: 20px;">
        <div class="card-body p-4">
            <div class="d-flex align-items-center mb-4">
                <a href="{{ route('dashboard') }}" class="btn btn-light rounded-circle me-3">
                    <i class="bi bi-arrow-left"></i>
                </a>
                <h4 class="fw-bold mb-0">Edit Transaksi</h4>
            </div>
            
            <form action="{{ route('transactions.update', $transaction->id) }}" method="POST">
                @csrf
                @method('PUT') {{-- PENTING: Untuk update data di Laravel --}}

                <div class="mb-3">
                    <label class="form-label fw-semibold">Tipe</label>
                    <select name="type" class="form-select rounded-pill" required>
                        <option value="expense" {{ old('type', $transaction->type ?: $transaction->category?->type) === 'expense' ? 'selected' : '' }}>Pengeluaran</option>
                        <option value="income" {{ old('type', $transaction->type ?: $transaction->category?->type) === 'income' ? 'selected' : '' }}>Pemasukan</option>
                    </select>
                </div>
                
                <div class="mb-3">
                    <label class="form-label fw-semibold">Jumlah (Rp)</label>
                    <input type="number" name="amount" class="form-control form-control-lg rounded-pill" 
                           value="{{ old('amount', $transaction->amount) }}" placeholder="Contoh: 50000" min="1" step="1" required>
                </div>

                <div class="mb-3">
                    <label class="form-label fw-semibold">Kategori</label>
                    <select name="category_id" class="form-select rounded-pill" required>
                        @foreach($categories as $category)
                            <option value="{{ $category->id }}" {{ old('category_id', $transaction->category_id) == $category->id ? 'selected' : '' }}>
                                {{ $category->name }} ({{ $category->type == 'income' ? 'Masuk' : 'Keluar' }})
                            </option>
                        @endforeach
                    </select>
                </div>

                <div class="mb-3">
                    <label class="form-label fw-semibold">Tanggal</label>
                    <input type="datetime-local" name="transaction_date" class="form-control rounded-pill" 
                           value="{{ old('transaction_date', \Carbon\Carbon::parse($transaction->transaction_date ?? $transaction->date)->format('Y-m-d\TH:i')) }}" required>
                </div>

                <div class="mb-4">
                    <label class="form-label fw-semibold">Catatan (Opsional)</label>
                    <textarea name="description" class="form-control" rows="3" 
                              style="border-radius: 15px;" placeholder="Beli nasi padang...">{{ old('description', $transaction->description) }}</textarea>
                </div>

                <div class="d-grid">
                    <button type="submit" class="btn btn-dark btn-lg rounded-pill py-3 fw-bold">Simpan Perubahan</button>
                    <a href="{{ route('dashboard') }}" class="btn btn-link text-decoration-none text-muted mt-2 text-center">Batal</a>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
