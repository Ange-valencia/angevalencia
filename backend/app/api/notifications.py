"""Notifications consultables dans l'app (badge non-lus)."""
from fastapi import APIRouter, Depends
from fastapi import HTTPException
from sqlalchemy.orm import Session

from ..core.dependencies import require_client
from ..database import get_db
from ..models import Notification, User
from ..schemas import NotificationOut

router = APIRouter()


@router.get("", response_model=list[NotificationOut])
def list_notifications(user: User = Depends(require_client),
                       db: Session = Depends(get_db)):
    return (db.query(Notification)
            .filter(Notification.user_id == user.id)
            .order_by(Notification.id.desc())
            .limit(50).all())


@router.post("/{notification_id}/read", response_model=NotificationOut)
def mark_read(notification_id: int, user: User = Depends(require_client),
              db: Session = Depends(get_db)):
    notification = db.get(Notification, notification_id)
    if notification is None or notification.user_id != user.id:
        raise HTTPException(404, "Notification introuvable")
    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return NotificationOut.model_validate(notification)