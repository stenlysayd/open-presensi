import httpx
from typing import Dict, Any
from app.core.config import settings

async def generate_ai_attendance_summary(
    organization_name: str,
    period: str,
    stats: Dict[str, Any]
) -> str:
    """
    Generate natural language executive summary for headmaster/pastor/leaders.
    Can use OpenAI or Gemini API if enabled, otherwise provides a structured deterministic template.
    """
    total = stats.get("total_members", 0)
    present = stats.get("present_count", 0)
    excused = stats.get("excused_count", 0)
    absent = stats.get("absent_count", 0)
    pct = stats.get("rate_percent", 0.0)

    # 1. Graceful Fallback if AI disabled or key missing
    if not settings.AI_SUMMARY_ENABLED or not settings.AI_API_KEY:
        return (
            f"📊 *Laporan Ringkasan Kehadiran - {organization_name}*\n"
            f"🗓️ Periode: {period}\n\n"
            f"• Total Terdaftar: {total} orang\n"
            f"• Hadir: {present} ({pct:.1f}%)\n"
            f"• Izin / Sakit: {excused}\n"
            f"• Tanpa Keterangan / Alpha: {absent}\n\n"
            f"💡 *Catatan:* Tingkat partisipasi kehadiran mencapai {pct:.1f}%. "
            f"Pastikan anggota yang berhalangan hadir mendapatkan tindak lanjut atau pendampingan."
        )

    # 2. If OpenAI configured
    prompt = (
        f"Sebagai asisten administrasi untuk {organization_name}, buatkan ringkasan eksekutif "
        f"yang singkat, padat, dan ramah dibaca di WhatsApp untuk pimpinan mengenai data kehadiran periode {period}:\n"
        f"- Total Anggota: {total}\n"
        f"- Hadir: {present} ({pct:.1f}%)\n"
        f"- Izin/Sakit: {excused}\n"
        f"- Alpha/Tidak Hadir: {absent}\n"
        f"Gunakan format poin penting dan sertakan 1-2 rekomendasi tindak lanjut singkat dalam Bahasa Indonesia."
    )

    try:
        if settings.AI_PROVIDER == "openai":
            async with httpx.AsyncClient(timeout=20.0) as client:
                resp = await client.post(
                    "https://api.openai.com/v1/chat/completions",
                    headers={"Authorization": f"Bearer {settings.AI_API_KEY}"},
                    json={
                        "model": settings.AI_MODEL_NAME,
                        "messages": [
                            {"role": "system", "content": "Anda adalah asisten data dan manajemen institusi lokal di Indonesia."},
                            {"role": "user", "content": prompt}
                        ],
                        "temperature": 0.4
                    }
                )
                if resp.status_code == 200:
                    data = resp.json()
                    return data["choices"][0]["message"]["content"]
    except Exception:
        pass

    # Fallback if request fails
    return (
        f"📊 *Ringkasan Kehadiran {organization_name}* ({period}):\n"
        f"Hadir: {present}/{total} ({pct:.1f}%). Izin/Sakit: {excused}, Alpha: {absent}."
    )
