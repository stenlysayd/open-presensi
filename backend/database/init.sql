-- Open Presensi: Initial Database Schema (PostgreSQL)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Organizations (Sekolah / Gereja / Yayasan)
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'school', -- 'school' or 'church' or 'community'
    code VARCHAR(50) UNIQUE,
    address TEXT,
    phone VARCHAR(50),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    radius_meter DOUBLE PRECISION DEFAULT 100.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. System Users (Staff, Admin, Guru, Majelis)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    identifier VARCHAR(100) UNIQUE NOT NULL, -- NUPTK / NIP / Email / No. Anggota
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'member', -- 'superadmin', 'admin', 'staff', 'member'
    device_id VARCHAR(255), -- For Hardware Device Binding
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Groups / Divisions (Kelas / Rayon / Kategorial)
CREATE TABLE IF NOT EXISTS groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL, -- e.g. "Kelas X MIPA 1" or "Rayon 4"
    category VARCHAR(100),       -- e.g. "Kelas", "Rayon", "Kategorial Pemuda"
    leader_user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Wali Kelas or Koordinator Rayon
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Members (Siswa / Jemaat)
CREATE TABLE IF NOT EXISTS members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    group_id UUID REFERENCES groups(id) ON DELETE SET NULL,
    registration_number VARCHAR(100) UNIQUE NOT NULL, -- NISN / No. Induk Jemaat
    name VARCHAR(255) NOT NULL,
    gender VARCHAR(10), -- 'L' or 'P'
    phone VARCHAR(50),
    parent_phone VARCHAR(50), -- No. WhatsApp Orang Tua / Wali
    qr_token VARCHAR(255) UNIQUE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Attendance Sessions / Events (KBM Harian / Ibadah Minggu / Rapat)
CREATE TABLE IF NOT EXISTS attendance_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    session_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    require_geofence BOOLEAN NOT NULL DEFAULT FALSE,
    qr_dynamic_secret VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Attendance Raw Records
CREATE TABLE IF NOT EXISTS attendance_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    session_id UUID REFERENCES attendance_sessions(id) ON DELETE SET NULL,
    member_id UUID REFERENCES members(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- In case a teacher/staff is recording
    record_type VARCHAR(20) NOT NULL DEFAULT 'masuk', -- 'masuk' or 'pulang'
    status VARCHAR(30) NOT NULL DEFAULT 'hadir', -- 'hadir', 'izin', 'sakit', 'alpha'
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    scan_method VARCHAR(50) NOT NULL DEFAULT 'qr_scan', -- 'qr_scan', 'manual', 'geofence'
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    notes TEXT,
    is_offline_sync BOOLEAN NOT NULL DEFAULT FALSE
);

-- 7. WhatsApp Message Queue
CREATE TABLE IF NOT EXISTS wa_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    target VARCHAR(100) NOT NULL, -- Nomor HP (62xxx) or Group ID (@g.us)
    message TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'SENT', 'FAILED'
    delay_seconds INT NOT NULL DEFAULT 3,
    retry_count INT NOT NULL DEFAULT 0,
    sent_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_members_qr ON members(qr_token);
CREATE INDEX IF NOT EXISTS idx_attendance_member_date ON attendance_records(member_id, recorded_at);
CREATE INDEX IF NOT EXISTS idx_wa_queue_status ON wa_queue(status, created_at);
