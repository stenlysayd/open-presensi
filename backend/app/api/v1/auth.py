from datetime import timedelta
from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import verify_password, get_password_hash, create_access_token, decode_access_token
from app.core.config import settings
from app.models.organization import User
from app.schemas.auth import LoginRequest, RegisterRequest, Token, UserResponse

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    payload = decode_access_token(token)
    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token autentikasi tidak valid atau sudah kedaluwarsa.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user_id = payload["sub"]
    user = db.query(User).filter(User.id == user_id, User.is_active == True).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User tidak ditemukan.")
    return user

def require_role(allowed_roles: list):
    def role_checker(current_user: User = Depends(get_current_user)):
        if current_user.role not in allowed_roles and current_user.role != "superadmin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Anda tidak memiliki hak akses untuk aksi ini."
            )
        return current_user
    return role_checker

@router.post("/register", response_model=UserResponse)
def register_user(req: RegisterRequest, db: Session = Depends(get_db)) -> Any:
    # Check duplicate
    existing = db.query(User).filter(
        (User.identifier == req.identifier) | (User.email == req.email)
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Identifier atau email sudah terdaftar.")

    user = User(
        name=req.name,
        identifier=req.identifier,
        email=req.email,
        password_hash=get_password_hash(req.password),
        org_id=req.org_id,
        role=req.role or "staff",
        device_id=None # Binding takes place upon first login
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.post("/login", response_model=Token)
def login(req: LoginRequest, db: Session = Depends(get_db)) -> Any:
    user = db.query(User).filter(
        (User.identifier == req.identifier) | (User.email == req.identifier)
    ).first()

    if not user or not verify_password(req.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Kredensial atau password salah.")

    # Device Binding Logic (Diadopsi dari Absensi Familia)
    if req.device_id:
        if not user.device_id:
            # First login: bind this device
            user.device_id = req.device_id
            db.commit()
        elif user.device_id != req.device_id and user.role not in ["superadmin"]:
            raise HTTPException(
                status_code=403,
                detail="Akun Anda terikat pada perangkat lain! Hubungi Admin untuk reset pengikatan perangkat."
            )

    token = create_access_token(
        data={"sub": str(user.id), "role": user.role, "org_id": str(user.org_id) if user.org_id else None}
    )
    return {
        "access_token": token,
        "token_type": "bearer",
        "role": user.role,
        "user_id": user.id,
        "name": user.name,
        "org_id": user.org_id
    }

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)) -> Any:
    return current_user

@router.post("/reset-device/{user_id}")
def reset_device_binding(
    user_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin", "admin"]))
) -> Any:
    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="Pengguna tidak ditemukan.")
    target_user.device_id = None
    db.commit()
    return {"success": True, "message": f"Pengikatan perangkat untuk {target_user.name} berhasil di-reset."}
