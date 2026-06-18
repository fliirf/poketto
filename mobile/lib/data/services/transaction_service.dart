import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_client.dart';
import 'package:poketto/data/models/transaction_model.dart';

class TransactionService {
  final ApiClient _apiClient;

  const TransactionService(this._apiClient);

  Future<List<TransactionModel>> getTransactions({
    String? month,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? categoryId,
  }) async {
    final query = <String, String>{};
    if (month != null) query['month'] = month;
    if (startDate != null) query['start_date'] = _date(startDate);
    if (endDate != null) query['end_date'] = _date(endDate);
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (categoryId != null) query['category_id'] = '$categoryId';
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final response = await _apiClient.get(
      '/transactions$suffix',
    );
    final items = readListPayload(response, const ['transactions']);
    return items
        .map((item) => TransactionModel.fromJson(asStringDynamicMap(item)))
        .toList();
  }

  String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Future<TransactionModel> getTransaction(int id) async {
    final response = await _apiClient.get('/transactions/$id');
    return TransactionModel.fromJson(
      readMapPayload(response, const ['transaction']),
    );
  }

  Future<TransactionModel> createTransaction(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.post('/transactions', body: payload);
    return TransactionModel.fromJson(
      readMapPayload(response, const ['transaction']),
    );
  }

  Future<TransactionModel> updateTransaction(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.put('/transactions/$id', body: payload);
    return TransactionModel.fromJson(
      readMapPayload(response, const ['transaction']),
    );
  }

  Future<void> deleteTransaction(int id) async {
    await _apiClient.delete('/transactions/$id');
  }
}
