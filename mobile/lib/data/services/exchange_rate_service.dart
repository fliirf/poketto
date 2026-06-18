import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_client.dart';
import 'package:poketto/data/models/exchange_rate_model.dart';

class ExchangeRateService {
  final ApiClient _apiClient;

  const ExchangeRateService(this._apiClient);

  Future<List<ExchangeRateModel>> getExchangeRates({
    String base = 'IDR',
  }) async {
    final response = await _apiClient.get(
      '/exchange-rates?base=${Uri.encodeQueryComponent(base.toUpperCase())}',
    );
    final items = readListPayload(response, const ['exchange_rates', 'rates']);
    return items
        .map((item) => ExchangeRateModel.fromJson(asStringDynamicMap(item)))
        .toList();
  }
}
