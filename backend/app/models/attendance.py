import uuid
from datetime import datetime, date, time
from sqlalchemy import Column, String, Boolean, Float, Text, ForeignKey, DateTime, Date, Time, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base

class AttendanceSession(Base):
    __tablename__ = "attendance_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    session_date = Column(Date, nullable=False, default=date.today)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    late_tolerance_minutes = Column(Integer, default=15)  # Toleransi keterlambatan (menit)
    require_geofence = Column(Boolean, default=False)
    qr_dynamic_secret = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    records = relationship("AttendanceRecord", back_populates="session")


class AttendanceRecord(Base):
    __tablename__ = "attendance_records"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)
    session_id = Column(UUID(as_uuid=True), ForeignKey("attendance_sessions.id", ondelete="SET NULL"), nullable=True)
    member_id = Column(UUID(as_uuid=True), ForeignKey("members.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    record_type = Column(String(20), nullable=False, default="masuk")  # 'masuk' or 'pulang'
    status = Column(String(30), nullable=False, default="hadir")  # 'hadir', 'izin', 'sakit', 'alpha'
    late_minutes = Column(Integer, default=0)  # Menit keterlambatan
    rfid_code = Column(String(100), nullable=True)  # Jika scan via hardware RFID
    recorded_at = Column(DateTime, default=datetime.utcnow, index=True)
    scan_method = Column(String(50), default="qr_scan")  # 'qr_scan', 'rfid', 'manual', 'geofence'
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    notes = Column(Text, nullable=True)
    is_offline_sync = Column(Boolean, default=False)

    session = relationship("AttendanceSession", back_populates="records")
    member = relationship("Member", back_populates="attendance_records")


class LeaveRequest(Base):
    """
    Model Pengajuan Izin/Sakit Mandiri Digital (diadopsi dari fitur /izin absensi-sekolah-qr-code)
    """
    __tablename__ = "leave_requests"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)
    member_id = Column(UUID(as_uuid=True), ForeignKey("members.id", ondelete="CASCADE"), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    category = Column(String(20), nullable=False, default="izin")  # 'izin' or 'sakit'
    reason = Column(Text, nullable=False)
    attachment_url = Column(String(500), nullable=True)  # Foto surat dokter / bukti
    status = Column(String(20), nullable=False, default="pending")  # 'pending', 'approved', 'rejected'
    reviewed_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    reviewed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)

    member = relationship("Member")
    reviewer = relationship("User")


class AssetItem(Base):
    """
    Model Aset / Inventaris (diadopsi dari BukuHub / Inventaris sistem perpustakaan & sarana gereja)
    """
    __tablename__ = "asset_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=False)  # e.g. "Buku Paket Matematika X", "LCD Proyektor A"
    code = Column(String(100), unique=True, nullable=False, index=True)
    qr_token = Column(String(255), unique=True, nullable=False, index=True)
    category = Column(String(100), nullable=True)  # "Buku", "Elektronik", "Alat Musik"
    status = Column(String(30), default="available")  # 'available', 'borrowed', 'maintenance'
    created_at = Column(DateTime, default=datetime.utcnow)


class AssetLoan(Base):
    """
    Sirkulasi Peminjaman Aset via QR Code (diadopsi dari BukuHub)
    """
    __tablename__ = "asset_loans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    asset_id = Column(UUID(as_uuid=True), ForeignKey("asset_items.id", ondelete="CASCADE"), nullable=False)
    member_id = Column(UUID(as_uuid=True), ForeignKey("members.id", ondelete="CASCADE"), nullable=False)
    borrowed_at = Column(DateTime, default=datetime.utcnow)
    due_date = Column(Date, nullable=False)
    returned_at = Column(DateTime, nullable=True)
    condition_notes = Column(Text, nullable=True)

    asset = relationship("AssetItem")
    member = relationship("Member")
