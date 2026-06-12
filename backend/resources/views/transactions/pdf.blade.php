<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Laporan Keuangan Poketto</title>
    <style>
        @page { margin: 26px; }
        * { box-sizing: border-box; }
        body {
            background: #f3f6fb;
            color: #172033;
            font-family: DejaVu Sans, sans-serif;
            font-size: 10.5px;
            line-height: 1.45;
        }
        .page {
            background: #ffffff;
            border-radius: 18px;
            padding: 22px;
        }
        .muted { color: #8090a7; }
        .income { color: #059669; }
        .expense { color: #dc2626; }
        .dark { color: #111827; }
        .text-right { text-align: right; }
        .header {
            border-bottom: 1px solid #e6edf5;
            margin-bottom: 18px;
            padding-bottom: 16px;
            width: 100%;
        }
        .brand-logo {
            background: #fff3e5;
            border: 1px solid #ffd8ad;
            border-radius: 14px;
            display: inline-block;
            height: 52px;
            object-fit: contain;
            padding: 7px;
            vertical-align: top;
            width: 52px;
        }
        .brand-fallback {
            background: #fff3e5;
            border: 1px solid #ffd8ad;
            border-radius: 14px;
            color: #d76b13;
            display: inline-block;
            font-size: 18px;
            font-weight: 800;
            height: 52px;
            line-height: 50px;
            text-align: center;
            vertical-align: top;
            width: 52px;
        }
        .brand-copy {
            display: inline-block;
            margin-left: 14px;
            vertical-align: top;
        }
        .brand-copy h1 {
            font-size: 24px;
            line-height: 1.1;
            margin: 2px 0 5px;
        }
        .brand-copy p { margin: 0; }
        .report-meta {
            text-align: right;
            vertical-align: top;
            width: 210px;
        }
        .pill {
            background: #fff4e8;
            border-radius: 999px;
            color: #c95f10;
            display: inline-block;
            font-size: 9px;
            font-weight: 700;
            letter-spacing: .5px;
            padding: 5px 10px;
            text-transform: uppercase;
        }
        table { border-collapse: collapse; width: 100%; }
        .stats { border-spacing: 10px 0; border-collapse: separate; margin: 0 -10px 18px; }
        .stat-card {
            background: #f8fafc;
            border: 1px solid #e6edf5;
            border-radius: 16px;
            padding: 13px 14px;
            width: 25%;
        }
        .stat-card small {
            color: #718096;
            display: block;
            font-weight: 700;
            margin-bottom: 7px;
        }
        .stat-card strong {
            display: block;
            font-size: 17px;
            line-height: 1.2;
            white-space: nowrap;
        }
        .section {
            background: #ffffff;
            border: 1px solid #e6edf5;
            border-radius: 16px;
            margin-bottom: 14px;
            padding: 15px;
        }
        .section.soft { background: #f8fafc; }
        .section-title {
            font-size: 13px;
            font-weight: 800;
            margin: 0 0 3px;
        }
        .section-subtitle {
            color: #8090a7;
            font-size: 9.5px;
            margin: 0 0 13px;
        }
        .ratio-row {
            margin-top: 10px;
            width: 100%;
        }
        .ratio-label {
            color: #718096;
            font-size: 9px;
            font-weight: 700;
            margin-bottom: 6px;
        }
        .bar-track {
            background: #e9eef5;
            border-radius: 999px;
            height: 10px;
            overflow: hidden;
            width: 100%;
        }
        .bar-fill {
            border-radius: 999px;
            height: 10px;
        }
        .bar-green { background: #10b981; }
        .bar-orange { background: #f28f33; }
        .bar-red { background: #ef4444; }
        .bar-row { margin-bottom: 10px; }
        .bar-name {
            font-size: 9.5px;
            font-weight: 800;
            margin-bottom: 5px;
        }
        .bar-value {
            float: right;
            font-weight: 800;
        }
        .visual-table { border-spacing: 12px 0; border-collapse: separate; margin: 0 -12px 14px; }
        .visual-cell {
            vertical-align: top;
            width: 50%;
        }
        .trend-wrap {
            height: 150px;
            padding-top: 8px;
        }
        .trend-table {
            border-collapse: separate;
            border-spacing: 4px 0;
            height: 140px;
            table-layout: fixed;
        }
        .trend-cell {
            height: 112px;
            text-align: center;
            vertical-align: bottom;
        }
        .trend-bar {
            background: #f28f33;
            border-radius: 8px 8px 2px 2px;
            display: inline-block;
            min-height: 5px;
            width: 100%;
        }
        .trend-label td {
            color: #8090a7;
            font-size: 8px;
            font-weight: 700;
            padding-top: 6px;
            text-align: center;
        }
        .trend-amount td {
            color: #172033;
            font-size: 7.5px;
            font-weight: 800;
            height: 18px;
            text-align: center;
            vertical-align: bottom;
        }
        .expense-list {
            background: #f8fafc;
            border-radius: 14px;
            padding: 12px;
        }
        .empty {
            background: #f8fafc;
            border: 1px dashed #dbe4ef;
            border-radius: 14px;
            color: #8090a7;
            padding: 18px;
            text-align: center;
        }
        .transactions thead th {
            background: #172033;
            color: #ffffff;
            font-size: 8.8px;
            letter-spacing: .4px;
            padding: 10px 9px;
            text-align: left;
            text-transform: uppercase;
        }
        .transactions thead th:first-child { border-radius: 12px 0 0 12px; }
        .transactions thead th:last-child { border-radius: 0 12px 12px 0; }
        .transactions tbody td {
            border-bottom: 1px solid #e9eef5;
            padding: 11px 9px;
            vertical-align: top;
        }
        .transactions tbody tr:nth-child(even) td { background: #f8fafc; }
        .category-chip {
            background: #e8fff4;
            border-radius: 999px;
            color: #047857;
            display: inline-block;
            font-size: 8.5px;
            font-weight: 800;
            padding: 4px 8px;
            white-space: nowrap;
        }
        .category-chip.expense-chip {
            background: #fff1f2;
            color: #be123c;
        }
        .description {
            color: #172033;
            font-weight: 700;
            margin-bottom: 3px;
        }
        .location {
            color: #8090a7;
            font-size: 9px;
        }
        .footer {
            color: #94a3b8;
            font-size: 8.5px;
            margin-top: 15px;
            text-align: center;
        }
    </style>
</head>
<body>
    @php
        $balance = $income - $expense;
        $totalTransactions = $transactions->count();
        $expenseRatio = $income > 0 ? min(100, ($expense / $income) * 100) : ($expense > 0 ? 100 : 0);
        $realExpenseRatio = $income > 0 ? ($expense / $income) * 100 : ($expense > 0 ? 100 : 0);
        $maxCategory = max($categoryBreakdown->max('total') ?? 0, 1);
        $maxDaily = max($dailyTrend->max('total') ?? 0, 1);
        $currencyRate = (float) ($currencyRate ?? 1);
        $fractionDigits = in_array(strtoupper($currency), ['IDR', 'JPY'], true) ? 0 : 2;
        $money = fn ($value) => $currency.' '.number_format(((float) $value) * $currencyRate, $fractionDigits, ',', '.');
        $periodLabel = trim($monthName.' '.$year);
        $generatedAt = now()->timezone(config('app.timezone', 'Asia/Jakarta'))->format('d M Y H:i');
    @endphp

    <div class="page">
        <table class="header">
            <tr>
                <td>
                    @if(! empty($logoPath) && file_exists($logoPath))
                        <img class="brand-logo" src="{{ $logoPath }}" alt="Poketto">
                    @else
                        <span class="brand-fallback">PO</span>
                    @endif
                    <div class="brand-copy">
                        <h1>Laporan Keuangan</h1>
                        <p class="muted">Ringkasan transaksi, tren, dan komposisi pengeluaran.</p>
                    </div>
                </td>
                <td class="report-meta">
                    <span class="pill">Financial report</span>
                    <p class="dark" style="font-weight: 800; margin: 10px 0 2px;">{{ $periodLabel }}</p>
                    <p class="muted" style="margin: 0;">Dibuat {{ $generatedAt }}</p>
                </td>
            </tr>
        </table>

        <table class="stats">
            <tr>
                <td class="stat-card">
                    <small>Total pemasukan</small>
                    <strong class="income">{{ $money($income) }}</strong>
                </td>
                <td class="stat-card">
                    <small>Total pengeluaran</small>
                    <strong class="expense">{{ $money($expense) }}</strong>
                </td>
                <td class="stat-card">
                    <small>Saldo periode</small>
                    <strong class="dark">{{ $money($balance) }}</strong>
                </td>
                <td class="stat-card">
                    <small>Total transaksi</small>
                    <strong class="dark">{{ $totalTransactions }}</strong>
                </td>
            </tr>
        </table>

        <div class="section soft">
            <table>
                <tr>
                    <td style="width: 68%; vertical-align: top;">
                        <h2 class="section-title">Ringkasan pemasukan vs pengeluaran</h2>
                        <p class="section-subtitle">Rasio pengeluaran terhadap pemasukan pada periode ini.</p>
                    </td>
                    <td class="text-right" style="vertical-align: top;">
                        <span class="pill">Rasio {{ number_format($realExpenseRatio, 0) }}%</span>
                    </td>
                </tr>
            </table>
            <div class="ratio-row">
                <div class="ratio-label">
                    Pengeluaran {{ $money($expense) }} dari pemasukan {{ $money($income) }}
                    <span style="float: right;">{{ number_format($realExpenseRatio, 0) }}%</span>
                </div>
                <div class="bar-track">
                    <div class="bar-fill {{ $realExpenseRatio > 100 ? 'bar-red' : 'bar-orange' }}" style="width: {{ $expenseRatio > 0 ? max(3, $expenseRatio) : 0 }}%;"></div>
                </div>
            </div>
            @if($realExpenseRatio > 100)
                <p class="expense" style="font-size: 9px; font-weight: 800; margin: 8px 0 0;">Pengeluaran melebihi pemasukan pada periode ini.</p>
            @endif
        </div>

        <table class="visual-table">
            <tr>
                <td class="visual-cell">
                    <div class="section">
                        <h2 class="section-title">Komposisi pengeluaran</h2>
                        <p class="section-subtitle">Pengeluaran berdasarkan kategori.</p>
                        @forelse($categoryBreakdown as $item)
                            <div class="bar-row">
                                <div class="bar-name">
                                    {{ $item['category'] }}
                                    <span class="bar-value">{{ $money($item['total']) }}</span>
                                </div>
                                <div class="bar-track">
                                    <div class="bar-fill bar-green" style="width: {{ max(4, ($item['total'] / $maxCategory) * 100) }}%;"></div>
                                </div>
                            </div>
                        @empty
                            <div class="empty">Belum ada data pengeluaran pada periode ini.</div>
                        @endforelse
                    </div>
                </td>
                <td class="visual-cell">
                    <div class="section">
                        <h2 class="section-title">Tren pengeluaran harian</h2>
                        <p class="section-subtitle">Pergerakan nominal pengeluaran per tanggal.</p>
                        @if($dailyTrend->isNotEmpty())
                            <div class="trend-wrap">
                                <table class="trend-table">
                                    <tr class="trend-amount">
                                        @foreach($dailyTrend->take(10) as $item)
                                            <td>{{ $money($item['total']) }}</td>
                                        @endforeach
                                    </tr>
                                    <tr>
                                        @foreach($dailyTrend->take(10) as $item)
                                            <td class="trend-cell">
                                                <span class="trend-bar" style="height: {{ max(6, ($item['total'] / $maxDaily) * 100) }}px;"></span>
                                            </td>
                                        @endforeach
                                    </tr>
                                    <tr class="trend-label">
                                        @foreach($dailyTrend->take(10) as $item)
                                            <td>{{ $item['label'] }}</td>
                                        @endforeach
                                    </tr>
                                </table>
                            </div>
                        @else
                            <div class="empty">Belum ada tren pengeluaran pada periode ini.</div>
                        @endif
                    </div>
                </td>
            </tr>
        </table>

        <div class="section">
            <h2 class="section-title">Daftar transaksi</h2>
            <p class="section-subtitle">Detail transaksi yang masuk ke laporan ini.</p>
            <table class="transactions">
                <thead>
                    <tr>
                        <th style="width: 13%;">Tanggal</th>
                        <th style="width: 16%;">Kategori</th>
                        <th style="width: 31%;">Catatan dan lokasi</th>
                        <th style="width: 16%;">Tipe</th>
                        <th class="text-right" style="width: 24%;">Nominal</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($transactions as $trx)
                        @php($type = $trx->type ?: $trx->category?->type)
                        <tr>
                            <td>{{ \Carbon\Carbon::parse($trx->transaction_date ?? $trx->date)->format('d M Y') }}</td>
                            <td>
                                <span class="category-chip {{ $type === 'expense' ? 'expense-chip' : '' }}">
                                    {{ $trx->category?->name ?? 'Tanpa kategori' }}
                                </span>
                            </td>
                            <td>
                                <div class="description">{{ $trx->description ?: '-' }}</div>
                                <div class="location">{{ $trx->location_name ?: 'Lokasi tidak diisi' }}</div>
                            </td>
                            <td>{{ $type === 'income' ? 'Pemasukan' : 'Pengeluaran' }}</td>
                            <td class="text-right {{ $type === 'income' ? 'income' : 'expense' }}" style="font-weight: 800;">
                                {{ $type === 'income' ? '+' : '-' }} {{ $money($trx->amount) }}
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5">
                                <div class="empty">Belum ada transaksi pada periode ini.</div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="footer">
            Poketto Finance Dashboard - laporan ini dibuat otomatis dari data transaksi pengguna.
        </div>
    </div>
</body>
</html>
