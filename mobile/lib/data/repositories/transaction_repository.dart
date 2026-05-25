import 'package:intl/intl.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/core/storage/token_storage.dart';
import 'package:poketto/data/models/transaction_model.dart';
import 'package:poketto/data/services/location_service.dart';
import 'package:poketto/data/services/transaction_service.dart';
import 'package:poketto/database/database_helper.dart';

class TransactionRepository {
  final TransactionService _transactionService;
  final TokenStorage _tokenStorage;
  final DatabaseHelper _databaseHelper;

  const TransactionRepository({
    required TransactionService transactionService,
    required TokenStorage tokenStorage,
    required DatabaseHelper databaseHelper,
  })  : _transactionService = transactionService,
        _tokenStorage = tokenStorage,
        _databaseHelper = databaseHelper;

  Future<List<Map<String, dynamic>>> getTransactionsByMonthForUi({
    required int userId,
    required String month,
  }) async {
    if (await _hasRemoteSession()) {
      try {
        final transactions =
            await _transactionService.getTransactions(month: month);
        return transactions
            .where((transaction) =>
                DateFormat('yyyy-MM').format(transaction.transactionDate) ==
                month)
            .map((transaction) => transaction.toUiMap())
            .toList();
      } on ApiException catch (error) {
        if (!error.canUseLocalFallback) rethrow;
      }
    }

    // TODO: Remove local transaction fallback once REST transaction sync is stable.
    final localTransactions =
        await _databaseHelper.getTransactionsByMonth(userId, month);
    return localTransactions;
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
    if (await _hasRemoteSession()) {
      try {
        final created = await _transactionService.createTransaction({
          'type': type,
          'category_id': categoryId,
          'amount': amount,
          'description': description,
          'transaction_date': transactionDate.toIso8601String(),
          ..._locationPayload(location),
        }..removeWhere((key, value) => value == null));
        return created.id > 0 ? created.id : 1;
      } on ApiException catch (error) {
        if (!error.canUseLocalFallback) rethrow;
      }
    }

    return _databaseHelper.createTransaction(
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      description: description,
      date: DateFormat('yyyy-MM-dd').format(transactionDate),
      budgetId: budgetId,
      locationLat: location?.latitude,
      locationLng: location?.longitude,
      locationName: location?.name,
    );
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
    if (await _hasRemoteSession()) {
      try {
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
      } on ApiException catch (error) {
        if (!error.canUseLocalFallback) rethrow;
      }
    }

    return _databaseHelper.updateTransaction(
      transactionId: transactionId,
      categoryId: categoryId,
      amount: amount,
      description: description,
      date: DateFormat('yyyy-MM-dd').format(transactionDate),
      budgetId: budgetId,
      locationLat: location?.latitude,
      locationLng: location?.longitude,
      locationName: location?.name,
    );
  }

  Future<int> deleteTransaction(int transactionId) async {
    if (await _hasRemoteSession()) {
      try {
        await _transactionService.deleteTransaction(transactionId);
        return 1;
      } on ApiException catch (error) {
        if (!error.canUseLocalFallback) rethrow;
      }
    }

    return _databaseHelper.deleteTransaction(transactionId);
  }

  Future<bool> _hasRemoteSession() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
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
