from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api import admin, auth, catalog, notifications, orders, payments, transport
from .config import settings
from .database import Base, engine
from . import models  # noqa: F401  (enregistre les tables)

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description="API AngeValencia — produits importés de Chine vendus en Côte d'Ivoire.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

prefix = settings.api_prefix
app.include_router(auth.router, prefix=f"{prefix}/auth", tags=["auth"])
app.include_router(transport.router, prefix=f"{prefix}/transport", tags=["transport"])
app.include_router(catalog.router, prefix=f"{prefix}/catalog", tags=["catalogue"])
app.include_router(orders.router, prefix=f"{prefix}/orders", tags=["commandes"])
app.include_router(notifications.router, prefix=f"{prefix}/notifications", tags=["notifications"])
app.include_router(payments.router, prefix=f"{prefix}/payments", tags=["paiements"])
app.include_router(admin.router, prefix=f"{prefix}/admin", tags=["administration"])


@app.get("/")
def root():
    return {"name": settings.app_name, "status": "ok"}


@app.get("/health")
def health():
    return {"status": "ok"}