import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/network/api_client.dart';

class RegisterController extends GetxController {
  final nameController = TextEditingController();
  final identifierController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final selectedRole = 'staff'.obs; // 'staff', 'member'
  final isPasswordHidden = true.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final identifier = identifierController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || identifier.isEmpty || password.isEmpty) {
      errorMessage.value = 'Nama, Identitas (NUPTK/NISN/Username), dan Kata Sandi wajib diisi.';
      return;
    }

    if (password != confirmPassword) {
      errorMessage.value = 'Konfirmasi kata sandi tidak cocok.';
      return;
    }

    if (password.length < 6) {
      errorMessage.value = 'Kata sandi minimal 6 karakter.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final payload = {
        'name': name,
        'identifier': identifier,
        'email': email.isNotEmpty ? email : null,
        'password': password,
        'role': selectedRole.value,
      };

      final response = await ApiClient.post('/auth/register', payload);

      if (response.statusCode == 200) {
        Get.back();
        Get.snackbar(
          'Pendaftaran Berhasil',
          'Akun untuk $name berhasil dibuat! Silakan masuk.',
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      } else {
        final body = jsonDecode(response.body);
        errorMessage.value = body['detail'] ?? 'Pendaftaran gagal.';
      }
    } catch (e) {
      errorMessage.value = 'Gagal menghubungi server: $e';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    identifierController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
