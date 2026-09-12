from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "AngeValencia API"
    debug: bool = True
    api_prefix: str = "/api"

    # Base de données : sqlite en développement, postgresql en production.
    database_url: str = "sqlite:///./angevalencia.db"

    secret_key: str = "a-changer-en-production"
    jwt_algorithm: str = "HS256"
    access_token_minutes: int = 60 * 24 * 30  # session longue pour mobiles

    # Délai affiché sur les fiches produits / avant commande (D3)
    default_delivery_delay: str = "~2 mois"

    # Règle retours (D2) : jours de garde du colis
    collection_grace_days: int = 14

    # Compte administrateur créé au premier lancement (scripts/seed_db.py)
    admin_email: str = ""
    admin_phone: str = ""
    admin_password: str = ""
    admin_name: str = "AngeValencia"


settings = Settings()