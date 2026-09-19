import uuid
from datetime import datetime, date
from typing import Any, List
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.organization import User, Member
from app.models.attendance import AssetItem, AssetLoan
from app.schemas.attendance import (
    AssetItemCreate, AssetItemResponse,
    AssetLoanCreate, AssetLoanResponse
)
from app.api.v1.auth import get_current_user, require_role

router = APIRouter()

@router.get("/", response_model=List[AssetItemResponse])
def list_assets(
    org_id: UUID,
    category: str = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    q = db.query(AssetItem).filter(AssetItem.org_id == org_id)
    if category:
        q = q.filter(AssetItem.category == category)
    return q.all()

@router.post("/", response_model=AssetItemResponse)
def create_asset(
    req: AssetItemCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin", "admin", "staff"]))
) -> Any:
    qr_tok = f"ASSET-{req.code.upper()}-{uuid.uuid4().hex[:6].upper()}"
    item = AssetItem(
        org_id=req.org_id,
        name=req.name,
        code=req.code.upper(),
        qr_token=qr_tok,
        category=req.category,
        status="available"
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item

@router.post("/loans", response_model=AssetLoanResponse)
def create_asset_loan(
    req: AssetLoanCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin", "admin", "staff"]))
) -> Any:
    """
    Sirkulasi Peminjaman Aset via QR Code (Diadopsi dari BukuHub / Inventaris)
    Scan QR Aset + Scan QR Anggota untuk peminjaman cepat.
    """
    asset = db.query(AssetItem).filter(AssetItem.qr_token == req.asset_qr_token).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Aset tidak ditemukan.")
    if asset.status != "available":
        raise HTTPException(status_code=400, detail=f"Aset sedang berstatus: {asset.status}")

    member = db.query(Member).filter(Member.qr_token == req.member_qr_token, Member.is_active == True).first()
    if not member:
        raise HTTPException(status_code=404, detail="Anggota peminjam tidak ditemukan.")

    loan = AssetLoan(
        asset_id=asset.id,
        member_id=member.id,
        due_date=req.due_date,
        condition_notes=req.notes
    )
    asset.status = "borrowed"
    db.add(loan)
    db.commit()
    db.refresh(loan)

    return AssetLoanResponse(
        id=loan.id,
        asset_name=asset.name,
        member_name=member.name,
        borrowed_at=loan.borrowed_at,
        due_date=loan.due_date,
        returned_at=loan.returned_at
    )

@router.post("/loans/{loan_id}/return")
def return_asset_loan(
    loan_id: UUID,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin", "admin", "staff"]))
) -> Any:
    loan = db.query(AssetLoan).filter(AssetLoan.id == loan_id).first()
    if not loan or loan.returned_at is not None:
        raise HTTPException(status_code=400, detail="Data peminjaman tidak valid atau sudah dikembalikan.")

    loan.returned_at = datetime.utcnow()
    loan.asset.status = "available"
    db.commit()

    return {"success": True, "message": f"Aset {loan.asset.name} telah dikembalikan."}
