<!DOCTYPE html>
<html>
<head>
    <title>Laporan Keuangan Poketto</title>
    <style>
        @page { margin: 28px; }
        body { color: #172033; font-family: DejaVu Sans, sans-serif; font-size: 11px; }
        .brand { border-bottom: 3px solid #f28f33; margin-bottom: 18px; padding-bottom: 14px; }
        .logo { background: #fff3e5; border-radius: 12px; color: #d76b13; display: inline-block; font-size: 18px; font-weight: 800; padding: 9px 12px; }
        .title { display: inline-block; margin-left: 10px; vertical-align: top; }
        .title h1 { font-size: 22px; margin: 0 0 4px; }
        .title p { color: #667085; margin: 0; }
        .summary-grid { margin: 18px 0; width: 100%; }
        .summary-card { background: #f8fafc; border: 1px solid #e5e7eb; border-radius: 12px; padding: 12px; width: 31%; }
        .summary-card small { color: #667085; display: block; font-weight: 700; margin-bottom: 6px; }
        .summary-card strong { font-size: 16px; }
        .income { color: #059669; }
        .expense { color: #dc2626; }
        .balance { color: #0f172a; }
        table { border-collapse: collapse; margin-top: 12px; width: 100%; }
        th { background: #f1f5f9; color: #64748b; font-size: 10px; padding: 9px; text-align: left; text-transform: uppercase; }
        td { border-bottom: 1px solid #e5e7eb; padding: 9px; }
        .text-end { text-align: right; }
        .section-title { font-size: 15px; margin: 20px 0 8px; }
        .bar-row { margin-bottom: 10px; }
        .bar-label { margin-bottom: 4px; }
        .bar-track { background: #f1f5f9; border-radius: 999px; height: 10px; overflow: hidden; width: 100%; }
        .bar-fill { background: #f28f33; height: 10px; }
        .empty { background: #f8fafc; border-radius: 12px; color: #667085; padding: 14px; text-align: center; }
    </style>
</head>
<body>
    @php
        $balance = $income - $expense;
        $maxCategory = max($categoryBreakdown->max('total') ?? 0, 1);
        $money = fn ($value) => $currency.' '.number_format((float) $value, 0, ',', '.');
    @endphp

    <div class="brand">
        <div class="logo">P</div>
        <div class="title">
            <h1>Laporan Keuangan Poketto</h1>
            <p>Periode: {{ trim($monthName.' '.$year) }}</p>
        </div>
    </div>

    <table class="summary-grid">
        <tr>
            <td class="summary-card">
                <small>Total Pemasukan</small>
                <strong class="income">{{ $money($income) }}</strong>
            </td>
            <td style="width: 3%; border: 0;"></td>
            <td class="summary-card">
                <small>Total Pengeluaran</small>
                <strong class="expense">{{ $money($expense) }}</strong>
            </td>
            <td style="width: 3%; border: 0;"></td>
            <td class="summary-card">
                <small>Saldo Akhir</small>
                <strong class="balance">{{ $money($balance) }}</strong>
            </td>
        </tr>
    </table>

    <h2 class="section-title">Visualisasi Pengeluaran per Kategori</h2>
    @forelse($categoryBreakdown as $item)
        <div class="bar-row">
            <div class="bar-label">
                <strong>{{ $item['category'] }}</strong>
                <span style="float: right;">{{ $money($item['total']) }}</span>
            </div>
            <div class="bar-track">
                <div class="bar-fill" style="width: {{ max(4, ($item['total'] / $maxCategory) * 100) }}%;"></div>
            </div>
        </div>
    @empty
        <div class="empty">Belum ada data pengeluaran pada periode ini.</div>
    @endforelse

    <h2 class="section-title">Daftar Transaksi</h2>
    <table>
        <thead>
            <tr>
                <th>Tanggal</th>
                <th>Kategori</th>
                <th>Keterangan</th>
                <th>Lokasi</th>
                <th class="text-end">Nominal</th>
            </tr>
        </thead>
        <tbody>
            @forelse($transactions as $trx)
                @php($type = $trx->type ?: $trx->category?->type)
                <tr>
                    <td>{{ \Carbon\Carbon::parse($trx->transaction_date ?? $trx->date)->format('d/m/Y') }}</td>
                    <td>{{ $trx->category?->name ?? 'Tanpa kategori' }}</td>
                    <td>{{ $trx->description ?? '-' }}</td>
                    <td>{{ $trx->location_name ?? '-' }}</td>
                    <td class="text-end {{ $type == 'income' ? 'income' : 'expense' }}">
                        {{ $type == 'income' ? '+' : '-' }} {{ $money($trx->amount) }}
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="5" class="empty">Belum ada transaksi pada periode ini.</td>
                </tr>
            @endforelse
        </tbody>
    </table>
</body>
</html>
