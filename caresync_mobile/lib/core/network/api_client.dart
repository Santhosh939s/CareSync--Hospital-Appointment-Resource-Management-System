import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../exceptions/app_exceptions.dart';

/// Centralised HTTP client for all CareSync API calls.
///
/// Every service layer class delegates network I/O to this single class,
/// ensuring consistent error handling, timeouts and JSON parsing.
class ApiClient {
  final http.Client _client;
  final String _baseUrl;

  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConstants.baseUrl;

  /// Sends a GET request and returns the decoded JSON body.
  Future<dynamic> get(String endpoint) async {
    return _send('GET', endpoint);
  }

  /// Sends a POST request with a JSON [body].
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    return _send('POST', endpoint, body: body);
  }

  /// Sends a PUT request with a JSON [body].
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    return _send('PUT', endpoint, body: body);
  }

  /// Internal method that handles all HTTP verbs, timeouts and error mapping.
  Future<dynamic> _send(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      late http.Response response;

      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 15));
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(const Duration(seconds: 15));
          break;
        default:
          throw const AppException('Unsupported HTTP method');
      }

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const TimeoutException();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Unexpected error: ${e.toString()}');
    }
  }

  /// Maps HTTP status codes to app-specific exceptions.
  dynamic _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    switch (response.statusCode) {
      case 200:
      case 201:
        return body;
      case 400:
        final message = body is Map ? (body['error'] ?? 'Invalid request') : 'Invalid request';
        throw ValidationException(message.toString());
      case 401:
        final message = body is Map ? (body['error'] ?? 'Invalid credentials') : 'Invalid credentials';
        throw AuthenticationException(message.toString());
      case 404:
        throw const NotFoundException();
      default:
        final message = body is Map ? (body['error'] ?? 'Server error') : 'Server error';
        throw ServerException(message.toString());
    }
  }

  /// Closes the underlying HTTP client. Call when the app is disposed.
  void dispose() {
    _client.close();
  }
}
