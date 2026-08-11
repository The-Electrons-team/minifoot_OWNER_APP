import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/app_format.dart';
import '../../../core/services/revenue_service.dart';
import '../../../core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Modèles
// ══════════════════════════════════════════════════════════════════════════════

class RevenueEntry {
  final String label; // ex: "Lun", "Sem 1", "Janv"
  final int amount; // en FCFA
  final int bookings; // nombre de réservations
  final double occupancy; // taux d'occupation 0.0 → 1.0

  const RevenueEntry({
    required this.label,
    required this.amount,
    required this.bookings,
    required this.occupancy,
  });
}

enum RevenuePeriod { daily, weekly, monthly }

// ══════════════════════════════════════════════════════════════════════════════
// Controller
// ══════════════════════════════════════════════════════════════════════════════

class RevenuesController extends GetxController {
  final _service = RevenueService();

  final period = RevenuePeriod.weekly.obs;
  final selectedBar = (-1).obs; // index de la barre sélectionnée
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Période pour le rapport PDF
  final reportPeriod = 'Ce mois'.obs;

  final dailyData = <RevenueEntry>[].obs;
  final weeklyData = <RevenueEntry>[].obs;
  final monthlyData = <RevenueEntry>[].obs;
  final terrainStats = <TerrainRevenueStat>[].obs;

  // ── Écran 42 : encaissements du mois et transactions ─────────────────────
  final transactions = <OwnerTransaction>[].obs;
  final monthPaid = 0.obs;
  final pendingAmount = 0.obs;
  final pendingCount = 0.obs;
  final payouts = <OwnerPayout>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadRevenues();
  }

  Future<void> loadRevenues() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final data = await _service.getOwnerRevenueData();
      dailyData.value = data.dailyEntries.map(_fromServiceEntry).toList();
      weeklyData.value = data.weeklyEntries.map(_fromServiceEntry).toList();
      monthlyData.value = data.monthlyEntries.map(_fromServiceEntry).toList();
      terrainStats.value = data.terrainStats;
      transactions.value = data.transactions;
      monthPaid.value = data.monthPaid;
      pendingAmount.value = data.pendingAmount;
      pendingCount.value = data.transactions
          .where((tx) => tx.status == 'pending')
          .length;
    } catch (_) {
      errorMessage.value =
          'Impossible de charger les revenus. Vérifiez votre connexion.';
    } finally {
      isLoading.value = false;
    }
    // L'historique des versements est secondaire : son échec ne doit pas
    // masquer les revenus déjà chargés.
    try {
      payouts.value = await _service.getPayoutHistory();
    } catch (_) {
      payouts.clear();
    }
  }

  Future<void> refreshRevenues() async {
    await loadRevenues();
  }

  RevenueEntry _fromServiceEntry(OwnerRevenueEntry entry) {
    return RevenueEntry(
      label: entry.label,
      amount: entry.amount,
      bookings: entry.bookings,
      occupancy: entry.occupancy,
    );
  }

  // ── Getters des données selon la période ─────────────────────────────────
  List<RevenueEntry> get entries {
    switch (period.value) {
      case RevenuePeriod.daily:
        return dailyData;
      case RevenuePeriod.weekly:
        return weeklyData;
      case RevenuePeriod.monthly:
        return monthlyData;
    }
  }

  int get totalRevenue => entries.fold(0, (sum, e) => sum + e.amount);

  int get totalBookings => entries.fold(0, (sum, e) => sum + e.bookings);

  double get avgOccupancy {
    if (entries.isEmpty) return 0;
    return entries.fold(0.0, (sum, e) => sum + e.occupancy) / entries.length;
  }

  int get bestAmount =>
      entries.fold(0, (max, e) => e.amount > max ? e.amount : max);

  bool get hasRevenueData => entries.any((entry) => entry.amount > 0);

  String get periodLabel {
    switch (period.value) {
      case RevenuePeriod.daily:
        return 'Cette semaine';
      case RevenuePeriod.weekly:
        return 'Ce mois';
      case RevenuePeriod.monthly:
        return 'Ces 6 mois';
    }
  }

  RevenueEntry? get selectedEntry {
    final i = selectedBar.value;
    if (i < 0 || i >= entries.length) return null;
    return entries[i];
  }

  // ── Changer la période ───────────────────────────────────────────────────
  void setPeriod(RevenuePeriod p) {
    if (period.value == p) return;
    period.value = p;
    selectedBar.value = -1;
  }

  void selectBar(int index) {
    selectedBar.value = selectedBar.value == index ? -1 : index;
  }

  // ── Données pour fl_chart ─────────────────────────────────────────────────
  List<BarChartGroupData> get barGroups {
    return List.generate(entries.length, (i) {
      final entry = entries[i];
      final isSelected = selectedBar.value == i;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: entry.amount.toDouble(),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            gradient: LinearGradient(
              colors: isSelected
                  ? [kGreenDark, kGreen]
                  : [
                      kGreen.withValues(alpha: 0.4),
                      kGreen.withValues(alpha: 0.7),
                    ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
        showingTooltipIndicators: isSelected ? [0] : [],
      );
    });
  }

  List<LineChartBarData> get occupancyLine {
    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.occupancy * 100);
    }).toList();

    return [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.35,
        color: kGold,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              kGold.withValues(alpha: 0.18),
              kGold.withValues(alpha: 0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    ];
  }

  // ── Format ────────────────────────────────────────────────────────────────
  String formatAmount(int amount) => AppFormat.amountCompact(amount);

  String formatAmountFull(int amount) =>
      AppFormat.amount(amount, withSymbol: false);

  String get occupancyPercent => '${(avgOccupancy * 100).round()}%';
}
