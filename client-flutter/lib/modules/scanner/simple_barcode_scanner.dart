import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SimpleBarcodeScanner extends StatefulWidget {
  final String title;
  const SimpleBarcodeScanner({super.key, required this.title});

  @override
  State<SimpleBarcodeScanner> createState() => _SimpleBarcodeScannerState();
}

class _SimpleBarcodeScannerState extends State<SimpleBarcodeScanner> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.amber);
                  case TorchState.off:
                  default:
                    return const Icon(Icons.flash_off, color: Colors.white70);
                }
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_isScanned) return;
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.trim().isNotEmpty) {
                  _isScanned = true;
                  Get.back(result: barcode.rawValue!.trim());
                  break;
                }
              }
            },
          ),
          // Target frame
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF27AE60), width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Arahkan kamera ke QR Code atau Barcode fisik',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
