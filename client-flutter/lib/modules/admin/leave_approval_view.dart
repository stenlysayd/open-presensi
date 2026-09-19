import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/values/app_constants.dart';

class LeaveApprovalController extends GetxController {
  final isLoading = false.obs;
  final pendingList = <Map<String, dynamic>>[].obs;
  final historyList = <Map<String, dynamic>>[].obs;
  final selectedOrgId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initData();
  }

  Future<void> initData() async {
    isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();
    selectedOrgId.value = prefs.getString(AppConstants.orgIdKey) ?? '';

    // If org_id is empty, fetch from /organizations/
    if (selectedOrgId.value.isEmpty) {
      try {
        final res = await ApiClient.get('/organizations/');
        if (res.statusCode == 200) {
          final List list = jsonDecode(res.body);
          if (list.isNotEmpty) {
            selectedOrgId.value = list.first['id'].toString();
          }
        }
      } catch (_) {}
    }

    await fetchLeaves();
    isLoading.value = false;
  }

  Future<void> fetchLeaves() async {
    if (selectedOrgId.value.isEmpty) return;
    try {
      final res = await ApiClient.get('/attendance/leave-requests?org_id=${selectedOrgId.value}');
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        final all = list.map((e) => Map<String, dynamic>.from(e)).toList();
        pendingList.value = all.where((e) => e['status'] == 'pending').toList();
        historyList.value = all.where((e) => e['status'] != 'pending').toList();
      }
    } catch (_) {}
  }

  Future<void> reviewLeave(String reqId, String newStatus, String memberName) async {
    try {
      final res = await ApiClient.patch(
        '/attendance/leave-requests/$reqId/review',
        {'status': newStatus},
      );

      if (res.statusCode == 200) {
        final isApproved = newStatus == 'approved';
        Get.snackbar(
          isApproved ? 'Disetujui' : 'Ditolak',
          'Pengajuan izin untuk $memberName telah ${isApproved ? "disetujui" : "ditolak"}.',
          backgroundColor: isApproved ? Colors.green.shade700 : Colors.red.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        fetchLeaves();
      } else {
        final body = jsonDecode(res.body);
        Get.snackbar('Gagal', body['detail'] ?? 'Gagal memproses review.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Kesalahan: $e');
    }
  }
}

class LeaveApprovalView extends StatelessWidget {
  const LeaveApprovalView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeaveApprovalController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verifikasi & Persetujuan Izin'),
          bottom: TabBar(
            tabs: [
              Obx(() => Tab(
                    text: 'Menunggu (${controller.pendingList.length})',
                  )),
              const Tab(text: 'Riwayat Selesai'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              // Tab 1: Menunggu Persetujuan
              controller.pendingList.isEmpty
                  ? const Center(
                      child: Text('Tidak ada pengajuan izin yang menunggu persetujuan.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.pendingList.length,
                      itemBuilder: (context, index) {
                        final item = controller.pendingList[index];
                        return _buildLeaveCard(context, controller, item, isPending: true);
                      },
                    ),

              // Tab 2: Riwayat
              controller.historyList.isEmpty
                  ? const Center(child: Text('Belum ada riwayat persetujuan.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.historyList.length,
                      itemBuilder: (context, index) {
                        final item = controller.historyList[index];
                        return _buildLeaveCard(context, controller, item, isPending: false);
                      },
                    ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLeaveCard(
    BuildContext context,
    LeaveApprovalController controller,
    Map<String, dynamic> item, {
    required bool isPending,
  }) {
    final isSakit = item['category'] == 'sakit';
    final status = item['status'] as String? ?? 'pending';

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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSakit ? Colors.orange.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isSakit ? 'SAKIT' : 'IZIN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSakit ? Colors.orange.shade900 : Colors.blue.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item['member_name'] ?? 'Anggota',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (!isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: status == 'approved' ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status == 'approved' ? 'DISETUJUI' : 'DITOLAK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status == 'approved' ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Tanggal: ${item['start_date']} s/d ${item['end_date']}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Alasan: "${item['reason'] ?? '-'}"',
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            if (isPending) ...[
              const SizedBox(height: 14),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Tolak'),
                    onPressed: () => controller.reviewLeave(
                      item['id'].toString(),
                      'rejected',
                      item['member_name'] ?? 'Anggota',
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Setujui'),
                    onPressed: () => controller.reviewLeave(
                      item['id'].toString(),
                      'approved',
                      item['member_name'] ?? 'Anggota',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
