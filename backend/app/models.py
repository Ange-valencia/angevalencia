# AngeValencia — modèle de données.

# Rôles     : client, admin (accès totalement séparés)
# Statut    : validé par défaut pour les clients
# Commande  : commande_recue → achat_chine → expedition → en_transit →
#             arrivee_ci → disponible_compagnie → recuperee
# Exceptions: retour_entrepot, annulee
#
# Paiement en 2 temps : payments.type = product (à la commande)
#                       payments.type = shipping (à l'arrivée).
from datetime import datetime

from sqlalchemy import (Boolean, DateTime, ForeignKey, Integer, String,
                        Text, UniqueConstraint, func)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


# ---------------------------------------------------------------- utilisateurs
class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str | None] = mapped_column(String(255), unique=True, nullable=True)
    phone: Mapped[str | None] = mapped_column(String(20), unique=True, nullable=True)
    full_name: Mapped[str] = mapped_column(String(150))
    password_hash: Mapped[str] = mapped_column(String(255))

    role: Mapped[str] = mapped_column(String(20), default="client")  # client|admin
    status: Mapped[str] = mapped_column(String(20), default="validated")

    # Récupération du colis : ville + compagnie préférée (D1)
    city_id: Mapped[int | None] = mapped_column(ForeignKey("cities.id"), nullable=True)
    preferred_company_id: Mapped[int | None] = mapped_column(
        ForeignKey("transport_companies.id"), nullable=True)

    notifications: Mapped[list["Notification"]] = relationship(
        back_populates="user", order_by="Notification.id.desc()")


# ---------------------------------------------------------------- transport
class TransportCompany(Base):
    """Compagnie de transport partenaire (UTB, CTE, SBTA)."""
    __tablename__ = "transport_companies"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(80), unique=True)
    priority: Mapped[int] = mapped_column(Integer, default=99)  # pré-sélection par défaut (D1)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    cities: Mapped[list["City"]] = relationship(secondary="company_serves_city")


class City(Base):
    __tablename__ = "cities"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100), unique=True)


class CompanyServesCity(Base):
    """Une compagnie dessert une ville (priorité par ville si besoin)."""
    __tablename__ = "company_serves_city"
    __table_args__ = (UniqueConstraint("company_id", "city_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    company_id: Mapped[int] = mapped_column(ForeignKey("transport_companies.id"), index=True)
    city_id: Mapped[int] = mapped_column(ForeignKey("cities.id"), index=True)
    priority: Mapped[int | None] = mapped_column(Integer, nullable=True)


# ---------------------------------------------------------------- catalogue
class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(80), unique=True)
    icon: Mapped[str | None] = mapped_column(String(50), nullable=True)
    is_clothing: Mapped[bool] = mapped_column(Boolean, default=False)  # True = tailles
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    products: Mapped[list["Product"]] = relationship(back_populates="category")


class Product(Base, TimestampMixin):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(primary_key=True)
    category_id: Mapped[int | None] = mapped_column(ForeignKey("categories.id"), index=True)
    name: Mapped[str] = mapped_column(String(200))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    price_xof: Mapped[int] = mapped_column(Integer)  # prix en FCFA
    delivery_delay_text: Mapped[str] = mapped_column(String(50), default="~2 mois")

    # Offre flash / mise en avant
    is_flash_offer: Mapped[bool] = mapped_column(Boolean, default=False)
    flash_discount_pct: Mapped[int | None] = mapped_column(Integer, nullable=True)
    flash_ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    is_popular: Mapped[bool] = mapped_column(Boolean, default=False)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    category: Mapped["Category | None"] = relationship(back_populates="products")
    images: Mapped[list["ProductImage"]] = relationship(
        back_populates="product", order_by="ProductImage.position",
        cascade="all, delete-orphan")
    sizes: Mapped[list["ProductSize"]] = relationship(
        back_populates="product", order_by="ProductSize.position",
        cascade="all, delete-orphan")


class ProductImage(Base):
    __tablename__ = "product_images"

    id: Mapped[int] = mapped_column(primary_key=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), index=True)
    url: Mapped[str] = mapped_column(Text)
    position: Mapped[int] = mapped_column(Integer, default=0)

    product: Mapped[Product] = relationship(back_populates="images")


class ProductSize(Base):
    """Tailles disponibles (vêtements & chaussures) — pas de stock par taille."""
    __tablename__ = "product_sizes"
    __table_args__ = (UniqueConstraint("product_id", "size_label"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), index=True)
    size_label: Mapped[str] = mapped_column(String(20))  # S, M, L, 40, 41, 42...
    position: Mapped[int] = mapped_column(Integer, default=0)

    product: Mapped[Product] = relationship(back_populates="sizes")


# ---------------------------------------------------------------- commandes
class Order(Base, TimestampMixin):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(30), unique=True, index=True)  # AV-2026-0001
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)

    status: Mapped[str] = mapped_column(String(30), default="commande_recue", index=True)
    # commande_recue|achat_chine|expedition|en_transit|arrivee_ci|
    # disponible_compagnie|recuperee|retour_entrepot|annulee

    # Montants (FCFA)
    total_product_xof: Mapped[int] = mapped_column(Integer)   # paiement 1
    shipping_fee_xof: Mapped[int | None] = mapped_column(Integer, nullable=True)
    shipping_fee_status: Mapped[str] = mapped_column(String(20), default="pending")  # pending|paid

    # Récupération en compagnie de transport
    city_id: Mapped[int | None] = mapped_column(ForeignKey("cities.id"), nullable=True)
    company_id: Mapped[int | None] = mapped_column(ForeignKey("transport_companies.id"), nullable=True)

    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    user: Mapped[User] = relationship()
    items: Mapped[list["OrderItem"]] = relationship(
        back_populates="order", cascade="all, delete-orphan")
    status_history: Mapped[list["OrderStatusHistory"]] = relationship(
        back_populates="order", order_by="OrderStatusHistory.changed_at",
        cascade="all, delete-orphan")
    payments: Mapped[list["Payment"]] = relationship(
        back_populates="order", cascade="all, delete-orphan")
    notifications: Mapped[list["Notification"]] = relationship(back_populates="order")


class OrderItem(Base):
    __tablename__ = "order_items"

    id: Mapped[int] = mapped_column(primary_key=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"), index=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"))
    product_name: Mapped[str] = mapped_column(String(200))      # copie (prix figé)
    size_label: Mapped[str | None] = mapped_column(String(20), nullable=True)
    unit_price_xof: Mapped[int] = mapped_column(Integer)
    quantity: Mapped[int] = mapped_column(Integer)
    line_total_xof: Mapped[int] = mapped_column(Integer)

    order: Mapped[Order] = relationship(back_populates="items")


class OrderStatusHistory(Base):
    __tablename__ = "order_status_history"

    id: Mapped[int] = mapped_column(primary_key=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"), index=True)
    status: Mapped[str] = mapped_column(String(30))
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    changed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    order: Mapped[Order] = relationship(back_populates="status_history")


# ---------------------------------------------------------------- paiements
class Payment(Base, TimestampMixin):
    __tablename__ = "payments"

    id: Mapped[int] = mapped_column(primary_key=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"), index=True)
    type: Mapped[str] = mapped_column(String(20), default="product")  # product|shipping
    method: Mapped[str] = mapped_column(String(30))  # orange_money|wave
    amount_xof: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    # pending|success|failed|refunded
    operator_transaction_id: Mapped[str | None] = mapped_column(String(100), nullable=True)
    confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    order: Mapped[Order] = relationship(back_populates="payments")


class Notification(Base, TimestampMixin):
    __tablename__ = "notifications"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    order_id: Mapped[int | None] = mapped_column(ForeignKey("orders.id"), nullable=True)
    type: Mapped[str] = mapped_column(String(40))  # order_status|payment|...
    title: Mapped[str] = mapped_column(String(200))
    body: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)

    user: Mapped[User] = relationship(back_populates="notifications")
    order: Mapped[Order | None] = relationship(back_populates="notifications")