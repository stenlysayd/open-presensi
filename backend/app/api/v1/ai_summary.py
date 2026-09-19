from datetime import datetime
from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.organization import Organization, Member, User
from app.models.attendance import AttendanceRecord
from app.schemas.notification import AISummaryRequest
from app.api.v1.auth import get_current_user, require_role
from app.services.ai_summary_service import generate_ai_attendance_summary

router = APIRouter()

@router.post("/generate")
async def generate_summary(
    req: AISummaryRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin", "admin", "staff"]))
) -> Any:
    org = db.query(Organization).filter(Organization.id == req.org_id).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organisasi tidak ditemukan.")

    start_d = datetime.strptime(req.start_date, "%Y-%m-%d").date()
    end_d = datetime.strptime(req.end_date, "%Y-%m-%d").date()

    total_members = db.query(Member).filter(Member.org_id == req.org_id, Member.is_active == True).count()
    records = db.query(AttendanceRecord).filter(
        AttendanceRecord.org_id == req.org_id,
        AttendanceRecord.recorded_at >= datetime.combine(start_d, datetime.min.time()),
        AttendanceRecord.recorded_at <= datetime.combine(end_d, datetime.max.time())
    ).all()

    present_ids = set()
    excused_ids = set()
    for r in records:
        if r.status == "hadir":
            present_ids.add(r.member_id)
        elif r.status in ["izin", "sakit"]:
            excused_ids.add(r.member_id)

    present_count = len(present_ids)
    excused_count = len(excused_ids)
    absent_count = max(0, total_members - present_count - excused_count)
    rate_pct = (present_count / total_members * 100.0) if total_members > 0 else 0.0

    stats = {
        "total_members": total_members,
        "present_count": present_count,
        "excused_count": excused_count,
        "absent_count": absent_count,
        "rate_percent": rate_pct
    }

    period_str = f"{start_d.strftime('%d/%m/%Y')} s/d {end_d.strftime('%d/%m/%Y')}"
    summary_text = await generate_ai_attendance_summary(org.name, period_str, stats)

    return {
        "success": True,
        "organization": org.name,
        "period": period_str,
        "stats": stats,
        "summary_text": summary_text
    }
