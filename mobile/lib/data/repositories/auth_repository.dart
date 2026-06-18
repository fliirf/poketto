import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/core/storage/token_storage.dart';
import 'package:poketto/data/models/user_model.dart';
import 'package:poketto/data/services/auth_service.dart';

class AuthSession {
  final UserModel user;
  final String? token;
  final bool usedLocalFallback;

  const AuthSession({
    required this.user,
    this.token,
    this.usedLocalFallback = false,
  });
}

class AuthRepository {
  final AuthService _authService;
  final TokenStorage _tokenStorage;

  const AuthRepository({
    required AuthService authService,
    required TokenStorage tokenStorage,
  })  : _authService = authService,
        _tokenStorage = tokenStorage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      if (response.token == null || response.token!.isEmpty) {
        throw const ApiException(
          message:
              'Login berhasil, tetapi token API tidak ditemukan di response.',
        );
      }
      await _saveRemoteSession(response);
      return AuthSession(
        user: response.user,
        token: response.token,
      );
    } on ApiException {
      await _tokenStorage.clearToken();
      rethrow;
    }
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      if (response.token != null) {
        await _saveRemoteSession(response);
      }
      return AuthSession(
        user: response.user,
        token: response.token,
      );
    } on ApiException {
      await _tokenStorage.clearToken();
      rethrow;
    }
  }

  Future<AuthSession?> restoreRemoteSession() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final user = await _authService.me();
      await _tokenStorage.saveUserCache(user.toJson());
      return AuthSession(user: user, token: token);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _tokenStorage.clearToken();
        return null;
      }
      return null;
    }
  }

  Future<void> logout() async {
    final token = await _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await _authService.logout();
      } on ApiException {
        // Local session cleanup is still required even if the endpoint is not ready.
      }
    }
    await _tokenStorage.clearToken();
  }

  Future<void> _saveRemoteSession(AuthApiResponse response) async {
    if (response.token != null && response.token!.isNotEmpty) {
      await _tokenStorage.saveToken(response.token!);
    }
    await _tokenStorage.saveUserCache(response.user.toJson());
  }
}
