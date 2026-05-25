import 'package:poketto/core/helpers/json_helpers.dart';

class CategoryModel {
  final int id;
  final String name;
  final String type;
  final double? monthlyBudget;
  final String? description;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.monthlyBudget,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: readInt(json['id'] ?? json['category_id'] ?? json['categoryId']) ?? 0,
      name: readString(json['name']) ?? 'Lainnya',
      type: readString(
            json['type'] ?? json['category_type'] ?? json['categoryType'],
          ) ??
          'expense',
      monthlyBudget: readDouble(
        json['monthly_budget'] ??
            json['monthlyBudget'] ??
            json['budget'] ??
            json['limit'] ??
            json['budget_limit'] ??
            json['budgetLimit'],
      ),
      description: readString(json['description']),
    );
  }

  Map<String, dynamic> toUiMap() {
    return {
      'category_id': id,
      'name': name,
      'type': type,
      'monthly_budget': monthlyBudget,
      'description': description,
    };
  }
}
