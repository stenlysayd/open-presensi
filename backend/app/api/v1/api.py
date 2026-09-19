from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.organizations import router as org_router
from app.api.v1.attendance import router as attendance_router
from app.api.v1.reports import router as reports_router
from app.api.v1.notifications import router as notifications_router
from app.api.v1.ai_summary import router as ai_summary_router
from app.api.v1.public import router as public_router
from app.api.v1.assets import router as assets_router

api_router = APIRouter()

api_router.include_router(public_router, prefix="/public", tags=["Layanan Mandiri Publik (/izin & /cek-kehadiran)"])
api_router.include_router(auth_router, prefix="/auth", tags=["Autentikasi & Pengguna"])
api_router.include_router(org_router, prefix="/organizations", tags=["Organisasi, Grup & Anggota"])
api_router.include_router(attendance_router, prefix="/attendance", tags=["Mesin Presensi QR, RFID & Perizinan"])
api_router.include_router(assets_router, prefix="/assets", tags=["Sirkulasi Peminjaman Aset (BukuHub)"])
api_router.include_router(reports_router, prefix="/reports", tags=["Laporan Excel, PDF & Cetak Kartu A4"])
api_router.include_router(notifications_router, prefix="/notifications", tags=["WhatsApp Gateway Queue"])
api_router.include_router(ai_summary_router, prefix="/ai-summary", tags=["AI Attendance Digest"])
