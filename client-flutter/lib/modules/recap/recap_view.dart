import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'recap_controller.dart';

class RecapView extends StatelessWidget {
  const RecapView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RecapController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Presensi'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        String formattedDate;
        try {
          formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(controller.selectedDate.value);
        } catch (_) {
          formattedDate = DateFormat('EEEE, d MMMM yyyy').format(controller.selectedDate.value);
        }

        return ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Date Filter Bar
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Color(0xFF1F497D)),
                title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: controller.selectedDate.value,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    controller.selectedDate.value = picked;
                    controller.fetchStats();
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Metric Cards Grid
            Row(
              children: [
                _buildStatCard('Hadir', '${controller.presentCount.value}', Colors.green),
                const SizedBox(width: 10),
                _buildStatCard('Izin/Sakit', '${controller.excusedCount.value}', Colors.orange),
                const SizedBox(width: 10),
                _buildStatCard('Alpha', '${controller.absentCount.value}', Colors.red),
              ],
            ),
            const SizedBox(height: 12),

            // Overall Attendance Rate Card
            Card(
              color: const Color(0xFFF8FAFC),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('Tingkat Partisipasi Kehadiran', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${controller.ratePercent.value}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F497D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // AI Attendance Digest Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.blue.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.indigo, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Ringkasan Otomatis AI',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Buat'),
                          onPressed: controller.generateAiSummary,
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 6),
                    Text(
                      controller.aiSummaryText.value.isEmpty
                          ? 'Klik tombol "Buat" untuk menghasilkan narasi rekap singkat ramah WhatsApp bagi pimpinan.'
                          : controller.aiSummaryText.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: controller.aiSummaryText.value.isEmpty ? Colors.grey : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Export Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                    ),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Unduh Excel'),
                    onPressed: () {
                      Get.snackbar('Ekspor', 'Sedang mengunduh file rekap Excel...', snackPosition: SnackPosition.BOTTOM);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Unduh PDF'),
                    onPressed: () {
                      Get.snackbar('Ekspor', 'Sedang mengunduh file rekap PDF...', snackPosition: SnackPosition.BOTTOM);
                    },
                  ),
                ),
              ],
            )
          ],
        );
      }),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
