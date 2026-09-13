import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';

const _iconChoices = [
  'smartphone',
  'laptop',
  'checkroom',
  'home_work',
  'category',
  'watch',
  'perfume',
  'shopping_bag',
];

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Category>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Category>> _load() async {
    final res = await context.read<ApiClient>().get('/admin/categories');
    return (res as List).map((c) => Category.fromJson(c)).toList();
  }

  void _reload() => setState(() => _future = _load());

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _openDialog({Category? category}) async {
    final c = category;
    final nameCtrl = TextEditingController(text: c?.name ?? '');
    var icon = c?.icon ?? 'category';
    var isClothing = c?.isClothing ?? false;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(c == null ? 'Nouvelle catégorie' : 'Modifier la catégorie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: icon,
                decoration: const InputDecoration(labelText: 'Icône'),
                items: _iconChoices
                    .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                    .toList(),
                onChanged: (v) => setDialogState(() => icon = v ?? 'category'),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Catégorie de vêtements'),
                value: isClothing,
                onChanged: (v) => setDialogState(() => isClothing = v),
              ),
              Form(
                key: formKey,
                child: const SizedBox.shrink(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  _snack('Le nom est requis');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;
    if (!mounted) return;
    final name = nameCtrl.text.trim();
    final payload = {
      'name': name,
      'icon': icon,
      'is_clothing': isClothing,
      'sort_order': c?.sortOrder ?? 0,
      'is_active': true,
    };
    try {
      final api = context.read<ApiClient>();
      if (c == null) {
        await api.post('/admin/categories', body: payload);
      } else {
        await api.put('/admin/categories/${c.id}', body: payload);
      }
      if (mounted) _reload();
    } catch (e) {
      if (mounted) _snack('$e');
    }
  }

  Future<void> _delete(Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie ?'),
        content: Text('« ${c.name} » sera supprimée.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    try {
      await context.read<ApiClient>().delete('/admin/categories/${c.id}');
      if (mounted) _reload();
    } catch (e) {
      if (mounted) _snack('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: FutureBuilder<List<Category>>(
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
                  FilledButton(onPressed: _reload, child: const Text('Réessayer')),
                ],
              ),
            );
          }
          final categories = snap.data ?? const [];
          if (categories.isEmpty) {
            return const Center(child: Text('Aucune catégorie. Ajoutes-en avec +'));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 90),
              itemCount: categories.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final c = categories[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.isClothing ? const Color(0xFFFFF3E0) : const Color(0xFFE3F2FD),
                    child: Icon(Icons.category,
                        color: c.isClothing
                            ? const Color(0xFFE65100)
                            : const Color(0xFF1565C0)),
                  ),
                  title: Text(c.name),
                  subtitle: Text(c.isClothing ? 'Vêtements' : 'Ordre ${c.sortOrder}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openDialog(category: c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () => _delete(c),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}