import 'package:poketto/core/helpers/json_helpers.dart';

class ExchangeRateModel {
  final String baseCurrency;
  final String targetCurrency;
  final double rate;
  final DateTime? date;

  const ExchangeRateModel({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.rate,
    this.date,
  });

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) {
    return ExchangeRateModel(
      baseCurrency:
          readString(json['base_currency'] ?? json['baseCurrency']) ?? 'IDR',
      targetCurrency:
          readString(json['target_currency'] ?? json['targetCurrency']) ??
              'USD',
      rate: readDouble(json['rate']) ?? 0,
      date: readDateTime(json['date']),
    );
  }
}
