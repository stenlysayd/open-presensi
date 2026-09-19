from datetime import date, datetime
from uuid import UUID
from typing import Any, Optional
from fastapi import APIRouter, Depends, Query, Response, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.organization import Organization, Member, Group, User
from app.models.attendance import AttendanceRecord
from app.api.v1.auth import get_current_user
from app.services.export_service import generate_attendance_excel, generate_attendance_pdf
from app.services.card_generator_service import generate_printable_card_grid_pdf

router = APIRouter()

def get_report_dataset(db: Session, org_id: UUID, start_date: date, end_date: date):
    org = db.query(Organization).filter(Organization.id == org_id).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organisasi tidak ditemukan.")

    rows = db.query(
        AttendanceRecord,
        Member.name.label("member_name"),
        Member.registration_number.label("registration_number"),
        Group.name.label("group_name")
    ).join(Member, AttendanceRecord.member_id == Member.id)\
     .outerjoin(Group, Member.group_id == Group.id)\
     .filter(
         AttendanceRecord.org_id == org_id,
         AttendanceRecord.recorded_at >= datetime.combine(start_date, datetime.min.time()),
         AttendanceRecord.recorded_at <= datetime.combine(end_date, datetime.max.time())
     ).order_by(AttendanceRecord.recorded_at.desc()).all()

    formatted = []
    for r, name, reg_num, grp_name in rows:
        formatted.append({
            "reg_number": reg_num,
            "name": name,
            "group_name": grp_name or "-",
            "record_type": r.record_type,
            "status": r.status,
            "time_str": r.recorded_at.strftime("%d/%m/%Y %H:%M")
        })

    return org.name, formatted

@router.get("/excel")
def export_excel(
    org_id: UUID,
    start_date: date = Query(default=date.today),
    end_date: date = Query(default=date.today),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Response:
    org_name, records = get_report_dataset(db, org_id, start_date, end_date)
    excel_bytes = generate_attendance_excel(org_name, start_date, end_date, records)

    filename = f"rekap_presensi_{start_date}_{end_date}.xlsx"
    return Response(
        content=excel_bytes,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'}
    )

@router.get("/pdf")
def export_pdf(
    org_id: UUID,
    start_date: date = Query(default=date.today),
    end_date: date = Query(default=date.today),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Response:
    org_name, records = get_report_dataset(db, org_id, start_date, end_date)
    pdf_bytes = generate_attendance_pdf(org_name, start_date, end_date, records)

    filename = f"rekap_presensi_{start_date}_{end_date}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'}
    )

@router.get("/printable-cards")
def export_printable_card_grid(
    org_id: UUID,
    group_id: Optional[UUID] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Response:
    """
    Cetak Lembar Kartu QR Code Grid 4 Kolom A4 (Diadopsi dari absensi-sekolah-qr-code)
    """
    org = db.query(Organization).filter(Organization.id == org_id).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organisasi tidak ditemukan.")

    q = db.query(Member).filter(Member.org_id == org_id, Member.is_active == True)
    if group_id:
        q = q.filter(Member.group_id == group_id)
    members = q.order_by(Member.name.asc()).all()

    if not members:
        raise HTTPException(status_code=404, detail="Tidak ada anggota yang ditemukan untuk dicetak kartunya.")

    card_data = []
    for m in members:
        group_title = m.group.name if m.group else org.name
        card_data.append({
            "name": m.name,
            "registration_number": m.registration_number,
            "group_name": group_title,
            "qr_token": m.qr_token
        })

    pdf_bytes = generate_printable_card_grid_pdf(org.name, card_data)
    filename = f"kartu_id_grid_{org.code or 'open'}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'}
    )

@router.get("/stats")
def get_attendance_stats(
    org_id: UUID,
    target_date: date = Query(default=date.today),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    total_members = db.query(Member).filter(Member.org_id == org_id, Member.is_active == True).count()
    
    records = db.query(AttendanceRecord).filter(
        AttendanceRecord.org_id == org_id,
        AttendanceRecord.recorded_at >= datetime.combine(target_date, datetime.min.time()),
        AttendanceRecord.recorded_at <= datetime.combine(target_date, datetime.max.time())
    ).all()

    present_member_ids = set()
    excused_member_ids = set()

    for r in records:
        if r.status == "hadir":
            present_member_ids.add(r.member_id)
        elif r.status in ["izin", "sakit"]:
            excused_member_ids.add(r.member_id)

    present_count = len(present_member_ids)
    excused_count = len(excused_member_ids)
    absent_count = max(0, total_members - present_count - excused_count)
    rate_pct = (present_count / total_members * 100.0) if total_members > 0 else 0.0

    return {
        "date": target_date.isoformat(),
        "total_members": total_members,
        "present_count": present_count,
        "excused_count": excused_count,
        "absent_count": absent_count,
        "rate_percent": round(rate_pct, 1)
    }
