import 'dart:convert';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/network/api_client.dart';

class RecapController extends GetxController {
  final selectedDate = DateTime.now().obs;
  final isLoading = false.obs;
  final totalMembers = 0.obs;
  final presentCount = 0.obs;
  final excusedCount = 0.obs;
  final absentCount = 0.obs;
  final ratePercent = 0.0.obs;
  final aiSummaryText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializeDateFormatting('id_ID', null).then((_) => update());
    fetchStats();
  }

  Future<void> fetchStats() async {
    isLoading.value = true;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);

    try {
      // 1. Fetch Stats
      // Note: org_id can be pulled from user session
      final res = await ApiClient.get('/reports/stats?target_date=$dateStr');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        totalMembers.value = data['total_members'] ?? 0;
        presentCount.value = data['present_count'] ?? 0;
        excusedCount.value = data['excused_count'] ?? 0;
        absentCount.value = data['absent_count'] ?? 0;
        ratePercent.value = (data['rate_percent'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (e) {
      // offline preview fallback
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateAiSummary() async {
    aiSummaryText.value = 'Membuat ringkasan kecerdasan buatan...';
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);

    try {
      final res = await ApiClient.post('/ai-summary/generate', {
        'start_date': dateStr,
        'end_date': dateStr,
      });
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        aiSummaryText.value = body['summary_text'] ?? 'Ringkasan berhasil dibuat.';
      } else {
        aiSummaryText.value = 'Gagal menghasilkan ringkasan AI.';
      }
    } catch (e) {
      aiSummaryText.value = 'Gagal menghubungi server AI: $e';
    }
  }
}
