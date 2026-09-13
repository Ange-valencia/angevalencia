import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product, this.categories = const []});

  final Product? product;
  final List<Category> categories;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _deliveryCtrl;
  late final List<TextEditingController> _imageCtrls;
  late final List<TextEditingController> _sizeCtrls;

  late int? _categoryId;
  late bool _isFlash;
  late int _flashPct;
  DateTime? _flashEnds;
  late bool _isPopular;
  late bool _isActive;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl =
        TextEditingController(text: p != null ? p.priceXof.toString() : '');
    _deliveryCtrl =
        TextEditingController(text: p?.deliveryDelayText ?? '~2 mois');
    _imageCtrls = (p?.images ?? const [''])
        .map((u) => TextEditingController(text: u))
        .toList();
    if (_imageCtrls.length > 5) _imageCtrls.removeRange(5, _imageCtrls.length);
    _sizeCtrls = ((p != null && p.sizes.isNotEmpty) ? p.sizes : const ['M', 'L', 'XL'])
        .take(6)
        .map((s) => TextEditingController(text: s))
        .toList();
    _categoryId = p?.categoryId ?? widget.categories.firstOrNull?.id;
    _isFlash = p?.isFlashOffer ?? false;
    _flashPct = p?.flashDiscountPct ?? 20;
    _flashEnds = p?.flashEndsAt;
    _isPopular = p?.isPopular ?? false;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _deliveryCtrl.dispose();
    for (final c in _imageCtrls) {
      c.dispose();
    }
    for (final c in _sizeCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFlashEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _flashEnds ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(() =>
        _flashEnds = DateTime(date.year, date.month, date.day, 23, 59, 59));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final priceText = _priceCtrl.text.replaceAll(' ', '').replaceAll(',', '.');
    final price = int.tryParse(priceText);
    if (name.isEmpty || price == null || price <= 0) {
      _snack('Renseigne au moins le nom et un prix valide');
      return;
    }
    final images = _imageCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final sizes = _sizeCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

    final product = Product(
      id: widget.product?.id ?? 0,
      categoryId: _categoryId,
      name: name,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      priceXof: price,
      deliveryDelayText: _deliveryCtrl.text.trim().isEmpty ? '~2 mois' : _deliveryCtrl.text.trim(),
      isFlashOffer: _isFlash,
      flashDiscountPct: _flashPct,
      flashEndsAt: _isFlash ? _flashEnds : null,
      isPopular: _isPopular,
      isActive: _isActive,
      images: images,
      sizes: sizes,
    );

    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      if (widget.product == null) {
        await api.post('/admin/products', body: product.toJson());
      } else {
        await api.put('/admin/products/${widget.product!.id}',
            body: product.toJson());
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('$e');
      }
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Nouveau produit' : 'Modifier le produit'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _loading ? null : _save,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(widget.product == null ? 'Créer le produit' : 'Enregistrer'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom du produit *'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'Catégorie'),
            items: widget.categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
                labelText: 'Prix (FCFA) *', hintText: '25000'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deliveryCtrl,
            decoration: const InputDecoration(
                labelText: 'Délai de livraison', hintText: '~2 mois'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Produit populaire'),
            value: _isPopular,
            onChanged: (v) => setState(() => _isPopular = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Actif (visible dans l’app client)'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Offre Flash'),
            subtitle: Text(_isFlash ? '-$_flashPct% en vitrine' : 'Activer l’offre flash'),
            value: _isFlash,
            onChanged: (v) => setState(() => _isFlash = v),
          ),
          if (_isFlash) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '$_flashPct',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: 'Réduction %', hintText: '20'),
                    onChanged: (v) =>
                        _flashPct = int.tryParse(v) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFlashEnd,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _flashEnds == null
                          ? 'Choisir la fin'
                          : 'Fin : ${_flashEnds!.day}/${_flashEnds!.month}',
                    ),
                  ),
                ),
              ],
            ),
            if (_flashEnds != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'L’offre se terminera le '
                  '${_flashEnds!.day.toString().padLeft(2, '0')}/'
                  '${_flashEnds!.month.toString().padLeft(2, '0')} à 23:59',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
          const Divider(height: 32),
          Text('Photos (URLs)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._imageCtrls.asMap().entries.map((e) => Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: e.value,
                      decoration: InputDecoration(
                        labelText: 'Image ${e.key + 1}',
                        hintText: 'https://…',
                        prefixIcon: const Icon(Icons.link),
                      ),
                    ),
                  ),
                  if (_imageCtrls.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: () => setState(() {
                        _imageCtrls.removeAt(e.key);
                      }),
                    ),
                ],
              )),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _imageCtrls.length >= 5
                  ? null
                  : () => setState(() {
                        _imageCtrls.add(TextEditingController());
                      }),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une image'),
            ),
          ),
          const Divider(height: 24),
          Text('Tailles disponibles',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._sizeCtrls.asMap().entries.map((e) => Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: e.value,
                      decoration: InputDecoration(
                          labelText: 'Taille ${e.key + 1}', hintText: 'M'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red),
                    onPressed: () => setState(() {
                      _sizeCtrls.removeAt(e.key);
                    }),
                  ),
                ],
              )),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _sizeCtrls.length >= 6
                  ? null
                  : () => setState(() {
                        _sizeCtrls.add(TextEditingController());
                      }),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une taille'),
            ),
          ),
        ],
      ),
    );
  }
}