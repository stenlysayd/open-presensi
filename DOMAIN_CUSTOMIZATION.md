# 🎯 Panduan Personalisasi Domain: Mode Khusus Sekolah vs Mode Khusus Gereja

Aplikasi **Open Presensi** dibangun dengan arsitektur **Domain-Agnostic (Bebas Domain)**. Artinya, model data di backend menggunakan entitas generik:
* `Organization` = Sekolah **ATAU** Gereja
* `Group` = Kelas (e.g. X MIPA 1) **ATAU** Rayon / Kategorial (e.g. Pemuda)
* `Member` = Siswa / Murid **ATAU** Warga Jemaat
* `Session` = Jam KBM / Upacara **ATAU** Ibadah Minggu / Doa Rayon
* `AssetItem` = Buku Perpustakaan & LCD **ATAU** Alat Musik & Sarana Ibadah

Jika Anda mengklon repositori ini dan **hanya ingin menggunakannya khusus untuk 1 kebutuhan saja** (hanya Sekolah **ATAU** hanya Gereja) tanpa menyisakan jejak yang membingungkan pengguna, ikuti langkah-langkah pembersihan di bawah ini.

---

## 🏫 SKENARIO A: Menjadikan Aplikasi 100% Khusus Sekolah

Gunakan panduan ini jika Anda mengimplementasikan sistem untuk SD, SMP, SMA, SMK, atau Kampus, dan ingin membuang semua istilah gereja.

### 1. Database & Seeder (`backend/database/seeder.py`)
Jalankan seeder hanya untuk preset sekolah:
```bash
python -m database.seeder --preset sekolah
```
**Pembersihan Kode Seeder:**
Buka [`backend/database/seeder.py`](backend/database/seeder.py), Anda dapat menghapus fungsi `seed_gereja()` dan menyederhanakan parser argumen di akhir file agar selalu menjalankan `seed_sekolah()`.

### 2. Portal Publik Web Mandiri (`backend/app/static/portal.html`)
Buka [`backend/app/static/portal.html`](backend/app/static/portal.html):
* Ubah `<title>` dan header utama dari:
  ```html
  <h1>Open Presensi</h1>
  <p>Portal Mandiri Sekolah & Gereja</p>
  ```
  Menjadi:
  ```html
  <h1>Portal Presensi Siswa</h1>
  <p>SMA Swasta Nusantara (Ganti dengan Nama Sekolah Anda)</p>
  ```
* Pada form perizinan dan cek riwayat, hapus kata-kata "atau Jemaat".
* Pastikan label identitas tetap menggunakan **NISN / NUPTK**.

### 3. Klien Mobile Flutter (`client-flutter/`)

#### A. Layar Registrasi Akun Baru ([`lib/modules/auth/register_view.dart`](client-flutter/lib/modules/auth/register_view.dart))
Ubah segmen peran pengguna agar spesifik untuk sekolah:
```dart
// Cari SegmentedButton<String> di register_view.dart:
ButtonSegment(value: 'staff', label: Text('Guru / Staf')),
ButtonSegment(value: 'member', label: Text('Siswa / Murid')), // Bukan 'Anggota'
```
Dan ganti hint identitas menjadi:
```dart
labelText: 'NUPTK / NISN *'
```

#### B. Dashboard Utama ([`lib/modules/home/home_view.dart`](client-flutter/lib/modules/home/home_view.dart))
Pastikan judul seksi peran menggunakan istilah sekolah:
* **Admin Section:**
  * Judul: `Pusat Kendali & Pengawasan Admin Sekolah`
  * Card 1: `Verifikasi & Persetujuan Izin Siswa/Guru`
  * Card 2: `Deteksi Dini Siswa Bolos (3+ Hari)`
  * Card 3: `Panel Pengaturan Sekolah & Geofence GPS`
* **Staff Section:**
  * Judul: `Tugas & Aktivitas Harian Guru`
  * Card 1: `Pemindaian Presensi Siswa (Kamera & RFID)`
  * Card 2: `Kartu QR Guru Saya`
  * Card 3: `Peminjaman Alat Kelas & LCD Proyektor`
  * Card 4: `Rekap Kehadiran Kelas Harian`
  * Card 5: `Pengajuan Izin / Tugas Dinas Luar Guru`
* **Member Section:**
  * Judul: `Layanan Mandiri Siswa`
  * Card 1: `Kartu Pelajar Digital Saya`
  * Card 2: `Pengajuan Surat Sakit / Izin Masuk`
  * Card 3: `Cek Riwayat Kehadiran Siswa`

#### C. Sirkulasi Aset ([`lib/modules/assets/asset_view.dart`](client-flutter/lib/modules/assets/asset_view.dart))
* Ubah judul AppBar menjadi: `Peminjaman LCD & Buku Perpustakaan`
* Ubah hint pencarian barang menjadi: `Cari LCD, proyektor, buku pelajaran...`

### 4. Daftar Pencarian & Penggantian Cepat (Find & Replace Checklist)
Lakukan pencarian global di folder proyek untuk memastikan tidak ada sisa kata:
| Cari Kata | Ganti Menjadi |
| :--- | :--- |
| `Gereja` / `church` | `Sekolah` / `school` |
| `Jemaat` | `Siswa` / `Murid` |
| `Rayon` / `Wilayah` | `Kelas` |
| `Majelis` / `Pendeta` | `Guru` / `Wali Kelas` |
| `Ibadah` | `KBM` / `Upacara` |

---

## ⛪ SKENARIO B: Menjadikan Aplikasi 100% Khusus Gereja

Gunakan panduan ini jika Anda mengimplementasikan sistem untuk Gereja Lokal, Pos Pelayanan, atau Komunitas Basis Rohani, dan ingin membuang semua istilah sekolah/guru/siswa.

### 1. Database & Seeder (`backend/database/seeder.py`)
Jalankan seeder hanya untuk preset gereja:
```bash
python -m database.seeder --preset gereja
```
**Pembersihan Kode Seeder:**
Buka [`backend/database/seeder.py`](backend/database/seeder.py), Anda dapat menghapus fungsi `seed_sekolah()` dan menyederhanakan parser argumen agar langsung menjalankan `seed_gereja()`.

### 2. Portal Publik Web Mandiri (`backend/app/static/portal.html`)
Buka [`backend/app/static/portal.html`](backend/app/static/portal.html):
* Ubah `<title>` dan header utama menjadi:
  ```html
  <h1>Sistem Informasi & Kehadiran Jemaat</h1>
  <p>GMIT Jemaat Kasih Karunia (Ganti dengan Nama Gereja Anda)</p>
  ```
* Ubah form perizinan menjadi: **"Pemberitahuan Berhalangan Hadir / Permohonan Doa Jemaat"**.
* Ubah input identitas menjadi: **"Nomor Induk Jemaat (NIJ) / No. WhatsApp"**.

### 3. Klien Mobile Flutter (`client-flutter/`)

#### A. Layar Registrasi Akun Baru ([`lib/modules/auth/register_view.dart`](client-flutter/lib/modules/auth/register_view.dart))
Ubah segmen peran pengguna:
```dart
ButtonSegment(value: 'staff', label: Text('Pengurus / Majelis')),
ButtonSegment(value: 'member', label: Text('Warga Jemaat')),
```
Dan ganti hint identitas menjadi:
```dart
labelText: 'Nomor Induk Jemaat (NIJ) / Username *'
```

#### B. Dashboard Utama ([`lib/modules/home/home_view.dart`](client-flutter/lib/modules/home/home_view.dart))
Ganti teks card menjadi istilah gerejawi:
* **Admin Section:**
  * Judul: `Pusat Kendali Pengurus & Tata Usaha Gereja`
  * Card 1: `Verifikasi Pemberitahuan Berhalangan / Permohonan Doa`
  * Card 2: `Peringatan Penggembalaan (3x Ibadah Tidak Hadir)` *(Sangat bermanfaat bagi Majelis/Pendeta untuk mengetahui anggota jemaat yang sakit atau membutuhkan perkunjungan)*
  * Card 3: `Panel Pengaturan Gereja & Geofence GPS Gedung Gereja`
* **Staff Section:**
  * Judul: `Pelayanan Petugas Ibadah & Majelis Jemaat`
  * Card 1: `Pemindaian Kartu Jemaat (Pintu Masuk Ibadah)`
  * Card 2: `Kartu QR Digital Pelayan Ibadah`
  * Card 3: `Peminjaman Alat Musik & Inventaris Gereja`
  * Card 4: `Rekap Kehadiran Ibadah Raya & Doa Rayon`
  * Card 5: `Pengajuan Izin Pelayanan / Cuti`
* **Member Section:**
  * Judul: `Layanan Mandiri Warga Jemaat`
  * Card 1: `Kartu Jemaat Digital Saya`
  * Card 2: `Pemberitahuan Berhalangan Ibadah / Permohonan Doa`
  * Card 3: `Riwayat Kehadiran Ibadah Saya`

#### C. Sirkulasi Aset ([`lib/modules/assets/asset_view.dart`](client-flutter/lib/modules/assets/asset_view.dart))
* Ubah judul AppBar menjadi: `Peminjaman Alat Musik & Sarana Ibadah`
* Ubah hint pencarian barang menjadi: `Cari keyboard, kabel mik, proyektor, buku kidung...`

### 4. Daftar Pencarian & Penggantian Cepat (Find & Replace Checklist)
Lakukan pencarian global di folder proyek untuk mengganti istilah sekolah menjadi gereja:
| Cari Kata | Ganti Menjadi |
| :--- | :--- |
| `Sekolah` / `school` | `Gereja` / `church` |
| `Siswa` / `Murid` | `Warga Jemaat` / `Jemaat` |
| `Guru` / `Wali Kelas` | `Majelis` / `Pengurus Rayon` |
| `Kepala Sekolah` | `Ketua Majelis Jemaat / Pendeta` |
| `Kelas` | `Rayon` / `Kategorial` |
| `Bolos` | `Tidak Hadir Beruntun (Perlu Dikunjungi)` |
| `NUPTK` / `NISN` | `Nomor Induk Jemaat (NIJ)` |
