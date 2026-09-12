import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/cart_provider.dart';
import '../theme.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = context.read<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du produit')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _gallery(product),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (product.isFlashActive) ...[
                      Text(formatXof(product.priceXof),
                          style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 8),
                    ],
                    Text(formatXof(product.priceEligible),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.orangeDark)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.flight_takeoff, size: 20, color: AppColors.orangeDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Livraison estimée : ${product.deliveryDelayText}.\n'
                        'Le colis arrive en compagnie de transport, vous le récupérez après '
                        'paiement des frais de transport.',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                  ]),
                ),
                if (product.sizes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Tailles disponibles',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: product.sizes
                        .map((s) => ChoiceChip(
                              label: Text(s.label),
                              selected: _selectedSize == s.label,
                              onSelected: (_) => setState(() => _selectedSize = s.label),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Description',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(product.description ?? 'Aucune description fournie.',
                    style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
                const SizedBox(height: 20),
                Row(children: [
                  const Text('Quantité', style: TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_quantity', style: const TextStyle(fontSize: 16)),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: () {
              if (widget.product.sizes.isNotEmpty && _selectedSize == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Choisissez une taille d\'abord')));
                return;
              }
              cart.add(product, quantity: _quantity, sizeLabel: _selectedSize);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Ajouté au panier · ${cart.totalXof} FCFA'),
                action: SnackBarAction(
                  label: 'Voir le panier',
                  textColor: Colors.white,
                  onPressed: () => Navigator.of(context).pushNamed('/cart'),
                ),
              ));
            },
            child: const Text('Ajouter au panier'),
          ),
        ),
      ),
    );
  }

  Widget _gallery(Product product) {
    if (product.images.isEmpty) {
      return Container(
        height: 260,
        color: AppColors.beigeDark.withValues(alpha: 0.4),
        child: const Icon(Icons.image_outlined, size: 72, color: AppColors.textMuted),
      );
    }
    return SizedBox(
      height: 260,
      child: PageView.builder(
        itemCount: product.images.length,
        itemBuilder: (context, index) => Image.network(
          product.images[index],
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.image_outlined,
              size: 72, color: AppColors.textMuted),
        ),
      ),
    );
  }
}