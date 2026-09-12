import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap, this.compact = false});

  final Product product;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.beigeLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.beigeDark, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _image(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  if (product.isFlashActive) ...[
                    Text(formatXof(product.priceXof),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough)),
                    Text(formatXof(product.priceEligible),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orangeDark)),
                  ] else
                    Text(formatXof(product.priceXof),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(product.deliveryDelayText,
                        style:
                            const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    return SizedBox(
      height: compact ? 110 : 140,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (product.images.isNotEmpty)
            Image.network(
              product.images.first,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ImageFallback(),
            )
          else
            const _ImageFallback(),
          if (product.isFlashActive)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.orange, borderRadius: BorderRadius.circular(6)),
                child: Text('-${product.discount}%',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          if (product.isPopular)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('POPULAIRE',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.beigeDark.withValues(alpha: 0.4),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 42, color: AppColors.textMuted),
      ),
    );
  }
}