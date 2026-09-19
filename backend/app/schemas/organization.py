from typing import Optional
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, ConfigDict

class OrganizationBase(BaseModel):
    name: str
    type: str = "school"  # school, church, community
    code: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    radius_meter: Optional[float] = 100.0

class OrganizationCreate(OrganizationBase):
    pass

class OrganizationResponse(OrganizationBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class GroupBase(BaseModel):
    name: str
    category: Optional[str] = None
    leader_user_id: Optional[UUID] = None

class GroupCreate(GroupBase):
    org_id: UUID

class GroupResponse(GroupBase):
    id: UUID
    org_id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class MemberBase(BaseModel):
    registration_number: str
    name: str
    gender: Optional[str] = None
    phone: Optional[str] = None
    parent_phone: Optional[str] = None
    group_id: Optional[UUID] = None

class MemberCreate(MemberBase):
    org_id: UUID

class MemberResponse(MemberBase):
    id: UUID
    org_id: UUID
    qr_token: str
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

