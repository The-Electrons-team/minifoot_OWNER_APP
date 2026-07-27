import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class OwnerDashboardData {
  final String ownerName;
  final int totalRevenue;
  final int todayRevenue;
  final int totalBookings;
  final int todayBookings;
  final int confirmedBookings;
  final int pendingPayments;
  final int terrainCount;
  final int activeTerrainCount;
  final double rating;
  final double occupancyRate;
  final int unreadNotifications;
  final List<double> weeklyData;
  final List<double> monthlyData;
  final List<Map<String, dynamic>> recentBookings;

  const OwnerDashboardData({
    required this.ownerName,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.totalBookings,
    required this.todayBookings,
    required this.confirmedBookings,
    required this.pendingPayments,
    required this.terrainCount,
    required this.activeTerrainCount,
    required this.rating,
    required this.occupancyRate,
    required this.unreadNotifications,
    required this.weeklyData,
    required this.monthlyData,
    required this.recentBookings,
  });

  factory OwnerDashboardData.fromJson(Map<String, dynamic> json) {
    return OwnerDashboardData(
      ownerName: json['ownerName']?.toString() ?? 'Propriétaire',
      totalRevenue: _asInt(json['totalRevenue']),
      todayRevenue: _asInt(json['todayRevenue']),
      totalBookings: _asInt(json['totalBookings']),
      todayBookings: _asInt(json['todayBookings']),
      confirmedBookings: _asInt(json['confirmedBookings']),
      pendingPayments: _asInt(json['pendingPayments']),
      terrainCount: _asInt(json['terrainCount']),
      activeTerrainCount: _asInt(json['activeTerrainCount']),
      rating: _asDouble(json['rating']),
      occupancyRate: _asDouble(json['occupancyRate']),
      unreadNotifications: _asInt(json['unreadNotifications']),
      weeklyData: _asDoubleList(json['weeklyData'], 7),
      monthlyData: _asDoubleList(json['monthlyData'], 12),
      recentBookings: _asMapList(json['recentBookings']),
    );
  }

  static List<double> _asDoubleList(dynamic value, int length) {
    final items = value is List ? value : const [];
    return List<double>.generate(length, (index) {
      if (index >= items.length) return 0;
      return _asDouble(items[index]);
    });
  }

  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DashboardService {
  final String _base = AppConfig.apiUrl;

  Future<OwnerDashboardData> getOwnerDashboard() async {
    final response = await http.get(
      Uri.parse('$_base/owner/dashboard'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return OwnerDashboardData.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erreur dashboard owner: ${response.body}');
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
