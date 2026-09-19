from typing import Any, List
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Response, UploadFile, File
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.organization import Organization, Group, Member, User
from app.schemas.organization import (
    OrganizationCreate, OrganizationResponse,
    GroupCreate, GroupResponse,
    MemberCreate, MemberResponse
)
from app.api.v1.auth import get_current_user, require_role
from app.services.qr_service import generate_member_qr_token, generate_qr_image_bytes
from app.services.import_service import parse_and_import_members_csv

router = APIRouter()

# --- ORGANIZATIONS ---
@router.get("/", response_model=List[OrganizationResponse])
def list_organizations(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)) -> Any:
    return db.query(Organization).all()

@router.post("/", response_model=OrganizationResponse)
def create_organization(
    req: OrganizationCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin"]))
) -> Any:
    org = Organization(**req.model_dump())
    db.add(org)
    db.commit()
    db.refresh(org)
    return org

# --- GROUPS (Kelas / Rayon) ---
@router.get("/{org_id}/groups", response_model=List[GroupResponse])
def list_groups(org_id: UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)) -> Any:
    return db.query(Group).filter(Group.org_id == org_id).all()

@router.post("/{org_id}/groups", response_model=GroupResponse)
def create_group(
    org_id: UUID,
    req: GroupCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin", "admin"]))
) -> Any:
    group = Group(**req.model_dump())
    db.add(group)
    db.commit()
    db.refresh(group)
    return group

# --- MEMBERS (Siswa / Jemaat) ---
@router.get("/{org_id}/members", response_model=List[MemberResponse])
def list_members(org_id: UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)) -> Any:
    return db.query(Member).filter(Member.org_id == org_id).all()

@router.post("/{org_id}/members", response_model=MemberResponse)
def create_member(
    org_id: UUID,
    req: MemberCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin", "admin", "staff"]))
) -> Any:
    existing = db.query(Member).filter(Member.registration_number == req.registration_number).first()
    if existing:
        raise HTTPException(status_code=400, detail="Nomor Induk / Registrasi sudah terdaftar.")

    qr_token = generate_member_qr_token(str(org_id), req.registration_number)
    member = Member(
        **req.model_dump(),
        qr_token=qr_token
    )
    db.add(member)
    db.commit()
    db.refresh(member)
    return member

@router.post("/{org_id}/members/import-csv")
async def import_members_csv(
    org_id: UUID,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin", "admin"]))
) -> Any:
    """
    Impor Massal Data Anggota dari File CSV (Diadopsi dari absensi-sekolah-qr-code)
    """
    content = await file.read()
    try:
        csv_text = content.decode("utf-8")
    except UnicodeDecodeError:
        csv_text = content.decode("latin-1")

    result = parse_and_import_members_csv(db, org_id, csv_text)
    return result

@router.get("/members/{member_id}/qr-image")
def get_member_qr_image(member_id: UUID, db: Session = Depends(get_db)) -> Response:
    member = db.query(Member).filter(Member.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Anggota tidak ditemukan.")

    img_bytes = generate_qr_image_bytes(member.qr_token)
    return Response(content=img_bytes, media_type="image/png")
