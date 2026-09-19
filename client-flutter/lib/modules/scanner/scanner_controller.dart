import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import '../../data/models/attendance_model.dart';
import '../../data/providers/offline_storage.dart';
import '../home/home_controller.dart';

class ScannerController extends GetxController {
  final recordType = 'masuk'.obs; // 'masuk' or 'pulang'
  final lastScannedName = ''.obs;
  final lastScannedStatus = ''.obs;
  final isProcessing = false.obs;
  final lastScanTime = Rx<DateTime?>(null);

  final Set<String> _recentScannedTokens = {};

  void switchRecordType(String type) {
    recordType.value = type;
  }

  Future<void> onQrDetected(String rawToken) async {
    final token = rawToken.trim();
    if (token.isEmpty || _recentScannedTokens.contains(token) || isProcessing.value) {
      return;
    }

    _recentScannedTokens.add(token);
    // Auto clear from buffer after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      _recentScannedTokens.remove(token);
    });

    isProcessing.value = true;
    HapticFeedback.mediumImpact();

    try {
      final payload = {
        'qr_token': token,
        'record_type': recordType.value,
        'status': 'hadir',
        'is_offline_sync': false,
      };

      // Try sending directly to server
      final response = await ApiClient.post('/attendance/scan', payload);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        lastScannedName.value = data['member_name'] ?? 'Anggota';
        lastScannedStatus.value = 'Hadir (${recordType.value}) - Terkirim Online';
      } else {
        final body = jsonDecode(response.body);
        lastScannedName.value = 'Perhatian';
        lastScannedStatus.value = body['detail'] ?? 'Presensi gagal tercatat.';
      }
    } catch (e) {
      // NETWORK ERROR / OFFLINE: Queue locally in OfflineStorage!
      final offlineModel = AttendanceRecordModel(
        qrToken: token,
        recordType: recordType.value,
        status: 'hadir',
        recordedAt: DateTime.now(),
        isOffline: true,
      );
      await OfflineStorage.saveOfflineScan(offlineModel);
      
      // Update badge in home
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshPendingOffline();
      }

      lastScannedName.value = 'Mode Offline';
      lastScannedStatus.value = 'Presensi $token tersimpan di antrean HP.';
    } finally {
      isProcessing.value = false;
      lastScanTime.value = DateTime.now();
    }
  }
}
