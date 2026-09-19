import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/network/api_client.dart';

class AssetController extends GetxController {
  final assetQrController = TextEditingController();
  final memberQrController = TextEditingController();
  final notesController = TextEditingController();

  final dueDate = DateTime.now().add(const Duration(days: 3)).obs;
  final isLoading = false.obs;
  final isFetching = false.obs;
  final assetList = <Map<String, dynamic>>[].obs;

  void setDueDate(DateTime date) {
    dueDate.value = date;
  }

  Future<void> submitLoan() async {
    final assetQr = assetQrController.text.trim();
    final memberQr = memberQrController.text.trim();

    if (assetQr.isEmpty) {
      Get.snackbar('Validasi Gagal', 'Kode QR Aset / Inventaris wajib diisi.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
      return;
    }
    if (memberQr.isEmpty) {
      Get.snackbar('Validasi Gagal', 'Kode QR Anggota Peminjam wajib diisi.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      final dueDateStr = dueDate.value.toIso8601String().split('T').first;
      final res = await ApiClient.post('/assets/loans', {
        'asset_qr_token': assetQr,
        'member_qr_token': memberQr,
        'due_date': dueDateStr,
        'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      });

      final body = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        Get.snackbar(
          'Peminjaman Berhasil',
          'Aset ${body['asset_name']} berhasil dipinjam oleh ${body['member_name']}.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF27AE60),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        assetQrController.clear();
        memberQrController.clear();
        notesController.clear();
      } else {
        final msg = body != null && body['detail'] != null ? body['detail'] : 'Gagal memproses peminjaman.';
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

  Future<void> returnLoan(String loanId, String assetName) async {
    isLoading.value = true;
    try {
      final res = await ApiClient.post('/assets/loans/$loanId/return', {});
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        Get.snackbar(
          'Pengembalian Berhasil',
          'Aset $assetName telah berhasil dikembalikan ke inventaris.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF27AE60),
          colorText: Colors.white,
        );
      } else {
        final msg = body != null && body['detail'] != null ? body['detail'] : 'Gagal memproses pengembalian.';
        Get.snackbar('Gagal', msg.toString(),
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Kesalahan Jaringan', e.toString(),
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    assetQrController.dispose();
    memberQrController.dispose();
    notesController.dispose();
    super.onClose();
  }
}

