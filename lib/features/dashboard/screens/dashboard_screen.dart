import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/utils/app_format.dart';
import '../../../core/utils/app_motion.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/owner_ui.dart';
import '../controllers/dashboard_controller.dart';

// ─── Constantes de layout ────────────────────────────────────────────────────
const double _kHeaderImageH = 220.0; // hauteur image expanded
const double _kCardFullH = 160.0; // hauteur revenue card expanded
const double _kCardCompactH = 60.0; // hauteur revenue card collapsed
const double _kOverlapFull = 60.0; // overlap expanded
const double _kOverlapMin =
    20.0; // overlap collapsed (card reste dans le header)
const double _kHeaderMinH = 72.0; // hauteur image collapsed (barre verte)

// expanded = image + card visible sous l'image
const double _kExpandedH = _kHeaderImageH + _kCardFullH - _kOverlapFull;
// collapsed = barre verte + card compacte - overlap mini (card chevauche toujours)
const double _kCollapsedH = _kHeaderMinH + _kCardCompactH - _kOverlapMin;

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.isController) {
      return _buildControllerDashboard();
    }

    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        color: kGreen,
        onRefresh: controller.refreshDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _DashboardHeader(controller: controller),
            // Espace pour la partie de la card qui dépasse sous le header
            const SliverToBoxAdapter(
              child: SizedBox(height: _kCardFullH - _kOverlapFull - 48),
            ),
            SliverToBoxAdapter(
              child: Obx(() => Column(
                children: [
                  _buildDashboardNotice(),
                  if (!controller.isController) _buildTodayFocus(),
                  if (!controller.isController) _buildStatsRow(),
                  _buildQuickActions(),
                  if (!controller.isController) _buildWeeklyChart(),
                  if (!controller.isController) _buildRecentBookings(),
                  const SizedBox(height: 84),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControllerDashboard() {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: kGreen,
          onRefresh: controller.refreshDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const ShapeDecoration(
                      gradient: kGreenGradient,
                      shape: CircleBorder(),
                    ),
                    alignment: Alignment.center,
                    child: Obx(
                      () => Text(
                        controller.ownerInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'POSTE DE CONTRÔLE',
                          style: TextStyle(
                            color: kGreen,
                            fontFamily: 'Orbitron',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Obx(
                          () => Text(
                            controller.ownerName.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kTextPrim,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => IconButton(
                      onPressed: controller.goToNotifications,
                      icon: Badge(
                        isLabelVisible: controller.notificationCount.value > 0,
                        label: Text('${controller.notificationCount.value}'),
                        child: const PhosphorIcon(
                          PhosphorIconsDuotone.bell,
                          color: kTextPrim,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Obx(
                () => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: DecoratedBox(
                    decoration: const ShapeDecoration(
                      gradient: kGreenGradient,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ControllerStat(
                              value: '${controller.todayBookings.value}',
                              label: "Réservations aujourd'hui",
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 44,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          Expanded(
                            child: _ControllerStat(
                              value: '${controller.activeTerrainCount.value}',
                              label: 'Terrains assignés',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildDashboardNotice(),
              const OwnerSectionHeader(
                title: "Actions d'aujourd'hui",
                subtitle: 'Accès limité aux opérations de contrôle',
              ),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardNotice() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
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
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kRedLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsDuotone.warningCircle,
              color: kRed,
              size: 18,
            ),
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

  // ─── Stats row ───────────────────────────────────────────────────────────
  /// Ce qui demande une action aujourd'hui.
  ///
  /// Le tableau de bord n'avait aucune surface de ce type : les paiements en
  /// attente n'apparaissaient que comme sous-titre d'une tuile de navigation,
  /// et rien ne distinguait une journée calme d'une journée chargée. Le bloc
  /// disparaît quand il n'y a rien à traiter — un encart vide est du bruit.
  Widget _buildTodayFocus() {
    return Obx(() {
      final pending = controller.pendingPayments.value;
      final today = controller.todayBookings.value;
      if (pending == 0 && today == 0) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: AppCard(
          borderColor: kBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OwnerSectionHeader(
                title: "À traiter aujourd'hui",
                subtitle: 'Ce qui attend une action de votre part',
              ),
              const SizedBox(height: AppSpacing.sm),
              if (today > 0)
                _FocusRow(
                  icon: PhosphorIconsRegular.calendarBlank,
                  color: kBlue,
                  label:
                      "$today réservation${today > 1 ? 's' : ''} aujourd'hui",
                  actionLabel: 'Voir',
                  onTap: controller.goToReservations,
                ),
              if (today > 0 && pending > 0)
                const SizedBox(height: AppSpacing.xs),
              if (pending > 0)
                _FocusRow(
                  icon: PhosphorIconsRegular.clockCountdown,
                  color: kGoldDeep,
                  label:
                      '$pending paiement${pending > 1 ? 's' : ''} en attente',
                  actionLabel: 'Traiter',
                  onTap: controller.goToPayments,
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Obx(
        () =>
            Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: kCardShadow,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCell(
                            icon: PhosphorIconsDuotone.calendarBlank,
                            iconColor: kBlue,
                            value: '${controller.todayBookings.value}',
                            label: "Aujourd'hui",
                          ),
                        ),
                        const VerticalDivider(
                          color: kDivider,
                          width: 1,
                          thickness: 1,
                        ),
                        Expanded(
                          child: _StatCell(
                            icon: PhosphorIconsDuotone.star,
                            iconColor: kGold,
                            value: '${controller.rating.value}',
                            label: 'Note',
                          ),
                        ),
                        const VerticalDivider(
                          color: kDivider,
                          width: 1,
                          thickness: 1,
                        ),
                        Expanded(
                          child: _StatCell(
                            icon: PhosphorIconsDuotone.chartPie,
                            iconColor: kGreen,
                            value:
                                '${(controller.occupancyRate.value * 100).round()}%',
                            label: 'Occupation',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .slideY(begin: 0.2, end: 0),
      ),
    );
  }

  // ─── Quick actions ────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const OwnerSectionHeader(title: 'Accès rapides'),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final actions = [
              _ActionData(
                icon: PhosphorIconsDuotone.calendarCheck,
                label: 'Réservations',
                color: kBlue,
                bgColor: kBlueLight,
                onTap: controller.goToReservations,
              ),
              _ActionData(
                icon: PhosphorIconsDuotone.clockCountdown,
                label: 'Créneaux',
                color: kGold,
                bgColor: kGoldLight,
                onTap: controller.goToAvailability,
              ),
              _ActionData(
                icon: PhosphorIconsDuotone.qrCode,
                label: 'Scanner',
                color: kOrange,
                bgColor: const Color(0xFFFFF3E0),
                onTap: controller.goToQrCheckIn,
              ),
              if (!controller.isController) ...[
                _ActionData(
                  icon: PhosphorIconsDuotone.soccerBall,
                  label: 'Terrains',
                  color: kGreen,
                  bgColor: kGreenLight,
                  onTap: controller.goToTerrains,
                ),
                _ActionData(
                  icon: PhosphorIconsDuotone.usersThree,
                  label: 'Contrôleurs',
                  color: kBlue,
                  bgColor: kBlueLight,
                  onTap: controller.goToControllers,
                ),
                _ActionData(
                  icon: PhosphorIconsDuotone.wallet,
                  label: 'Paiements',
                  color: kOrange,
                  bgColor: const Color(0xFFFFF3E0),
                  onTap: controller.goToPayments,
                ),
              ],
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 14,
                    children: List.generate(actions.length, (index) {
                      final a = actions[index];
                      return GestureDetector(
                            onTap: a.onTap,
                            child: Container(
                              width: itemWidth,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: kBgCard,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: kCardShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: a.bgColor,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: PhosphorIcon(
                                      a.icon,
                                      color: a.color,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    a.label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: kTextPrim,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(
                            duration: 400.ms,
                            delay: AppMotion.stagger(index, base: 400),
                          )
                          .slideX(begin: 0.15, end: 0);
                    }),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Weekly chart ─────────────────────────────────────────────────────────
  Widget _buildWeeklyChart() {
    return Obx(() {
      final data = controller.activeChartData;
      if (data.isEmpty) return const SizedBox.shrink();
      final maxVal = data.reduce((a, b) => a > b ? a : b);
      if (maxVal == 0) return const SizedBox.shrink();

      final isWeek = controller.chartPeriod.value == 'week';
      final labels = controller.activeChartLabels;

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: kCardShadow,
          ),
          child: Builder(
            builder: (_) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isWeek ? 'Cette semaine' : 'Par mois',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kTextPrim,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Revenus en F CFA',
                            style: TextStyle(fontSize: 12, color: kTextLight),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: kBgSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            _ChartToggle(
                              label: 'Sem.',
                              isActive: isWeek,
                              onTap: () => controller.toggleChartPeriod('week'),
                            ),
                            _ChartToggle(
                              label: 'Mois',
                              isActive: !isWeek,
                              onTap: () =>
                                  controller.toggleChartPeriod('month'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (maxVal / 1000) * 1.2,
                        backgroundColor: Colors.transparent,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: isWeek ? 20 : 50,
                          getDrawingHorizontalLine: (v) =>
                              FlLine(color: kDivider, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    labels[idx],
                                    style: TextStyle(
                                      fontSize: isWeek ? 11 : 9,
                                      color: kTextLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 28,
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        barGroups: data.asMap().entries.map((e) {
                          final isMax = e.value == maxVal;
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value / 1000,
                                width: isWeek ? 28 : 16,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                                gradient: isMax
                                    ? kGreenGradient
                                    : LinearGradient(
                                        colors: [
                                          kGreen.withValues(alpha: 0.18),
                                          kGreen.withValues(alpha: 0.08),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                              ),
                            ],
                          );
                        }).toList(),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipRoundedRadius: 10,
                            getTooltipItem: (group, groupIdx, rod, rodIdx) =>
                                BarTooltipItem(
                                  '${(rod.toY * 1000).toInt()} F',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      duration: const Duration(milliseconds: 400),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ).animate().fadeIn(duration: 500.ms, delay: 600.ms);
    });
  }

  // ─── Recent bookings ──────────────────────────────────────────────────────
  Widget _buildRecentBookings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Réservations récentes',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kTextPrim,
            ),
          ),
          const SizedBox(height: 14),
          Obx(() {
            if (controller.recentBookings.isEmpty) {
              return const _EmptyRecentBookings();
            }

            final displayed = controller.recentBookings.take(5).toList();
            final hasMore = controller.recentBookings.length > 5;

            return Column(
              children: [
                ...displayed.asMap().entries.map(
                  (entry) => _BookingTile(booking: entry.value)
                      .animate()
                      .fadeIn(
                        duration: 400.ms,
                        delay: AppMotion.stagger(entry.key, base: 700),
                      )
                      .slideY(begin: 0.1, end: 0),
                ),
                if (hasMore)
                  GestureDetector(
                    onTap: controller.goToReservations,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          'Voir plus',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── Bottom nav ───────────────────────────────────────────────────────────
}

class _ControllerStat extends StatelessWidget {
  final String value;
  final String label;

  const _ControllerStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SLIVER HEADER — image fixe + revenue card chevauchante
// ═══════════════════════════════════════════════════════════════════════════════

class _DashboardHeader extends StatelessWidget {
  final DashboardController controller;
  const _DashboardHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeaderDelegate(
        controller: controller,
        topPad: topPad,
        expandedHeight: _kExpandedH + topPad,
        collapsedHeight: _kCollapsedH + topPad,
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final DashboardController controller;
  final double topPad;
  final double expandedHeight;
  final double collapsedHeight;

  const _HeaderDelegate({
    required this.controller,
    required this.topPad,
    required this.expandedHeight,
    required this.collapsedHeight,
  });

  @override
  double get maxExtent => expandedHeight;
  @override
  double get minExtent => collapsedHeight;
  @override
  bool shouldRebuild(covariant _HeaderDelegate old) => false;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // t = 1 expanded → 0 collapsed
    final t = (1.0 - shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    // Hauteur image interpolée : de _kHeaderImageH → _kHeaderMinH
    final imageH = _kHeaderMinH + (_kHeaderImageH - _kHeaderMinH) * t + topPad;

    // Hauteur card interpolée : de _kCardFullH → _kCardCompactH
    final cardH = _kCardCompactH + (_kCardFullH - _kCardCompactH) * t;

    // Overlap interpolé : toujours présent, de _kOverlapFull → _kOverlapMin
    final overlap = _kOverlapMin + (_kOverlapFull - _kOverlapMin) * t;

    // Position top de la card : bas de l'image - overlap
    final cardTop = imageH - overlap;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Zone image (se réduit au scroll) ────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: imageH,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/terrain.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: kGreen),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        kGreen.withValues(alpha: 0.75),
                        Colors.black.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                ),
                // Avatar + nom + cloche (disparaît progressivement)
                Positioned(
                  top: topPad,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: _buildHeaderContent(context),
                  ),
                ),
                // Barre compacte dans l'image (apparaît quand collapsed)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _kHeaderMinH + topPad,
                  child: Opacity(
                    opacity: (1.0 - t * 3).clamp(0.0, 1.0),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: topPad,
                        left: 16,
                        right: 16,
                        bottom: 12,
                      ),
                      child: const Center(
                        child: Text(
                          'MINIFOOT',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Revenue card : uniquement pour les propriétaires ─────────────
        if (!controller.isController)
          Positioned(
            top: cardTop,
            left: 24,
            right: 24,
            height: cardH,
            child: _RevenueCardAnimated(controller: controller, t: t),
          ),
      ],
    );
  }

  Widget _buildHeaderContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gauche : titre + nom
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MINIFOOT',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 2),
              Obx(
                () => Text(
                  controller.ownerName.value,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          // Droite : notif + toggle thème
          Row(
            children: [
              _NotifBell(controller: controller),
              const SizedBox(width: 8),
              // Accès profil
              GestureDetector(
                onTap: controller.goToProfile,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: PhosphorIcon(
                      PhosphorIconsDuotone.user,
                      color: kGreen,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS EXTRAITS (utilisent Obx — ne peuvent pas être dans _HeaderDelegate)
// ═══════════════════════════════════════════════════════════════════════════════

class _NotifBell extends StatelessWidget {
  final DashboardController controller;
  const _NotifBell({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: controller.goToNotifications,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(
                PhosphorIconsDuotone.bell,
                color: kGreen,
                size: 22,
              ),
            ),
            Obx(
              () => controller.notificationCount.value > 0
                  ? Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: kRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            controller.notificationCount.value > 9
                                ? '9+'
                                : '${controller.notificationCount.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueCardAnimated extends StatelessWidget {
  final DashboardController controller;
  final double t; // 1 = expanded, 0 = collapsed

  const _RevenueCardAnimated({required this.controller, required this.t});

  static String _fmt(int value) => AppFormat.amount(value, withSymbol: false);

  @override
  Widget build(BuildContext context) {
    final isExpanded = t > 0.4;
    // Ombre plus forte quand collapsed (card au-dessus du contenu blanc)
    final shadowOpacity = 0.12 + (1.0 - t) * 0.14;
    final shadowBlur = 20.0 + (1.0 - t) * 16.0;
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: shadowOpacity),
              blurRadius: shadowBlur,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isExpanded ? 14 : 11,
          ),
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxHeight: double.infinity,
            child: isExpanded ? _buildExpanded() : _buildCompact(),
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: kGoldGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kGold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: PhosphorIcon(
                PhosphorIconsDuotone.wallet,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Revenus totaux',
                style: TextStyle(
                  fontSize: 13,
                  color: kTextSub,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kGreenLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIconsDuotone.checkCircle,
                    color: kGreen,
                    size: 13,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${controller.confirmedBookings.value} payées',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _fmt(controller.totalRevenue.value),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: kTextPrim,
                height: 1,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 2, left: 5),
              child: Text(
                'F CFA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextSub,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(height: 1, color: kDivider),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: kGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kGreen.withValues(alpha: 0.4),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "${_fmt(controller.todayRevenue.value)} F CFA aujourd'hui",
              style: const TextStyle(
                fontSize: 12,
                color: kTextSub,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: controller.goToPayments,
              child: Row(
                children: [
                  const Text(
                    'Détails',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kGreen,
                    ),
                  ),
                  const SizedBox(width: 3),
                  PhosphorIcon(
                    PhosphorIconsBold.caretRight,
                    color: kGreen,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompact() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: kGoldGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: PhosphorIcon(
            PhosphorIconsDuotone.wallet,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Revenus totaux',
                style: TextStyle(
                  fontSize: 11,
                  color: kTextSub,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_fmt(controller.totalRevenue.value)} F CFA',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: kTextPrim,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: kGreenLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIconsDuotone.checkCircle,
                color: kGreen,
                size: 13,
              ),
              const SizedBox(width: 3),
              Text(
                '${controller.confirmedBookings.value}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _ActionData {
  final dynamic icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  const _ActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}

class _EmptyRecentBookings extends StatelessWidget {
  const _EmptyRecentBookings();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: kGreenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: PhosphorIcon(
              PhosphorIconsDuotone.calendarCheck,
              color: kGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aucune réservation récente',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: kTextPrim,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Les réservations payées ou en attente apparaîtront ici.',
                  style: TextStyle(fontSize: 12, color: kTextSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final dynamic icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCell({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PhosphorIcon(icon, color: iconColor, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: kTextPrim,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: kTextSub,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String? ?? 'pending';
    final isConfirmed = status == 'confirmed';
    final isCancelled = status == 'cancelled';
    final statusColor = isConfirmed
        ? kGreen
        : isCancelled
        ? kRed
        : kGold;
    final statusBgColor = isConfirmed
        ? kGreenLight
        : isCancelled
        ? kRedLight
        : kGoldLight;
    final statusText = isConfirmed
        ? 'Confirmé'
        : isCancelled
        ? 'Annulé'
        : 'En attente';
    final amount = booking['amount'] as int;
    final raw = amount.toString();
    final amountStr = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) amountStr.write(' ');
      amountStr.write(raw[i]);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: PhosphorIcon(
              isConfirmed
                  ? PhosphorIconsDuotone.checkCircle
                  : isCancelled
                  ? PhosphorIconsDuotone.xCircle
                  : PhosphorIconsDuotone.clock,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: kTextPrim,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIconsDuotone.mapPin,
                      size: 13,
                      color: kTextLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking['terrain'] as String,
                      style: const TextStyle(fontSize: 12, color: kTextSub),
                    ),
                    Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        color: kTextLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    PhosphorIcon(
                      PhosphorIconsDuotone.clock,
                      size: 13,
                      color: kTextLight,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        booking['time'] as String,
                        style: const TextStyle(fontSize: 12, color: kTextSub),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountStr F',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kTextPrim,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartToggle extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ChartToggle({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? kGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : kTextSub,
          ),
        ),
      ),
    );
  }
}

/// Une ligne d'« à traiter aujourd'hui » : constat + action directe.
class _FocusRow extends StatelessWidget {
  const _FocusRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          AppIconBadge(icon: icon, color: color, size: AppIconBox.sm),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSize.bodySmall,
                fontWeight: FontWeight.w700,
                color: kTextPrim,
              ),
            ),
          ),
          Text(
            actionLabel,
            style: TextStyle(
              fontSize: AppFontSize.label,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const Icon(
            PhosphorIconsRegular.caretRight,
            size: 14,
            color: kTextLight,
          ),
        ],
      ),
    );
  }
}
