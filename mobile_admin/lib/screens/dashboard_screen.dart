import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_auth.dart';
import '../theme.dart';
import 'categories_screen.dart';
import 'clients_screen.dart';
import 'orders_screen.dart';
import 'products_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuth>();
    final admin = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion AngeValencia'),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (admin != null) ...[
            Text(
              'Bonjour ${admin.fullName}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text('Que veux-tu faire aujourd’hui ?',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 18),
          ],
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.15,
            children: [
              _Tile(
                icon: Icons.inventory_2_outlined,
                label: 'Produits',
                subtitle: 'Catalogue & prix',
                color: AppColors.orange,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ProductsScreen())),
              ),
              _Tile(
                icon: Icons.category_outlined,
                label: 'Catégories',
                subtitle: 'Organisation',
                color: const Color(0xFF2E7D32),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CategoriesScreen())),
              ),
              _Tile(
                icon: Icons.receipt_long_outlined,
                label: 'Commandes',
                subtitle: 'Suivi & statuts',
                color: const Color(0xFF1565C0),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const OrdersScreen())),
              ),
              _Tile(
                icon: Icons.people_outline,
                label: 'Clients',
                subtitle: 'Inscriptions',
                color: const Color(0xFF6A1B9A),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ClientsScreen())),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.beigeLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.beigeDark, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}