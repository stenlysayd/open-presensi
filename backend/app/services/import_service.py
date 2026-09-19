import csv
import io
from uuid import UUID
from typing import Dict, Any, List
from sqlalchemy.orm import Session
from app.models.organization import Member, Group
from app.services.qr_service import generate_member_qr_token

def parse_and_import_members_csv(
    db: Session,
    org_id: UUID,
    csv_content: str
) -> Dict[str, Any]:
    """
    Impor massal anggota dari file CSV (Diadopsi dari absensi-sekolah-qr-code)
    Mendukung header: nama, no_induk, gender, telepon, no_wa_wali, grup
    """
    f = io.StringIO(csv_content.strip())
    reader = csv.DictReader(f)

    # Normalize fieldnames to lowercase
    if not reader.fieldnames:
        return {"success": False, "message": "File CSV kosong atau header tidak valid."}

    created_count = 0
    skipped_count = 0
    errors = []

    # Cache existing groups
    groups = {g.name.lower(): g.id for g in db.query(Group).filter(Group.org_id == org_id).all()}

    for row_idx, raw_row in enumerate(reader, 1):
        row = {k.strip().lower(): v.strip() for k, v in raw_row.items() if k}
        
        name = row.get("nama") or row.get("name")
        reg_number = row.get("no_induk") or row.get("nisn") or row.get("reg_number")
        gender = (row.get("gender") or row.get("jk") or "L")[:1].upper()
        phone = row.get("telepon") or row.get("phone") or ""
        parent_phone = row.get("no_wa_wali") or row.get("parent_phone") or ""
        group_name = row.get("grup") or row.get("kelas") or row.get("rayon")

        if not name or not reg_number:
            errors.append(f"Baris {row_idx}: Nama atau Nomor Induk kosong.")
            skipped_count += 1
            continue

        # Check existing member
        existing = db.query(Member).filter(
            Member.org_id == org_id,
            Member.registration_number == reg_number
        ).first()

        if existing:
            skipped_count += 1
            continue

        # Resolve or auto-create Group
        group_id = None
        if group_name:
            grp_key = group_name.lower()
            if grp_key in groups:
                group_id = groups[grp_key]
            else:
                new_grp = Group(org_id=org_id, name=group_name, category="Kelas")
                db.add(new_grp)
                db.commit()
                db.refresh(new_grp)
                groups[grp_key] = new_grp.id
                group_id = new_grp.id

        qr_token = generate_member_qr_token(str(org_id), reg_number)
        member = Member(
            org_id=org_id,
            group_id=group_id,
            registration_number=reg_number,
            name=name,
            gender=gender,
            phone=phone,
            parent_phone=parent_phone,
            qr_token=qr_token
        )
        db.add(member)
        created_count += 1

    db.commit()
    return {
        "success": True,
        "created_count": created_count,
        "skipped_count": skipped_count,
        "errors": errors
    }
