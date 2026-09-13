import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';
import '../theme.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<OrderInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<OrderInfo> _load() async {
    final res = await context.read<ApiClient>().get('/admin/orders');
    final list = (res as List).map((o) => OrderInfo.fromJson(o)).toList();
    return list.firstWhere((o) => o.id == widget.orderId,
        orElse: () => list.first);
  }

  void _reload() => setState(() => _future = _load());

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _save(OrderInfo order, String newStatus, String? note,
      int? shippingFee) async {
    try {
      final body = <String, dynamic>{'status': newStatus};
      if (note != null && note.isNotEmpty) body['note'] = note;
      if (newStatus == 'disponible_compagnie') body['shipping_fee_xof'] = shippingFee;
      await context
          .read<ApiClient>()
          .put('/admin/orders/${order.id}/status', body: body);
      _reload();
    } catch (e) {
      _snack('$e');
    }
  }

  Future<void> _confirmPayment(Payment p) async {
    try {
      await context.read<ApiClient>().post('/admin/payments/${p.id}/confirm');
      _reload();
    } catch (e) {
      _snack('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la commande')),
      body: FutureBuilder<OrderInfo>(
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
                  Text('${snap.error}'),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: _reload, child: const Text('Réessayer')),
                ],
              ),
            );
          }
          final o = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(o.code,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Passée le ${formatDate(o.createdAt)}',
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              _section('Client', [
                _row(Icons.person_outline, o.user?.fullName ?? '—'),
                if (o.user?.phone != null)
                  _row(Icons.phone_outlined, o.user!.phone!),
                if (o.user?.email != null)
                  _row(Icons.mail_outline, o.user!.email!),
              ]),
              _section('Article(s)', [
                ...o.items.map((it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${it.quantity} × ${it.productName}'
                              '${it.sizeLabel != null ? ' (${it.sizeLabel})' : ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(formatXof(it.lineTotalXof),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )),
                const Divider(height: 14),
                _totalRow('Total produits', o.totalProductXof),
                _totalRow(
                  'Frais de transport',
                  o.shippingFeeXof,
                ),
              ]),
              _section('Paiements', [
                if (o.payments.isEmpty)
                  const Text('Aucun paiement enregistré',
                      style: TextStyle(color: AppColors.textMuted)),
                ...o.payments.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${p.type == 'product' ? 'Produit' : 'Transport'} · ${p.method}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(formatXof(p.amountXof),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          if (p.status == 'pending')
                            TextButton(
                              onPressed: () => _confirmPayment(p),
                              child: const Text('Confirmer'),
                            )
                          else
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                        ],
                      ),
                    )),
              ]),
              _section('Statut de livraison', [
                StatusEditor(
                  order: o,
                  onSave: (status, note, fee) =>
                      _save(o, status, note, fee),
                ),
              ]),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.beigeLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.beigeDark.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.orange)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );

  Widget _totalRow(String label, int? amount) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            Text(amount != null ? formatXof(amount) : '—',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class StatusEditor extends StatefulWidget {
  const StatusEditor({super.key, required this.order, required this.onSave});

  final OrderInfo order;
  final Future<void> Function(String status, String? note, int? fee) onSave;

  @override
  State<StatusEditor> createState() => _StatusEditorState();
}

class _StatusEditorState extends State<StatusEditor> {
  late String _status;
  late final TextEditingController _feeCtrl;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
    _feeCtrl =
        TextEditingController(text: '${widget.order.shippingFeeXof ?? ''}');
  }

  @override
  void dispose() {
    _feeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requiresFee = _status == 'disponible_compagnie';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Changer le statut'),
          isExpanded: true,
          items: orderStatusLabels.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => setState(() => _status = v ?? _status),
        ),
        if (requiresFee) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _feeCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Frais de transport (FCFA)',
              hintText: '3000',
            ),
          ),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _noteCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Note (optionnelle)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    final fee =
                        int.tryParse(_feeCtrl.text.replaceAll(' ', ''));
                    await widget
                        .onSave(_status, _noteCtrl.text.trim(),
                            requiresFee ? fee : null)
                        .whenComplete(() {
                      if (mounted) setState(() => _saving = false);
                    });
                  },
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Enregistrer le statut'),
          ),
        ),
      ],
    );
  }
}