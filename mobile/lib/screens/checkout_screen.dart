import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/payment_instructions.dart';
import 'order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<City>? _cities;
  List<TransportCompany>? _companies;
  PaymentConfig? _payConfig;
  City? _city;
  TransportCompany? _company;
  String _method = 'orange_money';
  final _txCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCities();
    _loadPayConfig();
  }

  Future<void> _loadPayConfig() async {
    try {
      final api = context.read<ApiClient>();
      final json = await api.get('/payments/config');
      if (mounted) setState(() => _payConfig = PaymentConfig.fromJson(json));
    } catch (e) {
      // La config ne bloquera pas la commande en cas d'échec réseau.
    }
  }

  Future<void> _loadCities() async {
    try {
      final api = context.read<ApiClient>();
      final json = await api.get('/transport/cities');
      final cities = (json as List).map((c) => City.fromJson(c)).toList();
      final defaultCity =
          cities.where((c) => c.id == context.read<AuthProvider>().user?.cityId).firstOrNull;
      setState(() {
        _cities = cities;
        if (defaultCity != null) _city = defaultCity;
      });
      if (_city != null) await _loadCompanies();
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _loadCompanies() async {
    final api = context.read<ApiClient>();
    final json = await api.get('/transport/cities/${_city!.id}/companies');
    final data = CityCompanies(
      city: City.fromJson(json['city']),
      companies: ((json['companies'] ?? []) as List)
          .map((c) => TransportCompany.fromJson(c))
          .toList(),
    );
    if (!mounted) return;
    setState(() {
      _companies = data.companies;
      _company = _companies!.firstOrNull;
    });
  }

  @override
  void dispose() {
    _txCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = context.read<CartProvider>();
    if (cart.totalXof < minOrderXof) {
      setState(() =>
          _error = 'Le montant minimum de commande est de 3 000 FCFA');
      return;
    }
    if (_city == null) {
      setState(() => _error = 'Choisissez votre ville de récupération');
      return;
    }
    if (_company == null) {
      setState(() => _error = 'Aucune compagnie ne dessert votre ville');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final cart = context.read<CartProvider>();
      final json = await api.post('/orders', body: {
        'items': cart.lines
            .map((l) => {
                  'product_id': l.product.id,
                  'quantity': l.quantity,
                  'size_label': l.sizeLabel,
                })
            .toList(),
        'city_id': _city!.id,
        'company_id': _company!.id,
        'payment_method': _method,
        'operator_transaction_id': _txCtrl.text.trim().isEmpty
            ? null
            : _txCtrl.text.trim(),
      });
      final order = Order.fromJson(json);
      cart.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
        (route) => route.isFirst,
      );
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Finaliser la commande')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card('Panier — ${formatXof(cart.totalXof)}', [
            for (final line in cart.lines)
              Text('${line.quantity}× ${line.product.name}'
                  '${line.sizeLabel != null ? ' (${line.sizeLabel})' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 14),
          _card('Ville de récupération', [
            _Dropdown<City>(
              value: _city,
              items: _cities,
              label: (c) => c.name,
              onChanged: (c) {
                setState(() {
                  _city = c;
                  _company = null;
                  _companies = null;
                });
                if (c != null) _loadCompanies();
              },
            ),
          ]),
          if (_companies != null) ...[
            const SizedBox(height: 14),
            _card('Compagnie de transport', [
              _Dropdown<TransportCompany>(
                value: _company,
                items: _companies,
                label: (c) => c.name,
                onChanged: (c) => setState(() => _company = c),
              ),
              const SizedBox(height: 8),
              Text(
                  'Votre colis sera livré à cette compagnie. Vous le récupérez '
                  'après paiement des frais de transport (au comptoir ou par ON / Wave).',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ],
          const SizedBox(height: 14),
          _card('Paiement du produit (à la commande)', [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'orange_money', label: Text('Orange Money')),
                ButtonSegment(value: 'wave', label: Text('Wave')),
              ],
              selected: {_method},
              onSelectionChanged: (s) => setState(() => _method = s.first),
            ),
            PaymentInstructions(
              config: _payConfig,
              method: _method,
              amountXof: cart.totalXof,
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _txCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Code de la transaction reçu',
                hintText: 'Ex : 2024812345',
                helperText:
                    'Envoie le montant exact au numéro indiqué puis saisis ici le code SMS de paiement.',
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppColors.orangeDark),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                    'Livraison estimée à environ 2 mois depuis la Chine. '
                    'Le paiement du transport est demandé à l\'arrivée.',
                    style: TextStyle(fontSize: 13)),
              ),
            ]),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Payer ${formatXof(cart.totalXof)}'),
          ),
        ),
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
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      );
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  final T? value;
  final List<T>? items;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Sélectionner'),
      items: (items ?? [])
          .map((item) => DropdownMenuItem(value: item, child: Text(label(item))))
          .toList(),
      onChanged: onChanged,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}