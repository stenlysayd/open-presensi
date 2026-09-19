# Panduan Berkontribusi (Contributing Guide)

Terima kasih atas minat Anda untuk berkontribusi pada **Open Presensi**! Proyek ini bertujuan memberdayakan sekolah dan gereja kecil di seluruh Indonesia dengan solusi sistem absensi dan manajemen yang gratis, andal, dan mudah dipasang.

---

## 🚀 Alur Kerja Berkontribusi

1. **Fork Repositori**: Buat fork ke akun GitHub Anda.
2. **Buat Branch Fitur**:
   ```bash
   git checkout -b feat/nama-fitur-anda
   # atau untuk perbaikan bug
   git checkout -b fix/deskripsi-masalah
   ```
3. **Uji Perubahan**:
   * Backend: jalankan `pytest` di folder `backend/`.
   * Flutter: jalankan `flutter test` dan `flutter analyze` di folder `client-flutter/`.
4. **Kirim Pull Request**:
   * Berikan deskripsi yang jelas mengenai apa yang ditambahkan/diperbaiki.
   * Codex / AI reviewer akan secara otomatis memberikan ulasan (*automated review*) pertama pada PR Anda.

---

## 🏷️ Mencari Isu Pertama ("good first issue")

Jika Anda baru pertama kali berkontribusi pada proyek open source, carilah issue dengan label:
* [`good first issue`](https://github.com/open-presensi/open-presensi/labels/good%20first%20issue)
* [`documentation`](https://github.com/open-presensi/open-presensi/labels/documentation)

Beberapa area yang sangat terbuka untuk kontribusi cepat:
* Format ekspor Excel/PDF yang lebih variatif.
* Desain kartu ID QR cetak (A4 paper grid).
* Alternatif gateway notifikasi (Telegram, Email SMTP, dsb.).

---

## 🛡️ Kebersihan Data (Data Hygiene)
Dilarang keras menyertakan data asli (nama siswa, NUPTK, nomor telepon, data jemaat) atau file kredensial rahasia (`.env`, `service-account.json`). Selalu gunakan data uji dari script `backend/database/seeder.py`.
