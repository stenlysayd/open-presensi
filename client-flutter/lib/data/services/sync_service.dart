import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../providers/offline_storage.dart';
import '../../core/network/api_client.dart';

class SyncService {
  static Future<Map<String, dynamic>> syncOfflineQueue() async {
    final queue = await OfflineStorage.getOfflineQueue();
    if (queue.isEmpty) {
      return {'synced': 0, 'message': 'Tidak ada antrean offline.'};
    }

    try {
      final payload = {
        'records': queue.map((e) => e.toJson()).toList(),
      };

      final response = await ApiClient.post('/attendance/batch-sync', payload);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        await OfflineStorage.clearOfflineQueue();
        return {
          'synced': queue.length,
          'message': 'Berhasil menyinkronkan ${queue.length} rekaman presensi offline.',
          'data': body['data']
        };
      } else {
        return {
          'synced': 0,
          'message': 'Gagal sinkronisasi: Status ${response.statusCode}'
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sync error: $e');
      }
      return {'synced': 0, 'message': 'Koneksi belum stabil: $e'};
    }
  }
}
