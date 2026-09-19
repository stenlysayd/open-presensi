class AppConstants {
  static const String appName = 'Open Presensi';
  // Gunakan 127.0.0.1 (dengan adb reverse) atau IP Wi-Fi laptop jika tanpa kabel
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  // Storage Keys
  static const String tokenKey = 'user_token';
  static const String roleKey = 'user_role';
  static const String userNameKey = 'user_name';
  static const String userIdKey = 'user_id';
  static const String orgIdKey = 'org_id';
  static const String offlineQueueKey = 'offline_attendance_queue';
}
