import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_client.dart';
import 'package:poketto/data/models/user_model.dart';

class AuthApiResponse {
  final UserModel user;
  final String? token;

  const AuthApiResponse({required this.user, this.token});
}

class AuthService {
  final ApiClient _apiClient;

  const AuthService(this._apiClient);

  Future<AuthApiResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/login',
      authenticated: false,
      body: {
        'email': email,
        'password': password,
      },
    );
    return _parseAuthResponse(response);
  }

  Future<AuthApiResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.post(
      '/register',
      authenticated: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return _parseAuthResponse(response);
  }

  Future<void> logout() async {
    await _apiClient.post('/logout');
  }

  Future<UserModel> me() async {
    final response = await _apiClient.get('/me');
    final userJson = readMapPayload(response, const ['user']);
    return UserModel.fromJson(userJson);
  }

  AuthApiResponse _parseAuthResponse(dynamic response) {
    final root = asStringDynamicMap(response);
    final data = asStringDynamicMap(root['data']);
    final userJson = readMapPayload(response, const ['user']);
    final token = readString(root['token']) ??
        readString(root['access_token']) ??
        readString(root['bearer_token']) ??
        readString(root['plainTextToken']) ??
        readString(root['plain_text_token']) ??
        readString(data['token']) ??
        readString(data['access_token']) ??
        readString(data['bearer_token']) ??
        readString(data['plainTextToken']) ??
        readString(data['plain_text_token']) ??
        readString(asStringDynamicMap(root['authorization'])['token']) ??
        readString(asStringDynamicMap(root['authorisation'])['token']) ??
        readString(asStringDynamicMap(data['authorization'])['token']) ??
        readString(asStringDynamicMap(data['authorisation'])['token']);

    return AuthApiResponse(
      user: UserModel.fromJson(userJson),
      token: token,
    );
  }
}
