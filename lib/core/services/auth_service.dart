import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class AuthService {
  final String _baseUrl = AppConfig.apiUrl;

  String _normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00221')) digits = digits.substring(5);
    if (digits.startsWith('221')) digits = digits.substring(3);
    return '+221$digits';
  }

  String _fileExtension(File file) {
    final name = file.path.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return 'jpg';
    final ext = name
        .substring(dot + 1)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return ext.isEmpty ? 'jpg' : ext;
  }

  MediaType _imageContentType(File file) {
    switch (_fileExtension(file)) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  Future<String?> savedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey);
  }

  Future<String?> savedRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.refreshTokenKey);
  }

  Future<void> saveTokens(String token, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
    if (refreshToken != null) {
      await prefs.setString(AppConfig.refreshTokenKey, refreshToken);
    }
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
    await prefs.remove(AppConfig.refreshTokenKey);
  }

  Future<Map<String, dynamic>?> refreshTokens(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(AppConfig.shortTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<http.Response> authenticatedRequest(
    Future<http.Response> Function(String token) request,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(AppConfig.tokenKey);
    if (token == null) throw Exception('Non authentifié');

    var response = await request(token);

    if (response.statusCode == 401) {
      final refresh = prefs.getString(AppConfig.refreshTokenKey);
      if (refresh != null) {
        final result = await refreshTokens(refresh);
        if (result != null) {
          token = result['token'] as String;
          await saveTokens(token, result['refreshToken'] as String?);
          response = await request(token);
        }
      }
    }

    return response;
  }

  Future<http.StreamedResponse> authenticatedMultipartRequest(
    Future<http.StreamedResponse> Function(String token) request,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(AppConfig.tokenKey);
    if (token == null) throw Exception('Non authentifié');

    var response = await request(token);

    if (response.statusCode == 401) {
      final refresh = prefs.getString(AppConfig.refreshTokenKey);
      if (refresh != null) {
        final result = await refreshTokens(refresh);
        if (result != null) {
          token = result['token'] as String;
          await saveTokens(token, result['refreshToken'] as String?);
          response = await request(token);
        }
      }
    }

    return response;
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': _normalizePhone(phone),
              'password': password,
            }),
          )
          .timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw Exception('SERVER_UNAVAILABLE');
    } on SocketException {
      throw Exception('SERVER_UNAVAILABLE');
    } on http.ClientException {
      throw Exception('SERVER_UNAVAILABLE');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('COMPTE_NON_TROUVE');
    } else if (response.statusCode == 401) {
      throw Exception('ID_INVALIDES');
    } else {
      throw Exception('Erreur de connexion: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> startSignup({
    required String phone,
    required String firstName,
    required String lastName,
    required String password,
    String? cniNumber,
  }) async {
    final cleanCni = cniNumber?.replaceAll(RegExp(r'\D'), '');
    final body = <String, dynamic>{
      'phone': _normalizePhone(phone),
      'firstName': firstName,
      'lastName': lastName,
      'password': password,
      if (cleanCni != null && cleanCni.isNotEmpty) 'cniNumber': cleanCni,
    };
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/auth/signup-owner'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw Exception('SERVER_UNAVAILABLE');
    } on SocketException {
      throw Exception('SERVER_UNAVAILABLE');
    } on http.ClientException {
      throw Exception('SERVER_UNAVAILABLE');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(decoded['message'] ?? 'Erreur d\'inscription');
    } else {
      throw Exception('Erreur d\'inscription: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': _normalizePhone(phone), 'code': code}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Code invalide: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> resendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/resend-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': _normalizePhone(phone)}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Impossible de renvoyer le code: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> uploadOwnerDocuments({
    required String token,
    required String cniNumber,
    required File profilePhoto,
    required File cniFront,
    required File cniBack,
  }) async {
    final cleanCni = cniNumber.replaceAll(RegExp(r'\D'), '');

    final streamed = await authenticatedMultipartRequest((t) async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/auth/owner/documents'),
      );
      request.headers['Authorization'] = 'Bearer $t';
      request.fields['cniNumber'] = cleanCni;
      request.files.add(
        await http.MultipartFile.fromPath(
          'profilePhoto',
          profilePhoto.path,
          filename: 'owner_profile_$cleanCni.${_fileExtension(profilePhoto)}',
          contentType: _imageContentType(profilePhoto),
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'cniFront',
          cniFront.path,
          filename: 'cni_recto_$cleanCni.${_fileExtension(cniFront)}',
          contentType: _imageContentType(cniFront),
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'cniBack',
          cniBack.path,
          filename: 'cni_verso_$cleanCni.${_fileExtension(cniBack)}',
          contentType: _imageContentType(cniBack),
        ),
      );
      return request.send().timeout(AppConfig.uploadTimeout);
    });

    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    throw Exception('Erreur upload documents: $body');
  }

  Future<Map<String, dynamic>> forgotPassword(String phone) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': _normalizePhone(phone)}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('COMPTE_NON_TROUVE');
    } else {
      throw Exception('Erreur réinitialisation: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String code,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': _normalizePhone(phone),
        'code': code,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('CODE_INVALIDE');
    } else {
      throw Exception('Erreur réinitialisation: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await authenticatedRequest((t) => http.get(
      Uri.parse('$_baseUrl/users/me?t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
    ));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur profil: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await authenticatedRequest((t) => http.patch(
      Uri.parse('$_baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
      body: jsonEncode(data),
    ));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur mise à jour profil: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> uploadAvatar({
    required String token,
    required File image,
  }) async {
    final streamed = await authenticatedMultipartRequest((t) async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/users/me/avatar'),
      );
      request.headers['Authorization'] = 'Bearer $t';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      return request.send();
    });

    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return jsonDecode(body);
    }
    throw Exception('Erreur upload avatar: $body');
  }

  Future<Map<String, dynamic>> getPayoutInfo(String token) async {
    final response = await authenticatedRequest((t) => http.get(
      Uri.parse('$_baseUrl/users/me/payout-info'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
    ));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur coordonnées paiement: ${response.body}');
  }

  /// Solde disponible pour retrait (paiements débloqués après scan QR, non encore virés).
  Future<Map<String, dynamic>> getPayoutBalance(String token) async {
    final response = await authenticatedRequest((t) => http.get(
      Uri.parse('$_baseUrl/owner/payout/balance'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
    ));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur solde retrait: ${response.body}');
  }

  /// Déclenche un retrait DexPay. DexPay choisit l'opérateur selon le numéro.
  Future<Map<String, dynamic>> requestPayout(
    String token, {
    required String phone,
    int? amount,
  }) async {
    final reqBody = <String, dynamic>{'phone': phone};
    if (amount != null) reqBody['amount'] = amount;

    final response = await authenticatedRequest((t) => http.post(
      Uri.parse('$_baseUrl/owner/payout/withdraw'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
      body: jsonEncode(reqBody),
    ));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    final decoded = jsonDecode(response.body);
    throw Exception(decoded['message'] ?? 'Erreur retrait: ${response.body}');
  }

  Future<void> updateFcmToken(String token, String fcmToken) async {
    final response = await authenticatedRequest((t) => http.patch(
      Uri.parse('$_baseUrl/users/me/fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
      body: jsonEncode({'token': fcmToken}),
    ));

    if (response.statusCode != 200) {
      throw Exception('Erreur token notification: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updatePayoutInfo(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await authenticatedRequest((t) => http.patch(
      Uri.parse('$_baseUrl/users/me/payout-info'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
      body: jsonEncode(data),
    ));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur coordonnées paiement: ${response.body}');
  }

  Future<void> requestPhoneChange({
    required String token,
    required String phone,
  }) async {
    final response = await authenticatedRequest((t) => http.post(
      Uri.parse('$_baseUrl/users/me/phone/request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
      body: jsonEncode({'phone': _normalizePhone(phone)}),
    ));

    if (response.statusCode == 200 || response.statusCode == 201) return;
    if (response.statusCode == 409) throw Exception('PHONE_ALREADY_USED');
    throw Exception('Erreur changement téléphone: ${response.body}');
  }

  Future<Map<String, dynamic>> confirmPhoneChange({
    required String token,
    required String phone,
    required String code,
  }) async {
    final response = await authenticatedRequest((t) => http.patch(
      Uri.parse('$_baseUrl/users/me/phone/confirm'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
      body: jsonEncode({'phone': _normalizePhone(phone), 'code': code}),
    ));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    if (response.statusCode == 401) throw Exception('CODE_INVALIDE');
    if (response.statusCode == 409) throw Exception('PHONE_ALREADY_USED');
    throw Exception('Erreur changement téléphone: ${response.body}');
  }

  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await authenticatedRequest((t) => http.patch(
      Uri.parse('$_baseUrl/users/me/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    ));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('MOT_DE_PASSE_ACTUEL_INCORRECT');
    } else {
      throw Exception('Erreur mot de passe: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> forceChangePassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await authenticatedRequest((t) => http.post(
      Uri.parse('$_baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
      body: jsonEncode({
        'password': newPassword,
      }),
    ));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur mot de passe: ${response.body}');
    }
  }

}
