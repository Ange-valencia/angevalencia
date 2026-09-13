import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../theme.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final belowMin = cart.totalXof > 0 && cart.totalXof < minOrderXof;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon panier')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.orange.withValues(alpha: 0.08),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 18, color: AppColors.orangeDark),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Commande minimum : 3 000 FCFA',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('Votre panier est vide'),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final line = cart.lines[index];
                      return _CartLineTile(line: line);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(formatXof(cart.totalXof),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.orangeDark)),
                      ],
                    ),
                    if (belowMin) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez encore ${formatXof(minOrderXof - cart.totalXof)} '
                        'pour atteindre le minimum de commande.',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: belowMin
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                      child: const Text('Commander'),
                    ),
                    const SizedBox(height: 4),
                    const Text('Paiement ON / Wave à la commande · '
                        'Frais de transport payés à l\'arrivée',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final product = line.product;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.beigeLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.beigeDark),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.beigeDark.withValues(alpha: 0.4),
            ),
            child: product.images.isEmpty
                ? const Icon(Icons.image_outlined, color: AppColors.textMuted)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.image_outlined)),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (line.sizeLabel != null)
                  Text('Taille : ${line.sizeLabel}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(formatXof(line.lineTotalXof),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.orangeDark)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                iconSize: 20,
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => cart.setQuantity(line, line.quantity - 1),
              ),
              Text('${line.quantity}'),
              IconButton(
                iconSize: 20,
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => cart.setQuantity(line, line.quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}