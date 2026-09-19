from typing import Optional
from pydantic import BaseModel, EmailStr, ConfigDict
from uuid import UUID

class Token(BaseModel):
    access_token: str
    token_type: str
    role: str
    user_id: UUID
    name: str
    org_id: Optional[UUID] = None


class TokenData(BaseModel):
    user_id: Optional[str] = None
    role: Optional[str] = None

class LoginRequest(BaseModel):
    identifier: str  # Email, NUPTK, or Username
    password: str
    device_id: Optional[str] = None  # Hardware ID for device binding

class RegisterRequest(BaseModel):
    name: str
    identifier: str
    email: Optional[EmailStr] = None
    password: str
    org_id: Optional[UUID] = None
    role: Optional[str] = "staff"

class UserResponse(BaseModel):
    id: UUID
    name: str
    identifier: str
    email: Optional[str] = None
    role: str
    device_id: Optional[str] = None
    is_active: bool

    model_config = ConfigDict(from_attributes=True)

