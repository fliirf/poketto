import 'package:poketto/core/helpers/json_helpers.dart';

class UserModel {
  final int id;
  final String name;
  final String email;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: readInt(json['id'] ?? json['user_id'] ?? json['userId']) ?? 0,
      name: readString(json['name']) ?? 'User',
      email: readString(json['email']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
