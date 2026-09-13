"""Commandes : création (paiement 1), historique, suivi, paiement transport (paiement 2)."""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..config import settings
from ..core.dependencies import require_client
from ..database import get_db
from ..models import (City, CompanyServesCity, Notification, Order,
                      OrderItem, OrderStatusHistory, Payment, Product,
                      ProductSize, TransportCompany, User)
from ..schemas import (OrderCreateIn, OrderOut, PayShippingOut,
                       ShippingPaymentIn)

router = APIRouter()


def _next_order_code(db: Session) -> str:
    count = db.query(Order).count() + 1
    return f"AV-{datetime.now().year}-{count:04d}"


def _companies_for_city(db: Session, city_id: int) -> list[TransportCompany]:
    return (db.query(TransportCompany)
            .join(CompanyServesCity, CompanyServesCity.company_id == TransportCompany.id)
            .filter(CompanyServesCity.city_id == city_id,
                    TransportCompany.is_active == True)  # noqa: E712
            .order_by(TransportCompany.priority, TransportCompany.name)
            .all())


def _resolve_company(db: Session, city_id: int,
                     requested_company_id: int | None, user: User) -> TransportCompany:
    """Règle D1 : compagnie la plus proche/prioritaire, choix possible du client."""
    city = db.get(City, city_id)
    if city is None:
        raise HTTPException(400, "Ville inconnue")

    available = _companies_for_city(db, city_id)
    if not available:
        raise HTTPException(400, f"Aucune compagnie de transport ne dessert {city.name}")

    if requested_company_id is not None:
        for company in available:
            if company.id == requested_company_id:
                return company
        raise HTTPException(400, "Cette compagnie ne dessert pas votre ville")

    # Pré-sélection : compagnie préférée du client si elle dessert la ville, sinon priorité UTB→CTE→SBTA
    if user.preferred_company_id:
        for company in available:
            if company.id == user.preferred_company_id:
                return company
    return available[0]


def _validate_size(db: Session, product: Product, size_label: str | None) -> None:
    product_sizes = db.query(ProductSize).filter(ProductSize.product_id == product.id).all()
    if product_sizes:
        labels = [s.size_label for s in product_sizes]
        if size_label not in labels:
            raise HTTPException(400, f"Taille indisponible pour '{product.name}' "
                                     f"(choisir : {', '.join(labels)})")
    elif size_label:
        raise HTTPException(400, "Ce produit ne propose pas de tailles")


def _create_notification(db: Session, user_id: int, order_id: int,
                         title: str, body: str | None = None,
                         ntype: str = "order_status") -> None:
    db.add(Notification(user_id=user_id, order_id=order_id,
                        title=title, body=body, type=ntype))


@router.post("", response_model=OrderOut)
def create_order(data: OrderCreateIn, user: User = Depends(require_client),
                 db: Session = Depends(get_db)):
    products: list[Product] = []
    total = 0
    for item in data.items:
        product = db.get(Product, item.product_id)
        if product is None or not product.is_active:
            raise HTTPException(400, "Produit introuvable")
        _validate_size(db, product, item.size_label)
        if item.quantity < 1:
            raise HTTPException(400, "Quantité invalide")
        products.append(product)

    company = _resolve_company(db, data.city_id, data.company_id, user)

    order = Order(
        code=_next_order_code(db),
        user_id=user.id,
        status="commande_recue",
        total_product_xof=total,
        shipping_fee_status="pending",
        city_id=data.city_id,
        company_id=company.id,
    )
    db.add(order)
    db.flush()

    for item, product in zip(data.items, products):
        line_total = product.price_xof * item.quantity
        total += line_total
        db.add(OrderItem(
            order_id=order.id,
            product_id=product.id,
            product_name=product.name,
            size_label=item.size_label,
            unit_price_xof=product.price_xof,
            quantity=item.quantity,
            line_total_xof=line_total,
        ))

    order.total_product_xof = total
    db.add(OrderStatusHistory(order_id=order.id, status="commande_recue",
                              note="Commande reçue, en attente de confirmation du paiement"))

    # Paiement 1 (produit) — paiement déclenché côté mobile, statut confirmé au webhook.
    db.add(Payment(order_id=order.id, type="product", method=data.payment_method,
                   amount_xof=total, status="pending",
                   operator_transaction_id=data.operator_transaction_id))

    _create_notification(
        db, user.id, order.id,
        f"Commande {order.code} reçue",
        f"Votre commande de {total:,} FCFA a bien été enregistrée. "
        f"Délai de livraison estimé : {settings.default_delivery_delay}. "
        f"Récupération prévue à la compagnie {company.name}.",
    )
    db.commit()
    db.refresh(order)
    return OrderOut.model_validate(order)


@router.get("", response_model=list[OrderOut])
def list_orders(user: User = Depends(require_client), db: Session = Depends(get_db)):
    orders = (db.query(Order)
              .filter(Order.user_id == user.id)
              .order_by(Order.id.desc()).all())
    return [OrderOut.model_validate(o) for o in orders]


@router.get("/{order_id}", response_model=OrderOut)
def order_detail(order_id: int, user: User = Depends(require_client),
                 db: Session = Depends(get_db)):
    order = db.get(Order, order_id)
    if order is None or order.user_id != user.id:
        raise HTTPException(404, "Commande introuvable")
    return OrderOut.model_validate(order)


@router.post("/{order_id}/pay-shipping", response_model=PayShippingOut)
def pay_shipping(order_id: int, data: ShippingPaymentIn,
                 user: User = Depends(require_client), db: Session = Depends(get_db)):
    """Paiement 2 : frais de transport, possible dès 'arrivee_ci' (D4)."""
    order = db.get(Order, order_id)
    if order is None or order.user_id != user.id:
        raise HTTPException(404, "Commande introuvable")
    if order.shipping_fee_xof is None:
        raise HTTPException(400, "Les frais de transport ne sont pas encore définis")
    if order.shipping_fee_status == "paid":
        raise HTTPException(400, "Les frais de transport sont déjà payés")

    db.add(Payment(order_id=order.id, type="shipping", method=data.payment_method,
                   amount_xof=order.shipping_fee_xof, status="pending",
                   operator_transaction_id=data.operator_transaction_id))
    _create_notification(
        db, user.id, order.id, "Paiement des frais de transport initié",
        f"Paiement de {order.shipping_fee_xof:,} FCFA via {data.payment_method} en attente.")
    db.commit()
    return PayShippingOut(payment_status="pending", shipping_fee_status="pending")