import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/revenues_controller.dart';
import '../../reports/screens/report_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Screen principal — Tableau de bord revenus
// ══════════════════════════════════════════════════════════════════════════════

class RevenuesScreen extends GetView<RevenuesController> {
  const RevenuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: kGreen,
        onRefresh: controller.refreshRevenues,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _buildPeriodTabs()),
            SliverToBoxAdapter(child: _buildNotice()),
            SliverToBoxAdapter(child: _buildKpiCards()),
            SliverToBoxAdapter(child: _buildBarChart()),
            SliverToBoxAdapter(child: _buildOccupancyChart()),
            SliverToBoxAdapter(child: _buildTopPerformers()),
            SliverToBoxAdapter(child: _buildReportButton(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kBgCard,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: kTextPrim,
          size: 18,
        ),
      ),
      title: const Text(
        'Revenus',
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: kTextPrim,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: kDivider),
      ),
    );
  }

  // ── Onglets Journalier / Hebdo / Mensuel ──────────────────────────────────
  Widget _buildPeriodTabs() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: kCardShadow,
          ),
          child: Row(
            children: [
              _PeriodTab(
                label: 'Journalier',
                icon: Icons.today_rounded,
                isSelected: controller.period.value == RevenuePeriod.daily,
                onTap: () => controller.setPeriod(RevenuePeriod.daily),
              ),
              _PeriodTab(
                label: 'Hebdo',
                icon: Icons.view_week_rounded,
                isSelected: controller.period.value == RevenuePeriod.weekly,
                onTap: () => controller.setPeriod(RevenuePeriod.weekly),
              ),
              _PeriodTab(
                label: 'Mensuel',
                icon: Icons.calendar_month_rounded,
                isSelected: controller.period.value == RevenuePeriod.monthly,
                onTap: () => controller.setPeriod(RevenuePeriod.monthly),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotice() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              minHeight: 3,
              color: kGreen,
              backgroundColor: kGreenLight,
            ),
          ),
        );
      }

      if (controller.errorMessage.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kRedLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: kRed, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.errorMessage.value,
                style: const TextStyle(
                  color: kRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Cartes KPI ──────────────────────────────────────────────────────────────
  Widget _buildKpiCards() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          children: [
            // Carte revenus totaux — grande
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: kGreenGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: kGreen.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        controller.periodLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${controller.formatAmountFull(controller.totalRevenue)} F CFA',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+12% vs période précédente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 12),

            // 2 petites cartes
            Row(
              children: [
                Expanded(
                  child:
                      _KpiSmallCard(
                            icon: Icons.calendar_month_rounded,
                            iconColor: kBlue,
                            iconBg: kBlueLight,
                            label: 'Réservations',
                            value: '${controller.totalBookings}',
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms)
                          .slideY(begin: 0.1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      _KpiSmallCard(
                            icon: Icons.pie_chart_rounded,
                            iconColor: kGold,
                            iconBg: kGoldLight,
                            label: 'Taux moy.',
                            value: controller.occupancyPercent,
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 150.ms)
                          .slideY(begin: 0.1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Graphique barre revenus ──────────────────────────────────────────────────
  Widget _buildBarChart() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: kCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: kGreenLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      size: 18,
                      color: kGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Revenus',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kTextPrim,
                    ),
                  ),
                  const Spacer(),
                  if (controller.selectedEntry != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kGreenLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${controller.selectedEntry!.label} : ${controller.formatAmountFull(controller.selectedEntry!.amount)} F',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kGreen,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: controller.hasRevenueData
                    ? BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: controller.bestAmount.toDouble() * 1.25,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchCallback: (event, response) {
                              if (event is FlTapUpEvent &&
                                  response?.spot != null) {
                                HapticFeedback.selectionClick();
                                controller.selectBar(
                                  response!.spot!.touchedBarGroupIndex,
                                );
                              }
                            },
                            touchTooltipData: BarTouchTooltipData(
                              tooltipRoundedRadius: 10,
                              getTooltipColor: (group) => kBgCard,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final entry = controller.entries[groupIndex];
                                return BarTooltipItem(
                                  '${controller.formatAmount(entry.amount)} F\n',
                                  const TextStyle(
                                    color: kGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '${entry.bookings} rés.',
                                      style: const TextStyle(
                                        color: kTextSub,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final i = value.toInt();
                                  if (i < 0 || i >= controller.entries.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      controller.entries[i].label,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: kTextSub,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 28,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    controller.formatAmount(value.toInt()),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: kTextLight,
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: (controller.bestAmount / 4)
                                .clamp(1, double.infinity),
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: kBorder,
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: controller.barGroups,
                        ),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      )
                    : const _EmptyRevenueChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Courbe taux d'occupation ─────────────────────────────────────────────────
  Widget _buildOccupancyChart() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: kCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: kGoldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      size: 18,
                      color: kGold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Taux d\'occupation',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kTextPrim,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kGoldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Moy. ${controller.occupancyPercent}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 140,
                child: controller.hasRevenueData
                    ? LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: 100,
                          lineBarsData: controller.occupancyLine,
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final i = value.toInt();
                                  if (i < 0 || i >= controller.entries.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      controller.entries[i].label,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: kTextSub,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 24,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  if (value % 25 != 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    '${value.toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: kTextLight,
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 25,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: kBorder,
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineTouchData: const LineTouchData(enabled: false),
                        ),
                        duration: const Duration(milliseconds: 400),
                      )
                    : const _EmptyRevenueChart(compact: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top performers par terrain ───────────────────────────────────────────────
  Widget _buildTopPerformers() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: kCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: kBlueLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.stadium_rounded,
                      size: 18,
                      color: kBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Par terrain',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kTextPrim,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (controller.terrainStats.isEmpty)
                const _EmptyTerrainStats()
              else
                ...controller.terrainStats.asMap().entries.map((e) {
                  final stat = e.value;
                  final rank = e.key + 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: rank == 1 ? kGoldLight : kBgSurface,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '#$rank',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: rank == 1 ? kGold : kTextSub,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                stat.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kTextPrim,
                                ),
                              ),
                            ),
                            Text(
                              '${controller.formatAmountFull(stat.amount)} F',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kTextPrim,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(stat.rate * 100).round()}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: stat.rate >= 0.7 ? kGreen : kTextSub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: stat.rate,
                            backgroundColor: kBgSurface,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              rank == 1 ? kGold : kGreen,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bouton générer rapport ──────────────────────────────────────────────────
  Widget _buildReportButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Get.to(
            () => const ReportScreen(),
            arguments: {
              'reportType': 'revenues',
              'periodKey': controller.period.value.name,
              'period': controller.periodLabel,
              'totalRevenue': controller.totalRevenue,
              'totalBookings': controller.totalBookings,
              'occupancy': controller.occupancyPercent,
              'entries': controller.entries,
            },
          );
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: kGreenGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: kGreen.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Générer le rapport PDF — ${controller.periodLabel}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Widgets privés
// ══════════════════════════════════════════════════════════════════════════════

class _EmptyRevenueChart extends StatelessWidget {
  final bool compact;

  const _EmptyRevenueChart({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kBgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            compact ? Icons.show_chart_rounded : Icons.bar_chart_rounded,
            color: kTextLight,
            size: compact ? 26 : 30,
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucune donnée sur cette période',
            style: TextStyle(
              color: kTextSub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTerrainStats extends StatelessWidget {
  const _EmptyTerrainStats();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Aucun terrain avec revenu confirmé pour le moment.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kTextSub,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? kGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : kTextSub),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : kTextSub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiSmallCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _KpiSmallCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kTextPrim,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: kTextSub),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
