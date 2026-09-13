import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';
import '../theme.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<(List<Product>, List<Category>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<Product>, List<Category>)> _load() async {
    final api = context.read<ApiClient>();
    final products = (await api.get('/admin/products') as List)
        .map((p) => Product.fromJson(p))
        .toList();
    final categories = (await api.get('/admin/categories') as List)
        .map((c) => Category.fromJson(c))
        .toList();
    return (products, categories);
  }

  void _reload() => setState(() => _future = _load());

  String _categoryName(List<Category> categories, int? id) =>
      categories.where((c) => c.id == id).map((c) => c.name).firstOrNull ??
      '—';

  Future<void> _delete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le produit ?'),
        content: Text('« ${p.name} » sera supprimé du catalogue.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    try {
      await context.read<ApiClient>().delete('/admin/products/${p.id}');
      if (mounted) _reload();
    } catch (e) {
      if (mounted) _snack('$e');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          if (created == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: FutureBuilder<(List<Product>, List<Category>)>(
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
                  Text('${snap.error}',
                      style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('Réessayer')),
                ],
              ),
            );
          }
          final (products, categories) =
              snap.data ?? (const <Product>[], const <Category>[]);
          if (products.isEmpty) {
            return const Center(child: Text('Aucun produit. Ajoute-en un avec +'));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 90),
              itemCount: products.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final p = products[index];
                return ListTile(
                  leading: p.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            p.images.first,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _NoImage(),
                          ),
                        )
                      : const _NoImage(),
                  title: Text(p.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${formatXof(p.priceXof)} · ${_categoryName(categories, p.categoryId)}'
                    '${p.isActive ? '' : ' · (inactif)'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p.isFlashOffer)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.bolt,
                              color: AppColors.orange, size: 18),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          final ok = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                                builder: (_) =>
                                    ProductFormScreen(product: p, categories: categories)),
                          );
                          if (ok == true) _reload();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        onPressed: () => _delete(p),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NoImage extends StatelessWidget {
  const _NoImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
          color: AppColors.beigeDark.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.image_outlined,
          size: 20, color: AppColors.textMuted),
    );
  }
}