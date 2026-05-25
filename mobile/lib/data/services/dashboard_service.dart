import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_client.dart';
import 'package:poketto/data/models/dashboard_summary_model.dart';

class DashboardService {
  final ApiClient _apiClient;

  const DashboardService(this._apiClient);

  Future<DashboardSummaryModel> getSummary() async {
    final response = await _apiClient.get('/dashboard/summary');
    return DashboardSummaryModel.fromJson(
      readMapPayload(response, const ['summary', 'dashboard']),
    );
  }
}
