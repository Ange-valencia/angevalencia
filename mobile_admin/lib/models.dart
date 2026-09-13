class Payment {
  final int id;
  final String type;
  final String method;
  final int amountXof;
  final String status;
  final String? operatorTransactionId;

  Payment({
    required this.id,
    required this.type,
    required this.method,
    required this.amountXof,
    required this.status,
    this.operatorTransactionId,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'],
        type: json['type'],
        method: json['method'],
        amountXof: json['amount_xof'],
        status: json['status'],
        operatorTransactionId: json['operator_transaction_id'],
      );
}

class PaymentConfig {
  final String? orangeMoneyNumber;
  final String? waveNumber;
  final String? instructions;

  PaymentConfig({
    this.orangeMoneyNumber,
    this.waveNumber,
    this.instructions,
  });

  factory PaymentConfig.fromJson(Map<String, dynamic> json) => PaymentConfig(
        orangeMoneyNumber: json['orange_money_number'],
        waveNumber: json['wave_number'],
        instructions: json['instructions'],
      );
}

class AdminUser {
  final int id;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;

  AdminUser({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.role = 'client',
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'],
        fullName: json['full_name'],
        email: json['email'],
        phone: json['phone'],
        role: json['role'] ?? 'client',
      );
}

class Category {
  final int id;
  final String name;
  final String? icon;
  final bool isClothing;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.isClothing = false,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        isClothing: json['is_clothing'] ?? false,
        sortOrder: json['sort_order'] ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'name': name, 'icon': icon, 'is_clothing': isClothing, 'sort_order': sortOrder, 'is_active': true};
}

class Product {
  final int id;
  final int? categoryId;
  final String name;
  final String? description;
  final int priceXof;
  final String deliveryDelayText;
  final bool isFlashOffer;
  final int? flashDiscountPct;
  final DateTime? flashEndsAt;
  final bool isPopular;
  final bool isActive;
  final List<String> images;
  final List<String> sizes;

  Product({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.priceXof,
    this.deliveryDelayText = '~2 mois',
    this.isFlashOffer = false,
    this.flashDiscountPct,
    this.flashEndsAt,
    this.isPopular = false,
    this.isActive = true,
    this.images = const [],
    this.sizes = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        categoryId: json['category_id'],
        name: json['name'],
        description: json['description'],
        priceXof: json['price_xof'],
        deliveryDelayText: json['delivery_delay_text'] ?? '~2 mois',
        isFlashOffer: json['is_flash_offer'] ?? false,
        flashDiscountPct: json['flash_discount_pct'],
        flashEndsAt: json['flash_ends_at'] != null
            ? DateTime.tryParse(json['flash_ends_at'])
            : null,
        isPopular: json['is_popular'] ?? false,
        isActive: json['is_active'] ?? true,
        images: ((json['images'] ?? []) as List)
            .map((i) => i['url'] as String)
            .toList(),
        sizes: ((json['sizes'] ?? []) as List)
            .map((s) => s['size_label'] as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'name': name,
        'description': description,
        'price_xof': priceXof,
        'delivery_delay_text': deliveryDelayText,
        'is_flash_offer': isFlashOffer,
        'flash_discount_pct': isFlashOffer ? flashDiscountPct : null,
        'flash_ends_at': isFlashOffer && flashEndsAt != null
            ? flashEndsAt!.toIso8601String()
            : null,
        'is_popular': isPopular,
        'is_active': isActive,
        'images': images,
        'sizes': sizes,
      };
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String? sizeLabel;
  final int unitPriceXof;
  final int quantity;
  final int lineTotalXof;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.sizeLabel,
    required this.unitPriceXof,
    required this.quantity,
    required this.lineTotalXof,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'],
        productId: json['product_id'],
        productName: json['product_name'],
        sizeLabel: json['size_label'],
        unitPriceXof: json['unit_price_xof'],
        quantity: json['quantity'],
        lineTotalXof: json['line_total_xof'],
      );
}

class OrderInfo {
  final int id;
  final String code;
  final String status;
  final int totalProductXof;
  final int? shippingFeeXof;
  final String shippingFeeStatus;
  final AdminUser? user;
  final List<OrderItem> items;
  final List<Payment> payments;
  final DateTime? createdAt;

  OrderInfo({
    required this.id,
    required this.code,
    required this.status,
    required this.totalProductXof,
    this.shippingFeeXof,
    this.shippingFeeStatus = 'pending',
    this.user,
    this.items = const [],
    this.payments = const [],
    this.createdAt,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) => OrderInfo(
        id: json['id'],
        code: json['code'],
        status: json['status'],
        totalProductXof: json['total_product_xof'],
        shippingFeeXof: json['shipping_fee_xof'],
        shippingFeeStatus: json['shipping_fee_status'] ?? 'pending',
        user: json['user'] != null
            ? AdminUser.fromJson(json['user'])
            : null,
        items: ((json['items'] ?? []) as List)
            .map((i) => OrderItem.fromJson(i))
            .toList(),
        payments: ((json['payments'] ?? []) as List)
            .map((p) => Payment.fromJson(p))
            .toList(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
      );
}

const orderStatusLabels = {
  'commande_recue': 'Commande reçue',
  'achat_chine': 'Achat en Chine',
  'expedition': 'Expédition',
  'en_transit': 'En transit',
  'arrivee_ci': 'Arrivée en CI',
  'disponible_compagnie': 'Disponible en compagnie',
  'recuperee': 'Récupérée',
  'retour_entrepot': 'Retour entrepôt',
  'annulee': 'Annulée',
};

String statusLabel(String status) => orderStatusLabels[status] ?? status;

String formatDate(DateTime? t) {
  if (t == null) return '';
  final d = t.toLocal();
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} $h:$m';
}