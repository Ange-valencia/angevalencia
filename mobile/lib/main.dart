import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'core/api_client.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

void main() {
  runApp(const AngeValenciaApp());
}

class AngeValenciaApp extends StatelessWidget {
  const AngeValenciaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) => AuthProvider(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'AngeValencia',
        debugShowCheckedModeBanner: false,
        theme: buildAngeValenciaTheme(),
        home: const RootGate(),
      ),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.restoring) {
      return const _SplashScreen();
    }
    if (auth.isLoggedIn) {
      return const HomeShell();
    }
    return const AuthScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_boat_filled,
                size: 72, color: AppColors.orange),
            const SizedBox(height: 16),
            Text('AngeValencia',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}