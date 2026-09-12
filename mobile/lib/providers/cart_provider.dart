import 'package:flutter/foundation.dart';

import '../models.dart';

class CartLine {
  final Product product;
  final int quantity;
  final String? sizeLabel;

  CartLine({required this.product, required this.quantity, this.sizeLabel});

  int get lineTotalXof => product.priceEligible * quantity;
  bool get sameProduct => product.id == product.id;
}

class CartProvider extends ChangeNotifier {
  final List<CartLine> _lines = [];

  List<CartLine> get lines => List.unmodifiable(_lines);
  bool get isEmpty => _lines.isEmpty;

  int get totalXof => _lines.fold(0, (sum, l) => sum + l.lineTotalXof);
  int get count => _lines.fold(0, (sum, l) => sum + l.quantity);

  void add(Product product, {int quantity = 1, String? sizeLabel}) {
    final existing = _lines.indexWhere((l) =>
        l.product.id == product.id && l.sizeLabel == sizeLabel);
    if (existing >= 0) {
      _lines[existing] = CartLine(
        product: product,
        quantity: _lines[existing].quantity + quantity,
        sizeLabel: sizeLabel,
      );
    } else {
      _lines.add(CartLine(product: product, quantity: quantity, sizeLabel: sizeLabel));
    }
    notifyListeners();
  }

  void remove(CartLine line) {
    _lines.remove(line);
    notifyListeners();
  }

  void setQuantity(CartLine line, int quantity) {
    if (quantity <= 0) {
      remove(line);
      return;
    }
    final index = _lines.indexOf(line);
    _lines[index] = CartLine(product: line.product, quantity: quantity, sizeLabel: line.sizeLabel);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}