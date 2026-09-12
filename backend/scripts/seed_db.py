"""Seed de la base AngeValencia.

Usage :
    cd backend
    python -m scripts.seed_db
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from sqlalchemy.orm import Session  # noqa: E402

from app.config import settings  # noqa: E402
from app.core.security import hash_password  # noqa: E402
from app.database import Base, SessionLocal, engine  # noqa: E402
from app.models import (Category, City, CompanyServesCity,  # noqa: E402
                        TransportCompany, User)

# Données du cahier des charges (compagnies → villes desservies)
COMPANIES = {
    "UTB": {
        "priority": 1,
        "cities": [
            "Abidjan", "Bouaké", "Yamoussoukro", "Daloa", "Gagnoa", "San-Pédro",
            "Soubré", "Sassandra", "Man", "Korhogo", "Ferkessédougou", "Dimbokro",
            "Tiébissou", "Béoumi", "Bouaflé", "Bonon", "Gonaté", "Duékoué",
            "Divo", "Méagui", "Yabayo",
        ],
    },
    "CTE": {
        "priority": 2,
        "cities": [
            "Abidjan", "Abengourou", "Bondoukou", "Bouna", "Bouaflé", "Bouaké",
            "Daoukro", "Mankono", "Séguéla", "Tanda", "Tiébissou", "Yamoussoukro",
        ],
    },
    "SBTA": {
        "priority": 3,
        "cities": [
            "Abidjan", "Agboville", "Daloa", "Diégonéfla", "Divo", "Gagnoa",
            "Issia", "Méagui", "Oumé", "San-Pédro", "Soubré", "Abengourou",
            "Bondoukou", "Vavoua", "Tiassalé",
        ],
    },
}

CATEGORIES = [
    {"name": "Téléphones", "icon": "smartphone", "is_clothing": False, "sort_order": 1},
    {"name": "Informatique", "icon": "laptop", "is_clothing": False, "sort_order": 2},
    {"name": "Mode", "icon": "checkroom", "is_clothing": True, "sort_order": 3},
    {"name": "Maison", "icon": "home", "is_clothing": False, "sort_order": 4},
    {"name": "Autres", "icon": "category", "is_clothing": False, "sort_order": 5},
]


def seed_transport(db: Session) -> None:
    city_names = sorted({
        city for data in COMPANIES.values() for city in data["cities"]
    })
    for name in city_names:
        if not db.query(City).filter(City.name == name).first():
            db.add(City(name=name))

    for name, data in COMPANIES.items():
        company = db.query(TransportCompany).filter(TransportCompany.name == name).first()
        if company is None:
            company = TransportCompany(name=name, priority=data["priority"])
            db.add(company)
        else:
            company.priority = data["priority"]
        db.flush()

        for city_name in data["cities"]:
            city = db.query(City).filter(City.name == city_name).first()
            if city is None:
                continue
            link = db.query(CompanyServesCity).filter(
                CompanyServesCity.company_id == company.id,
                CompanyServesCity.city_id == city.id,
            ).first()
            if link is None:
                db.add(CompanyServesCity(company_id=company.id, city_id=city.id))


def seed_categories(db: Session) -> None:
    for cat in CATEGORIES:
        if not db.query(Category).filter(Category.name == cat["name"]).first():
            db.add(Category(**cat))


def seed_admin(db: Session) -> None:
    if not settings.admin_email and not settings.admin_phone:
        print("  Aucun compte admin configuré (.env : ADMIN_EMAIL/ADMIN_PHONE/ADMIN_PASSWORD)")
        return
    admin = db.query(User).filter(User.role == "admin").first()
    if admin:
        return
    db.add(User(
        email=settings.admin_email or None,
        phone=settings.admin_phone or None,
        full_name=settings.admin_name,
        password_hash=hash_password(settings.admin_password),
        role="admin",
    ))
    print(f"  Créé : compte admin '{settings.admin_email or settings.admin_phone}'")


def main() -> None:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        print("Seed transport (compagnies + villes)…")
        seed_transport(db)
        print("Seed catégories…")
        seed_categories(db)
        print("Seed admin…")
        seed_admin(db)
        db.commit()
        print("Terminé.")
    finally:
        db.close()


if __name__ == "__main__":
    main()