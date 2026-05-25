@extends('layouts.app')

@section('content')
<div class="container py-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h3 class="fw-bold mb-0">Laporan Transaksi</h3>
        <a href="{{ route('transactions.create') }}" class="btn btn-dark rounded-pill px-4">+ Tambah</a>
    </div>

    {{-- Form Filter --}}
    <div class="card border-0 shadow-sm mb-4" style="border-radius: 15px;">
        <div class="card-body p-4">
            <form action="{{ route('transactions.index') }}" method="GET" class="row g-3 align-items-end">
                <div class="col-md-2">
                    <label class="form-label small fw-bold text-muted">Start Date</label>
                    <input type="date" name="start_date" class="form-control rounded-pill" value="{{ $filters['start_date'] ?? request('start_date') }}">
                </div>
                <div class="col-md-2">
                    <label class="form-label small fw-bold text-muted">End Date</label>
                    <input type="date" name="end_date" class="form-control rounded-pill" value="{{ $filters['end_date'] ?? request('end_date') }}">
                </div>
                <div class="col-md-2">
                    <label class="form-label small fw-bold text-muted">Bulan</label>
                    <input type="month" name="month" class="form-control rounded-pill" value="{{ $filters['month'] ?? request('month') }}">
                </div>
                <div class="col-md-2">
                    <label class="form-label small fw-bold text-muted">Kategori</label>
                    <select name="category_id" class="form-select rounded-pill">
                        <option value="">Semua</option>
                        @foreach($categories as $category)
                            <option value="{{ $category->id }}" {{ (string)($filters['category_id'] ?? request('category_id')) === (string)$category->id ? 'selected' : '' }}>
                                {{ $category->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-2">
                    <label class="form-label small fw-bold text-muted">Tipe</label>
                    <select name="type" class="form-select rounded-pill">
                        <option value="">Semua</option>
                        <option value="expense" {{ ($filters['type'] ?? request('type')) === 'expense' ? 'selected' : '' }}>Expense</option>
                        <option value="income" {{ ($filters['type'] ?? request('type')) === 'income' ? 'selected' : '' }}>Income</option>
                    </select>
                </div>
                <div class="col-md-2 d-flex gap-2">
                    <button type="submit" class="btn btn-primary rounded-pill w-100">Filter</button>
                    <a href="{{ route('transactions.index') }}" class="btn btn-light rounded-pill">Reset</a>
                </div>
            </form>
        </div>
    </div>

    {{-- Ringkasan Filter --}}
    <div class="row mb-4">
        <div class="col-md-6">
            <div class="p-3 bg-success bg-opacity-10 border border-success border-opacity-25 rounded-4 text-center">
                <p class="small text-success mb-1 fw-bold">Pemasukan Bulan Ini</p>
                <h4 class="fw-bold text-success mb-0">Rp {{ number_format($monthlyIncome, 0, ',', '.') }}</h4>
            </div>
        </div>
        <div class="col-md-6">
            <div class="p-3 bg-danger bg-opacity-10 border border-danger border-opacity-25 rounded-4 text-center">
                <p class="small text-danger mb-1 fw-bold">Pengeluaran Bulan Ini</p>
                <h4 class="fw-bold text-danger mb-0">Rp {{ number_format($monthlyExpense, 0, ',', '.') }}</h4>
            </div>
        </div>
    </div>

    {{-- Tabel Transaksi --}}
    <div class="card border-0 shadow-sm" style="border-radius: 15px;">
        <div class="table-responsive p-3">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th>Tanggal</th>
                        <th>Kategori</th>
                        <th>Keterangan</th>
                        <th>Lokasi</th>
                        <th class="text-end">Nominal</th>
                        <th class="text-center">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($transactions as $trx)
                        <tr>
                            <td>{{ \Carbon\Carbon::parse($trx->date)->format('d M Y') }}</td>
                            <td>
                                <span class="badge {{ $trx->category->type == 'income' ? 'bg-success' : 'bg-danger' }} bg-opacity-10 {{ $trx->category->type == 'income' ? 'text-success' : 'text-danger' }} rounded-pill px-3">
                                    {{ $trx->category->name }}
                                </span>
                            </td>
                            <td class="text-muted small">{{ $trx->description ?? '-' }}</td>
                            <td class="text-muted small">
                                {{ $trx->location_name ?: (($trx->location_lat && $trx->location_lng) ? $trx->location_lat.', '.$trx->location_lng : '-') }}
                            </td>
                            <td class="fw-bold text-end {{ $trx->category->type == 'income' ? 'text-success' : 'text-danger' }}">
                                {{ $trx->category->type == 'income' ? '+' : '-' }} Rp {{ number_format($trx->amount, 0, ',', '.') }}
                            </td>
                            <td class="text-center">
                                <div class="d-flex justify-content-center gap-2">
                                    <a href="{{ route('transactions.edit', $trx->id) }}" class="btn btn-sm btn-outline-primary border-0">
                                        <i class="bi bi-pencil-square"></i>
                                    </a>
                                    <form action="{{ route('transactions.destroy', $trx->id) }}" method="POST" onsubmit="return confirm('Hapus transaksi?')">
                                        @csrf @method('DELETE')
                                        <button type="submit" class="btn btn-sm btn-outline-danger border-0">
                                            <i class="bi bi-trash"></i>
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="text-center py-5 text-muted">
                                Tidak ada transaksi pada periode ini.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
