import 'package:poketto/core/helpers/json_helpers.dart';

class TransactionModel {
  final int id;
  final int? userId;
  final int? categoryId;
  final String categoryName;
  final String type;
  final double amount;
  final String? description;
  final DateTime transactionDate;
  final double? locationLat;
  final double? locationLng;
  final String? locationName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.userId,
    this.categoryId,
    this.categoryName = 'Lainnya',
    this.description,
    this.locationLat,
    this.locationLng,
    this.locationName,
    this.createdAt,
    this.updatedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final date = readDateTime(json['transaction_date']) ??
        readDateTime(json['date']) ??
        DateTime.now();
    final locationMap = asStringDynamicMap(json['location']);

    return TransactionModel(
      id: readInt(json['id'] ?? json['transaction_id']) ?? 0,
      userId: readInt(json['user_id'] ?? json['userId']),
      categoryId: readInt(json['category_id'] ?? json['categoryId']),
      categoryName: readString(
            json['category_name'] ??
                json['categoryName'] ??
                asStringDynamicMap(json['category'])['name'],
          ) ??
          'Lainnya',
      type: readString(
            json['type'] ??
                json['category_type'] ??
                asStringDynamicMap(json['category'])['type'],
          ) ??
          'expense',
      amount: readDouble(json['amount']) ?? 0,
      description: readString(json['description']),
      transactionDate: date,
      locationLat: readDouble(
        json['location_lat'] ??
            json['locationLat'] ??
            json['latitude'] ??
            json['lat'] ??
            locationMap['latitude'] ??
            locationMap['lat'],
      ),
      locationLng: readDouble(
        json['location_lng'] ??
            json['locationLng'] ??
            json['longitude'] ??
            json['lng'] ??
            locationMap['longitude'] ??
            locationMap['lng'],
      ),
      locationName: readString(
        json['location_name'] ??
            json['locationName'] ??
            json['address'] ??
            locationMap['name'] ??
            locationMap['address'] ??
            locationMap['formatted_address'],
      ),
      createdAt: readDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: readDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'type': type,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'transaction_date': transactionDate.toIso8601String(),
      'location_lat': locationLat,
      'location_lng': locationLng,
      'location_name': locationName,
      'latitude': locationLat,
      'longitude': locationLng,
      'lat': locationLat,
      'lng': locationLng,
      'address': locationName,
    }..removeWhere((key, value) => value == null);
  }

  Map<String, dynamic> toUiMap() {
    return {
      'transaction_id': id,
      'user_id': userId,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_type': type,
      'amount': amount,
      'description': description,
      'transaction_date': transactionDate.toIso8601String(),
      'date': transactionDate.toIso8601String(),
      'location_lat': locationLat,
      'location_lng': locationLng,
      'location_name': locationName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
