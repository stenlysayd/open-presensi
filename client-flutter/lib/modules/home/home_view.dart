import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import '../scanner/scanner_view.dart';
import '../recap/recap_view.dart';
import '../my_qr/my_qr_view.dart';
import '../leave/leave_view.dart';
import '../assets/asset_view.dart';
import '../admin/admin_view.dart';
import '../admin/leave_approval_view.dart';
import '../admin/consecutive_alerts_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Presensi'),
        actions: [
          // Connection Mode Badge (Diadopsi dari penilaian-kebersihan)
          Obx(() => Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: controller.pendingOfflineCount.value > 0
                      ? Colors.amber.shade700
                      : const Color(0xFF27AE60),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.pendingOfflineCount.value > 0
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_done_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      controller.pendingOfflineCount.value > 0 ? 'Mode Lokal' : 'DB Aktif',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: controller.logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshPendingOffline,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F497D), Color(0xFF2C3E50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 36, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() => Text(
                              controller.userName.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                        const SizedBox(height: 4),
                        Obx(() => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                controller.userRole.value.toUpperCase(),
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Offline Sync Banner
            Obx(() {
              final count = controller.pendingOfflineCount.value;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.amber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$count Presensi Tersimpan Offline',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'Tekan tombol sinkronisasi saat internet tersedia.',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: controller.isSyncing.value ? null : controller.triggerSync,
                      child: controller.isSyncing.value
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Sinkron', style: TextStyle(fontSize: 12)),
                    )
                  ],
                ),
              );
            }),

            // Tampilan Menu Berdasarkan Peran Pengguna (Role-based Dashboard)
            Obx(() {
              final role = controller.userRole.value.toLowerCase();
              if (role == 'superadmin' || role == 'admin') {
                return _buildAdminSection();
              } else if (role == 'member') {
                return _buildMemberSection();
              } else {
                return _buildStaffSection();
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pusat Kendali & Pengawasan Admin',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F497D)),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Verifikasi & Persetujuan Izin',
          subtitle: 'Tinjau dan setujui surat izin/sakit yang diajukan siswa atau guru.',
          icon: Icons.approval_outlined,
          iconColor: Colors.indigo.shade700,
          onTap: () => Get.to(() => const LeaveApprovalView()),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Deteksi Dini Siswa Bolos (3+ Hari)',
          subtitle: 'Peringatan otomatis siswa yang tidak hadir beruntun untuk dihubungi.',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red.shade700,
          onTap: () => Get.to(() => const ConsecutiveAlertsView()),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Panel Pengaturan & Anggota',
          subtitle: 'Kelola data organisasi, radius geofencing GPS, tambah siswa, dan WhatsApp.',
          icon: Icons.admin_panel_settings_outlined,
          iconColor: Colors.blue.shade800,
          onTap: () => Get.to(() => const AdminView()),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Rekap Presensi & Ekspor Laporan',
          subtitle: 'Statistik kehadiran lengkap, unduh Excel, PDF resmi, dan ringkasan AI.',
          icon: Icons.analytics_outlined,
          iconColor: Colors.orange.shade800,
          onTap: () => Get.to(() => const RecapView()),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Sirkulasi Aset & Inventaris (BukuHub)',
          subtitle: 'Peminjaman buku, LCD proyektor, atau fasilitas via QR.',
          icon: Icons.inventory_2_outlined,
          iconColor: Colors.teal.shade700,
          onTap: () => Get.to(() => const AssetView()),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Pemindaian Presensi (Mode Petugas)',
          subtitle: 'Buka scanner jika bertugas mengabsen di pos gerbang.',
          icon: Icons.qr_code_scanner,
          iconColor: const Color(0xFF1F497D),
          onTap: () => Get.to(() => const ScannerView()),
        ),
      ],
    );
  }

  Widget _buildStaffSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tugas & Aktivitas Harian Guru',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F497D)),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Pemindaian Presensi Siswa (QR & RFID)',
          subtitle: 'Scan kartu QR siswa saat masuk kelas atau di gerbang sekolah.',
          icon: Icons.qr_code_scanner,
          iconColor: const Color(0xFF1F497D),
          onTap: () => Get.to(() => const ScannerView()),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Kartu QR Guru Saya',
          subtitle: 'Tampilkan identitas QR pribadi untuk check-in kehadiran guru.',
          icon: Icons.badge_outlined,
          iconColor: const Color(0xFF27AE60),
          onTap: () => Get.to(() => const MyQrView()),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Peminjaman Alat & Fasilitas (BukuHub)',
          subtitle: 'Pinjam proyektor LCD kelas, buku perpustakaan, atau perlengkapan.',
          icon: Icons.inventory_2_outlined,
          iconColor: Colors.teal.shade700,
          onTap: () => Get.to(() => const AssetView()),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Rekap Kehadiran Harian',
          subtitle: 'Pantau persentase dan daftar siswa yang hadir hari ini.',
          icon: Icons.analytics_outlined,
          iconColor: Colors.orange.shade700,
          onTap: () => Get.to(() => const RecapView()),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Pengajuan Izin / Tugas Dinas Luar',
          subtitle: 'Ajukan surat izin atau cuti jika berhalangan hadir mengajar.',
          icon: Icons.event_note_outlined,
          iconColor: Colors.purple.shade600,
          onTap: () => Get.to(() => const LeaveView()),
        ),
      ],
    );
  }

  Widget _buildMemberSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Layanan Mandiri Siswa / Anggota',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F497D)),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Kartu QR Digital Saya',
          subtitle: 'Tunjukkan kartu QR ini ke guru atau mesin scanner untuk presensi.',
          icon: Icons.badge_outlined,
          iconColor: const Color(0xFF27AE60),
          onTap: () => Get.to(() => const MyQrView()),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Pengajuan Izin Sakit / Berhalangan',
          subtitle: 'Ajukan surat izin atau bukti sakit langsung ke wali kelas.',
          icon: Icons.event_note_outlined,
          iconColor: Colors.purple.shade600,
          onTap: () => Get.to(() => const LeaveView()),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Cek Riwayat Kehadiran Saya',
          subtitle: 'Pantau catatan presensi dan persentase kehadiran Anda.',
          icon: Icons.calendar_month_outlined,
          iconColor: Colors.blue.shade700,
          onTap: () => Get.to(() => const RecapView()),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
