import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, Float, Text, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base

class Organization(Base):
    __tablename__ = "organizations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    type = Column(String(50), nullable=False, default="school")  # school, church, community
    code = Column(String(50), unique=True, index=True)
    address = Column(Text, nullable=True)
    phone = Column(String(50), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    radius_meter = Column(Float, default=100.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    users = relationship("User", back_populates="organization", cascade="all, delete-orphan")
    groups = relationship("Group", back_populates="organization", cascade="all, delete-orphan")
    members = relationship("Member", back_populates="organization", cascade="all, delete-orphan")


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=True)
    name = Column(String(255), nullable=False)
    identifier = Column(String(100), unique=True, nullable=False, index=True)  # NUPTK/NIP/Email
    email = Column(String(255), unique=True, nullable=True, index=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False, default="staff")  # superadmin, admin, staff, member
    device_id = Column(String(255), nullable=True)  # Device hardware binding
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    organization = relationship("Organization", back_populates="users")


class Group(Base):
    __tablename__ = "groups"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=False)  # "Kelas X MIPA 1" or "Rayon 4"
    category = Column(String(100), nullable=True)  # "Kelas", "Rayon", "Kategorial"
    leader_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    organization = relationship("Organization", back_populates="groups")
    members = relationship("Member", back_populates="group")


class Member(Base):
    __tablename__ = "members"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)
    group_id = Column(UUID(as_uuid=True), ForeignKey("groups.id", ondelete="SET NULL"), nullable=True)
    registration_number = Column(String(100), unique=True, nullable=False, index=True)  # NISN or No. Jemaat
    name = Column(String(255), nullable=False)
    gender = Column(String(10), nullable=True)  # 'L' or 'P'
    phone = Column(String(50), nullable=True)
    parent_phone = Column(String(50), nullable=True)  # WhatsApp notification target
    qr_token = Column(String(255), unique=True, nullable=False, index=True)
    rfid_code = Column(String(100), unique=True, nullable=True, index=True)  # RFID Card / Tag UID
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    organization = relationship("Organization", back_populates="members")
    group = relationship("Group", back_populates="members")
    attendance_records = relationship("AttendanceRecord", back_populates="member", cascade="all, delete-orphan")
