import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_controller.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrasi & Pengaturan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Data',
            onPressed: controller.fetchAdminOverview,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(18.0),
          children: [
            // Organisasi Info Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          controller.orgType.value == 'church' ? Icons.church : Icons.school,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.orgName.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Kode: ${controller.orgCode.value} • ${controller.orgType.value == 'church' ? "Gereja Lokal" : "Sekolah"}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          controller.orgAddress.value,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Quick Status Grid
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    title: 'Total Anggota',
                    value: '${controller.memberList.length} Jiwa',
                    icon: Icons.people_alt_outlined,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoTile(
                    title: 'Radius GPS',
                    value: '${controller.orgRadius.value.toInt()} Meter',
                    icon: Icons.radar,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section: Kelola Anggota
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Anggota / Siswa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F497D)),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Tambah'),
                  onPressed: () => _showAddMemberDialog(context, controller),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (controller.memberList.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Belum ada anggota terdaftar.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.memberList.length,
                itemBuilder: (context, index) {
                  final member = controller.memberList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: member['gender'] == 'P' ? Colors.pink.shade100 : Colors.blue.shade100,
                        child: Text(
                          member['gender'] ?? 'L',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: member['gender'] == 'P' ? Colors.pink.shade800 : Colors.blue.shade800,
                          ),
                        ),
                      ),
                      title: Text(
                        member['name'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'No: ${member['registration_number']} • Ortu: ${member['parent_phone'] ?? "-"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.qr_code, color: Colors.indigo),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),

            // Section: Pengaturan & Integrasi Sistem
            const Text(
              'Panduan & Konfigurasi Sistem',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F497D)),
            ),
            const SizedBox(height: 10),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.public, color: Colors.indigo, size: 28),
                      title: Text('Portal Mandiri Siswa & Jemaat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('Akses via browser laptop/HP tanpa login: /portal, /izin, dan /cek-kehadiran'),
                    ),
                    Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.security, color: Colors.green, size: 28),
                      title: Text('Fitur Device Binding (Anti Titip Absen)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('Satu akun staf terkunci ke satu perangkat ponsel. Jika staf ganti HP, admin dapat meresetnya via endpoint /auth/reset-device.'),
                    ),
                    Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.message, color: Colors.teal, size: 28),
                      title: Text('WhatsApp Gateway (Fonnte)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('Notifikasi otomatis masuk/pulang terkirim ke WhatsApp orang tua bila WA_ENABLED=true di file backend .env.'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, AdminController controller) {
    final regController = TextEditingController();
    final nameController = TextEditingController();
    final parentPhoneController = TextEditingController();
    var selectedGender = 'L';

    Get.defaultDialog(
      title: 'Tambah Anggota Baru',
      content: StatefulBuilder(builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: regController,
                decoration: const InputDecoration(
                  labelText: 'NISN / No Induk / No Registrasi *',
                  hintText: 'Contoh: 2024001',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap *',
                  hintText: 'Contoh: Maria Magdalena',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: parentPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'No. WA Ortu / Wali *',
                  hintText: 'Contoh: 08123456789',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Gender: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'L', label: Text('Laki-laki')),
                        ButtonSegment(value: 'P', label: Text('Perempuan')),
                      ],
                      selected: {selectedGender},
                      onSelectionChanged: (newVal) => setState(() => selectedGender = newVal.first),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
      textConfirm: 'Simpan',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (regController.text.trim().isEmpty || nameController.text.trim().isEmpty) {
          Get.snackbar('Validasi', 'Nomor Induk dan Nama wajib diisi.', snackPosition: SnackPosition.BOTTOM);
          return;
        }
        controller.addMember(
          regNumber: regController.text.trim(),
          name: nameController.text.trim(),
          gender: selectedGender,
          parentPhone: parentPhoneController.text.trim(),
        );
      },
    );
  }
}
