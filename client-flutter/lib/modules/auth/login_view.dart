import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart';
import 'register_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 72,
                  color: Color(0xFF1F497D),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Open Presensi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F497D),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sistem Presensi & Manajemen Komunitas\n(Sekolah / Gereja Lokal)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 36),

                Obx(() => controller.errorMessage.value.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          controller.errorMessage.value,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        ),
                      )
                    : const SizedBox.shrink()),

                TextField(
                  controller: controller.identifierController,
                  decoration: InputDecoration(
                    labelText: 'NUPTK / NISN / Email',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() => TextField(
                      controller: controller.passwordController,
                      obscureText: controller.isPasswordHidden.value,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordHidden.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                const SizedBox(height: 24),

                Obx(() => ElevatedButton(
                      onPressed: controller.isLoading.value ? null : controller.login,
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgress32(),
                            )
                          : const Text('Masuk ke Sistem', style: TextStyle(fontSize: 16)),
                    )),
                const SizedBox(height: 16),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum memiliki akun? ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    TextButton(
                      onPressed: () => Get.to(() => const RegisterView()),
                      child: const Text('Daftar di sini', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mode offline aktif otomatis jika jaringan terputus.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CircularProgress32 extends StatelessWidget {
  const CircularProgress32({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(strokeWidth: 2, color: Colors.white);
  }
}
