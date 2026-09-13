import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, {this.statusCode = 0});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static String get baseUrl {
    if (kIsWeb) return const String.fromEnvironment('API_URL', defaultValue: 'https://angevalencia.vercel.app');
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!Platform.isAndroid) return 'https://angevalencia.vercel.app';
    return 'https://angevalencia.vercel.app';
  }

  String? _token;
  String get token => _token ?? '';

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Uri _uri(String path, [Map<String, dynamic>? query]) =>
      Uri.parse('$baseUrl/api$path').replace(queryParameters: query);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _client.get(_uri(path, query), headers: _headers);
    return _decode(res);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    final headers = auth ? _headers : {'Content-Type': 'application/json'};
    final res = await _client.post(_uri(path),
        headers: headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final res =
        await _client.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await _client.delete(_uri(path), headers: _headers);
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final text = utf8.decode(res.bodyBytes);
    final body = text.isEmpty ? null : _tryDecode(text);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final message = body is Map && body['detail'] != null
        ? body['detail'].toString()
        : 'Erreur serveur (${res.statusCode})';
    throw ApiException(message, statusCode: res.statusCode);
  }

  dynamic _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return text;
    }
  }
}