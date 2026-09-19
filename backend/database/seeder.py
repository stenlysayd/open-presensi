import argparse
import sys
import uuid

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass
from datetime import datetime, time, date
from app.core.database import SessionLocal, engine, Base
from app.core.security import get_password_hash
from app.models.organization import Organization, User, Group, Member
from app.models.attendance import AttendanceSession
from app.services.qr_service import generate_member_qr_token

def seed_database(preset: str = "sekolah"):
    db = SessionLocal()
    try:
        Base.metadata.create_all(bind=engine)
        print(f"⏳ Memulai proses pengisian data dummy dengan preset: {preset.upper()}...")

        hashed_pass = get_password_hash("rahasia123")

        # 1. Buat Super Admin Global
        admin_user = db.query(User).filter(User.identifier == "admin@komunitas.id").first()
        if not admin_user:
            admin_user = User(
                name="Administrator Sistem",
                identifier="admin@komunitas.id",
                email="admin@komunitas.id",
                password_hash=hashed_pass,
                role="superadmin"
            )
            db.add(admin_user)
            db.commit()
            print("✅ Superadmin dibuat: admin@komunitas.id / rahasia123")

        if preset.lower() == "sekolah":
            # --- PRESET SEKOLAH: SMA Swasta Nusantara ---
            org = db.query(Organization).filter(Organization.code == "SMANUS").first()
            if not org:
                org = Organization(
                    name="SMA Swasta Nusantara",
                    type="school",
                    code="SMANUS",
                    address="Jl. Pendidikan No. 45, Kupang, NTT",
                    phone="081234567890",
                    latitude=-10.180430,
                    longitude=123.605320,
                    radius_meter=150.0
                )
                db.add(org)
                db.commit()
                db.refresh(org)
                print(f"✅ Organisasi dibuat: {org.name}")

            # Guru / Staf
            guru = db.query(User).filter(User.identifier == "198501012010011001").first()
            if not guru:
                guru = User(
                    org_id=org.id,
                    name="Pak Budi Santoso, S.Pd.",
                    identifier="198501012010011001",
                    email="guru@komunitas.id",
                    password_hash=hashed_pass,
                    role="staff"
                )
                db.add(guru)
                db.commit()
                db.refresh(guru)
                print(f"✅ Guru dibuat: {guru.name} (guru@komunitas.id / rahasia123)")

            # Kelas
            kelas = db.query(Group).filter(Group.org_id == org.id, Group.name == "Kelas X MIPA 1").first()
            if not kelas:
                kelas = Group(
                    org_id=org.id,
                    name="Kelas X MIPA 1",
                    category="Kelas",
                    leader_user_id=guru.id
                )
                db.add(kelas)
                db.commit()
                db.refresh(kelas)

            # Siswa Dummy
            dummy_students = [
                ("NISN001", "Ahmad Fauzi", "L", "081200000001", "6281299990001"),
                ("NISN002", "Siti Rahmawati", "P", "081200000002", "6281299990002"),
                ("NISN003", "Yohanes Putra Lede", "L", "081200000003", "6281299990003"),
                ("NISN004", "Maria Angelita", "P", "081200000004", "6281299990004"),
                ("NISN005", "Daniel Christian", "L", "081200000005", "6281299990005"),
            ]

            for nisn, name, gender, phone, parent_phone in dummy_students:
                m = db.query(Member).filter(Member.registration_number == nisn).first()
                if not m:
                    token = generate_member_qr_token(str(org.id), nisn)
                    m = Member(
                        org_id=org.id,
                        group_id=kelas.id,
                        registration_number=nisn,
                        name=name,
                        gender=gender,
                        phone=phone,
                        parent_phone=parent_phone,
                        qr_token=token
                    )
                    db.add(m)
            db.commit()
            print("✅ 5 Siswa dummy berhasil diisi.")

        else:
            # --- PRESET GEREJA: GMIT Jemaat Kasih Karunia ---
            org = db.query(Organization).filter(Organization.code == "GMITKK").first()
            if not org:
                org = Organization(
                    name="GMIT Jemaat Kasih Karunia",
                    type="church",
                    code="GMITKK",
                    address="Jl. Kasih No. 12, Sikumana, Kota Kupang",
                    phone="081399887766",
                    latitude=-10.180430,
                    longitude=123.605320,
                    radius_meter=200.0
                )
                db.add(org)
                db.commit()
                db.refresh(org)
                print(f"✅ Organisasi dibuat: {org.name}")

            # Majelis / Pengurus
            majelis = db.query(User).filter(User.identifier == "MJL001").first()
            if not majelis:
                majelis = User(
                    org_id=org.id,
                    name="Pnt. Markus Ndun",
                    identifier="MJL001",
                    email="majelis@komunitas.id",
                    password_hash=hashed_pass,
                    role="staff"
                )
                db.add(majelis)
                db.commit()
                db.refresh(majelis)
                print(f"✅ Majelis dibuat: {majelis.name} (majelis@komunitas.id / rahasia123)")

            # Rayon
            rayon = db.query(Group).filter(Group.org_id == org.id, Group.name == "Rayon 3").first()
            if not rayon:
                rayon = Group(
                    org_id=org.id,
                    name="Rayon 3",
                    category="Rayon",
                    leader_user_id=majelis.id
                )
                db.add(rayon)
                db.commit()
                db.refresh(rayon)

            # Jemaat Dummy
            dummy_members = [
                ("REG001", "Keluarga Bapak Yohanes Daud", "L", "081311110001", "6281311110001"),
                ("REG002", "Ibu Debora Rondo", "P", "081311110002", "6281311110002"),
                ("REG003", "Pemuda Mikael Tefa", "L", "081311110003", "6281311110003"),
                ("REG004", "Ibu Esterina Bella", "P", "081311110004", "6281311110004"),
                ("REG005", "Bpk. Paulus Hurek", "L", "081311110005", "6281311110005"),
            ]

            for reg, name, gender, phone, parent_phone in dummy_members:
                m = db.query(Member).filter(Member.registration_number == reg).first()
                if not m:
                    token = generate_member_qr_token(str(org.id), reg)
                    m = Member(
                        org_id=org.id,
                        group_id=rayon.id,
                        registration_number=reg,
                        name=name,
                        gender=gender,
                        phone=phone,
                        parent_phone=parent_phone,
                        qr_token=token
                    )
                    db.add(m)
            db.commit()
            print("✅ 5 Jemaat dummy berhasil diisi.")

        print("🎉 Seeding data berhasil diselesaikan dengan aman!")

    except Exception as e:
        print(f"❌ Terjadi kesalahan saat seeding: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Seed database dengan data dummy Indonesia.")
    parser.add_argument("--preset", choices=["sekolah", "gereja"], default="sekolah", help="Pilih preset data awal")
    args = parser.parse_args()
    seed_database(args.preset)
