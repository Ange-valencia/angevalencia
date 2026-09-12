from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from ..core.security import decode_token
from ..database import get_db
from ..models import User

_bearer = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Non connecté")
    try:
        payload = decode_token(credentials.credentials)
    except Exception:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Session invalide ou expirée")
    user = db.get(User, int(payload["sub"]))
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Utilisateur introuvable")
    return user


def require_client(user: User = Depends(get_current_user)) -> User:
    """Espace client : interdit aux administrateurs par défaut."""
    if user.role != "client":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Accès réservé aux clients")
    return user


def require_admin(user: User = Depends(get_current_user)) -> User:
    """Espace administrateur : totalement séparé, réservé à l'équipe AngeValencia."""
    if user.role != "admin":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Accès réservé à l'équipe AngeValencia")
    return user