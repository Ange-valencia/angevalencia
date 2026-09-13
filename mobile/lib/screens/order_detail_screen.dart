import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/payment_instructions.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<Order> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Order> _load() async {
    final api = context.read<ApiClient>();
    final json = await api.get('/orders/${widget.orderId}');
    return Order.fromJson(json);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suivi de commande')),
      body: FutureBuilder<Order>(
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
          final order = snap.data!;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(order.code,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Commandé le ${_date(order.createdAt)}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 16),
                _StatusStepper(current: order.status),
                const SizedBox(height: 16),
                if (order.status == 'disponible_compagnie' &&
                    order.shippingFeeStatus != 'paid' &&
                    order.shippingFeeXof != null)
                  _ShippingPaymentCard(order: order, onPaid: _refresh),
                const SizedBox(height: 16),
                _card('Articles', [
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}× ${item.productName}'
                              '${item.sizeLabel != null ? ' (${item.sizeLabel})' : ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(formatXof(item.lineTotalXof),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total produits', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(formatXof(order.totalProductXof),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: AppColors.orangeDark)),
                    ],
                  ),
                  if (order.shippingFeeXof != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Frais de transport', style: TextStyle(fontSize: 13)),
                        Text(formatXof(order.shippingFeeXof!),
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                ]),
                const SizedBox(height: 14),
                _card('Paiements', [
                  for (final payment in order.payments.reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            payment.status == 'success'
                                ? Icons.check_circle
                                : Icons.hourglass_top,
                            size: 18,
                            color: payment.status == 'success'
                                ? AppColors.success
                                : AppColors.orangeDark,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${payment.type == 'shipping' ? 'Frais de transport' : 'Produit'} '
                              '· ${payment.method == 'orange_money' ? 'Orange Money' : 'Wave'}'
                              '${payment.operatorTransactionId != null ? '\nCode : ${payment.operatorTransactionId}' : ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatXof(payment.amountXof),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(
                                _paymentStatusLabel(payment.status),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: payment.status == 'success'
                                        ? AppColors.success
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ]),
                const SizedBox(height: 14),
                _card('Historique', [
                  for (final entry in order.statusHistory.reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle,
                              size: 18,
                              color: (orderSteps.contains(entry.status) &&
                                      orderSteps.indexOf(order.status) >=
                                          orderSteps.indexOf(entry.status))
                                  ? AppColors.success
                                  : AppColors.textMuted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(orderStepLabels[entry.status] ?? entry.status,
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600)),
                                if (entry.note != null)
                                  Text(entry.note!,
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.textMuted)),
                                if (entry.changedAt != null)
                                  Text(_date(entry.changedAt),
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.beigeLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.beigeDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );

  String _date(DateTime? dt) {
    if (dt == null) return '-';
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _paymentStatusLabel(String status) {
    switch (status) {
      case 'success':
        return 'Validé';
      case 'failed':
        return 'Échoué';
      case 'refunded':
        return 'Remboursé';
      default:
        return 'En attente de validation';
    }
  }
}

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    final currentIndex = orderSteps.indexOf(current);
    if (currentIndex < 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.beigeLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.beigeDark),
        ),
        child: Text(orderStepLabels[current] ?? current,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    return Column(
      children: List.generate(orderSteps.length, (index) {
        final step = orderSteps[index];
        final done = index <= currentIndex;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 22,
                color: done ? AppColors.success : AppColors.textMuted,
              ),
              if (index < orderSteps.length - 1)
                Container(
                  width: 2,
                  height: 22,
                  color: done ? AppColors.success : AppColors.beigeDark,
                ),
            ]),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 14),
              child: Text(
                orderStepLabels[step] ?? step,
                style: TextStyle(
                  fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                  color: done ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ShippingPaymentCard extends StatefulWidget {
  const _ShippingPaymentCard({required this.order, required this.onPaid});

  final Order order;
  final VoidCallback onPaid;

  @override
  State<_ShippingPaymentCard> createState() => _ShippingPaymentCardState();
}

class _ShippingPaymentCardState extends State<_ShippingPaymentCard> {
  String _method = 'orange_money';
  PaymentConfig? _config;
  final _txCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final api = context.read<ApiClient>();
      final json = await api.get('/payments/config');
      if (mounted) setState(() => _config = PaymentConfig.fromJson(json));
    } catch (_) {
      // La config ne bloque pas le paiement en cas d'échec réseau.
    }
  }

  @override
  void dispose() {
    _txCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      final api = context.read<ApiClient>();
      await api.post('/orders/${widget.order.id}/pay-shipping', body: {
        'payment_method': _method,
        'operator_transaction_id': _txCtrl.text.trim().isEmpty
            ? null
            : _txCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Paiement envoyé — un administrateur va vérifier sous peu.')));
      widget.onPaid();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.local_shipping_outlined, color: AppColors.orangeDark),
            const SizedBox(width: 8),
            const Text('Colis disponible — payer les frais de transport',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          Text('Frais de transport : ${formatXof(widget.order.shippingFeeXof!)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'orange_money', label: Text('Orange Money')),
              ButtonSegment(value: 'wave', label: Text('Wave')),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
          ),
          PaymentInstructions(
            config: _config,
            method: _method,
            amountXof: widget.order.shippingFeeXof!,
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _txCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Code de la transaction reçu',
              hintText: 'Ex : 2024812345',
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _pay,
              child: _busy
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Payer les frais de transport'),
            ),
          ),
        ],
      ),
    );
  }
}