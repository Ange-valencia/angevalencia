"""Espace administrateur (équipe AngeValencia) — accès totalement séparé.

Protégé par require_admin : aucun client ne peut y accéder.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..core.dependencies import require_admin
from ..core.security import create_access_token, hash_password, verify_password
from ..database import get_db
from ..models import (Category, Notification, Order, OrderItem,
                      OrderStatusHistory, Payment, Product, ProductImage,
                      ProductSize, User)
from ..schemas import (AdminLoginIn, AuthOut, CategoryIn, CategoryOut,
                       OrderOut, OrderStatusUpdateIn, ProductIn, ProductOut,
                       UserOut)

router = APIRouter()

VALID_LIVRAISON_STATUSES = {
    "commande_recue", "achat_chine", "expedition", "en_transit",
    "arrivee_ci", "disponible_compagnie", "recuperee", "retour_entrepot", "annulee",
}


def _identifier_candidates(identifier: str) -> list[str]:
    """Suppose qu'un numéro local (ex. 0102030405) cache un +225…"""
    candidates = [identifier]
    if identifier.startswith("0") and len(identifier) <= 12:
        candidates += ["+225" + identifier, "225" + identifier]
    return candidates


# ---------------------------------------------------------------- authentification admin
@router.post("/auth/login", response_model=AuthOut)
def admin_login(data: AdminLoginIn, db: Session = Depends(get_db)):
    user = None
    for candidate in _identifier_candidates(data.identifier):
        user = db.query(User).filter(
            (User.email == data.identifier) | (User.phone == candidate)
        ).first()
        if user is not None:
            break
    if user is None or user.role != "admin":
        raise HTTPException(404, "Compte administrateur introuvable")
    if not verify_password(data.password, user.password_hash):
        raise HTTPException(401, "Mot de passe incorrect")
    token = create_access_token(user.id, user.email or user.phone or "", user.role)
    return AuthOut(token=token, user=UserOut.model_validate(user))


@router.get("/auth/me", response_model=UserOut)
def admin_me(user: User = Depends(require_admin)):
    return UserOut.model_validate(user)


@router.get("/users", response_model=list[UserOut])
def list_users(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    """Liste des clients inscrits (espace admin)."""
    return db.query(User).filter(User.role == "client").order_by(User.id.desc()).all()


# ---------------------------------------------------------------- catégories
@router.get("/categories", response_model=list[CategoryOut])
def list_categories(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return db.query(Category).order_by(Category.sort_order, Category.name).all()


@router.post("/categories", response_model=CategoryOut)
def create_category(data: CategoryIn, db: Session = Depends(get_db),
                    _: User = Depends(require_admin)):
    if db.query(Category).filter(Category.name == data.name).first():
        raise HTTPException(400, "Cette catégorie existe déjà")
    category = Category(**data.model_dump())
    db.add(category)
    db.commit()
    db.refresh(category)
    return CategoryOut.model_validate(category)


@router.put("/categories/{category_id}", response_model=CategoryOut)
def update_category(category_id: int, data: CategoryIn, db: Session = Depends(get_db),
                    _: User = Depends(require_admin)):
    category = db.get(Category, category_id)
    if category is None:
        raise HTTPException(404, "Catégorie introuvable")
    for key, value in data.model_dump().items():
        setattr(category, key, value)
    db.commit()
    db.refresh(category)
    return CategoryOut.model_validate(category)


@router.delete("/categories/{category_id}", status_code=204)
def delete_category(category_id: int, db: Session = Depends(get_db),
                    _: User = Depends(require_admin)):
    category = db.get(Category, category_id)
    if category is None:
        raise HTTPException(404, "Catégorie introuvable")
    if db.query(Product).filter(Product.category_id == category_id).first():
        raise HTTPException(400, "Impossible de supprimer : des produits y sont rattachés")
    db.delete(category)
    db.commit()


# ---------------------------------------------------------------- produits
@router.get("/products", response_model=list[ProductOut])
def list_products(category_id: int | None = None, db: Session = Depends(get_db),
                  _: User = Depends(require_admin)):
    query = db.query(Product)
    if category_id:
        query = query.filter(Product.category_id == category_id)
    return [ProductOut.model_validate(p) for p in query.order_by(Product.id.desc()).all()]


@router.post("/products", response_model=ProductOut)
def create_product(data: ProductIn, db: Session = Depends(get_db),
                   _: User = Depends(require_admin)):
    if data.category_id and db.get(Category, data.category_id) is None:
        raise HTTPException(400, "Catégorie inconnue")

    product = Product(
        category_id=data.category_id,
        name=data.name,
        description=data.description,
        price_xof=data.price_xof,
        delivery_delay_text=data.delivery_delay_text or "~2 mois",
        is_flash_offer=data.is_flash_offer,
        flash_discount_pct=data.flash_discount_pct,
        flash_ends_at=data.flash_ends_at,
        is_popular=data.is_popular,
        is_active=data.is_active,
    )
    db.add(product)
    db.flush()

    for position, url in enumerate(data.images):
        db.add(ProductImage(product_id=product.id, url=url, position=position))
    for position, label in enumerate(data.sizes):
        db.add(ProductSize(product_id=product.id, size_label=label, position=position))

    db.commit()
    db.refresh(product)
    return ProductOut.model_validate(product)


@router.put("/products/{product_id}", response_model=ProductOut)
def update_product(product_id: int, data: ProductIn, db: Session = Depends(get_db),
                   _: User = Depends(require_admin)):
    product = db.get(Product, product_id)
    if product is None:
        raise HTTPException(404, "Produit introuvable")
    if data.category_id and db.get(Category, data.category_id) is None:
        raise HTTPException(400, "Catégorie inconnue")

    for key, value in data.model_dump(exclude={"images", "sizes"}).items():
        setattr(product, key, value)

    old_images = db.query(ProductImage).filter(ProductImage.product_id == product.id).all()
    for image in old_images:
        db.delete(image)
    for position, url in enumerate(data.images):
        db.add(ProductImage(product_id=product.id, url=url, position=position))

    old_sizes = db.query(ProductSize).filter(ProductSize.product_id == product.id).all()
    for size in old_sizes:
        db.delete(size)
    for position, label in enumerate(data.sizes):
        db.add(ProductSize(product_id=product.id, size_label=label, position=position))

    db.commit()
    db.refresh(product)
    return ProductOut.model_validate(product)


@router.delete("/products/{product_id}", status_code=204)
def delete_product(product_id: int, db: Session = Depends(get_db),
                   _: User = Depends(require_admin)):
    product = db.get(Product, product_id)
    if product is None:
        raise HTTPException(404, "Produit introuvable")
    if db.query(OrderItem).filter(OrderItem.product_id == product_id).first():
        product.is_active = False  # soft delete si déjà commandé
        db.commit()
        return
    db.delete(product)
    db.commit()


# ---------------------------------------------------------------- commandes & suivi
@router.get("/orders", response_model=list[OrderOut])
def list_orders(status: str | None = None, db: Session = Depends(get_db),
                _: User = Depends(require_admin)):
    query = db.query(Order)
    if status:
        query = query.filter(Order.status == status)
    return [OrderOut.model_validate(o) for o in query.order_by(Order.id.desc()).all()]


@router.put("/orders/{order_id}/status", response_model=OrderOut)
def update_order_status(order_id: int, data: OrderStatusUpdateIn,
                        db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    order = db.get(Order, order_id)
    if order is None:
        raise HTTPException(404, "Commande introuvable")

    if data.status not in VALID_LIVRAISON_STATUSES:
        raise HTTPException(400, "Statut de livraison invalide")

    # Frais de transport : obligatoires à l'étape 'disponible_compagnie'
    if data.status == "disponible_compagnie":
        if data.shipping_fee_xof is None:
            raise HTTPException(400, "Les frais de transport sont requis (shipping_fee_xof)")
        order.shipping_fee_xof = data.shipping_fee_xof

    old_status = order.status
    order.status = data.status

    if data.status == "recuperee" and old_status != "recuperee":
        order.shipping_fee_status = "paid"

    db.add(OrderStatusHistory(order_id=order.id, status=data.status, note=data.note))

    _notify_order_status(db, order, admin)

    db.commit()
    db.refresh(order)
    return OrderOut.model_validate(order)


def _confirm_payment(db: Session, payment: Payment, operator_transaction_id: str) -> None:
    from datetime import datetime
    payment.status = "success"
    payment.operator_transaction_id = operator_transaction_id
    payment.confirmed_at = datetime.now(timezone.utc)


def _notify_order_status(db: Session, order: Order, admin: User) -> None:
    labels = {
        "commande_recue": "Commande reçue",
        "achat_chine": "Achat effectué en Chine",
        "expedition": "Colis expédié",
        "en_transit": "En transit",
        "arrivee_ci": "Arrivé en Côte d'Ivoire",
        "disponible_compagnie": "Disponible en compagnie de transport",
        "recuperee": "Colis récupéré",
        "retour_entrepot": "Colis retourné à l'entrepôt",
        "annulee": "Commande annulée",
    }
    title = labels.get(order.status, order.status)
    body = None
    if order.status == "disponible_compagnie" and order.shipping_fee_xof:
        body = (f"Votre colis est disponible. "
                f"Frais de transport à payer : {order.shipping_fee_xof:,} FCFA.")
    db.add(Notification(user_id=order.user_id, order_id=order.id,
                        title=title, body=body, type="order_status"))


# ---------------------------------------------------------------- paiements (validation manuelle MVP)
@router.post("/payments/{payment_id}/confirm", response_model=OrderOut)
def confirm_payment(payment_id: int, db: Session = Depends(get_db),
                    _: User = Depends(require_admin)):
    """Validation manuelle d'un paiement en attendant les webhooks OM/Wave."""
    payment = db.get(Payment, payment_id)
    if payment is None:
        raise HTTPException(404, "Paiement introuvable")
    if payment.status == "success":
        raise HTTPException(400, "Paiement déjà confirmé")

    _confirm_payment(db, payment, f"manual-{payment_id}")

    order = db.get(Order, payment.order_id)
    if payment.type == "product" and order.shipping_fee_status == "pending":
        if order.paid_at is None:
            from datetime import datetime
            order.paid_at = datetime.now(timezone.utc)
        db.add(OrderStatusHistory(order_id=order.id, status="commande_recue",
                                  note="Paiement du produit confirmé"))
    elif payment.type == "shipping":
        order.shipping_fee_status = "paid"
        db.add(OrderStatusHistory(order_id=order.id, status=order.status,
                                  note="Frais de transport payés"))

    db.commit()
    db.refresh(order)
    return OrderOut.model_validate(order)