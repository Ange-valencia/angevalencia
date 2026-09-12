import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _registerMode = false;
  bool _obscurePin = true;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final password = _passwordCtrl.text.trim();
    if (password.length != 4) {
      _snack('Le code PIN doit contenir 4 chiffres');
      return;
    }
    bool ok;
    if (_registerMode) {
      final identifier = _emailCtrl.text.trim();
      ok = await auth.register(
        fullName: _nameCtrl.text.trim(),
        email: identifier.contains('@') ? identifier : null,
        phone: identifier.isNotEmpty && !identifier.contains('@') ? identifier : null,
        password: password,
      );
    } else {
      ok = await auth.login(identifier: _loginCtrl.text.trim(), password: password);
    }
    if (!ok && mounted) {
      _snack(auth.error ?? 'Échec de la connexion');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.sailing, size: 64, color: AppColors.orange),
                  const SizedBox(height: 8),
                  Text('AngeValencia',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Produits de Chine, livrés en Côte d\'Ivoire',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 28),

                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Connexion')),
                      ButtonSegment(value: true, label: Text('Inscription')),
                    ],
                    selected: {_registerMode},
                    onSelectionChanged: (s) => setState(() => _registerMode = s.first),
                  ),
                  const SizedBox(height: 20),

                  if (_registerMode) ...[
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email ou téléphone (+225)',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _loginCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email ou téléphone',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'Code PIN (4 chiffres)',
                      counterText: '',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscurePin ? Icons.visibility_off : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscurePin = !_obscurePin),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Livraison estimée à environ 2 mois depuis la Chine.\n'
                    'Récupération en compagnie de transport.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: auth.loading ? null : _submit,
                    child: auth.loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_registerMode ? 'Créer mon compte' : 'Se connecter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}