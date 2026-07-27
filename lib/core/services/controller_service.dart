import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class ControllerService {
  final String _base = AppConfig.apiUrl;

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey) ?? '';
  }

  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await _token()}',
  };

  Future<List<dynamic>> getControllers() async {
    final response = await http.get(
      Uri.parse('$_base/owner/controllers'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'] as List<dynamic>? ?? [];
    }
    throw Exception('Erreur chargement controllers: ${response.body}');
  }

  Future<Map<String, dynamic>> createController({
    required String firstName,
    required String lastName,
    required String phone,
    required List<String> complexIds,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/owner/controllers'),
      headers: await _headers(),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'complexIds': complexIds,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erreur création controller: ${response.body}');
  }

  Future<Map<String, dynamic>> updateController(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      Uri.parse('$_base/owner/controllers/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erreur mise à jour controller: ${response.body}');
  }

  Future<List<dynamic>> getActivity(String id) async {
    final response = await http.get(
      Uri.parse('$_base/owner/controllers/$id/activity'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'] as List<dynamic>? ?? [];
    }
    throw Exception('Erreur activité controller: ${response.body}');
  }
}
