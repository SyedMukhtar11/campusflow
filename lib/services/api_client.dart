import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Exception thrown by ApiClient on network errors or bad HTTP status codes.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;

  const ApiException(
    this.message, [
    this.statusCode = 0,
    this.data,
  ]);

  @override
  String toString() => message;
}

/// Centralized HTTP client managing baseUrl, token header injection,
/// timeouts, and error handling.
class ApiClient {
  static const String productionBaseUrl =
      'https://campusflow-nq50.onrender.com';

  static final ApiClient instance = ApiClient._internal();
  factory ApiClient({String? baseUrl, http.Client? client}) {
    if (baseUrl != null) instance.setBaseUrl(baseUrl);
    return instance;
  }
  ApiClient._internal()
      : _baseUrl = _trimSlash(ApiConfig.baseUrl),
        _http = http.Client();

  /// Default API base URL.
  static String get defaultBaseUrl => ApiConfig.baseUrl;

  String _baseUrl;
  final http.Client _http;
  String? token;

  String get baseUrl => _baseUrl;
  void setBaseUrl(String url) => _baseUrl = _trimSlash(url);

  String? get authToken => token;
  void setAuthToken(String? value) => token = value;

  static String _trimSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    var p = path.startsWith('/') ? path : '/$path';
    final prefix = ApiConfig.apiPrefix;
    if (prefix.isNotEmpty && !p.startsWith(prefix)) p = '$prefix$p';
    final fullUrl = '$_baseUrl$p';
    final uri = Uri.parse(fullUrl);

    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) =>
      _send(() => _http.get(_uri(path, queryParams), headers: _headers));

  Future<dynamic> post(String path, {Object? body}) => _send(() => _http.post(
        _uri(path),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ));

  Future<dynamic> put(String path, {Object? body}) => _send(() => _http.put(
        _uri(path),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ));

  Future<dynamic> patch(String path, {Object? body}) => _send(() => _http.patch(
        _uri(path),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ));

  Future<dynamic> delete(String path) =>
      _send(() => _http.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final res = await request().timeout(ApiConfig.timeout);
      final dynamic decoded = res.body.isEmpty ? null : jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
      throw ApiException(
        _messageFrom(decoded) ?? 'Request failed with status ${res.statusCode}',
        res.statusCode,
        decoded,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
        408,
      );
    } on http.ClientException {
      throw const ApiException(
        'Unable to connect to server. Check your network connection.',
        0,
      );
    } on FormatException {
      throw const ApiException(
        'The server sent an unexpected response.',
        500,
      );
    } catch (e) {
      throw ApiException(e.toString(), 0);
    }
  }

  static String? _messageFrom(dynamic body) {
    if (body is Map) {
      final m = body['message'] ?? body['error'] ?? body['msg'];
      if (m != null) return m.toString();
    }
    return null;
  }
}
