import asyncio
import random
import httpx
from datetime import datetime
from typing import Tuple
from sqlalchemy.orm import Session
from app.core.config import settings
from app.models.notification import WAQueue

async def send_via_fonnte(target: str, message: str, token: str) -> Tuple[bool, str]:
    """
    Kirim via Fonnte API (Mengadopsi pola cron wa_worker.php dari GMIT Pniel)
    """
    clean_target = target.strip()
    is_group = "@g.us" in clean_target or "-" in clean_target
    
    headers = {"Authorization": token}
    payload = {
        "target": clean_target,
        "message": message,
        "delay": "2-5",
        "typing": "true"
    }
    if not is_group and not clean_target.startswith("62"):
        payload["countryCode"] = "62"

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            resp = await client.post("https://api.fonnte.com/send", data=payload, headers=headers)
            data = resp.json()
            if data.get("status") is True or resp.status_code == 200:
                return True, "Success"
            return False, data.get("reason", "Unknown provider failure")
        except Exception as e:
            return False, str(e)

async def dispatch_pending_wa_queue(db: Session, max_items: int = 10) -> int:
    """
    Background worker loop for processing pending messages.
    """
    if not settings.WA_ENABLED or not settings.WA_API_TOKEN:
        return 0

    pending = db.query(WAQueue).filter(
        WAQueue.status == "PENDING"
    ).order_by(WAQueue.created_at.asc()).limit(max_items).all()

    if not pending:
        return 0

    sent_count = 0
    for item in pending:
        # Anti-ban human-like randomized sleep (2 to 5 seconds)
        sleep_delay = random.uniform(2.0, 5.0)
        await asyncio.sleep(sleep_delay)

        success, note = await send_via_fonnte(item.target, item.message, settings.WA_API_TOKEN)
        if success:
            item.status = "SENT"
            item.sent_at = datetime.utcnow()
            sent_count += 1
        else:
            item.retry_count += 1
            item.error_message = note
            if item.retry_count >= 3:
                item.status = "FAILED"

        db.commit()

    return sent_count
