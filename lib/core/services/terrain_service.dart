import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/paginated.dart';

class TerrainService {
  final String _base = AppConfig.apiUrl;

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey) ?? '';
  }

  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await _token()}',
  };

  // ── GET /terrains/mine ─────────────────────────────────────────────────────
  Future<Paginated<dynamic>> getMesTerrains({int page = 1}) async {
    final uri = Uri.parse(
      '$_base/terrains/mine',
    ).replace(queryParameters: {'page': '$page'});

    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      return Paginated<dynamic>.fromBody(jsonDecode(response.body), page: page);
    }
    throw Exception('Erreur chargement terrains: ${response.body}');
  }

  /// Récupère tous les terrains, page après page.
  ///
  /// Utilisé là où la liste complète est nécessaire (sélecteurs, statistiques),
  /// pas pour l'affichage d'une liste défilante.
  Future<List<dynamic>> getAllMesTerrains() async {
    final all = <dynamic>[];
    var page = 1;

    while (true) {
      final result = await getMesTerrains(page: page);
      all.addAll(result.items);
      if (!result.hasMore || result.items.isEmpty) break;
      page += 1;
      if (page > 100) break;
    }

    return all;
  }

  // ── POST /terrains ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> creerTerrain(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_base/terrains'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erreur création terrain: ${response.body}');
  }

  // ── PATCH /terrains/:id ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> modifierTerrain(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      Uri.parse('$_base/terrains/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erreur modification terrain: ${response.body}');
  }

  // ── DELETE /terrains/:id ───────────────────────────────────────────────────
  Future<void> supprimerTerrain(String id) async {
    final response = await http.delete(
      Uri.parse('$_base/terrains/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur suppression terrain: ${response.body}');
    }
  }

  // ── GET /terrains/:id/slots?date=YYYY-MM-DD ────────────────────────────────
  Future<List<dynamic>> getCreneaux(
    String terrainId,
    String date, {
    String? subTerrainId,
  }) async {
    final uri = Uri.parse('$_base/terrains/$terrainId/slots').replace(
      queryParameters: {
        'date': date,
        if (subTerrainId != null && subTerrainId.isNotEmpty)
          'subTerrainId': subTerrainId,
      },
    );
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Erreur chargement créneaux: ${response.body}');
  }

  // ── POST /terrains/:id/slots/block ─────────────────────────────────────────
  Future<void> bloquerCreneau(
    String terrainId,
    String date,
    String slot, {
    String? subTerrainId,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/terrains/$terrainId/slots/block'),
      headers: await _headers(),
      body: jsonEncode({
        'date': date,
        'slot': slot,
        if (subTerrainId != null && subTerrainId.isNotEmpty)
          'subTerrainId': subTerrainId,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur blocage créneau: ${response.body}');
    }
  }

  // ── DELETE /terrains/:id/slots/block ───────────────────────────────────────
  Future<void> debloquerCreneau(
    String terrainId,
    String date,
    String slot, {
    String? subTerrainId,
  }) async {
    final uri = Uri.parse('$_base/terrains/$terrainId/slots/block').replace(
      queryParameters: {
        'date': date,
        'slot': slot,
        if (subTerrainId != null && subTerrainId.isNotEmpty)
          'subTerrainId': subTerrainId,
      },
    );
    final response = await http.delete(
      uri,
      headers: await _headers(),
    );




    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur déblocage créneau: ${response.body}');
    }
  }

  // ── POST /terrains/:id/images ──────────────────────────────────────────────
  Future<void> uploadImages(String terrainId, List<XFile> images) async {
    final token = await _token();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/terrains/$terrainId/images'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      final bytes = await image.readAsBytes();
      final extension = _extensionFromName(image.name);
      final filename =
          'terrain-${DateTime.now().microsecondsSinceEpoch}-$index$extension';
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          bytes,
          filename: filename,
          contentType: _mediaTypeFromExtension(extension),
        ),
      );
    }
    final response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = await response.stream.bytesToString();
      throw Exception('Erreur upload images: $body');
    }
  }

  String _extensionFromName(String name) {
    final match = RegExp(r'\.[a-zA-Z0-9]{2,5}$').firstMatch(name);
    return match?.group(0)?.toLowerCase() ?? '.jpg';
  }

  MediaType _mediaTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return MediaType('image', 'png');
      case '.webp':
        return MediaType('image', 'webp');
      case '.jpg':
      case '.jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  // ── GET /terrains/:id/reviews ──────────────────────────────────────────────
  Future<List<dynamic>> getReviews(String terrainId) async {
    final response = await http.get(
      Uri.parse('$_base/terrains/$terrainId/reviews'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Erreur chargement avis: ${response.body}');
  }
}
