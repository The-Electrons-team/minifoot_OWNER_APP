import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class ReservationService {
  final String _base = AppConfig.apiUrl;

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey) ?? '';
  }

  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await _token()}',
  };

  Future<List<dynamic>> getOwnerReservations({String? status}) async {
    final uri = Uri.parse('$_base/reservations/owner/mine').replace(
      queryParameters: status == null || status.isEmpty
          ? null
          : {'status': status},
    );

    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) return body;
      if (body is Map<String, dynamic>) {
        return body['data'] as List<dynamic>? ?? [];
      }
      return [];
    }
    throw Exception('Erreur chargement réservations: ${response.body}');
  }

  Future<void> cancelOwnerReservation(String id) async {
    final response = await http.patch(
      Uri.parse('$_base/reservations/owner/$id/cancel'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur annulation réservation: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> scanOwnerReservation(String qrData) async {
    final response = await http.post(
      Uri.parse('$_base/reservations/owner/check-in/scan'),
      headers: await _headers(),
      body: jsonEncode({'qrData': qrData}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Erreur scan QR: ${response.body}');
  }

  Future<Map<String, dynamic>> confirmOwnerCheckIn(String id) async {
    final response = await http.patch(
      Uri.parse('$_base/reservations/owner/$id/check-in'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Erreur confirmation présence: ${response.body}');
  }

  Future<Map<String, dynamic>> getOwnerReservationDetail(String id) async {
    final response = await http.get(
      Uri.parse('$_base/reservations/owner/$id'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Erreur détail réservation: ${response.body}');
  }
}
