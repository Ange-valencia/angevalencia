class User {
  final int id;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final int? cityId;
  final int? preferredCompanyId;

  User({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.role = 'client',
    this.cityId,
    this.preferredCompanyId,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        fullName: json['full_name'],
        email: json['email'],
        phone: json['phone'],
        role: json['role'] ?? 'client',
        cityId: json['city_id'],
        preferredCompanyId: json['preferred_company_id'],
      );

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'city_id': cityId,
        'preferred_company_id': preferredCompanyId,
      };
}

class Category {
  final int id;
  final String name;
  final String? icon;
  final bool isClothing;

  Category({required this.id, required this.name, this.icon, this.isClothing = false});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        isClothing: json['is_clothing'] ?? false,
      );
}

class ProductSize {
  final int id;
  final String label;

  ProductSize({required this.id, required this.label});

  factory ProductSize.fromJson(Map<String, dynamic> json) =>
      ProductSize(id: json['id'], label: json['size_label']);
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
  final List<String> images;
  final List<ProductSize> sizes;

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
    this.images = const [],
    this.sizes = const [],
  });

  int get priceEligible => isFlashActive ? (priceXof * (100 - discount) / 100).round() : priceXof;

  int get discount => flashDiscountPct ?? 0;

  bool get isFlashActive =>
      isFlashOffer && flashDiscountPct != null && (flashEndsAt == null || flashEndsAt!.isAfter(DateTime.now()));

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        categoryId: json['category_id'],
        name: json['name'],
        description: json['description'],
        priceXof: json['price_xof'],
        deliveryDelayText: json['delivery_delay_text'] ?? '~2 mois',
        isFlashOffer: json['is_flash_offer'] ?? false,
        flashDiscountPct: json['flash_discount_pct'],
        flashEndsAt: json['flash_ends_at'] != null ? DateTime.tryParse(json['flash_ends_at']) : null,
        isPopular: json['is_popular'] ?? false,
        images: ((json['images'] ?? []) as List).map((i) => i['url'] as String).toList(),
        sizes: ((json['sizes'] ?? []) as List).map((s) => ProductSize.fromJson(s)).toList(),
      );
}

class City {
  final int id;
  final String name;

  City({required this.id, required this.name});

  factory City.fromJson(Map<String, dynamic> json) => City(id: json['id'], name: json['name']);
}

class TransportCompany {
  final int id;
  final String name;
  final int priority;

  TransportCompany({required this.id, required this.name, required this.priority});

  factory TransportCompany.fromJson(Map<String, dynamic> json) =>
      TransportCompany(id: json['id'], name: json['name'], priority: json['priority'] ?? 99);
}

class CityCompanies {
  final City city;
  final List<TransportCompany> companies;

  CityCompanies({required this.city, required this.companies});
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

class OrderStatus {
  final String status;
  final String? note;
  final DateTime? changedAt;

  OrderStatus({required this.status, this.note, this.changedAt});

  factory OrderStatus.fromJson(Map<String, dynamic> json) => OrderStatus(
        status: json['status'],
        note: json['note'],
        changedAt: json['changed_at'] != null ? DateTime.tryParse(json['changed_at']) : null,
      );
}

class PaymentInfo {
  final int id;
  final String type;
  final String method;
  final int amountXof;
  final String status;

  PaymentInfo({
    required this.id,
    required this.type,
    required this.method,
    required this.amountXof,
    required this.status,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) => PaymentInfo(
        id: json['id'],
        type: json['type'],
        method: json['method'],
        amountXof: json['amount_xof'],
        status: json['status'],
      );
}

class Order {
  final int id;
  final String code;
  final String status;
  final int totalProductXof;
  final int? shippingFeeXof;
  final String shippingFeeStatus;
  final int? cityId;
  final int? companyId;
  final List<OrderItem> items;
  final List<OrderStatus> statusHistory;
  final List<PaymentInfo> payments;
  final DateTime? createdAt;

  Order({
    required this.id,
    required this.code,
    required this.status,
    required this.totalProductXof,
    this.shippingFeeXof,
    this.shippingFeeStatus = 'pending',
    this.cityId,
    this.companyId,
    this.items = const [],
    this.statusHistory = const [],
    this.payments = const [],
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'],
        code: json['code'],
        status: json['status'],
        totalProductXof: json['total_product_xof'],
        shippingFeeXof: json['shipping_fee_xof'],
        shippingFeeStatus: json['shipping_fee_status'] ?? 'pending',
        cityId: json['city_id'],
        companyId: json['company_id'],
        items: ((json['items'] ?? []) as List).map((i) => OrderItem.fromJson(i)).toList(),
        statusHistory:
            ((json['status_history'] ?? []) as List).map((s) => OrderStatus.fromJson(s)).toList(),
        payments:
            ((json['payments'] ?? []) as List).map((p) => PaymentInfo.fromJson(p)).toList(),
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      );
}

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String? body;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        type: json['type'],
        title: json['title'],
        body: json['body'],
        isRead: json['is_read'] ?? false,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      );
}

/// Libellés et ordre des étapes de suivi (alignés sur le backend).
const orderSteps = [
  'commande_recue',
  'achat_chine',
  'expedition',
  'en_transit',
  'arrivee_ci',
  'disponible_compagnie',
  'recuperee',
];

const orderStepLabels = {
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