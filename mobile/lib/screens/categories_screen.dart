import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/category_icon.dart';
import 'product_list_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

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
    final api = context.read<ApiClient>();
    final json = await api.get('/catalog/categories');
    return (json as List).map((c) => Category.fromJson(c)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: widget.showAppBar ? AppBar(title: const Text('Catégories')) : null,
      body: SafeArea(
        child: FutureBuilder<List<Category>>(
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
            final categories = snap.data ?? const [];
            if (categories.isEmpty) {
              return const Center(child: Text('Aucune catégorie'));
            }
            return GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(20),
              mainAxisSpacing: 20,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: categories
                  .map((c) => InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProductListScreen(category: c),
                        )),
                        child: Column(
                          children: [
                            Container(
                              width: 66,
                              height: 66,
                              decoration: const BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(categoryIcon(c.icon),
                                  color: Colors.white, size: 30),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}