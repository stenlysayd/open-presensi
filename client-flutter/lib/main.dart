import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/values/app_constants.dart';
import 'modules/auth/login_view.dart';
import 'modules/home/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Cek sesi login tersimpan di SharedPreferences (Auto-Login)
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(AppConstants.tokenKey);
  final initialRoute = (token != null && token.isNotEmpty) ? '/home' : '/login';

  runApp(OpenPresensiApp(initialRoute: initialRoute));
}

class OpenPresensiApp extends StatelessWidget {
  final String initialRoute;
  const OpenPresensiApp({super.key, this.initialRoute = '/login'});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Open Presensi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/login', page: () => const LoginView()),
        GetPage(name: '/home', page: () => const HomeView()),
      ],
    );
  }
}

