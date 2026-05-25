import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_client.dart';
import 'package:poketto/data/models/transaction_model.dart';

class TransactionService {
  final ApiClient _apiClient;

  const TransactionService(this._apiClient);

  Future<List<TransactionModel>> getTransactions({String? month}) async {
    final response = await _apiClient.get(
      month == null ? '/transactions' : '/transactions?month=$month',
    );
    final items = readListPayload(response, const ['transactions']);
    return items
        .map((item) => TransactionModel.fromJson(asStringDynamicMap(item)))
        .toList();
  }

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
