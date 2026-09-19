from datetime import date, datetime
from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.organization import Member, Organization, Group
from app.models.attendance import AttendanceRecord, LeaveRequest
from app.schemas.attendance import LeaveRequestCreate, LeaveRequestResponse

router = APIRouter()

@router.post("/leave-requests", response_model=LeaveRequestResponse)
def submit_public_leave_request(
    req: LeaveRequestCreate,
    db: Session = Depends(get_db)
) -> Any:
    """
    Portal Pengajuan Izin/Sakit Mandiri Tanpa Perlu Login (/izin)
    Diadopsi langsung dari absensi-sekolah-qr-code.
    """
    member = db.query(Member).filter(
        Member.registration_number == req.registration_number.strip(),
        Member.is_active == True
    ).first()

    if not member:
        raise HTTPException(
            status_code=404,
            detail="Nomor Induk / Registrasi tidak ditemukan. Pastikan Anda memasukkan nomor yang valid."
        )

    if req.end_date < req.start_date:
        raise HTTPException(status_code=400, detail="Tanggal selesai tidak boleh lebih awal dari tanggal mulai.")

    leave = LeaveRequest(
        org_id=member.org_id,
        member_id=member.id,
        start_date=req.start_date,
        end_date=req.end_date,
        category=req.category.lower(),
        reason=req.reason,
        attachment_url=req.attachment_url,
        status="pending"
    )
    db.add(leave)
    db.commit()
    db.refresh(leave)

    return LeaveRequestResponse(
        id=leave.id,
        org_id=leave.org_id,
        member_id=leave.member_id,
        member_name=member.name,
        category=leave.category,
        start_date=leave.start_date,
        end_date=leave.end_date,
        reason=leave.reason,
        attachment_url=leave.attachment_url,
        status=leave.status,
        created_at=leave.created_at
    )

@router.get("/check-attendance")
def public_check_attendance(
    reg_number: str = Query(..., description="NISN atau Nomor Induk"),
    db: Session = Depends(get_db)
) -> Any:
    """
    Portal Pengecekan Riwayat Kehadiran Mandiri Tanpa Login (/cek-kehadiran)
    Diadopsi langsung dari absensi-sekolah-qr-code.
    """
    member = db.query(Member).filter(
        Member.registration_number == reg_number.strip(),
        Member.is_active == True
    ).first()

    if not member:
        raise HTTPException(status_code=404, detail="Data anggota tidak ditemukan.")

    records = db.query(AttendanceRecord).filter(
        AttendanceRecord.member_id == member.id
    ).order_by(AttendanceRecord.recorded_at.desc()).limit(30).all()

    group_name = member.group.name if member.group else "-"

    history = []
    for r in records:
        history.append({
            "record_type": r.record_type,
            "status": r.status,
            "recorded_at": r.recorded_at.strftime("%d/%m/%Y %H:%M"),
            "late_minutes": r.late_minutes,
            "scan_method": r.scan_method,
            "notes": r.notes
        })

    return {
        "member_name": member.name,
        "registration_number": member.registration_number,
        "group_name": group_name,
        "total_records": len(records),
        "history": history
    }
