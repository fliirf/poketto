@extends('layouts.app')

@section('content')
<style>
    @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap');
    
    body {
        font-family: 'Poppins', sans-serif;
        background-color: #f8f9fa;
    }

    .dashboard-container {
        padding: 30px;
        max-width: 1200px;
        margin: 0 auto;
    }

    .welcome-card {
        background: linear-gradient(135deg, #f28f33 0%, #e07e22 100%);
        color: white;
        border-radius: 20px;
        padding: 30px;
        margin-bottom: 30px;
        box-shadow: 0 10px 20px rgba(242, 143, 51, 0.2);
    }

    .stat-card {
        background: white;
        border-radius: 15px;
        padding: 20px;
        border: none;
        box-shadow: 0 4px 6px rgba(0,0,0,0.05);
        transition: transform 0.3s;
    }

    .stat-card:hover {
        transform: translateY(-5px);
    }

    .icon-box {
        width: 50px;
        height: 50px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
        margin-bottom: 15px;
    }

    .btn-logout {
        background-color: rgba(255, 255, 255, 0.2);
        border: 1px solid white;
        color: white;
        border-radius: 30px;
        padding: 8px 20px;
        transition: 0.3s;
    }

    .btn-logout:hover {
        background-color: white;
        color: #f28f33;
    }
</style>

<div class="dashboard-container">
    {{-- Header / Welcome --}}
    <div class="welcome-card d-flex justify-content-between align-items-center">
        <div>
            <h2 class="fw-bold">Halo, {{ Auth::user()->name }}! 👋</h2>
            <p class="mb-0">Siap mengelola keuanganmu hari ini agar tetap makmur?</p>
        </div>
        <form action="{{ route('logout') }}" method="POST">
            @csrf
            <button type="submit" class="btn btn-logout">
                <i class="bi bi-box-arrow-right me-2"></i>Keluar
            </button>
        </form>
    </div>

    <div class="stat-card mb-4">
        <form action="{{ route('dashboard') }}" method="GET" class="row g-3 align-items-end">
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
                <a href="{{ route('dashboard') }}" class="btn btn-light rounded-pill">Reset</a>
            </div>
        </form>
    </div>

    {{-- Row Statistik --}}
    <div class="row">
        <div class="col-md-4 mb-4">
            <div class="stat-card">
                <div class="icon-box bg-success bg-opacity-10 text-success">
                    <i class="bi bi-wallet2"></i>
                </div>
                <h6 class="text-muted small text-uppercase">Total Saldo</h6>
                <h3 class="fw-bold">Rp {{ number_format($totalBalance, 0, ',', '.') }}</h3>
            </div>
        </div>

        <div class="col-md-4 mb-4">
            <div class="stat-card">
                <div class="icon-box bg-danger bg-opacity-10 text-danger">
                    <i class="bi bi-graph-down-arrow"></i>
                </div>
                <h6 class="text-muted small text-uppercase">Pengeluaran Bulan Ini</h6>
                <h3 class="fw-bold text-danger">Rp {{ number_format($monthlyExpense, 0, ',', '.') }}</h3>
            </div>
        </div>

        <div class="col-md-4 mb-4">
            <div class="stat-card">
                <div class="icon-box bg-warning bg-opacity-10 text-warning">
                    <i class="bi bi-lightning-charge"></i>
                </div>
                <h6 class="text-muted small text-uppercase">Financial Health</h6>
                <h3 class="fw-bold text-warning">{{ $healthStatus }}</h3>
            </div>
        </div>
    </div>

    <div class="row mt-4">
        @if(!empty($alerts))
            <div class="col-12 mb-4">
                <div class="stat-card border-start border-warning border-4">
                    <h5 class="fw-bold mb-3">Financial Warning</h5>
                    @foreach($alerts as $alert)
                        <div class="alert alert-warning mb-2">
                            {{ is_array($alert) ? $alert['message'] : $alert->message }}
                        </div>
                    @endforeach
                </div>
            </div>
        @endif

        <div class="col-12">
            <div class="stat-card">
                <h5 class="fw-bold mb-4">Tren Pengeluaran (7 Hari Terakhir)</h5>
                <canvas id="expenseChart" style="max-height: 300px;"></canvas>
            </div>
        </div>
    </div>

    {{-- Aksi Cepat --}}
<div class="mt-4">
    <h5 class="fw-bold mb-3">Aksi Cepat</h5>
    <div class="d-flex gap-3">
        {{-- Tombol Tambah --}}
        <a href="{{ route('transactions.create') }}" class="btn btn-dark rounded-pill px-4 d-flex align-items-center">
            <i class="bi bi-plus-lg me-2"></i> Tambah Transaksi
        </a>

        {{-- Tombol PDF --}}
        {{-- Note: Kita gunakan bulan dan tahun saat ini sebagai default jika di Dashboard --}}
        <a href="{{ route('transactions.export_pdf', ['month' => date('m'), 'year' => date('Y')]) }}" 
           class="btn btn-outline-danger rounded-pill px-4 d-flex align-items-center">
            <i class="bi bi-file-earmark-pdf me-2"></i> Laporan PDF
        </a>
        <a href="{{ route('categories.index') }}" class="btn btn-outline-primary rounded-pill px-4 d-flex align-items-center">
            <i class="bi bi-tags me-2"></i> Kelola Kategori
        </a>
        <a href="{{ route('settings.edit') }}" class="btn btn-outline-secondary rounded-pill px-4 d-flex align-items-center">
            <i class="bi bi-sliders me-2"></i> Settings
        </a>
    </div>
</div>

    {{-- Tabel Riwayat --}}
    <div class="mt-5">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h5 class="fw-bold mb-0">Riwayat Transaksi Terakhir</h5>
            <a href="{{ route('transactions.index') }}" class="text-decoration-none small fw-bold text-primary">
                Lihat Semua <i class="bi bi-arrow-right small"></i>
            </a>
        </div>
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
                        @forelse($recentTransactions as $trx)
                            <tr>
                                <td class="small text-muted">{{ \Carbon\Carbon::parse($trx->date)->format('d M Y') }}</td>
                                <td>
                                    <span class="badge {{ $trx->category->type == 'income' ? 'bg-success' : 'bg-danger' }} bg-opacity-10 {{ $trx->category->type == 'income' ? 'text-success' : 'text-danger' }} rounded-pill px-3">
                                        {{ $trx->category->name }}
                                    </span>
                                </td>
                                <td class="small">{{ Str::limit($trx->description, 30) ?? '-' }}</td>
                                <td class="small text-muted">
                                    {{ $trx->location_name ?: (($trx->location_lat && $trx->location_lng) ? $trx->location_lat.', '.$trx->location_lng : '-') }}
                                </td>
                                <td class="fw-bold text-end {{ $trx->category->type == 'income' ? 'text-success' : 'text-danger' }}">
                                    {{ $trx->category->type == 'income' ? '+' : '-' }} Rp {{ number_format($trx->amount, 0, ',', '.') }}
                                </td>
                                <td class="text-center">
                                    <div class="d-flex justify-content-center gap-2">
                                        {{-- Tombol Edit --}}
                                        <a href="{{ route('transactions.edit', $trx->id) }}" class="btn btn-sm btn-outline-primary border-0">
                                            <i class="bi bi-pencil-square"></i>
                                        </a>

                                        {{-- Tombol Hapus --}}
                                        <form action="{{ route('transactions.destroy', $trx->id) }}" method="POST" onsubmit="return confirm('Yakin mau hapus transaksi ini?')">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="btn btn-sm btn-outline-danger border-0">
                                                <i class="bi bi-trash"></i>
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="text-center py-4 text-muted">
                                    <i class="bi bi-emoji-frown d-block fs-2 mb-2"></i>
                                    Belum ada transaksi. Yuk, mulai mencatat!
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
<script>
    // Memastikan script berjalan SETELAH semua elemen (termasuk Chart.js di layout) dimuat
    document.addEventListener('DOMContentLoaded', function() {
        const ctx = document.getElementById('expenseChart').getContext('2d');
        
        const expenseTrend = @json($expenseTrend ?? []);
        const labels = expenseTrend.map(item => item.label || item.date);
        const dataValues = expenseTrend.map(item => Number(item.total || 0));

        new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Pengeluaran (Rp)',
                    data: dataValues,
                    borderColor: '#f28f33',
                    backgroundColor: 'rgba(242, 143, 51, 0.1)',
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 5,
                    pointBackgroundColor: '#f28f33',
                    pointBorderColor: '#fff',
                    pointHoverRadius: 7
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                let label = context.dataset.label || '';
                                if (label) { label += ': '; }
                                if (context.parsed.y !== null) {
                                    label += 'Rp ' + context.parsed.y.toLocaleString('id-ID');
                                }
                                return label;
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            callback: function(value) {
                                return 'Rp ' + value.toLocaleString('id-ID');
                            }
                        }
                    }
                }
            }
        });
    });
</script>
@endsection
