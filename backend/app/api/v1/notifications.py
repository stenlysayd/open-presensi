from typing import Any, List
from uuid import UUID
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.organization import User
from app.models.notification import WAQueue
from app.schemas.notification import WAQueueCreate, WAQueueResponse
from app.api.v1.auth import get_current_user, require_role
from app.services.wa_service import dispatch_pending_wa_queue

router = APIRouter()

@router.get("/queue", response_model=List[WAQueueResponse])
def list_wa_queue(
    org_id: UUID,
    status: str = Query(None),
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin", "admin"]))
) -> Any:
    q = db.query(WAQueue).filter(WAQueue.org_id == org_id)
    if status:
        q = q.filter(WAQueue.status == status.upper())
    return q.order_by(WAQueue.created_at.desc()).limit(50).all()

@router.post("/queue", response_model=WAQueueResponse)
def enqueue_wa_message(
    req: WAQueueCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin", "admin"]))
) -> Any:
    item = WAQueue(**req.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item

@router.post("/dispatch")
async def trigger_dispatch_worker(
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["superadmin", "admin"]))
) -> Any:
    sent = await dispatch_pending_wa_queue(db, max_items=10)
    return {"success": True, "processed": sent, "message": f"{sent} pesan berhasil diproses dan dikirim."}
