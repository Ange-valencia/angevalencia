import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'product_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<(List<Category>, List<Product>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<Category>, List<Product>)> _load() async {
    final api = context.read<ApiClient>();
    final categories = (await api.get('/catalog/categories') as List)
        .map((c) => Category.fromJson(c))
        .toList();
    final products = (await api.get('/catalog/products') as List)
        .map((p) => Product.fromJson(p))
        .toList();
    return (categories, products);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: FutureBuilder<(List<Category>, List<Product>)>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return _ErrorView(
                  message: '${snap.error}',
                  onRetry: _refresh,
                );
              }
              final (categories, products) =
                  snap.data ?? (const <Category>[], const <Product>[]);
              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const _BannerPromo(),
                  _SectionTitle('Catégories'),
                  _CategoriesRow(categories: categories),
                  _FlashOffers(products: products),
                  _SectionTitle('Produits populaires'),
                  _PopularGrid(products: products, all: products),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('Impossible de charger le catalogue'),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _BannerPromo extends StatelessWidget {
  const _BannerPromo();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, AppColors.orangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MODE ACHETER EN LIGNE',
              style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          const Text('La Chine, à portée de main',
              style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Livraison ~2 mois · Récupération en compagnie de transport',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text('Découvrir',
                style: TextStyle(
                    color: AppColors.orangeDark, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ?action,
        ],
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final category = categories[index];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProductListScreen(category: category),
            )),
            child: SizedBox(
              width: 62,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_icon(category.icon), color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _icon(String? name) => switch (name) {
        'smartphone' => Icons.smartphone,
        'laptop' => Icons.laptop,
        'checkroom' => Icons.checkroom,
        'home' => Icons.home,
        _ => Icons.widgets,
      };
}

class _FlashOffers extends StatelessWidget {
  const _FlashOffers({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final flash = products.where((p) => p.isFlashActive).toList();
    if (flash.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          'Offres flash',
          action: const _FlashCountdown(),
        ),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: flash.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = flash[index];
              return SizedBox(
                width: 150,
                child: ProductCard(
                  product: product,
                  compact: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product))),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FlashCountdown extends StatefulWidget {
  const _FlashCountdown();

  @override
  State<_FlashCountdown> createState() => _FlashCountdownState();
}

class _FlashCountdownState extends State<_FlashCountdown> {
  DateTime? _end;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _end ??= DateTime.now().add(const Duration(days: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Text('Se termine dans ~2j',
        style: const TextStyle(color: AppColors.orangeDark, fontSize: 12));
  }
}

class _PopularGrid extends StatelessWidget {
  const _PopularGrid({required this.products, required this.all});

  final List<Product> products;
  final List<Product> all;

  @override
  Widget build(BuildContext context) {
    final popular = products.where((p) => p.isPopular).toList();
    final shown = popular.isNotEmpty ? popular : all.take(6).toList();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.72,
      children: shown
          .map((p) => ProductCard(
                product: p,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: p))),
              ))
          .toList(),
    );
  }
}