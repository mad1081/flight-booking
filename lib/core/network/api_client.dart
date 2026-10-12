import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required String baseUrl, http.Client? client, this.accessToken})
    : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final String? Function()? accessToken;

  Future<Object?> get(
    String path, {
    Map<String, String>? query,
    bool authorized = false,
  }) => _send('GET', path, query: query, authorized: authorized);

  Future<Object?> post(
    String path,
    Map<String, Object?> body, {
    bool authorized = false,
  }) => _send('POST', path, body: body, authorized: authorized);

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, Object?>? body,
    bool authorized = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (authorized) {
      final token = accessToken?.call();
      if (token == null || token.isEmpty) {
        throw const ApiException(401, 'Кіру қажет.');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    final response =
        await (method == 'GET'
                ? _client.get(uri, headers: headers)
                : _client.post(uri, headers: headers, body: jsonEncode(body)))
            .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        response.statusCode == 401
            ? 'Қайта кіріңіз.'
            : response.statusCode == 409
            ? 'Бұл орын бос емес. Басқа орын таңдаңыз.'
            : 'Сервермен байланыс орнатылмады. Қайталап көріңіз.',
      );
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  void close() => _client.close();
}
