"""Catalogue public (consultable par les clients connectés).

Listes en lots (limit/offset) : l'application défile en continu.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..core.dependencies import require_client
from ..database import get_db
from ..models import Category, Product
from ..schemas import CategoryOut, ProductOut

router = APIRouter()

_active = require_client


def _product_price_xof(product: Product) -> int:
    """Prix effectif après réduction des offres flash encore valides."""
    if (product.is_flash_offer and product.flash_discount_pct
            and (product.flash_ends_at is None
                 or product.flash_ends_at > datetime.now(timezone.utc))):
        return round(product.price_xof * (100 - product.flash_discount_pct) / 100)
    return product.price_xof


@router.get("/categories", response_model=list[CategoryOut])
def list_categories(db: Session = Depends(get_db)):
    return (db.query(Category)
            .filter(Category.is_active == True)  # noqa: E712
            .order_by(Category.sort_order, Category.name).all())


@router.get("/products", response_model=list[ProductOut])
def list_products(category_id: int | None = None, q: str | None = None,
                  min_price: int | None = None, max_price: int | None = None,
                  flash_only: bool = False, popular_only: bool = False,
                  limit: int = 50, offset: int = 0,
                  user=Depends(_active), db: Session = Depends(get_db)):
    query = db.query(Product).filter(Product.is_active == True)  # noqa: E712
    if category_id:
        query = query.filter(Product.category_id == category_id)
    if q:
        query = query.filter(Product.name.ilike(f"%{q}%"))
    if min_price is not None:
        query = query.filter(Product.price_xof >= min_price)
    if max_price is not None:
        query = query.filter(Product.price_xof <= max_price)
    if flash_only:
        query = query.filter(Product.is_flash_offer == True)  # noqa: E712
    if popular_only:
        query = query.filter(Product.is_popular == True)  # noqa: E712
    products = query.order_by(Product.id.desc()).limit(limit).offset(offset).all()
    return [ProductOut.model_validate(p) for p in products]


@router.get("/products/{product_id}", response_model=ProductOut)
def product_detail(product_id: int, user=Depends(_active), db: Session = Depends(get_db)):
    product = db.get(Product, product_id)
    if product is None or not product.is_active:
        raise HTTPException(404, "Produit introuvable")
    return ProductOut.model_validate(product)