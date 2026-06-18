import 'package:poketto/core/helpers/json_helpers.dart';

class ExchangeRateModel {
  final String baseCurrency;
  final String targetCurrency;
  final double rate;
  final DateTime? fetchedAt;

  const ExchangeRateModel({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.rate,
    this.fetchedAt,
  });

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) {
    return ExchangeRateModel(
      baseCurrency:
          readString(json['base_currency'] ?? json['baseCurrency']) ?? 'IDR',
      targetCurrency:
          readString(json['target_currency'] ?? json['targetCurrency']) ??
              'USD',
      rate: readDouble(json['rate']) ?? 0,
      fetchedAt: readDateTime(json['fetched_at'] ??
          json['fetchedAt'] ??
          json['updated_at'] ??
          json['created_at'] ??
          json['date']),
    );
  }

  static const idr = ExchangeRateModel(
    baseCurrency: 'IDR',
    targetCurrency: 'IDR',
    rate: 1,
  );
}

class CurrencyConverter {
  const CurrencyConverter._();

  static double? convert({
    required double amount,
    required String baseCurrency,
    required String targetCurrency,
    required Iterable<ExchangeRateModel> rates,
  }) {
    if (!amount.isFinite) return null;
    final baseRate = _rateFor(baseCurrency, rates);
    final targetRate = _rateFor(targetCurrency, rates);
    if (baseRate == null || targetRate == null || baseRate <= 0) return null;
    final result = amount * targetRate / baseRate;
    return result.isFinite ? result : null;
  }

  static double? _rateFor(String currency, Iterable<ExchangeRateModel> rates) {
    final normalized = currency.toUpperCase();
    if (normalized == 'IDR') return 1;
    for (final rate in rates) {
      if (rate.baseCurrency.toUpperCase() == 'IDR' &&
          rate.targetCurrency.toUpperCase() == normalized &&
          rate.rate.isFinite &&
          rate.rate > 0) {
        return rate.rate;
      }
    }
    return null;
  }
}
