import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'scanner_controller.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final FocusNode _keyboardFocusNode = FocusNode();
  String _rfidBuffer = '';
  final TextEditingController _manualInputController = TextEditingController();

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_rfidBuffer.isNotEmpty) {
          final controller = Get.find<ScannerController>();
          controller.onQrDetected(_rfidBuffer.trim());
          _rfidBuffer = '';
        }
      } else if (event.character != null && event.character!.isNotEmpty) {
        _rfidBuffer += event.character!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScannerController());

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleHardwareKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Presensi QR & RFID Scanner'),
          actions: [
            IconButton(
              icon: const Icon(Icons.nfc_outlined),
              tooltip: 'Mendukung USB RFID / Barcode Reader',
              onPressed: () {
                Get.snackbar(
                  'Dukungan Hardware RFID',
                  'Sistem otomatis menerima input dari RFID scanner USB tanpa perlu menekan tombol.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Mode Selector (Masuk / Pulang)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sesi Absen: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Obx(() => SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'masuk', label: Text('Masuk')),
                          ButtonSegment(value: 'pulang', label: Text('Pulang')),
                        ],
                        selected: {controller.recordType.value},
                        onSelectionChanged: (Set<String> newSelection) {
                          controller.switchRecordType(newSelection.first);
                        },
                      )),
                ],
              ),
            ),

            // Camera Viewport with Scanner
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          controller.onQrDetected(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                  ),

                  // Scanner target frame
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF27AE60), width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  // Bottom scan result overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Obx(() {
                      if (controller.lastScannedName.value.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Arahkan kamera ke kartu QR atau tempelkan kartu RFID ke scanner USB',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        );
                      }

                      final isOffline = controller.lastScannedName.value.contains('Offline');
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isOffline ? Colors.orange.shade800 : const Color(0xFF1F497D),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.lastScannedName.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.lastScannedStatus.value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Manual Input Fallback
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualInputController,
                      decoration: InputDecoration(
                        hintText: 'Input manual kode QR / UID RFID',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final text = _manualInputController.text.trim();
                      if (text.isNotEmpty) {
                        controller.onQrDetected(text);
                        _manualInputController.clear();
                      }
                    },
                    child: const Text('Simpan'),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
