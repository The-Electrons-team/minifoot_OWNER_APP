import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/paginated.dart';

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

  Future<Paginated<dynamic>> getOwnerReservations({
    String? status,
    int page = 1,
  }) async {
    final uri = Uri.parse('$_base/reservations/owner/mine').replace(
      queryParameters: {
        'page': '$page',
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      return Paginated<dynamic>.fromBody(jsonDecode(response.body), page: page);
    }
    throw Exception('Erreur chargement réservations: ${response.body}');
  }

  /// Récupère **toutes** les réservations, page après page.
  ///
  /// À réserver aux calculs qui doivent être exhaustifs — revenus, rapports
  /// PDF — où une troncature silencieuse fausserait des montants. Les écrans de
  /// liste doivent passer par [getOwnerReservations] page par page.
  Future<List<dynamic>> getAllOwnerReservations({String? status}) async {
    final all = <dynamic>[];
    var page = 1;

    while (true) {
      final result = await getOwnerReservations(status: status, page: page);
      all.addAll(result.items);
      if (!result.hasMore || result.items.isEmpty) break;
      page += 1;
      // Garde-fou : une pagination mal formée côté serveur ne doit pas
      // provoquer une boucle infinie sur le téléphone.
      if (page > 100) break;
    }

    return all;
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
