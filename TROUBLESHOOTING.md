# 🛠️ Panduan Pemecahan Masalah & Debugging (Troubleshooting Guide)

Dokumen ini merangkum seluruh potensi kendala teknis yang umum terjadi saat instalasi, konfigurasi jaringan, maupun pengembangan **Open Presensi**, bersumber langsung dari skenario pengujian di lingkungan nyata (*Windows 10/11, Python 3.13, PostgreSQL, dan Perangkat Android Fisik*).

---

## Daftar Isi
1. [Backend & Database](#1-backend--database)
   - [Error Python 3.13: Passlib & Bcrypt Incompatibility](#error-python-313-passlib--bcrypt-incompatibility)
   - [Gagal Autentikasi Database PostgreSQL](#gagal-autentikasi-database-postgresql)
   - [Pydantic V2 Migration Warnings](#pydantic-v2-migration-warnings)
2. [Jaringan & Perangkat Keras Mobile (Android)](#2-jaringan--perangkat-keras-mobile-android)
   - [ClientException: Connection reset by peer (10.0.2.2 vs HP Fisik)](#clientexception-connection-reset-by-peer-10022-vs-hp-fisik)
   - [Perintah adb Tidak Dikenali di Terminal Windows](#perintah-adb-tidak-dikenali-di-terminal-windows)
   - [Cleartext Traffic (HTTP Non-SSL) Ditolak oleh Android](#cleartext-traffic-http-non-ssl-ditolak-oleh-android)
3. [Antarmuka & Klien Flutter](#3-antarmuka--klien-flutter)
   - [LocaleDataException: Format Tanggal Bahasa Indonesia](#localedataexception-format-tanggal-bahasa-indonesia)
   - [RenderFlex Right Overflow (Kotak Kuning-Hitam)](#renderflex-right-overflow-kotak-kuning-hitam)
   - [Kamera Scanner Layar Hitam atau Izin Ditolak](#kamera-scanner-layar-hitam-atau-izin-ditolak)
   - [Sesi Login Hilang Setiap Kali Aplikasi Ditutup](#sesi-login-hilang-setiap-kali-aplikasi-ditutup)

---

## 1. Backend & Database

### Error Python 3.13: Passlib & Bcrypt Incompatibility

#### Gejala:
```text
AttributeError: module 'bcrypt' has no attribute '__about__'
❌ Terjadi kesalahan saat seeding: password cannot be longer than 72 bytes
```

#### Akar Masalah:
Pustaka `passlib` tidak lagi aktif dikembangkan dan membaca atribut internal `bcrypt.__about__.__version__` yang telah dihapus pada rilis `bcrypt >= 4.0.0` dan Python 3.13.

#### Solusi:
Proyek Open Presensi **tidak lagi menggunakan `passlib`**, melainkan langsung memanfaatkan pustaka `bcrypt` resmi di [`backend/app/core/security.py`](backend/app/core/security.py):
```python
import bcrypt

def verify_password(plain_password: str, hashed_password: str) -> bool:
    pwd_bytes = plain_password[:72].encode('utf-8')
    return bcrypt.checkpw(pwd_bytes, hashed_password.encode('utf-8'))

def get_password_hash(password: str) -> str:
    pwd_bytes = password[:72].encode('utf-8')
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pwd_bytes, salt).decode('utf-8')
```
> **Penting:** Bcrypt membatasi panjang input maksimal 72 byte. Selalu pastikan pemotongan `[:72]` dilakukan sebelum hashing.

---

### Gagal Autentikasi Database PostgreSQL

#### Gejala:
```text
psycopg2.OperationalError: FATAL: password authentication failed for user "postgres"
```

#### Solusi:
1. Pastikan berkas `backend/.env` telah dibuat dari `backend/.env.example`:
   ```bash
   cp backend/.env.example backend/.env
   ```
2. Sesuaikan `DATABASE_URL` dengan username, password, dan port PostgreSQL Anda:
   ```env
   # Format: postgresql://[USER]:[PASSWORD]@[HOST]:[PORT]/[DATABASE_NAME]
   DATABASE_URL="postgresql://postgres:postgres@localhost:5432/open_presensi"
   ```
3. Jika menggunakan Docker Compose, jalankan kontainer terlebih dahulu:
   ```bash
   docker compose up -d db
   ```

---

## 2. Jaringan & Perangkat Keras Mobile (Android)

### ClientException: Connection reset by peer (10.0.2.2 vs HP Fisik)

#### Gejala:
```text
Tidak dapat terhubung ke server:
ClientException: Connection reset by peer, uri=http://10.0.2.2:8000/api/v1/auth/login
```

#### Akar Masalah:
Alamat IP `10.0.2.2` adalah alias perutean khusus untuk **Android Emulator resmi di komputer host**. Jika Anda menjalankan aplikasi di **HP Fisik Android** (melalui kabel USB atau Wi-Fi), HP Anda tidak dapat mengenali IP `10.0.2.2`.

#### Solusi 1: Menggunakan Kabel USB (Rekomendasi Terbaik & Paling Stabil)
Gunakan fitur *Reverse Port Forwarding* dari Android Debug Bridge (ADB):
```powershell
# Jalankan perintah ini saat HP terhubung dengan USB Debugging aktif:
adb reverse tcp:8000 tcp:8000
```
Lalu pastikan konfigurasi di `client-flutter/lib/core/values/app_constants.dart` menggunakan:
```dart
static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
```

#### Solusi 2: Menggunakan Jaringan Wi-Fi yang Sama (Tanpa Kabel)
1. Cari tahu IP lokal laptop/komputer Anda (misal `192.168.1.15` di Windows via perintah `ipconfig`).
2. Jalankan server FastAPI dengan `--host 0.0.0.0` (jangan hanya `127.0.0.1`):
   ```bash
   python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```
3. Ubah `baseUrl` di Flutter menjadi:
   ```dart
   static const String baseUrl = 'http://192.168.1.15:8000/api/v1';
   ```

---

### Perintah adb Tidak Dikenali di Terminal Windows

#### Gejala:
```text
adb : The term 'adb' is not recognized as the name of a cmdlet, function, script file...
```

#### Solusi:
Jika Android Studio terpasang tetapi direktori `platform-tools` belum masuk ke `PATH` Windows, jalankan ADB langsung dari lokasi standarnya:
```powershell
# PowerShell:
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8000 tcp:8000

# Atau periksa perangkat yang terdeteksi:
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```
*Tips:* Tambahkan `C:\Users\<Username Anda>\AppData\Local\Android\Sdk\platform-tools` ke System Environment Variables `PATH` agar perintah `adb` dapat dipanggil langsung dari mana saja.

---

### Cleartext Traffic (HTTP Non-SSL) Ditolak oleh Android

#### Gejala:
Aplikasi tidak bisa menghubungi server backend lokal meskipun IP sudah benar (biasanya error `CLEARTEXT_COMMUNICATION_NOT_PERMITTED` pada Android 9+).

#### Solusi:
Di `client-flutter/android/app/src/main/AndroidManifest.xml`, tambahkan atribut `android:usesCleartextTraffic="true"` pada tag `<application>`:
```xml
<application
    android:label="Open Presensi"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="true">
```

---

## 3. Antarmuka & Klien Flutter

### LocaleDataException: Format Tanggal Bahasa Indonesia

#### Gejala:
```text
LocaleDataException: Locale data has not been initialized, call initializeDateFormatting(<locale>).
```

#### Solusi:
Pastikan inisialisasi simbol lokal dipanggil sebelum `runApp` di `client-flutter/lib/main.dart`:
```dart
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const OpenPresensiApp());
}
```

---

### RenderFlex Right Overflow (Kotak Kuning-Hitam)

#### Gejala:
Peringatan visual berupa garis kuning-hitam di pojok kanan widget dengan teks:
```text
A RenderFlex overflowed by 32 pixels on the right.
```

#### Solusi:
Pada layout baris (`Row`), widget teks dengan isi dinamis yang panjang akan mendesak widget tombol di sebelahnya jika tidak diberi batasan ruang fleksibel. Bungkus elemen teks dengan `Expanded`:
```dart
// SEBELUM (Rentan overflow):
Row(
  children: [
    Text(item['title']), // Melebar melewati batas layar
    ElevatedButton(...),
  ],
)

// SESUDAH (Aman):
Row(
  children: [
    Expanded(
      child: Text(item['title'], overflow: TextOverflow.ellipsis),
    ),
    ElevatedButton(
      style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
      ...,
    ),
  ],
)
```

---

### Kamera Scanner Layar Hitam atau Izin Ditolak

#### Solusi:
1. Pastikan izin kamera telah didaftarkan di `client-flutter/android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-feature android:name="android.hardware.camera" android:required="false"/>
   ```
2. Jika kamera baru pertama kali dibuka, pastikan memilih opsi **"Saat aplikasi digunakan" (While using the app)** pada dialog perizinan OS Android.

---

### Sesi Login Hilang Setiap Kali Aplikasi Ditutup

#### Solusi:
Di `client-flutter/lib/main.dart`, aplikasi telah diatur agar memeriksa `SharedPreferences` sebelum menentukan layar awal (`initialRoute`):
```dart
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString(AppConstants.tokenKey);
final initialRoute = (token != null && token.isNotEmpty) ? '/home' : '/login';

runApp(OpenPresensiApp(initialRoute: initialRoute));
```
Pengguna akan tetap masuk secara permanen hingga tombol **Keluar** ditekan.
