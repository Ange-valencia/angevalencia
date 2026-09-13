import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';
import '../theme.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  late Future<PaymentConfig> _future;
  late TextEditingController _onCtrl;
  late TextEditingController _waveCtrl;
  late TextEditingController _instrCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _onCtrl = TextEditingController();
    _waveCtrl = TextEditingController();
    _instrCtrl = TextEditingController();
    _future = _load();
  }

  Future<PaymentConfig> _load() async {
    final res =
        await context.read<ApiClient>().get('/admin/payments/config');
    final config = PaymentConfig.fromJson(res);
    _onCtrl.text = config.orangeMoneyNumber ?? '';
    _waveCtrl.text = config.waveNumber ?? '';
    _instrCtrl.text = config.instructions ?? '';
    return config;
  }

  @override
  void dispose() {
    _onCtrl.dispose();
    _waveCtrl.dispose();
    _instrCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = {
        'orange_money_number': _onCtrl.text.trim().isEmpty
            ? null
            : _onCtrl.text.trim(),
        'wave_number': _waveCtrl.text.trim().isEmpty
            ? null
            : _waveCtrl.text.trim(),
        'instructions': _instrCtrl.text.trim().isEmpty
            ? null
            : _instrCtrl.text.trim(),
      };
      await context
          .read<ApiClient>()
          .put('/admin/payments/config', body: body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Numéros de paiement enregistrés')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages paiement')),
      body: FutureBuilder<PaymentConfig>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${snap.error}'),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: const Text('Réessayer')),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Ces numéros sont affichés dans l’app client pour que les '
                'clients envoient leur paiement Orange Money / Wave.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _onCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numéro Orange Money',
                  hintText: '+225…',
                  prefixIcon: Icon(Icons.smartphone),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _waveCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numéro Wave',
                  hintText: '+225…',
                  prefixIcon: Icon(Icons.smartphone),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _instrCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Instructions affichées',
                  hintText:
                      'Ex : Envoie le montant exact au numéro indiqué puis saisis le code SMS reçu. Un administrateur valide sous 24h.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }
}