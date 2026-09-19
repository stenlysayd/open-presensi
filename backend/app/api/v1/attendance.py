from typing import Any, List, Optional
from uuid import UUID
from datetime import date, datetime, timedelta
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.organization import User, Member, Group
from app.models.attendance import AttendanceRecord, AttendanceSession, LeaveRequest
from app.schemas.attendance import (
    QRScanRequest, RFIDScanRequest, BatchOfflineSyncRequest,
    SessionCreate, SessionResponse,
    AttendanceRecordResponse, LeaveRequestResponse, LeaveRequestReview,
    ConsecutiveAbsenceItem
)
from app.api.v1.auth import get_current_user, require_role
from app.services.attendance_service import (
    record_scan, record_scan_by_rfid,
    process_batch_offline_sync, get_consecutive_absence_alerts
)

router = APIRouter()

@router.post("/scan")
def scan_attendance_qr(
    req: QRScanRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Rapid single scan endpoint via QR Code.
    """
    record, member = record_scan(db, req, recorded_by_user_id=current_user.id)
    return {
        "success": True,
        "message": f"Presensi {record.record_type} untuk {member.name} berhasil tercatat.",
        "data": {
            "record_id": record.id,
            "member_id": member.id,
            "member_name": member.name,
            "status": record.status,
            "late_minutes": record.late_minutes,
            "record_type": record.record_type,
            "recorded_at": record.recorded_at.isoformat()
        }
    }

@router.post("/scan-rfid")
def scan_attendance_rfid(
    req: RFIDScanRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Rapid single scan endpoint via RFID Card / Hardware Scanner.
    Diadopsi dari absensi-sekolah-qr-code.
    """
    record, member = record_scan_by_rfid(
        db,
        rfid_code=req.rfid_code,
        record_type=req.record_type,
        session_id=req.session_id,
        user_id=current_user.id
    )
    return {
        "success": True,
        "message": f"Presensi RFID {record.record_type} untuk {member.name} berhasil tercatat.",
        "data": {
            "record_id": record.id,
            "member_name": member.name,
            "rfid_code": req.rfid_code,
            "status": record.status,
            "late_minutes": record.late_minutes,
            "record_type": record.record_type
        }
    }

@router.post("/batch-sync")
def batch_sync_offline_attendance(
    req: BatchOfflineSyncRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    result = process_batch_offline_sync(db, req.records, recorded_by_user_id=current_user.id)
    return {
        "success": True,
        "message": f"Sinkronisasi selesai: {result['synced_successfully']} berhasil, {result['failed_count']} gagal.",
        "data": result
    }

@router.get("/records", response_model=List[AttendanceRecordResponse])
def get_attendance_records(
    org_id: UUID,
    filter_date: Optional[date] = Query(None),
    session_id: Optional[UUID] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    query = db.query(
        AttendanceRecord,
        Member.name.label("member_name"),
        Member.registration_number.label("registration_number"),
        Group.name.label("group_name")
    ).join(Member, AttendanceRecord.member_id == Member.id)\
     .outerjoin(Group, Member.group_id == Group.id)\
     .filter(AttendanceRecord.org_id == org_id)

    if filter_date:
        query = query.filter(
            AttendanceRecord.recorded_at >= datetime.combine(filter_date, datetime.min.time()),
            AttendanceRecord.recorded_at <= datetime.combine(filter_date, datetime.max.time())
        )
    if session_id:
        query = query.filter(AttendanceRecord.session_id == session_id)

    rows = query.order_by(AttendanceRecord.recorded_at.desc()).all()
    
    result = []
    for record, mem_name, reg_num, grp_name in rows:
        result.append(AttendanceRecordResponse(
            id=record.id,
            member_id=record.member_id,
            member_name=mem_name,
            registration_number=reg_num,
            group_name=grp_name,
            record_type=record.record_type,
            status=record.status,
            late_minutes=record.late_minutes or 0,
            recorded_at=record.recorded_at,
            scan_method=record.scan_method,
            notes=record.notes
        ))
    return result

@router.get("/consecutive-alerts", response_model=List[ConsecutiveAbsenceItem])
def get_consecutive_absence_warning(
    org_id: UUID,
    days: int = Query(default=3, ge=2, le=14),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    """
    Peringatan Ketidakhadiran Beruntun 3+ Hari (Diadopsi dari absensi-sekolah-qr-code)
    """
    return get_consecutive_absence_alerts(db, org_id, threshold_days=days)

@router.get("/leave-requests", response_model=List[LeaveRequestResponse])
def list_leave_requests(
    org_id: UUID,
    status: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    q = db.query(LeaveRequest).join(Member).filter(LeaveRequest.org_id == org_id)
    if status:
        q = q.filter(LeaveRequest.status == status.lower())
    rows = q.order_by(LeaveRequest.created_at.desc()).all()

    res = []
    for item in rows:
        res.append(LeaveRequestResponse(
            id=item.id,
            org_id=item.org_id,
            member_id=item.member_id,
            member_name=item.member.name,
            category=item.category,
            start_date=item.start_date,
            end_date=item.end_date,
            reason=item.reason,
            attachment_url=item.attachment_url,
            status=item.status,
            created_at=item.created_at
        ))
    return res

@router.patch("/leave-requests/{req_id}/review")
def review_leave_request(
    req_id: UUID,
    review: LeaveRequestReview,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin", "admin", "staff"]))
) -> Any:
    leave = db.query(LeaveRequest).filter(LeaveRequest.id == req_id).first()
    if not leave:
        raise HTTPException(status_code=404, detail="Pengajuan izin tidak ditemukan.")

    leave.status = review.status.lower()
    leave.reviewed_by = admin.id
    leave.reviewed_at = datetime.utcnow()

    # Jika disetujui, buat rekaman presensi sah (izin/sakit) pada rentang tanggal tersebut!
    if review.status.lower() == "approved":
        cur_d = leave.start_date
        while cur_d <= leave.end_date:
            if cur_d.weekday() < 5:  # Skip weekend
                rec_dt = datetime.combine(cur_d, datetime.min.time()) + timedelta(hours=8)
                rec = AttendanceRecord(
                    org_id=leave.org_id,
                    member_id=leave.member_id,
                    user_id=admin.id,
                    record_type="masuk",
                    status=leave.category,
                    recorded_at=rec_dt,
                    scan_method="manual",
                    notes=f"Disetujui dari pengajuan izin: {leave.reason}"
                )
                db.add(rec)
            cur_d += timedelta(days=1)

    db.commit()
    return {"success": True, "message": f"Pengajuan izin berhasil di-{review.status}."}

@router.post("/sessions", response_model=SessionResponse)
def create_session(
    req: SessionCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin", "admin", "staff"]))
) -> Any:
    session = AttendanceSession(**req.model_dump())
    db.add(session)
    db.commit()
    db.refresh(session)
    return session
