import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_storage.dart';

/// Low-level HTTP client. All screens talk to repositories, not this directly.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  // Override with:
  // flutter run --dart-define=API_BASE_URL=http://your-ip:8000/api/v1
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.61.100.128:8000/api/v1',
  );
  static const _timeout = Duration(seconds: 20);

  // Called by AuthProvider on 401 so the app can log the user out.
  void Function()? onUnauthorized;

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (auth) {
      final token = await TokenStorage.instance.read();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    final response = await http
        .get(Uri.parse('$_baseUrl$path'), headers: await _headers(auth: auth))
        .timeout(_timeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: await _headers(auth: auth),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl$path'),
          headers: await _headers(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl$path'), headers: await _headers())
        .timeout(_timeout);
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw const ApiException('Session expired. Please log in again.', 401);
    }

    if (response.body.trim().isEmpty) {
      if (response.statusCode >= 400) {
        throw ApiException(
          'Request failed (${response.statusCode})',
          response.statusCode,
        );
      }
      return const {};
    }

    late final Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      } else if (decoded is List) {
        body = {'data': decoded};
      } else {
        throw const FormatException('Unexpected payload');
      }
    } catch (_) {
      throw ApiException('Invalid server response', response.statusCode);
    }

    if (response.statusCode >= 400) {
      final message =
          body['message'] as String? ??
          (body['errors'] as Map?)?.values.first?.toString() ??
          'Request failed (${response.statusCode})';
      throw ApiException(message, response.statusCode);
    }

    return body;
  }

  /// Extracts a list from either `{ "data": [...] }` or a bare `[...]`.
  static List<Map<String, dynamic>> asList(Map<String, dynamic> body) {
    final raw = body['data'] ?? body['items'] ?? body;
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
    return const [];
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, this.statusCode);

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 422;

  @override
  String toString() => message;
}
