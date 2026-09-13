import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.category, this.title, this.query});

  final Category? category;
  final String? title;
  final String? query;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Product>> _load() async {
    final api = context.read<ApiClient>();
    final query = <String, dynamic>{
      if (widget.category != null) 'category_id': '${widget.category!.id}',
      if (widget.query != null && widget.query!.trim().isNotEmpty)
        'q': widget.query!.trim(),
    };
    final json = await api.get(
        '/catalog/products', query: query.isEmpty ? null : query);
    return (json as List).map((p) => Product.fromJson(p)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.title ??
              widget.category?.name ??
              (widget.query != null ? 'Résultats' : 'Produits'))),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('${snap.error}',
                    style: const TextStyle(color: AppColors.error)));
          }
          final products = snap.data ?? [];
          if (products.isEmpty) {
            return Center(
                child: Text(
                    widget.query != null
                        ? 'Aucun résultat pour cette recherche'
                        : 'Aucun produit dans cette catégorie'));
          }
          return GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
            children: products
                .map((p) => ProductCard(
                      product: p,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: p))),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}