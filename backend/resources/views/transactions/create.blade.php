@extends('layouts.app')

@section('content')
<div class="container" style="max-width: 600px;">
    <div class="card border-0 shadow-sm" style="border-radius: 20px;">
        <div class="card-body p-4">
            <h4 class="fw-bold mb-4 text-center">Catat Transaksi Baru</h4>
            
            <form action="{{ route('transactions.store') }}" method="POST">
                @csrf

                <div class="mb-3">
                    <label class="form-label fw-semibold">Tipe</label>
                    <select name="type" class="form-select rounded-pill" required>
                        <option value="expense" {{ old('type') === 'expense' ? 'selected' : '' }}>Pengeluaran</option>
                        <option value="income" {{ old('type') === 'income' ? 'selected' : '' }}>Pemasukan</option>
                    </select>
                </div>
                
                <div class="mb-3">
                    <label class="form-label fw-semibold">Jumlah (Rp)</label>
                    <input type="number" name="amount" class="form-control form-control-lg rounded-pill" placeholder="Contoh: 50000" value="{{ old('amount') }}" min="1" step="1" required>
                </div>

                <div class="mb-3">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <label class="form-label fw-semibold mb-0">Kategori</label>
                        <button type="button" class="btn btn-sm btn-outline-primary rounded-pill px-3" data-bs-toggle="modal" data-bs-target="#modalTambahKategori">
                            <i class="bi bi-plus-lg"></i> Kategori Baru
                        </button>
                    </div>
                    <select name="category_id" class="form-select rounded-pill" required>
                        <option value="" disabled selected>Pilih Kategori</option>
                        @foreach($categories as $category)
                            <option value="{{ $category->id }}" {{ old('category_id') == $category->id ? 'selected' : '' }}>
                                {{ $category->name }} ({{ $category->type == 'income' ? 'Masuk' : 'Keluar' }})
                            </option>
                        @endforeach
                    </select>
                </div>

                <div class="mb-3">
                    <label class="form-label fw-semibold">Tanggal</label>
                    <input type="datetime-local" name="transaction_date" class="form-control rounded-pill" value="{{ old('transaction_date', now()->format('Y-m-d\TH:i')) }}" required>
                </div>

                <div class="mb-4">
                    <label class="form-label fw-semibold">Catatan (Opsional)</label>
                    <textarea name="description" class="form-control" rows="3" style="border-radius: 15px;" placeholder="Beli nasi padang...">{{ old('description') }}</textarea>
                </div>

                <div class="d-grid">
                    <button type="submit" class="btn btn-dark btn-lg rounded-pill py-3 fw-bold">Simpan Transaksi</button>
                    <a href="/dashboard" class="btn btn-link text-decoration-none text-muted mt-2 text-center">Batal</a>
                </div>
            </form>
        </div>
    </div>
</div>

<div class="modal fade" id="modalTambahKategori" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content" style="border-radius: 20px; border: none;">
            <div class="modal-header border-0 px-4 pt-4">
                <h5 class="fw-bold">Tambah Kategori Baru</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form action="{{ route('categories.store') }}" method="POST">
                @csrf
                <div class="modal-body px-4">
                    <div class="mb-3">
                        <label class="form-label">Nama Kategori</label>
                        <input type="text" name="name" class="form-control rounded-pill" placeholder="Contoh: Kopi, Listrik, Freelance" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Tipe</label>
                        <select name="type" class="form-select rounded-pill" required>
                            <option value="expense">Pengeluaran (Expense)</option>
                            <option value="income">Pemasukan (Income)</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Budget Bulanan</label>
                        <input type="number" name="monthly_budget" class="form-control rounded-pill" placeholder="Contoh: 500000" min="0" step="1">
                    </div>
                </div>
                <div class="modal-footer border-0 px-4 pb-4">
                    <button type="button" class="btn btn-light rounded-pill px-4" data-bs-dismiss="modal">Tutup</button>
                    <button type="submit" class="btn btn-primary rounded-pill px-4">Simpan Kategori</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
