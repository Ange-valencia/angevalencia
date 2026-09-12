import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  List<City>? _cities;
  List<TransportCompany>? _companies;
  int? _cityId;
  int? _companyId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiClient>();
      final auth = context.read<AuthProvider>();
      final cities = (await api.get('/transport/cities') as List)
          .map((c) => City.fromJson(c))
          .toList();
      final companies = (await api.get('/transport/companies') as List)
          .map((c) => TransportCompany.fromJson(c))
          .toList();
      setState(() {
        _cities = cities;
        _companies = companies;
        _cityId = auth.user?.cityId;
        _companyId = auth.user?.preferredCompanyId;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await context
        .read<AuthProvider>()
        .updateProfile(cityId: _cityId, preferredCompanyId: _companyId);
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Profil mis à jour')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon compte')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.beigeLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.beigeDark),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.orange,
                child: Text(
                  (user?.fullName.isNotEmpty == true)
                      ? user!.fullName[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? '',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(user?.email ?? user?.phone ?? '',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _label('Ville de récupération'),
          DropdownButtonFormField<int>(
            initialValue: _cityId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Choisir votre ville'),
            items: (_cities ?? [])
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => _cityId = v),
          ),
          const SizedBox(height: 14),
          _label('Compagnie de transport préférée (optionnel)'),
          DropdownButtonFormField<int>(
            initialValue: _companyId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Compagnie préférée'),
            hint: const Text('Aucune — choix par défaut'),
            items: (_companies ?? [])
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => _companyId = v),
          ),
          const SizedBox(height: 8),
          Text(
              'Si votre compagnie préférée dessert votre ville, elle sera '
              'pré-sélectionnée à la commande.',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
          ),
          const SizedBox(height: 30),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            onPressed: () => context.read<AuthProvider>().logout(),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      );
}