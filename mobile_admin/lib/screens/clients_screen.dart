import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';
import '../theme.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  late Future<List<AdminUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AdminUser>> _load() async {
    final res = await context.read<ApiClient>().get('/admin/users');
    return (res as List).map((u) => AdminUser.fromJson(u)).toList();
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: FutureBuilder<List<AdminUser>>(
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
                      onPressed: _reload, child: const Text('Réessayer')),
                ],
              ),
            );
          }
          final users = snap.data ?? const [];
          if (users.isEmpty) {
            return const Center(child: Text('Aucun client inscrit pour l’instant'));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              itemCount: users.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final u = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.orange.withValues(alpha: 0.15),
                    child: Text(
                      u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  title: Text(u.fullName),
                  subtitle: Text(
                    [u.phone, u.email].whereType<String>().join(' · '),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text('#${u.id}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}