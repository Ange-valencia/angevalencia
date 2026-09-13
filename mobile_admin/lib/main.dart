import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'providers/admin_auth.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

void main() {
  final api = ApiClient();
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AdminAuth>(create: (_) => AdminAuth(api)),
      ],
      child: const AngeValenciaAdminApp(),
    ),
  );
}

class AngeValenciaAdminApp extends StatelessWidget {
  const AngeValenciaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AngeValencia Admin',
      debugShowCheckedModeBanner: false,
      theme: buildAngeValenciaTheme(),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuth>();
    return auth.isLogged ? const DashboardScreen() : const LoginScreen();
  }
}