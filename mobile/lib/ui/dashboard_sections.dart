import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/data/models/exchange_rate_model.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/app_widgets.dart';

const dashboardChartColors = <Color>[
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF8B5CF6),
  Color(0xFF06B6D4),
  Color(0xFFEC4899),
  Color(0xFF64748B),
  Color(0xFF3B82F6),
];

enum BudgetHealth { unset, safe, warning, reached, exceeded }

class BudgetMetrics {
  final double limit;
  final double spent;
  final double remaining;
  final double percentage;
  final double threshold;

  const BudgetMetrics({
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.threshold,
  });

  factory BudgetMetrics.resolve({
    double? limit,
    double? spent,
    double? remaining,
    double? percentage,
    double threshold = 80,
  }) {
    final safeLimit = _finiteNonNegative(limit);
    final safeSpent = _finiteNonNegative(spent);
    final computedPercentage =
        safeLimit > 0 ? safeSpent / safeLimit * 100 : 0.0;
    return BudgetMetrics(
      limit: safeLimit,
      spent: safeSpent,
      remaining: remaining != null && remaining.isFinite
          ? math.max(0, remaining)
          : math.max(0, safeLimit - safeSpent),
      percentage: percentage != null && percentage.isFinite
          ? math.max(0, percentage)
          : computedPercentage,
      threshold: threshold.isFinite ? threshold.clamp(1, 100).toDouble() : 80,
    );
  }

  BudgetHealth get health {
    if (limit <= 0) return BudgetHealth.unset;
    if (spent > limit) return BudgetHealth.exceeded;
    if (spent == limit) return BudgetHealth.reached;
    if (percentage >= threshold) return BudgetHealth.warning;
    return BudgetHealth.safe;
  }

  double get progress => (percentage / 100).clamp(0, 1).toDouble();

  static double _finiteNonNegative(double? value) =>
      value != null && value.isFinite ? math.max(0, value) : 0;
}

class DashboardBudgetCard extends StatelessWidget {
  final String title;
  final String periodLabel;
  final BudgetMetrics metrics;
  final String Function(double) formatAmount;

  const DashboardBudgetCard({
    super.key,
    required this.title,
    required this.periodLabel,
    required this.metrics,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final color = _healthColor(context, metrics.health);
    final status = switch (metrics.health) {
      BudgetHealth.unset => 'Belum diatur',
      BudgetHealth.safe => 'Aman',
      BudgetHealth.warning => 'Mendekati threshold',
      BudgetHealth.reached => 'Limit tercapai',
      BudgetHealth.exceeded => 'Melebihi limit',
    };
    return AppCard(
      key: ValueKey('budget-$title'),
      padding: const EdgeInsets.all(PokettoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(periodLabel,
                        style: TextStyle(
                            color: context.poketto.mutedText, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: PokettoSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BudgetValue(label: 'Limit', value: formatAmount(metrics.limit)),
              _BudgetValue(
                  label: 'Terpakai', value: formatAmount(metrics.spent)),
              _BudgetValue(
                  label: 'Sisa', value: formatAmount(metrics.remaining)),
            ],
          ),
          const SizedBox(height: PokettoSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: metrics.progress,
              color: color,
              backgroundColor: context.poketto.softSurface,
            ),
          ),
          const SizedBox(height: PokettoSpacing.sm),
          Text(
            metrics.limit <= 0
                ? 'Atur budget melalui Settings.'
                : '${metrics.percentage.toStringAsFixed(0)}% terpakai · peringatan mulai ${metrics.threshold.toStringAsFixed(0)}%',
            style: TextStyle(color: context.poketto.mutedText, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Color _healthColor(BuildContext context, BudgetHealth health) =>
      switch (health) {
        BudgetHealth.safe => context.poketto.income,
        BudgetHealth.warning => context.poketto.warning,
        BudgetHealth.reached ||
        BudgetHealth.exceeded =>
          context.poketto.expense,
        BudgetHealth.unset => context.poketto.mutedText,
      };
}

class _BudgetValue extends StatelessWidget {
  final String label;
  final String value;

  const _BudgetValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 92),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: context.poketto.softSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: context.poketto.mutedText, fontSize: 10.5)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class ExpenseCompositionCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String Function(double) formatAmount;

  const ExpenseCompositionCard({
    super.key,
    required this.items,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final entries = items
        .map((item) => CompositionEntry(
              name: readString(item['category'] ??
                      item['category_name'] ??
                      item['name']) ??
                  'Lainnya',
              amount:
                  math.max(0, readDouble(item['total'] ?? item['amount']) ?? 0),
            ))
        .where((item) => item.amount > 0)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final total = entries.fold<double>(0, (sum, item) => sum + item.amount);

    return AppCard(
      key: const ValueKey('expense-composition-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Komposisi pengeluaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Proporsi per kategori pada periode aktif',
              style: TextStyle(color: context.poketto.mutedText, fontSize: 12)),
          const SizedBox(height: PokettoSpacing.lg),
          if (entries.isEmpty || total <= 0)
            _EmptySection(
                icon: Icons.donut_large_rounded,
                message: 'Belum ada pengeluaran pada periode ini.')
          else ...[
            Center(
              child: SizedBox(
                width: 164,
                height: 164,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      key: const ValueKey('expense-donut-chart'),
                      size: const Size.square(164),
                      painter: DonutChartPainter(entries: entries),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total',
                            style: TextStyle(
                                color: context.poketto.mutedText,
                                fontSize: 11)),
                        const SizedBox(height: 3),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 112),
                          child: FittedBox(
                            child: Text(formatAmount(total),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: PokettoSpacing.lg),
            ...entries.asMap().entries.map((indexed) {
              final item = indexed.value;
              final percentage = total > 0 ? item.amount / total * 100 : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dashboardChartColors[
                            indexed.key % dashboardChartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Text('${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: context.poketto.mutedText,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 118),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          formatAmount(item.amount),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class CompositionEntry {
  final String name;
  final double amount;

  const CompositionEntry({required this.name, required this.amount});
}

class DonutChartPainter extends CustomPainter {
  final List<CompositionEntry> entries;

  DonutChartPainter({required this.entries});

  @override
  void paint(Canvas canvas, Size size) {
    final total = entries.fold<double>(0, (sum, item) => sum + item.amount);
    if (total <= 0 || size.isEmpty) return;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;
    for (var index = 0; index < entries.length; index++) {
      final sweep = entries[index].amount / total * math.pi * 2;
      final paint = Paint()
        ..color = dashboardChartColors[index % dashboardChartColors.length]
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = 28;
      canvas.drawArc(rect, start, math.max(0, sweep - .018), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) =>
      oldDelegate.entries != entries;
}

class ExpenseTrendCard extends StatefulWidget {
  final List<Map<String, dynamic>> points;
  final String periodLabel;
  final String Function(double) formatAmount;

  const ExpenseTrendCard({
    super.key,
    required this.points,
    required this.periodLabel,
    required this.formatAmount,
  });

  @override
  State<ExpenseTrendCard> createState() => _ExpenseTrendCardState();
}

class _ExpenseTrendCardState extends State<ExpenseTrendCard> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final points = widget.points.map(TrendEntry.fromMap).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final hasExpense = points.any((point) => point.amount > 0);
    final total = points.fold<double>(0, (sum, point) => sum + point.amount);
    final average = points.isEmpty ? 0.0 : total / points.length;
    final barWidth = points.length > 14 ? 28.0 : 38.0;
    final chartWidth = math.max(
        MediaQuery.sizeOf(context).width - 72, points.length * barWidth);

    return AppCard(
      key: const ValueKey('expense-trend-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tren pengeluaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(widget.periodLabel,
              style: TextStyle(color: context.poketto.mutedText, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TrendMetric(label: 'Total', value: widget.formatAmount(total)),
              _TrendMetric(
                  label: 'Rata-rata', value: widget.formatAmount(average)),
            ],
          ),
          const SizedBox(height: PokettoSpacing.md),
          if (!hasExpense)
            _EmptySection(
                icon: Icons.bar_chart_rounded,
                message: 'Belum ada pengeluaran pada periode ini.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                height: 204,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxValue = points
                        .map((point) => point.amount)
                        .fold<double>(1, math.max);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: points.asMap().entries.map((indexed) {
                        final selected = selectedIndex == indexed.key;
                        final point = indexed.value;
                        final height = point.amount <= 0
                            ? 5.0
                            : 130 * point.amount / maxValue;
                        final interval = points.length > 21
                            ? 5
                            : points.length > 10
                                ? 3
                                : 1;
                        final showLabel = indexed.key % interval == 0 ||
                            indexed.key == points.length - 1;
                        return SizedBox(
                          width: barWidth,
                          child: InkWell(
                            key: ValueKey('trend-bar-${indexed.key}'),
                            onTap: () => setState(() {
                              selectedIndex = selected ? null : indexed.key;
                            }),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: 42,
                                  child: selected
                                      ? FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${DateFormat('d MMM', 'id_ID').format(point.date)}\n${widget.formatAmount(point.amount)}',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: selected ? 22 : 17,
                                  height: math.max(5, height),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(.62),
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(7)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 28,
                                  child: showLabel
                                      ? Text(
                                          DateFormat('d MMM', 'id_ID')
                                              .format(point.date),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: context.poketto.mutedText,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TrendEntry {
  final DateTime date;
  final double amount;

  const TrendEntry({required this.date, required this.amount});

  factory TrendEntry.fromMap(Map<String, dynamic> map) => TrendEntry(
        date: readDateTime(map['date']) ?? DateTime(1970),
        amount: math.max(0, readDouble(map['total'] ?? map['amount']) ?? 0),
      );
}

class _TrendMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TrendMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: context.poketto.softSurface,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text('$label: $value',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

class CurrencyConverterCard extends StatefulWidget {
  final List<ExchangeRateModel> rates;
  final String preferredCurrency;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const CurrencyConverterCard({
    super.key,
    required this.rates,
    required this.preferredCurrency,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  State<CurrencyConverterCard> createState() => _CurrencyConverterCardState();
}

class _CurrencyConverterCardState extends State<CurrencyConverterCard> {
  final amountController = TextEditingController(text: '1');
  String base = 'USD';
  String target = 'IDR';

  @override
  void initState() {
    super.initState();
    final preferred = widget.preferredCurrency.toUpperCase();
    if (preferred != 'IDR') {
      base = preferred;
      target = 'IDR';
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencies = <String>[
      'IDR',
      ...widget.rates
          .where((rate) => rate.rate > 0)
          .map((rate) => rate.targetCurrency.toUpperCase())
    ].toSet().toList();
    if (!currencies.contains(base)) base = currencies.first;
    if (!currencies.contains(target) || target == base) {
      target =
          currencies.firstWhere((item) => item != base, orElse: () => base);
    }
    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
    final result = amount == null
        ? null
        : CurrencyConverter.convert(
            amount: amount,
            baseCurrency: base,
            targetCurrency: target,
            rates: widget.rates,
          );
    final oneUnit = CurrencyConverter.convert(
      amount: 1,
      baseCurrency: base,
      targetCurrency: target,
      rates: widget.rates,
    );
    final updatedAt = widget.rates
        .map((rate) => rate.fetchedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(
            null,
            (latest, item) =>
                latest == null || item.isAfter(latest) ? item : latest);

    return AppCard(
      key: const ValueKey('currency-converter-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Currency converter',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              IconButton(
                tooltip: 'Muat ulang kurs',
                onPressed: widget.loading ? null : widget.onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (updatedAt != null)
            Text(
              'Update ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(updatedAt.toLocal())}',
              style: TextStyle(color: context.poketto.mutedText, fontSize: 11),
            ),
          const SizedBox(height: PokettoSpacing.md),
          if (widget.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.error != null || currencies.length < 2)
            _SectionError(
              message: widget.error ?? 'Kurs mata uang belum tersedia.',
              onRetry: widget.onRetry,
            )
          else ...[
            TextField(
              key: const ValueKey('converter-amount'),
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                prefixIcon: Icon(Icons.calculate_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CurrencySelect(
                    key: const ValueKey('converter-base'),
                    label: 'Dari',
                    value: base,
                    currencies: currencies,
                    onChanged: (value) => setState(() {
                      base = value;
                      if (target == base) {
                        target = currencies.firstWhere((item) => item != base);
                      }
                    }),
                  ),
                ),
                IconButton(
                  key: const ValueKey('converter-swap'),
                  tooltip: 'Tukar mata uang',
                  onPressed: () => setState(() {
                    final previousBase = base;
                    base = target;
                    target = previousBase;
                  }),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  color: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: _CurrencySelect(
                    key: const ValueKey('converter-target'),
                    label: 'Ke',
                    value: target,
                    currencies: currencies,
                    onChanged: (value) => setState(() {
                      target = value;
                      if (base == target) {
                        base = currencies.firstWhere((item) => item != target);
                      }
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(PokettoSpacing.md),
              decoration: BoxDecoration(
                color: context.poketto.softSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hasil',
                      style: TextStyle(
                          color: context.poketto.mutedText, fontSize: 11)),
                  const SizedBox(height: 5),
                  Text(
                    result == null
                        ? 'Masukkan angka yang valid'
                        : _formatConverted(result, target),
                    key: const ValueKey('converter-result'),
                    style: const TextStyle(
                        fontSize: 23, fontWeight: FontWeight.w900),
                  ),
                  if (oneUnit != null) ...[
                    const SizedBox(height: 5),
                    Text('1 $base = ${_formatConverted(oneUnit, target)}',
                        key: const ValueKey('converter-rate'),
                        style: TextStyle(
                            color: context.poketto.mutedText, fontSize: 11.5)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatConverted(double value, String currency) {
    final digits = currency == 'IDR' || currency == 'JPY'
        ? 0
        : value.abs() < 1
            ? 6
            : 2;
    return '${NumberFormat.decimalPatternDigits(locale: 'id_ID', decimalDigits: digits).format(value)} $currency';
  }
}

class _CurrencySelect extends StatelessWidget {
  final String label;
  final String value;
  final List<String> currencies;
  final ValueChanged<String> onChanged;

  const _CurrencySelect({
    super.key,
    required this.label,
    required this.value,
    required this.currencies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: currencies
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      );
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptySection({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 38, color: context.poketto.mutedText),
              const SizedBox(height: 9),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.poketto.mutedText)),
            ],
          ),
        ),
      );
}

class _SectionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SectionError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.poketto.expense.withOpacity(.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      );
}
