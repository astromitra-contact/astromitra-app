import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin HTTP wrapper used by every repository. Centralizes:
///   - base URL + JSON headers
///   - request timeout
///   - error parsing matching this specific backend's two response shapes:
///       nested:  { success:false, error:{ code, message } }
///       flat:    { success:false, code, message }   (only QUESTION_LIMIT_REACHED)
///   - retry — GET ONLY. POST/PATCH/DELETE are never auto-retried here:
///     a retried POST /api/kundli/generate would create a second Kundli
///     record (the backend does not deduplicate by content, by design —
///     see the backend README), and a retried POST /api/chat/ask could
///     plausibly deduct credits twice for one user action. Both are worse
///     outcomes than surfacing a clear error and letting the person tap
///     "Try again" themselves. GET requests (credit status) are naturally
///     safe to retry since they don't change server state.
class ApiClient {
  final http.Client _client;
  final String baseUrl;

  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> get(String path) => _send(
        () => _client.get(_uri(path), headers: _headers),
        retryable: true,
      );

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) => _send(
        () => _client.post(_uri(path), headers: _headers, body: body != null ? jsonEncode(body) : null),
        retryable: false,
      );

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) => _send(
        () => _client.patch(_uri(path), headers: _headers, body: body != null ? jsonEncode(body) : null),
        retryable: false,
      );

  Future<Map<String, dynamic>> delete(String path) => _send(
        () => _client.delete(_uri(path), headers: _headers),
        retryable: false,
      );

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request, {
    required bool retryable,
  }) async {
    final attempts = retryable ? AppConfig.maxRetries + 1 : 1;
    Object? lastError;

    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final response = await request().timeout(AppConfig.requestTimeout);
        return _parseResponse(response);
      } on TimeoutException {
        final err = ApiException.timeout();
        lastError = err;
        if (!retryable) throw err;
      } on SocketException {
        final err = ApiException.network(
          'Could not reach the AstroMitra server. Please check your internet connection.',
        );
        lastError = err;
        if (!retryable) throw err;
      } on ApiException {
        rethrow; // parsed backend error — never retried, never masked.
      }

      if (attempt < attempts - 1) {
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    if (lastError is ApiException) throw lastError;
    throw ApiException.network('Could not reach the AstroMitra server. Please try again.');
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      json = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      throw ApiException(
        message: 'The server returned an unexpected response (status ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final success = json['success'] == true;
    if (response.statusCode >= 200 && response.statusCode < 300 && success) {
      return json;
    }

    // Two possible error shapes from this backend — see class doc above.
    String message = 'Something went wrong. Please try again.';
    String? code;

    final nestedError = json['error'];
    if (nestedError is Map<String, dynamic>) {
      message = (nestedError['message'] as String?) ?? message;
      code = nestedError['code'] as String?;
    } else if (json['message'] is String) {
      message = json['message'] as String;
      code = json['code'] as String?;
    }

    throw ApiException(message: message, code: code, statusCode: response.statusCode);
  }

  void dispose() => _client.close();
}
