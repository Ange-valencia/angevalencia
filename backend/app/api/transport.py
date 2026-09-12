"""Transport de référence : villes et compagnies partenaires (UTB, CTE, SBTA).

Règle D1 : si plusieurs compagnies desservent une même ville, le client choisit ;
la pré-sélection suit transport_companies.priority (UTB=1, CTE=2, SBTA=3).
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import City, CompanyServesCity, TransportCompany
from ..schemas import CityCompaniesOut, CityOut, CompanyOut

router = APIRouter()


@router.get("/cities", response_model=list[CityOut])
def list_cities(db: Session = Depends(get_db)):
    return db.query(City).order_by(City.name).all()


@router.get("/cities/{city_id}/companies", response_model=CityCompaniesOut)
def city_companies(city_id: int, db: Session = Depends(get_db)):
    city = db.get(City, city_id)
    if city is None:
        raise HTTPException(404, "Ville inconnue")

    rows = (
        db.query(TransportCompany)
        .join(CompanyServesCity, CompanyServesCity.company_id == TransportCompany.id)
        .filter(CompanyServesCity.city_id == city_id,
                TransportCompany.is_active == True)  # noqa: E712
        .order_by(TransportCompany.priority, TransportCompany.name)
        .all()
    )
    return CityCompaniesOut(
        city=CityOut.model_validate(city),
        companies=[CompanyOut.model_validate(c) for c in rows],
    )


@router.get("/companies", response_model=list[CompanyOut])
def list_companies(db: Session = Depends(get_db)):
    return (db.query(TransportCompany)
            .filter(TransportCompany.is_active == True)  # noqa: E712
            .order_by(TransportCompany.priority).all())


@router.get("/companies/{company_id}/cities", response_model=list[CityOut])
def company_cities(company_id: int, db: Session = Depends(get_db)):
    company = db.get(TransportCompany, company_id)
    if company is None:
        raise HTTPException(404, "Compagnie inconnue")
    return (db.query(City)
            .join(CompanyServesCity, CompanyServesCity.city_id == City.id)
            .filter(CompanyServesCity.company_id == company_id)
            .order_by(City.name).all())