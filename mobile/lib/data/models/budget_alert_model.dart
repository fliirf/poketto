import 'package:poketto/core/helpers/json_helpers.dart';

class BudgetAlertModel {
  final int id;
  final String alertType;
  final String message;
  final String? title;
  final int? categoryId;
  final double? thresholdValue;
  final double? currentValue;
  final bool isRead;
  final DateTime? createdAt;

  const BudgetAlertModel({
    required this.id,
    required this.alertType,
    required this.message,
    this.title,
    this.categoryId,
    this.thresholdValue,
    this.currentValue,
    this.isRead = false,
    this.createdAt,
  });

  factory BudgetAlertModel.fromJson(Map<String, dynamic> json) {
    return BudgetAlertModel(
      id: readInt(json['id'] ?? json['alert_id']) ?? 0,
      alertType: readString(json['alert_type'] ?? json['type']) ?? 'warning',
      message: readString(json['message']) ?? 'Ada peringatan keuangan.',
      title: readString(json['title']),
      categoryId: readInt(json['category_id']),
      thresholdValue: readDouble(json['threshold_value']),
      currentValue: readDouble(json['current_value']),
      isRead: readBool(json['is_read']),
      createdAt: readDateTime(json['created_at']),
    );
  }
}
