import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:poketto/core/config/api_config.dart';
import 'package:poketto/core/debug/category_debug.dart';
import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/core/storage/token_storage.dart';

class ApiClient {
  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;

  ApiClient({
    this.baseUrl = ApiConfig.baseUrl,
    required this.tokenStorage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<dynamic> get(String path, {bool authenticated = true}) {
    return _send('GET', path, authenticated: authenticated);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send('PUT', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send('PATCH', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> delete(String path, {bool authenticated = true}) {
    return _send('DELETE', path, authenticated: authenticated);
  }

  Uri _uri(String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$cleanBase/$cleanPath');
  }

  Future<Map<String, String>> _headers(bool authenticated) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    try {
      final request = http.Request(method, _uri(path));
      request.headers.addAll(await _headers(authenticated));
      if (body != null) {
        request.body = jsonEncode(body);
      }

      if (path.contains('categories')) {
        logCategoryFlow(
          '$method ${request.url} token=${request.headers.containsKey('Authorization')} payload=${request.body}',
        );
      }

      final streamed =
          await _client.send(request).timeout(ApiConfig.requestTimeout);
      final response = await http.Response.fromStream(streamed);
      if (path.contains('categories')) {
        logCategoryFlow(
          '$method ${request.url} status=${response.statusCode} body=${response.body}',
        );
      }
      return _handleResponse(response);
    } on TimeoutException catch (error) {
      throw ApiException(message: 'Request timeout', cause: error);
    } on http.ClientException catch (error) {
      throw ApiException(message: 'Network request failed', cause: error);
    } on FormatException catch (error) {
      throw ApiException(message: 'Response API tidak valid.', cause: error);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: 'Koneksi bermasalah.', cause: error);
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    if (response.body.trim().isNotEmpty) {
      decoded = jsonDecode(response.body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (response.statusCode == 401) {
      unawaited(tokenStorage.clearToken());
    }

    final message = _readErrorMessage(decoded);
    throw ApiException(
      statusCode: response.statusCode,
      message: message ?? response.reasonPhrase ?? 'API request failed',
    );
  }

  String? _readErrorMessage(dynamic decoded) {
    final map = asStringDynamicMap(decoded);
    if (map.isEmpty) return null;

    for (final key in const ['message', 'error', 'detail']) {
      final value = readString(map[key]);
      if (value != null) return value;
    }

    final errors = map['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }

    return null;
  }
}
