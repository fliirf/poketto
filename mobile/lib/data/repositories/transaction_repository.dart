import 'package:intl/intl.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/core/storage/token_storage.dart';
import 'package:poketto/data/services/location_service.dart';
import 'package:poketto/data/services/transaction_service.dart';

class TransactionRepository {
  final TransactionService _transactionService;
  final TokenStorage _tokenStorage;

  const TransactionRepository({
    required TransactionService transactionService,
    required TokenStorage tokenStorage,
  })  : _transactionService = transactionService,
        _tokenStorage = tokenStorage;

  Future<List<Map<String, dynamic>>> getTransactionsByMonthForUi({
    required int userId,
    required String month,
  }) async {
    await _requireRemoteSession();

    final transactions =
        await _transactionService.getTransactions(month: month);
    return transactions
        .where((transaction) =>
            DateFormat('yyyy-MM').format(transaction.transactionDate) == month)
        .map((transaction) => transaction.toUiMap())
        .toList();
  }

  Future<int> createTransaction({
    required int userId,
    required int categoryId,
    required String type,
    required double amount,
    required String description,
    required DateTime transactionDate,
    int? budgetId,
    TransactionLocation? location,
  }) async {
    await _requireRemoteSession();

    final created = await _transactionService.createTransaction({
      'type': type,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'transaction_date': transactionDate.toIso8601String(),
      ..._locationPayload(location),
    }..removeWhere((key, value) => value == null));
    return created.id > 0 ? created.id : 1;
  }

  Future<int> updateTransaction({
    required int transactionId,
    required int categoryId,
    required String type,
    required double amount,
    required String description,
    required DateTime transactionDate,
    int? budgetId,
    TransactionLocation? location,
  }) async {
    await _requireRemoteSession();

    await _transactionService.updateTransaction(
        transactionId,
        {
          'type': type,
          'category_id': categoryId,
          'amount': amount,
          'description': description,
          'transaction_date': transactionDate.toIso8601String(),
          ..._locationPayload(location),
        }..removeWhere((key, value) => value == null));
    return 1;
  }

  Future<int> deleteTransaction(int transactionId) async {
    await _requireRemoteSession();
    await _transactionService.deleteTransaction(transactionId);
    return 1;
  }

  Future<void> _requireRemoteSession() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Sesi berakhir. Silakan login ulang.',
        statusCode: 401,
      );
    }
  }

  Map<String, dynamic> _locationPayload(TransactionLocation? location) {
    return {
      'location_lat': location?.latitude,
      'location_lng': location?.longitude,
      'location_name': location?.name,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'lat': location?.latitude,
      'lng': location?.longitude,
      'address': location?.name,
    }..removeWhere((key, value) => value == null);
  }
}
