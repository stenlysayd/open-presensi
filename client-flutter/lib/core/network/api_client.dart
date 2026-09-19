import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../values/app_constants.dart';

class ApiClient {
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();
    return await http.post(url, headers: headers, body: jsonEncode(data)).timeout(
      const Duration(seconds: 10),
    );
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();
    return await http.get(url, headers: headers).timeout(
      const Duration(seconds: 10),
    );
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();
    return await http.patch(url, headers: headers, body: jsonEncode(data)).timeout(
      const Duration(seconds: 10),
    );
  }
}
