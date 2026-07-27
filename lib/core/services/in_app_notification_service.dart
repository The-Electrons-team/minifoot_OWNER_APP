import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class InAppNotificationService {
  final String _base = AppConfig.apiUrl;

  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final response = await http.get(
      Uri.parse(
        '$_base/notifications',
      ).replace(queryParameters: {'page': '$page'}),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erreur notifications: ${response.body}');
  }

  Future<void> markRead(String id) async {
    final response = await http.patch(
      Uri.parse('$_base/notifications/$id/read'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lecture notification: ${response.body}');
    }
  }

  Future<void> markAllRead() async {
    final response = await http.patch(
      Uri.parse('$_base/notifications/read-all'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lecture notifications: ${response.body}');
    }
  }

  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await _token()}',
  };

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey) ?? '';
  }
}
