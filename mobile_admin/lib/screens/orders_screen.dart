import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';
import '../theme.dart';
import 'order_detail_screen.dart';

final _statuses = orderStatusLabels.keys.toList();

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String? _filter;
  late Future<List<OrderInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<OrderInfo>> _load() async {
    final res = await context.read<ApiClient>().get('/admin/orders',
        query: _filter == null ? null : {'status': _filter});
    return (res as List).map((o) => OrderInfo.fromJson(o)).toList();
  }

  void _reload() => setState(() => _future = _load());

  void _setFilter(String? f) {
    _filter = f;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commandes')),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                FilterChip(
                  label: const Text('Tous'),
                  selected: _filter == null,
                  onSelected: (_) => _setFilter(null),
                ),
                const SizedBox(width: 8),
                ..._statuses.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(statusLabel(s)),
                        selected: _filter == s,
                        onSelected: (_) => _setFilter(s),
                      ),
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<OrderInfo>>(
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
                            onPressed: _reload,
                            child: const Text('Réessayer')),
                      ],
                    ),
                  );
                }
                final orders = snap.data ?? const [];
                if (orders.isEmpty) {
                  return const Center(
                      child: Text('Aucune commande pour ce filtre'));
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final o = orders[index];
                      return ListTile(
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(orderId: o.id)),
                          );
                          _reload();
                        },
                        title: Text(o.code,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          '${o.user?.fullName ?? 'Client #${o.user?.id ?? '—'}'}\n'
                          '${formatDate(o.createdAt)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.beigeDark.withValues(alpha: 0.4),
                          child: const Icon(Icons.receipt_long_outlined,
                              color: AppColors.textPrimary),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatXof(o.totalProductXof),
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _statusColor(o.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusLabel(o.status),
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'commande_recue':
        return const Color(0xFF0288D1);
      case 'achat_chine':
      case 'expedition':
      case 'en_transit':
        return const Color(0xFFF57C00);
      case 'arrivee_ci':
      case 'disponible_compagnie':
        return const Color(0xFF2E7D32);
      case 'recuperee':
        return const Color(0xFF00695C);
      case 'retour_entrepot':
        return const Color(0xFF6A1B9A);
      case 'annulee':
        return const Color(0xFFB71C1C);
      default:
        return AppColors.textMuted;
    }
  }
}