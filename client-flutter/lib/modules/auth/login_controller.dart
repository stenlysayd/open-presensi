import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/values/app_constants.dart';
import '../home/home_view.dart';

class LoginController extends GetxController {
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isPasswordHidden = true.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> login() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      errorMessage.value = 'Mohon isi NUPTK/Email dan Password.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await ApiClient.post('/auth/login', {
        'identifier': identifier,
        'password': password,
        'device_id': 'FLUTTER_CLIENT_DEVICE_ID', // Can be hardware ID on mobile
      });

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, body['access_token']);
        await prefs.setString(AppConstants.roleKey, body['role']);
        await prefs.setString(AppConstants.userNameKey, body['name']);
        await prefs.setString(AppConstants.userIdKey, body['user_id']);
        if (body['org_id'] != null) {
          await prefs.setString(AppConstants.orgIdKey, body['org_id'].toString());
        }

        Get.offAll(() => const HomeView());
      } else {
        final body = jsonDecode(response.body);
        errorMessage.value = body['detail'] ?? 'Login gagal.';
      }
    } catch (e) {
      errorMessage.value = 'Tidak dapat terhubung ke server: $e';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    identifierController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
