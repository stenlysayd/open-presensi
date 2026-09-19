import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'register_controller.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1F497D),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 56,
                  color: Color(0xFF1F497D),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Buat Akun Open Presensi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F497D),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Daftarkan diri Anda untuk sekolah atau gereja',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Error Message Container
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

                // Nama Lengkap
                TextField(
                  controller: controller.nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap *',
                    hintText: 'Contoh: Ahmad Subagyo, S.Pd',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Identifier
                TextField(
                  controller: controller.identifierController,
                  decoration: InputDecoration(
                    labelText: 'NUPTK / NISN / Username *',
                    hintText: 'Digunakan saat masuk ke sistem',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Email
                TextField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email (Opsional)',
                    hintText: 'nama@domain.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Pilihan Peran
                const Text(
                  'Peran dalam Organisasi:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Obx(() => SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'staff', label: Text('Staf / Guru')),
                        ButtonSegment(value: 'member', label: Text('Siswa / Anggota')),
                      ],
                      selected: {controller.selectedRole.value},
                      onSelectionChanged: (Set<String> newSelection) {
                        controller.selectedRole.value = newSelection.first;
                      },
                    )),
                const SizedBox(height: 14),

                // Kata Sandi with Toggle
                Obx(() => TextField(
                      controller: controller.passwordController,
                      obscureText: controller.isPasswordHidden.value,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi *',
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
                const SizedBox(height: 14),

                // Konfirmasi Kata Sandi
                Obx(() => TextField(
                      controller: controller.confirmPasswordController,
                      obscureText: controller.isPasswordHidden.value,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi *',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                const SizedBox(height: 24),

                // Tombol Daftar
                Obx(() => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: controller.isLoading.value ? null : controller.register,
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Daftar Sekarang', style: TextStyle(fontSize: 16)),
                    )),
                const SizedBox(height: 16),

                // Link ke Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah memiliki akun? ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Masuk di sini', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
