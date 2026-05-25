import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_client.dart';
import 'package:poketto/data/models/budget_alert_model.dart';

class BudgetAlertService {
  final ApiClient _apiClient;

  const BudgetAlertService(this._apiClient);

  Future<List<BudgetAlertModel>> getAlerts() async {
    final response = await _apiClient.get('/budget-alerts');
    final items = readListPayload(response, const ['alerts', 'budget_alerts']);
    return items
        .map((item) => BudgetAlertModel.fromJson(asStringDynamicMap(item)))
        .toList();
  }
}
