<!DOCTYPE html>
<html>
<head>
    <title>Laporan Keuangan Poketto</title>
    <style>
        body { font-family: sans-serif; font-size: 12px; }
        .header { text-align: center; margin-bottom: 30px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        table, th, td { border: 1px solid #ddd; padding: 8px; }
        th { background-color: #f2f2f2; text-align: left; }
        .text-end { text-align: right; }
        .summary { margin-top: 20px; padding: 10px; background: #f9f9f9; }
        .income { color: green; }
        .expense { color: red; }
    </style>
</head>
<body>
    <div class="header">
        <h2>Laporan Keuangan POKETTO</h2>
        <p>Periode: {{ $monthName }} {{ $year }}</p>
    </div>

    <table>
        <thead>
            <tr>
                <th>Tanggal</th>
                <th>Kategori</th>
                <th>Keterangan</th>
                <th class="text-end">Nominal</th>
            </tr>
        </thead>
        <tbody>
            @foreach($transactions as $trx)
            <tr>
                @php($type = $trx->type ?: $trx->category?->type)
                <td>{{ \Carbon\Carbon::parse($trx->transaction_date ?? $trx->date)->format('d/m/Y') }}</td>
                <td>{{ $trx->category?->name ?? 'Tanpa kategori' }} ({{ ucfirst($type) }})</td>
                <td>{{ $trx->description ?? '-' }}</td>
                <td class="text-end">
                    {{ $type == 'income' ? '+' : '-' }} Rp {{ number_format($trx->amount, 0, ',', '.') }}
                </td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <div class="summary">
        <p>Total Pemasukan: <span class="income">Rp {{ number_format($income, 0, ',', '.') }}</span></p>
        <p>Total Pengeluaran: <span class="expense">Rp {{ number_format($expense, 0, ',', '.') }}</span></p>
        <hr>
        <p><strong>Saldo Akhir: Rp {{ number_format($income - $expense, 0, ',', '.') }}</strong></p>
    </div>
</body>
</html>
