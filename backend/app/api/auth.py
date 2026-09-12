from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..core.dependencies import get_current_user, require_client
from ..core.security import create_access_token, hash_password, verify_password
from ..database import get_db
from ..models import User
from ..schemas import AuthOut, LoginIn, ProfileUpdateIn, RegisterIn, UserOut

router = APIRouter()


@router.post("/register", response_model=AuthOut)
def register(data: RegisterIn, db: Session = Depends(get_db)):
    if data.email is None and data.phone is None:
        raise HTTPException(400, "Email ou téléphone requis pour l'inscription")

    if data.email and db.query(User).filter(User.email == data.email).first():
        raise HTTPException(400, "Cet email est déjà enregistré")
    if data.phone and db.query(User).filter(User.phone == data.phone).first():
        raise HTTPException(400, "Ce numéro est déjà enregistré")

    user = User(
        email=data.email,
        phone=data.phone,
        full_name=data.full_name,
        password_hash=hash_password(data.password),
        role="client",
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(user.id, user.email or user.phone or "", user.role)
    return AuthOut(token=token, user=UserOut.model_validate(user))


@router.post("/login", response_model=AuthOut)
def login(data: LoginIn, db: Session = Depends(get_db)):
    user = db.query(User).filter(
        (User.email == data.identifier) | (User.phone == data.identifier)
    ).first()
    if user is None or not verify_password(data.password, user.password_hash):
        raise HTTPException(401, "Identifiant ou mot de passe incorrect")
    token = create_access_token(user.id, user.email or user.phone or "", user.role)
    return AuthOut(token=token, user=UserOut.model_validate(user))


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(require_client)):
    return UserOut.model_validate(user)


@router.put("/profile", response_model=UserOut)
def update_profile(data: ProfileUpdateIn, user: User = Depends(require_client),
                   db: Session = Depends(get_db)):
    if data.full_name is not None:
        user.full_name = data.full_name
    if data.email is not None:
        exists = db.query(User).filter(User.email == data.email, User.id != user.id).first()
        if exists:
            raise HTTPException(400, "Cet email est déjà enregistré")
        user.email = data.email
    if data.phone is not None:
        exists = db.query(User).filter(User.phone == data.phone, User.id != user.id).first()
        if exists:
            raise HTTPException(400, "Ce numéro est déjà enregistré")
        user.phone = data.phone
    if data.city_id is not None:
        user.city_id = data.city_id
    if data.preferred_company_id is not None:
        user.preferred_company_id = data.preferred_company_id

    db.commit()
    db.refresh(user)
    return UserOut.model_validate(user)


@router.get("/", response_model=UserOut)
def current_user(user: User = Depends(get_current_user)):
    return UserOut.model_validate(user)