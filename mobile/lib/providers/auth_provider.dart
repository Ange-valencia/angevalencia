import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api) {
    _restore();
  }

  final ApiClient _api;
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('av_token');
    if (token == null) return;
    _api.setToken(token);
    try {
      final json = await _api.get('/auth/me');
      _user = User.fromJson(json);
      notifyListeners();
    } catch (e) {
      await prefs.remove('av_token');
    }
  }

  Future<bool> register({
    required String fullName,
    String? email,
    String? phone,
    required String password,
  }) async {
    return _authenticate(() => _api.post('/auth/register', auth: false, body: {
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'password': password,
        }));
  }

  Future<bool> login({required String identifier, required String password}) async {
    return _authenticate(
        () => _api.post('/auth/login', auth: false, body: {
              'identifier': identifier,
              'password': password,
            }));
  }

  Future<bool> _authenticate(Future<dynamic> Function() call) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final json = await call();
      _user = User.fromJson(json['user']);
      _api.setToken(json['token']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('av_token', json['token']);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _api.clearToken();
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('av_token');
    notifyListeners();
  }

  Future<String?> updateProfile({int? cityId, int? preferredCompanyId}) async {
    try {
      final json = await _api.put('/auth/profile', body: {
        'city_id': cityId,
        'preferred_company_id': preferredCompanyId,
      });
      _user = User.fromJson(json);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}