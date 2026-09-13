import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/category_icon.dart';
import '../widgets/product_card.dart';
import 'categories_screen.dart';
import 'notifications_screen.dart';
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
                  const _HomeHeader(),
                  _PromoCarousel(products: products),
                  _SectionTitle(
                    'Catégories',
                    action: _SeeAllLink(
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CategoriesScreen(),
                      )),
                    ),
                  ),
                  _CategoriesRow(categories: categories),
                  _FlashSection(products: products),
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

/// En-tête : logo Ange (orange) Valencia (noir), cloche de notification
/// et barre de recherche.
class _HomeHeader extends StatefulWidget {
  const _HomeHeader();

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader> {
  final _searchCtrl = TextEditingController();
  List<AppNotification> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final api = context.read<ApiClient>();
      final json = await api.get('/notifications');
      if (!mounted) return;
      setState(() {
        _notifications =
            (json as List).map((n) => AppNotification.fromJson(n)).toList();
      });
    } catch (_) {}
  }

  void _search(String value) {
    if (value.trim().isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          ProductListScreen(query: value.trim(), title: 'Recherche'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.isRead).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                    children: [
                      TextSpan(
                          text: 'Ange', style: TextStyle(color: AppColors.orange)),
                      TextSpan(
                          text: 'Valencia', style: TextStyle(color: AppColors.black)),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      NotificationsScreen(notifications: _notifications),
                )),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none,
                        color: AppColors.textPrimary, size: 27),
                    if (unread > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          constraints:
                              const BoxConstraints(minWidth: 18, minHeight: 18),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text('$unread',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            decoration: InputDecoration(
              hintText: 'Rechercher un produit, une marque...',
              hintStyle:
                  const TextStyle(fontSize: 14, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carrousel promo basé sur les images produits, avec points de pagination.
class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel({required this.products});

  final List<Product> products;

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  late final PageController _controller;
  late final List<Product> _slides;
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _slides = widget.products.where((p) => p.images.isNotEmpty).take(5).toList();
    _controller = PageController();
    if (_slides.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) => _next());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (!_controller.hasClients || _slides.isEmpty) return;
    final next = (_current + 1) % _slides.length;
    _controller.animateToPage(next,
        duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) return const _BannerFallback();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          SizedBox(
            height: 168,
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, index) =>
                  _PromoSlide(product: _slides[index]),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _current ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _current ? AppColors.orange : AppColors.beigeDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoSlide extends StatelessWidget {
  const _PromoSlide({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    void open() => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product)));

    return GestureDetector(
      onTap: open,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF1F1A12), AppColors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (product.images.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 150,
                child: Image.network(
                  product.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF16130E).withValues(alpha: 0.92),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('PROMO',
                      style: TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2)),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(formatXof(product.priceEligible),
                      style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: open,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        child: Text('Voir',
                            style: TextStyle(
                                color: AppColors.orangeDark,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bannière statique affichée si aucun produit n'a d'image.
class _BannerFallback extends StatelessWidget {
  const _BannerFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, AppColors.orangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MODE ACHETER EN LIGNE',
              style: TextStyle(
                  color: Colors.white, fontSize: 12, letterSpacing: 1.5)),
          SizedBox(height: 8),
          Text('La Chine, à portée de main',
              style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text(
              'Livraison ~2 mois · Récupération en compagnie de transport',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          ?action,
        ],
      ),
    );
  }
}

class _SeeAllLink extends StatelessWidget {
  const _SeeAllLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Voir tout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Icon(Icons.arrow_forward_ios, size: 12),
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
      height: 84,
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
              width: 56,
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(categoryIcon(category.icon),
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 5),
                  Text(category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textPrimary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Section Offres Flash : fond noir, vrai compte à rebours HH:MM:SS
/// et petites cartes produits côte à côte.
class _FlashSection extends StatefulWidget {
  const _FlashSection({required this.products});

  final List<Product> products;

  @override
  State<_FlashSection> createState() => _FlashSectionState();
}

class _FlashSectionState extends State<_FlashSection> {
  Timer? _ticker;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    final activeEnds = widget.products
        .where((p) => p.isFlashActive && p.flashEndsAt != null)
        .map((p) => p.flashEndsAt!)
        .where((d) => d.isAfter(DateTime.now()));
    if (activeEnds.isNotEmpty) {
      _end = activeEnds.reduce((a, b) => a.isBefore(b) ? a : b);
    } else {
      _end = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
          .add(const Duration(days: 1));
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flash = widget.products.where((p) => p.isFlashActive).toList();
    if (flash.isEmpty) return const SizedBox.shrink();

    final remaining = _end!.difference(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.only(top: 16, bottom: 18),
      color: AppColors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Offres Flash',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                _Countdown(
                    remaining: remaining.isNegative ? Duration.zero : remaining),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: Text('Se termine dans',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          SizedBox(
            height: 192,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: flash.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = flash[index];
                return SizedBox(
                  width: 148,
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
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    Widget unit(String value) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2419),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value,
              style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()])),
        );

    Widget separator() => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Text(':',
              style: TextStyle(
                  color: Color(0xFFFFD54F), fontWeight: FontWeight.w800)),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [unit(h), separator(), unit(m), separator(), unit(s)],
    );
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