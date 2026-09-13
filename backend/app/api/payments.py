"""Configuration des comptes de réception mobile money (paiement manuel)."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import PaymentConfig
from ..schemas import PaymentConfigOut

router = APIRouter()


@router.get("/config", response_model=PaymentConfigOut)
def get_payment_config(db: Session = Depends(get_db)):
    """Numéros à afficher dans l'app pour payer par Orange Money / Wave."""
    config = db.get(PaymentConfig, 1)
    if config is None:
        config = PaymentConfig(id=1)
        db.add(config)
        db.commit()
        db.refresh(config)
    return PaymentConfigOut.model_validate(config)