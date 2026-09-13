from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


# ---------------------------------------------------------------- auth
class RegisterIn(BaseModel):
    full_name: str = Field(min_length=2, max_length=150)
    email: EmailStr | None = None
    phone: str | None = Field(
        default=None, pattern=r"^(\+?225)?[0-9]{8,10}$", description="Numéro ivoirien +225")
    password: str = Field(pattern=r"^\d{4}$", min_length=4, max_length=4,
                          description="Code PIN à 4 chiffres")

    model_config = {
        "json_schema_extra": {
            "examples": [
                {"full_name": "Awa Kouadio", "phone": "+2250708091011",
                 "password": "1234"},
                {"full_name": "Awa Kouadio", "email": "awa@exemple.ci",
                 "password": "1234"},
            ]
        }
    }


class LoginIn(BaseModel):
    identifier: str = Field(min_length=3, description="Email ou téléphone")
    password: str


class UserOut(BaseModel):
    id: int
    full_name: str
    email: str | None = None
    phone: str | None = None
    role: str
    city_id: int | None = None
    preferred_company_id: int | None = None

    model_config = {"from_attributes": True}


class AuthOut(BaseModel):
    token: str
    user: UserOut


class ProfileUpdateIn(BaseModel):
    full_name: str | None = Field(default=None, min_length=2, max_length=150)
    email: EmailStr | None = None
    phone: str | None = Field(default=None, pattern=r"^(\+?225)?[0-9]{8,10}$")
    city_id: int | None = None
    preferred_company_id: int | None = None


# ---------------------------------------------------------------- transport
class CityOut(BaseModel):
    id: int
    name: str

    model_config = {"from_attributes": True}


class CompanyOut(BaseModel):
    id: int
    name: str
    priority: int

    model_config = {"from_attributes": True}


class CityCompaniesOut(BaseModel):
    city: CityOut
    companies: list[CompanyOut]


# ---------------------------------------------------------------- catalogue
class CategoryOut(BaseModel):
    id: int
    name: str
    icon: str | None = None
    is_clothing: bool
    sort_order: int

    model_config = {"from_attributes": True}


class CategoryIn(BaseModel):
    name: str = Field(min_length=2, max_length=80)
    icon: str | None = None
    is_clothing: bool = False
    sort_order: int = 0
    is_active: bool = True


class ProductSizeOut(BaseModel):
    id: int
    size_label: str

    model_config = {"from_attributes": True}


class ProductImageOut(BaseModel):
    id: int
    url: str
    position: int

    model_config = {"from_attributes": True}


class ProductOut(BaseModel):
    id: int
    category_id: int | None = None
    name: str
    description: str | None = None
    price_xof: int
    delivery_delay_text: str
    is_flash_offer: bool
    flash_discount_pct: int | None = None
    flash_ends_at: datetime | None = None
    is_popular: bool
    is_active: bool
    images: list[ProductImageOut] = []
    sizes: list[ProductSizeOut] = []

    model_config = {"from_attributes": True}


class ProductIn(BaseModel):
    category_id: int | None = None
    name: str = Field(min_length=2, max_length=200)
    description: str | None = None
    price_xof: int = Field(gt=0)
    delivery_delay_text: str | None = None
    is_flash_offer: bool = False
    flash_discount_pct: int | None = Field(default=None, ge=1, le=90)
    flash_ends_at: datetime | None = None
    is_popular: bool = False
    is_active: bool = True
    images: list[str] = []
    sizes: list[str] = []


# ---------------------------------------------------------------- commandes
class OrderItemIn(BaseModel):
    product_id: int
    quantity: int = Field(ge=1)
    size_label: str | None = None


class OrderCreateIn(BaseModel):
    items: list[OrderItemIn] = Field(min_length=1)
    city_id: int
    company_id: int | None = None
    payment_method: str = Field(pattern="^(orange_money|wave)$")
    operator_transaction_id: str | None = Field(default=None, max_length=100)


class OrderItemOut(BaseModel):
    id: int
    product_id: int
    product_name: str
    size_label: str | None = None
    unit_price_xof: int
    quantity: int
    line_total_xof: int

    model_config = {"from_attributes": True}


class OrderStatusOut(BaseModel):
    status: str
    note: str | None = None
    changed_at: datetime | None = None

    model_config = {"from_attributes": True}


class PaymentOut(BaseModel):
    id: int
    type: str
    method: str
    amount_xof: int
    status: str
    operator_transaction_id: str | None = None
    confirmed_at: datetime | None = None

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------- configuration paiement
class PaymentConfigOut(BaseModel):
    orange_money_number: str | None = None
    wave_number: str | None = None
    instructions: str | None = None

    model_config = {"from_attributes": True}


class PaymentConfigUpdateIn(BaseModel):
    orange_money_number: str | None = Field(default=None, max_length=20)
    wave_number: str | None = Field(default=None, max_length=20)
    instructions: str | None = None


class OrderOut(BaseModel):
    id: int
    code: str
    status: str
    total_product_xof: int
    shipping_fee_xof: int | None = None
    shipping_fee_status: str
    city_id: int | None = None
    company_id: int | None = None
    user: UserOut | None = None
    items: list[OrderItemOut] = []
    status_history: list[OrderStatusOut] = []
    payments: list[PaymentOut] = []
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class OrderStatusUpdateIn(BaseModel):
    status: str = Field(min_length=3, max_length=30)
    shipping_fee_xof: int | None = Field(default=None, gt=0,
                                         description="Obligatoire à 'disponible_compagnie'")
    note: str | None = None


class ShippingPaymentIn(BaseModel):
    payment_method: str = Field(pattern="^(orange_money|wave)$")
    operator_transaction_id: str | None = Field(default=None, max_length=100)


class PayShippingOut(BaseModel):
    payment_status: str
    shipping_fee_status: str


# ---------------------------------------------------------------- notifications
class NotificationOut(BaseModel):
    id: int
    type: str
    title: str
    body: str | None = None
    is_read: bool
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------- admin
class AdminLoginIn(BaseModel):
    identifier: str = Field(min_length=3, description="Email ou téléphone admin")
    password: str


class ProductSizeIn(BaseModel):
    size_label: str = Field(min_length=1, max_length=20)