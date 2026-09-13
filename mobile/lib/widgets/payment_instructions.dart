import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class PaymentInstructions extends StatelessWidget {
  const PaymentInstructions({
    super.key,
    required this.config,
    required this.method,
    required this.amountXof,
  });

  final PaymentConfig? config;
  final String method;
  final int amountXof;

  @override
  Widget build(BuildContext context) {
    final number = config?.numberFor(method);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envoie ${formatXof(amountXof)} par ${config?.labelFor(method) ?? method}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 6),
            if (number != null)
              SelectableText(
                number,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppColors.orangeDark),
              ),
            if (number == null)
              const Text('Numéro de réception à venir.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            if (config?.instructions != null && config!.instructions!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(config!.instructions!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}