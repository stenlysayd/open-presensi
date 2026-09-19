import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Text, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base

class WAQueue(Base):
    __tablename__ = "wa_queue"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=True)
    target = Column(String(100), nullable=False)  # Phone number (628xxx) or Group ID (@g.us)
    message = Column(Text, nullable=False)
    status = Column(String(20), nullable=False, default="PENDING", index=True)  # PENDING, SENT, FAILED
    delay_seconds = Column(Integer, nullable=False, default=3)
    retry_count = Column(Integer, nullable=False, default=0)
    sent_at = Column(DateTime, nullable=True)
    error_message = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
