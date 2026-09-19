import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'asset_controller.dart';
import '../scanner/simple_barcode_scanner.dart';

class AssetView extends StatelessWidget {
  const AssetView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AssetController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sirkulasi Aset (BukuHub)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2, color: Colors.teal.shade800, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Peminjaman buku perpustakaan, proyektor LCD, atau perlengkapan ibadah cukup dengan memindai kode QR Aset dan QR Anggota.',
                      style: TextStyle(fontSize: 13, color: Colors.teal.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Token Aset
            const Text(
              'Kode QR Aset / Barcode Barang *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.assetQrController,
              decoration: InputDecoration(
                hintText: 'Contoh: ASSET-LCD-01-A1B2C3',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  tooltip: 'Pindai Kamera',
                  onPressed: () async {
                    final scanned = await Get.to<String>(() => const SimpleBarcodeScanner(title: 'Pindai QR Aset'));
                    if (scanned != null && scanned.isNotEmpty) {
                      controller.assetQrController.text = scanned;
                    }
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Token Anggota Peminjam
            const Text(
              'Kode QR Anggota Peminjam *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.memberQrController,
              decoration: InputDecoration(
                hintText: 'Contoh: OP-20241001-XXXXXX',
                prefixIcon: const Icon(Icons.badge_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Pindai Kartu Anggota',
                  onPressed: () async {
                    final scanned = await Get.to<String>(() => const SimpleBarcodeScanner(title: 'Pindai Kartu Anggota'));
                    if (scanned != null && scanned.isNotEmpty) {
                      controller.memberQrController.text = scanned;
                    }
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Tenggat Waktu Pengembalian
            const Text(
              'Tenggat Pengembalian (Due Date) *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Obx(() => OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.event_available, color: Colors.teal),
                  label: Text(
                    'Harus Kembali: ${controller.dueDate.value.toIso8601String().split('T').first}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: controller.dueDate.value,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) controller.setDueDate(picked);
                  },
                )),
            const SizedBox(height: 20),

            // Catatan Kondisi
            const Text(
              'Catatan Kondisi Barang (Opsional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.notesController,
              decoration: InputDecoration(
                hintText: 'Contoh: Termasuk kabel HDMI & remote, kondisi baik.',
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
                      backgroundColor: Colors.teal.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: controller.isLoading.value ? null : controller.submitLoan,
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Catat Peminjaman Aset',
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
