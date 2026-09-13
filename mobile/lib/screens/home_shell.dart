import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    final screens = const [
      HomeScreen(),
      CategoriesScreen(showAppBar: false),
      OrdersScreen(),
      CartScreen(),
      AccountScreen(),
    ];

    final labels = const ['Accueil', 'Catégories', 'Commandes', 'Panier', 'Compte'];
    final icons = const [
      Icons.storefront_outlined,
      Icons.grid_view_outlined,
      Icons.receipt_long_outlined,
      Icons.shopping_cart_outlined,
      Icons.person_outline,
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (var i = 0; i < labels.length; i++)
            NavigationDestination(
              icon: Stack(clipBehavior: Clip.none, children: [
                Icon(icons[i], color: Colors.white70),
                if (i == 3 && cart.count > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text('${cart.count}',
                          style: const TextStyle(color: Colors.white, fontSize: 9)),
                    ),
                  ),
              ]),
              selectedIcon: Icon(icons[i], color: Colors.white),
              label: labels[i],
            ),
        ],
      ),
    );
  }
}