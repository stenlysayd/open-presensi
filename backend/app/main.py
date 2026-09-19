import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, RedirectResponse
from app.core.config import settings
from app.core.database import engine, Base
import app.models  # Import all models to ensure registration with Base
from app.api.v1.api import api_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create database tables if not exist on server startup
    try:
        Base.metadata.create_all(bind=engine)
    except Exception as e:
        print(f"Warning: Could not initialize database on startup: {e}")
    yield

app = FastAPI(
    title=settings.APP_NAME,
    description="Sistem Presensi dan Manajemen Komunitas Open Source untuk Sekolah & Gereja Kecil di Indonesia.",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# CORS Configuration for Flutter Web and Mobile
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")

STATIC_DIR = os.path.join(os.path.dirname(__file__), "static")

@app.get("/portal", tags=["Public Portal"])
def get_portal():
    """Portal Mandiri Tanpa Login untuk Siswa, Orang Tua, dan Jemaat"""
    portal_path = os.path.join(STATIC_DIR, "portal.html")
    return FileResponse(portal_path)

@app.get("/izin", tags=["Public Portal"])
def redirect_izin():
    """Shortcut ke Portal Pengajuan Izin Mandiri"""
    return RedirectResponse(url="/portal#izin")

@app.get("/cek-kehadiran", tags=["Public Portal"])
def redirect_cek_kehadiran():
    """Shortcut ke Portal Pengecekan Riwayat Kehadiran Mandiri"""
    return RedirectResponse(url="/portal#cek")

@app.get("/", tags=["Status"])
def root_status():
    return {
        "status": "online",
        "app": settings.APP_NAME,
        "version": "0.1.0",
        "portal": "/portal",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health", tags=["Status"])
def health_check():
    return {"status": "healthy", "environment": settings.ENVIRONMENT}

