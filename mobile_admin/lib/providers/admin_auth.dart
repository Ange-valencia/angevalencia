import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models.dart';

class AdminAuth extends ChangeNotifier {
  AdminAuth(this.api);

  final ApiClient api;

  AdminUser? user;

  bool get isLogged => api.token.isNotEmpty;

  Future<void> login(String identifier, String password) async {
    final res = await api.post(
      '/admin/auth/login',
      body: {'identifier': identifier, 'password': password},
      auth: false,
    );
    final token = res['token'] as String;
    if (token.isEmpty) throw ApiException('Réponse invalide du serveur');
    api.setToken(token);
    user = AdminUser.fromJson(res['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  void logout() {
    api.clearToken();
    user = null;
    notifyListeners();
  }
}