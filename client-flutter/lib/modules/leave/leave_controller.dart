import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/network/api_client.dart';

class LeaveController extends GetxController {
  final regNumberController = TextEditingController();
  final reasonController = TextEditingController();
  final attachmentController = TextEditingController();

  final selectedCategory = 'sakit'.obs;
  final startDate = DateTime.now().obs;
  final endDate = DateTime.now().obs;
  final isLoading = false.obs;

  final categories = [
    {'value': 'sakit', 'label': 'Sakit'},
    {'value': 'izin', 'label': 'Izin Keperluan'},
    {'value': 'dispensasi', 'label': 'Dispensasi'},
    {'value': 'cuti', 'label': 'Cuti'},
  ];

  void setCategory(String category) {
    selectedCategory.value = category;
  }

  void setStartDate(DateTime date) {
    startDate.value = date;
    if (endDate.value.isBefore(date)) {
      endDate.value = date;
    }
  }

  void setEndDate(DateTime date) {
    if (date.isBefore(startDate.value)) {
      Get.snackbar('Kesalahan Tanggal', 'Tanggal selesai tidak boleh sebelum tanggal mulai.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
      return;
    }
    endDate.value = date;
  }

  Future<void> submitLeaveRequest() async {
    final reg = regNumberController.text.trim();
    final reason = reasonController.text.trim();

    if (reg.isEmpty) {
      Get.snackbar('Validasi Gagal', 'Nomor Induk / Registrasi wajib diisi.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
      return;
    }

    if (reason.isEmpty) {
      Get.snackbar('Validasi Gagal', 'Alasan permohonan wajib diisi.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      final startStr = startDate.value.toIso8601String().split('T').first;
      final endStr = endDate.value.toIso8601String().split('T').first;

      final res = await ApiClient.post('/public/leave-requests', {
        'registration_number': reg,
        'category': selectedCategory.value,
        'start_date': startStr,
        'end_date': endStr,
        'reason': reason,
        'attachment_url': attachmentController.text.trim().isEmpty ? null : attachmentController.text.trim(),
      });

      final body = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        Get.snackbar(
          'Berhasil Diajukan',
          'Permohonan izin untuk ${body['member_name']} telah dikirim untuk verifikasi.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF27AE60),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        regNumberController.clear();
        reasonController.clear();
        attachmentController.clear();
      } else {
        final msg = body != null && body['detail'] != null ? body['detail'] : 'Gagal mengirim permohonan.';
        Get.snackbar('Gagal', msg.toString(),
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Terjadi Kesalahan', e.toString(),
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    regNumberController.dispose();
    reasonController.dispose();
    attachmentController.dispose();
    super.onClose();
  }
}

