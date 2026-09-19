import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyQrView extends StatelessWidget {
  const MyQrView({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample dummy badge for member preview
    const sampleToken = 'OP-NISN001-DEMO';
    const sampleName = 'Ahmad Fauzi';
    const sampleReg = 'NISN: 0081234567';
    const sampleGroup = 'Kelas X MIPA 1 / SMA Nusantara';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartu QR Digital Saya'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                  child: Column(
                    children: [
                      const Text(
                        'KARTU IDENTITAS DIGITAL',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // QR Code Widget
                      QrImageView(
                        data: sampleToken,
                        version: QrVersions.auto,
                        size: 220.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        sampleName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F497D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        sampleReg,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        sampleGroup,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tunjukkan kartu ini kepada guru atau petugas ibadah saat tiba di lokasi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
