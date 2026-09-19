import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'leave_controller.dart';

class LeaveView extends StatelessWidget {
  const LeaveView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeaveController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Izin Mandiri'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F497D).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1F497D).withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1F497D), size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Pengajuan permohonan izin/sakit resmi untuk siswa atau jemaat. Permohonan akan diverifikasi oleh pengurus.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF1F497D)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nomor Induk Input
            const Text(
              'Nomor Induk / Registrasi *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.regNumberController,
              decoration: InputDecoration(
                hintText: 'Contoh: 20241001 atau JMT-001',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Kategori Chips
            const Text(
              'Kategori Izin *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.categories.map((cat) {
                    final isSelected = controller.selectedCategory.value == cat['value'];
                    return ChoiceChip(
                      label: Text(cat['label']!),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1F497D),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (selected) {
                        if (selected) controller.setCategory(cat['value']!);
                      },
                    );
                  }).toList(),
                )),
            const SizedBox(height: 20),

            // Rentang Tanggal
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal Mulai *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Obx(() => OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              controller.startDate.value.toIso8601String().split('T').first,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: controller.startDate.value,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (picked != null) controller.setStartDate(picked);
                            },
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal Selesai *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Obx(() => OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.event, size: 18),
                            label: Text(
                              controller.endDate.value.toIso8601String().split('T').first,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: controller.endDate.value,
                                firstDate: controller.startDate.value,
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (picked != null) controller.setEndDate(picked);
                            },
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Alasan Izin
            const Text(
              'Alasan / Keterangan *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Jelaskan alasan izin secara ringkas dan jelas...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Tautan Bukti (Opsional)
            const Text(
              'Tautan Bukti / Surat Dokter (Opsional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.attachmentController,
              decoration: InputDecoration(
                hintText: 'https://... (tautan foto surat dokter/bukti izin)',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F497D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: controller.isLoading.value ? null : controller.submitLeaveRequest,
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Kirim Permohonan Izin',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
