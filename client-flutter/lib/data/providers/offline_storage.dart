import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_model.dart';
import '../../core/values/app_constants.dart';

class OfflineStorage {
  static Future<void> saveOfflineScan(AttendanceRecordModel scan) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentQueue = prefs.getStringList(AppConstants.offlineQueueKey) ?? [];
    
    currentQueue.add(jsonEncode(scan.toJson()));
    await prefs.setStringList(AppConstants.offlineQueueKey, currentQueue);
  }

  static Future<List<AttendanceRecordModel>> getOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentQueue = prefs.getStringList(AppConstants.offlineQueueKey) ?? [];
    
    return currentQueue.map((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      return AttendanceRecordModel.fromJson(decoded);
    }).toList();
  }

  static Future<void> clearOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.offlineQueueKey);
  }

  static Future<int> getPendingQueueCount() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentQueue = prefs.getStringList(AppConstants.offlineQueueKey) ?? [];
    return currentQueue.length;
  }
}
