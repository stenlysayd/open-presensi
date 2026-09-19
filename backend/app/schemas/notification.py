from typing import Optional
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, ConfigDict

class WAQueueCreate(BaseModel):
    target: str  # Nomor WhatsApp (628xxx) or Group ID (@g.us)
    message: str
    org_id: Optional[UUID] = None
    delay_seconds: int = 3

class WAQueueResponse(BaseModel):
    id: UUID
    target: str
    message: str
    status: str
    delay_seconds: int
    retry_count: int
    sent_at: Optional[datetime] = None
    error_message: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class AISummaryRequest(BaseModel):
    org_id: UUID
    start_date: str  # YYYY-MM-DD
    end_date: str    # YYYY-MM-DD
    target_audience: str = "Pimpinan / Kepala Sekolah / Ketua Majelis"
