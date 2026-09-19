import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/values/app_constants.dart';

class AdminController extends GetxController {
  final isLoading = false.obs;
  final orgList = <Map<String, dynamic>>[].obs;
  final memberList = <Map<String, dynamic>>[].obs;

  final selectedOrgId = ''.obs;
  final orgName = ''.obs;
  final orgCode = ''.obs;
  final orgAddress = ''.obs;
  final orgRadius = 150.0.obs;
  final orgType = 'school'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAdminOverview();
  }

  Future<void> fetchAdminOverview() async {
    isLoading.value = true;
    try {
      final res = await ApiClient.get('/organizations/');
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        orgList.value = data.map((e) => Map<String, dynamic>.from(e)).toList();

        if (orgList.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final savedOrgId = prefs.getString(AppConstants.orgIdKey);
          final activeOrg = orgList.firstWhere(
            (o) => o['id'].toString() == savedOrgId,
            orElse: () => orgList.first,
          );

          selectedOrgId.value = activeOrg['id'].toString();
          orgName.value = activeOrg['name'] ?? '-';
          orgCode.value = activeOrg['code'] ?? '-';
          orgAddress.value = activeOrg['address'] ?? 'Belum ada alamat';
          orgRadius.value = (activeOrg['radius_meter'] as num?)?.toDouble() ?? 100.0;
          orgType.value = activeOrg['type'] ?? 'school';

          await fetchMembers(selectedOrgId.value);
        }
      }
    } catch (e) {
      Get.snackbar('Error Admin', 'Gagal memuat data administrasi: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMembers(String orgId) async {
    try {
      final res = await ApiClient.get('/organizations/$orgId/members');
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        memberList.value = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> addMember({
    required String regNumber,
    required String name,
    required String gender,
    required String parentPhone,
  }) async {
    if (selectedOrgId.value.isEmpty) return;

    try {
      final payload = {
        'org_id': selectedOrgId.value,
        'registration_number': regNumber,
        'name': name,
        'gender': gender,
        'parent_phone': parentPhone,
      };

      final res = await ApiClient.post('/organizations/${selectedOrgId.value}/members', payload);
      if (res.statusCode == 200) {
        Get.back();
        Get.snackbar(
          'Sukses',
          'Anggota $name ($regNumber) berhasil ditambahkan beserta QR kodenya!',
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        fetchMembers(selectedOrgId.value);
      } else {
        final body = jsonDecode(res.body);
        Get.snackbar('Gagal', body['detail'] ?? 'Gagal menambah anggota.', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Kesalahan: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
