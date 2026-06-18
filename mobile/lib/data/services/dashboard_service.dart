import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_client.dart';
import 'package:poketto/data/models/dashboard_summary_model.dart';

class DashboardService {
  final ApiClient _apiClient;

  const DashboardService(this._apiClient);

  Future<DashboardSummaryModel> getSummary({
    String? month,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? categoryId,
  }) async {
    final query = <String, String>{};
    if (month != null) query['month'] = month;
    if (startDate != null) {
      query['start_date'] = _date(startDate);
    }
    if (endDate != null) query['end_date'] = _date(endDate);
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (categoryId != null) query['category_id'] = '$categoryId';
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final response = await _apiClient.get('/dashboard/summary$suffix');
    return DashboardSummaryModel.fromJson(
      readMapPayload(response, const ['summary', 'dashboard']),
    );
  }

  String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
