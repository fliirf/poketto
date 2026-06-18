import 'package:poketto/core/network/api_client.dart';
import 'package:poketto/core/storage/token_storage.dart';
import 'package:poketto/data/repositories/auth_repository.dart';
import 'package:poketto/data/repositories/budget_alert_repository.dart';
import 'package:poketto/data/repositories/category_repository.dart';
import 'package:poketto/data/repositories/dashboard_repository.dart';
import 'package:poketto/data/repositories/exchange_rate_repository.dart';
import 'package:poketto/data/repositories/transaction_repository.dart';
import 'package:poketto/data/repositories/user_settings_repository.dart';
import 'package:poketto/data/services/auth_service.dart';
import 'package:poketto/data/services/budget_alert_service.dart';
import 'package:poketto/data/services/category_service.dart';
import 'package:poketto/data/services/dashboard_service.dart';
import 'package:poketto/data/services/exchange_rate_service.dart';
import 'package:poketto/data/services/location_service.dart';
import 'package:poketto/data/services/notification_service.dart';
import 'package:poketto/data/services/transaction_service.dart';
import 'package:poketto/data/services/user_settings_service.dart';

class AppRepositories {
  static final tokenStorage = TokenStorage();
  static final apiClient = ApiClient(tokenStorage: tokenStorage);
  static final auth = AuthRepository(
    authService: AuthService(apiClient),
    tokenStorage: tokenStorage,
  );

  static final categories = CategoryRepository(
    categoryService: CategoryService(apiClient),
    tokenStorage: tokenStorage,
  );

  static final transactions = TransactionRepository(
    transactionService: TransactionService(apiClient),
    tokenStorage: tokenStorage,
  );

  static final budgetAlerts = BudgetAlertRepository(
    budgetAlertService: BudgetAlertService(apiClient),
    tokenStorage: tokenStorage,
  );

  static final dashboard = DashboardRepository(
    dashboardService: DashboardService(apiClient),
    budgetAlertRepository: budgetAlerts,
    tokenStorage: tokenStorage,
  );

  static final exchangeRates = ExchangeRateRepository(
    exchangeRateService: ExchangeRateService(apiClient),
    tokenStorage: tokenStorage,
  );

  static final userSettings = UserSettingsRepository(
    userSettingsService: UserSettingsService(apiClient),
    tokenStorage: tokenStorage,
  );

  static final location = LocationService();
  static final notifications = NotificationService();
}
