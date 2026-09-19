import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/values/app_constants.dart';

class ConsecutiveAlertsController extends GetxController {
  final isLoading = false.obs;
  final alerts = <Map<String, dynamic>>[].obs;
  final thresholdDays = 3.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      var orgId = prefs.getString(AppConstants.orgIdKey);

      if (orgId == null || orgId.isEmpty) {
        final orgRes = await ApiClient.get('/organizations/');
        if (orgRes.statusCode == 200) {
          final List list = jsonDecode(orgRes.body);
          if (list.isNotEmpty) {
            orgId = list.first['id'].toString();
          }
        }
      }

      if (orgId != null && orgId.isNotEmpty) {
        final res = await ApiClient.get('/attendance/consecutive-alerts?org_id=$orgId&days=${thresholdDays.value}');
        if (res.statusCode == 200) {
          final List list = jsonDecode(res.body);
          alerts.value = list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data peringatan: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

class ConsecutiveAlertsView extends StatelessWidget {
  const ConsecutiveAlertsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ConsecutiveAlertsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peringatan Bolos 3+ Hari'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: controller.fetchAlerts,
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
            // Alert Info Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sistem Deteksi Dini (Early Warning)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Menampilkan siswa atau jemaat yang tidak hadir 3 hari atau lebih berturut-turut tanpa keterangan izin.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (controller.alerts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 54, color: Colors.green.shade600),
                      const SizedBox(height: 12),
                      const Text(
                        'Kondisi Kehadiran Baik!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tidak ada anggota yang mengalami ketidakhadiran beruntun tanpa keterangan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...controller.alerts.map((item) {
                final days = item['consecutive_days'] ?? 0;
                final phone = item['parent_phone'] ?? '-';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$days HARI BOLOS',
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item['group_name'] ?? 'Kelas -',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item['member_name'] ?? 'Nama Anggota',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'No. Induk: ${item['registration_number']}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Terakhir Hadir: ${item['last_seen_date'] ?? "Belum pernah hadir"}',
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('No. Wali: $phone', style: const TextStyle(fontSize: 13)),
                            const Spacer(),
                            TextButton.icon(
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Salin No'),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: phone));
                                Get.snackbar('Tersalin', 'Nomor $phone disalin ke clipboard.', snackPosition: SnackPosition.BOTTOM);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      }),
    );
  }
}
