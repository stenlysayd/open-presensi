import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/values/app_constants.dart';
import '../../data/providers/offline_storage.dart';
import '../../data/services/sync_service.dart';

class HomeController extends GetxController {
  final userName = ''.obs;
  final userRole = ''.obs;
  final pendingOfflineCount = 0.obs;
  final isSyncing = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
    refreshPendingOffline();
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    userName.value = prefs.getString(AppConstants.userNameKey) ?? 'Pengguna';
    userRole.value = prefs.getString(AppConstants.roleKey) ?? 'Staf';
  }

  Future<void> refreshPendingOffline() async {
    pendingOfflineCount.value = await OfflineStorage.getPendingQueueCount();
  }

  Future<void> triggerSync() async {
    if (pendingOfflineCount.value == 0) {
      Get.snackbar('Informasi', 'Tidak ada data antrean offline yang perlu disinkronkan.');
      return;
    }

    isSyncing.value = true;
    final res = await SyncService.syncOfflineQueue();
    isSyncing.value = false;

    await refreshPendingOffline();
    Get.snackbar(
      res['synced'] > 0 ? 'Sukses' : 'Perhatian',
      res['message'] ?? '',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAllNamed('/login');
  }
}
