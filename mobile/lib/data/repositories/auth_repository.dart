import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/core/storage/token_storage.dart';
import 'package:poketto/data/models/user_model.dart';
import 'package:poketto/data/services/auth_service.dart';
import 'package:poketto/database/database_helper.dart';

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
  final DatabaseHelper _databaseHelper;

  const AuthRepository({
    required AuthService authService,
    required TokenStorage tokenStorage,
    required DatabaseHelper databaseHelper,
  })  : _authService = authService,
        _tokenStorage = tokenStorage,
        _databaseHelper = databaseHelper;

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
      final localUserId = await _saveLocalAuthUser(
        user: response.user,
        password: password,
      );
      return AuthSession(
        user: UserModel(
          id: localUserId ?? response.user.id,
          name: response.user.name,
          email: response.user.email,
        ),
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
      final localUserId = await _saveLocalAuthUser(
        user: response.user,
        password: password,
      );
      return AuthSession(
        user: UserModel(
          id: localUserId ?? response.user.id,
          name: response.user.name,
          email: response.user.email,
        ),
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
      return AuthSession(user: await _localizeCachedUser(user), token: token);
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

  Future<int?> _saveLocalAuthUser({
    required UserModel user,
    required String password,
  }) async {
    try {
      return await _databaseHelper.upsertUser(
        name: user.name,
        email: user.email,
        password: password,
      );
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> _localizeCachedUser(UserModel user) async {
    try {
      final localUser = await _databaseHelper.getUserByEmail(user.email);
      if (localUser == null) return user;
      return UserModel.fromJson(localUser);
    } catch (_) {
      return user;
    }
  }
}
