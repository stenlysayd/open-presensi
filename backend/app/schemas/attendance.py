from typing import Optional, List
from uuid import UUID
from datetime import datetime, date, time
from pydantic import BaseModel, ConfigDict


class QRScanRequest(BaseModel):
    qr_token: str
    record_type: str = "masuk"  # 'masuk' or 'pulang'
    status: str = "hadir"  # 'hadir', 'izin', 'sakit', 'alpha'
    session_id: Optional[UUID] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    notes: Optional[str] = None
    is_offline_sync: bool = False
    recorded_at: Optional[datetime] = None

class RFIDScanRequest(BaseModel):
    rfid_code: str
    record_type: str = "masuk"
    session_id: Optional[UUID] = None

class BatchOfflineSyncRequest(BaseModel):
    records: List[QRScanRequest]

class SessionCreate(BaseModel):
    org_id: UUID
    title: str
    session_date: date
    start_time: time
    end_time: time
    late_tolerance_minutes: int = 15
    require_geofence: bool = False

class SessionResponse(BaseModel):
    id: UUID
    org_id: UUID
    title: str
    session_date: date
    start_time: time
    end_time: time
    late_tolerance_minutes: int
    require_geofence: bool
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class AttendanceRecordResponse(BaseModel):
    id: UUID
    member_id: UUID
    member_name: Optional[str] = None
    registration_number: Optional[str] = None
    group_name: Optional[str] = None
    record_type: str
    status: str
    late_minutes: int = 0
    scan_method: str
    recorded_at: datetime
    notes: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class DailyRecapItem(BaseModel):
    date: date
    total_members: int
    present: int
    excused: int  # Izin / Sakit
    absent: int   # Alpha
    rate_percent: float

class DailyRecapResponse(BaseModel):
    org_id: UUID
    start_date: date
    end_date: date
    summary: List[DailyRecapItem]

# --- LEAVE REQUEST SCHEMAS (Fitur Pengajuan Izin Mandiri /izin) ---
class LeaveRequestCreate(BaseModel):
    registration_number: str
    start_date: date
    end_date: date
    category: str = "izin"  # 'izin' or 'sakit'
    reason: str
    attachment_url: Optional[str] = None

class LeaveRequestReview(BaseModel):
    status: str  # 'approved' or 'rejected'

class LeaveRequestResponse(BaseModel):
    id: UUID
    org_id: UUID
    member_id: UUID
    member_name: Optional[str] = None
    category: str
    start_date: date
    end_date: date
    reason: str
    attachment_url: Optional[str] = None
    status: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# --- CONSECUTIVE ABSENCE WARNING SCHEMA (Fitur Peringatan 3 Hari Bolos) ---
class ConsecutiveAbsenceItem(BaseModel):
    member_id: UUID
    registration_number: str
    member_name: str
    group_name: Optional[str] = None
    parent_phone: Optional[str] = None
    consecutive_days: int
    last_seen_date: Optional[date] = None

# --- ASSET / BUKUHUB LOAN SCHEMAS ---
class AssetItemCreate(BaseModel):
    org_id: UUID
    name: str
    code: str
    category: Optional[str] = "Umum"

class AssetItemResponse(BaseModel):
    id: UUID
    name: str
    code: str
    qr_token: str
    category: Optional[str]
    status: str

    model_config = ConfigDict(from_attributes=True)

class AssetLoanCreate(BaseModel):
    asset_qr_token: str
    member_qr_token: str
    due_date: date
    notes: Optional[str] = None

class AssetLoanResponse(BaseModel):
    id: UUID
    asset_name: str
    member_name: str
    borrowed_at: datetime
    due_date: date
    returned_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
