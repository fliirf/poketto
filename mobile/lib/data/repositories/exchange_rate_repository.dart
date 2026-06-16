import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/core/storage/token_storage.dart';
import 'package:poketto/data/models/exchange_rate_model.dart';
import 'package:poketto/data/services/exchange_rate_service.dart';

class ExchangeRateRepository {
  final ExchangeRateService _exchangeRateService;
  final TokenStorage _tokenStorage;

  const ExchangeRateRepository({
    required ExchangeRateService exchangeRateService,
    required TokenStorage tokenStorage,
  })  : _exchangeRateService = exchangeRateService,
        _tokenStorage = tokenStorage;

  Future<List<ExchangeRateModel>> getExchangeRates() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Sesi berakhir. Silakan login ulang.',
        statusCode: 401,
      );
    }

    return _exchangeRateService.getExchangeRates();
  }
}
