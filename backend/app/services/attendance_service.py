import math
from datetime import datetime, date, timedelta, time
from uuid import UUID
from typing import Optional, List, Tuple, Dict, Any
from sqlalchemy.orm import Session
from fastapi import HTTPException

from app.models.organization import Member, Organization, Group
from app.models.attendance import AttendanceRecord, AttendanceSession, LeaveRequest
from app.models.notification import WAQueue
from app.schemas.attendance import QRScanRequest

def calculate_haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Haversine formula to compute distance between two coordinates in meters.
    Derived from Absensi Familia anti-fraud engine.
    """
    R = 6371000.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (math.sin(delta_phi / 2.0) ** 2 +
         math.cos(phi1) * math.cos(phi2) * (math.sin(delta_lambda / 2.0) ** 2))
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return R * c

def record_scan(
    db: Session,
    scan_data: QRScanRequest,
    recorded_by_user_id: Optional[UUID] = None
) -> Tuple[AttendanceRecord, Member]:
    # 1. Look up member by QR token
    member = db.query(Member).filter(Member.qr_token == scan_data.qr_token, Member.is_active == True).first()
    if not member:
        raise HTTPException(status_code=404, detail="Token QR tidak valid atau anggota tidak aktif.")

    org = db.query(Organization).filter(Organization.id == member.org_id).first()

    # 2. Check geofence
    if scan_data.latitude is not None and scan_data.longitude is not None and org and org.latitude and org.longitude:
        dist = calculate_haversine_distance(scan_data.latitude, scan_data.longitude, org.latitude, org.longitude)
        allowed_radius = org.radius_meter or 100.0
        if dist > allowed_radius:
            raise HTTPException(
                status_code=400,
                detail=f"Di luar jangkauan lokasi! Jarak Anda {int(dist)}m (Maksimal {int(allowed_radius)}m)."
            )

    record_time = scan_data.recorded_at or datetime.utcnow()
    scan_date = record_time.date()

    # 3. Check for existing scan today
    existing = db.query(AttendanceRecord).filter(
        AttendanceRecord.member_id == member.id,
        AttendanceRecord.record_type == scan_data.record_type,
        AttendanceRecord.recorded_at >= datetime.combine(scan_date, datetime.min.time()),
        AttendanceRecord.recorded_at <= datetime.combine(scan_date, datetime.max.time()),
    ).first()

    if existing:
        raise HTTPException(
            status_code=400,
            detail=f"Presensi {scan_data.record_type} untuk {member.name} hari ini sudah tercatat pkl {existing.recorded_at.strftime('%H:%M')}."
        )

    # 4. Hitung Menit Keterlambatan (Late Minutes Calculation - Fitur absensi-sekolah-qr-code)
    late_minutes = 0
    if scan_data.record_type == "masuk" and scan_data.session_id:
        session = db.query(AttendanceSession).filter(AttendanceSession.id == scan_data.session_id).first()
        if session and session.start_time:
            session_start_dt = datetime.combine(scan_date, session.start_time)
            tolerance_dt = session_start_dt + timedelta(minutes=session.late_tolerance_minutes or 15)
            if record_time > tolerance_dt:
                diff = record_time - session_start_dt
                late_minutes = max(0, int(diff.total_seconds() / 60))

    # 5. Insert Attendance Record
    new_record = AttendanceRecord(
        org_id=member.org_id,
        session_id=scan_data.session_id,
        member_id=member.id,
        user_id=recorded_by_user_id,
        record_type=scan_data.record_type,
        status=scan_data.status,
        late_minutes=late_minutes,
        recorded_at=record_time,
        scan_method="qr_scan",
        latitude=scan_data.latitude,
        longitude=scan_data.longitude,
        notes=scan_data.notes,
        is_offline_sync=scan_data.is_offline_sync
    )
    db.add(new_record)

    # 6. Notifikasi WhatsApp otomatis jika ada nomor orang tua/wali
    if member.parent_phone and scan_data.status == "hadir":
        formatted_time = record_time.strftime("%H:%M")
        late_notice = f" (Terlambat {late_minutes} menit)" if late_minutes > 0 else ""
        msg = (
            f"Halo, menginformasikan bahwa {member.name} "
            f"telah tercatat presensi '{scan_data.record_type}' pada {scan_date.strftime('%d/%m/%Y')} pukul {formatted_time}{late_notice}. "
            f"Status: {scan_data.status.upper()}."
        )
        wa_item = WAQueue(
            org_id=member.org_id,
            target=member.parent_phone,
            message=msg,
            status="PENDING",
            delay_seconds=3
        )
        db.add(wa_item)

    db.commit()
    db.refresh(new_record)
    return new_record, member

def record_scan_by_rfid(
    db: Session,
    rfid_code: str,
    record_type: str = "masuk",
    session_id: Optional[UUID] = None,
    user_id: Optional[UUID] = None
) -> Tuple[AttendanceRecord, Member]:
    """
    Presensi instan via kartu RFID (Hardware USB RFID Reader Keystroke / Tap)
    Diadopsi langsung dari absensi-sekolah-qr-code.
    """
    clean_rfid = rfid_code.strip()
    member = db.query(Member).filter(Member.rfid_code == clean_rfid, Member.is_active == True).first()
    if not member:
        raise HTTPException(status_code=404, detail=f"Kartu RFID '{clean_rfid}' belum terdaftar pada anggota manapun.")

    scan_req = QRScanRequest(
        qr_token=member.qr_token,
        record_type=record_type,
        status="hadir",
        session_id=session_id
    )
    record, mem = record_scan(db, scan_req, recorded_by_user_id=user_id)
    record.scan_method = "rfid"
    record.rfid_code = clean_rfid
    db.commit()
    return record, mem

def process_batch_offline_sync(
    db: Session,
    records: List[QRScanRequest],
    recorded_by_user_id: Optional[UUID] = None
) -> dict:
    success_count = 0
    failed_items = []

    for item in records:
        item.is_offline_sync = True
        try:
            record_scan(db, item, recorded_by_user_id)
            success_count += 1
        except Exception as e:
            failed_items.append({
                "qr_token": item.qr_token,
                "error": str(e)
            })

    return {
        "total_submitted": len(records),
        "synced_successfully": success_count,
        "failed_count": len(failed_items),
        "failures": failed_items
    }

def get_consecutive_absence_alerts(
    db: Session,
    org_id: UUID,
    threshold_days: int = 3
) -> List[Dict[str, Any]]:
    """
    Peringatan Ketidakhadiran Beruntun (Diadopsi dari absensi-sekolah-qr-code)
    Mendeteksi siswa/jemaat yang tidak hadir 3+ hari kerja berturut-turut tanpa keterangan.
    """
    members = db.query(Member).join(Group, Member.group_id == Group.id, isouter=True)\
        .filter(Member.org_id == org_id, Member.is_active == True).all()

    today = date.today()
    alerts = []

    for m in members:
        # Check attendance records in the last 7 days
        recent_records = db.query(AttendanceRecord).filter(
            AttendanceRecord.member_id == m.id,
            AttendanceRecord.recorded_at >= datetime.combine(today - timedelta(days=7), datetime.min.time())
        ).order_by(AttendanceRecord.recorded_at.desc()).all()

        present_dates = {r.recorded_at.date() for r in recent_records if r.status in ["hadir", "izin", "sakit"]}
        
        consecutive_absent = 0
        last_seen = None

        for day_offset in range(1, 8):
            d = today - timedelta(days=day_offset)
            if d.weekday() >= 5:  # Skip weekend
                continue
            if d in present_dates:
                last_seen = d
                break
            else:
                consecutive_absent += 1

        if consecutive_absent >= threshold_days:
            group_name = m.group.name if m.group else "-"
            alerts.append({
                "member_id": m.id,
                "registration_number": m.registration_number,
                "member_name": m.name,
                "group_name": group_name,
                "parent_phone": m.parent_phone,
                "consecutive_days": consecutive_absent,
                "last_seen_date": last_seen
            })

    return alerts
