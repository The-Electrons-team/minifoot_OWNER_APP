import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';

// Écran 12 (Accueil) et 13 (Accueil — journée creuse) du design
// "MiniFoot Owner Refonte". Un seul écran principal + une action, comme le
// reste des écrans (« carte à traiter » exclue tant qu'elle n'a pas de
// donnée réelle derrière — voir DashboardController.urgentBooking).
class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        color: kGreen,
        onRefresh: controller.refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 18,
                  children: [
                    const _ScanCta(),
                    Obx(() {
                      final urgent = controller.urgentBooking;
                      if (urgent == null) return const SizedBox.shrink();
                      return _UrgentCard(booking: urgent);
                    }),
                    const _UpcomingSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── En-tête vert ────────────────────────────────────────────────────────────
class _Header extends GetView<DashboardController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.of(context).padding.top + 12,
        22,
        26,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: kBg,
                  shape: BoxShape.circle,
                ),
                child: Obx(
                  () => Text(
                    controller.ownerInitials,
                    style: kArchivo(size: 15, weight: FontWeight.w700, color: kGreen),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalizedToday(),
                      style: kManrope(
                        size: 13,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.3,
                      ),
                    ),
                    Obx(
                      () => Text(
                        'Bonjour ${controller.ownerName.value.split(' ').first}',
                        style: kArchivo(size: 17, weight: FontWeight.w700, color: Colors.white, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.goToNotifications,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const PhosphorIcon(
                        PhosphorIconsRegular.bell,
                        color: Colors.white,
                        size: 20,
                      ),
                      Obx(
                        () => controller.notificationCount.value > 0
                            ? Positioned(
                                top: -2,
                                right: -3,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: kGold,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: kGreen, width: 2),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Obx(() {
            final count = controller.todayBookings.value;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$count',
                  style: kArchivo(
                    size: 46,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.03 * 46,
                  ),
                ),
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    count <= 1
                        ? 'réservation aujourd\'hui\nsur ${controller.activeTerrainCount.value} terrain${controller.activeTerrainCount.value > 1 ? 's' : ''} actif${controller.activeTerrainCount.value > 1 ? 's' : ''}'
                        : 'réservations aujourd\'hui\nsur ${controller.activeTerrainCount.value} terrain${controller.activeTerrainCount.value > 1 ? 's' : ''} actif${controller.activeTerrainCount.value > 1 ? 's' : ''}',
                    style: kManrope(
                      size: 14,
                      weight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: 'REVENUS DU JOUR',
                  value: Obx(
                    () => Text(
                      '${_thousands(controller.todayRevenue.value)} F',
                      style: kArchivo(size: 19, weight: FontWeight.w700, color: Colors.white, height: 1.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  label: 'OCCUPATION',
                  value: Obx(
                    () => Text(
                      '${(controller.occupancyRate.value * 100).round()} %',
                      style: kArchivo(size: 19, weight: FontWeight.w700, color: Colors.white, height: 1.2),
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

  static String _capitalizedToday() {
    final formatted = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  static String _thousands(int value) =>
      NumberFormat.decimalPattern('fr_FR').format(value);
}

class _StatPill extends StatelessWidget {
  final String label;
  final Widget value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: kManrope(
              size: 11,
              weight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.04 * 11,
            ),
          ),
          const SizedBox(height: 7),
          value,
        ],
      ),
    );
  }
}

// ─── CTA scan ────────────────────────────────────────────────────────────────
class _ScanCta extends GetView<DashboardController> {
  const _ScanCta();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: controller.goToQrCheckIn,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: kTextPrim,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kTextPrim.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const PhosphorIcon(
                PhosphorIconsRegular.scan,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scanner un joueur',
                    style: kArchivo(size: 16, weight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Check-in en 2 secondes',
                    style: kManrope(
                      size: 12.5,
                      weight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              color: Colors.white.withValues(alpha: 0.65),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Carte "à traiter maintenant" ────────────────────────────────────────────
class _UrgentCard extends GetView<DashboardController> {
  final Map<String, dynamic> booking;

  const _UrgentCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final name = (booking['name'] ?? '').toString();
    final time = (booking['time'] ?? '').toString();
    final terrain = (booking['terrain'] ?? '').toString();
    final amount = booking['amount'] is int ? booking['amount'] as int : 0;
    final id = (booking['id'] ?? '').toString();
    final initials = _initialsOf(name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: kGold,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kGold.withValues(alpha: 0.2),
                    blurRadius: 0,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'À TRAITER MAINTENANT',
              style: kManrope(
                size: 13,
                weight: FontWeight.w700,
                color: kTextPrim,
                letterSpacing: 0.09 * 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: kTextPrim.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kGoldLight,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      initials,
                      style: kArchivo(size: 13, weight: FontWeight.w700, color: kGoldDeep),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name · $time',
                          style: kArchivo(size: 15, weight: FontWeight.w700, color: kTextPrim, height: 1.3),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$terrain · ${_thousands(amount)} F',
                          style: kManrope(size: 13, weight: FontWeight.w400, color: kTextSub, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                spacing: 9,
                children: [
                  GestureDetector(
                    onTap: id.isEmpty
                        ? null
                        : () => Get.find<DashboardController>().refuseUrgentBooking(id),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kRed.withValues(alpha: 0.35), width: 1.5),
                      ),
                      child: Text(
                        'Refuser',
                        style: kManrope(size: 14, weight: FontWeight.w700, color: kRed),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: id.isEmpty
                          ? null
                          : () => Get.find<DashboardController>().confirmUrgentBooking(id),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Confirmer',
                          style: kManrope(size: 14.5, weight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _thousands(int value) =>
      NumberFormat.decimalPattern('fr_FR').format(value);

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts.last[0] : '';
    return '$first$second'.toUpperCase();
  }
}

// ─── Section "Prochainement" ─────────────────────────────────────────────────
class _UpcomingSection extends GetView<DashboardController> {
  const _UpcomingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROCHAINEMENT',
              style: kManrope(size: 13, weight: FontWeight.w700, color: kTextPrim, letterSpacing: 0.09 * 13),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.goToReservations,
              child: Text(
                'Tout voir',
                style: kManrope(size: 13, weight: FontWeight.w600, color: kGreen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Obx(() {
          if (controller.isLoading.value && controller.recentBookings.isEmpty) {
            return const _UpcomingLoading();
          }
          final upcoming = controller.upcomingBookings;
          if (upcoming.isEmpty) return const _NoUpcoming();
          return Container(
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: kTextPrim.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < upcoming.length; i++) ...[
                  if (i > 0)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.only(left: 16),
                      color: kTextPrim.withValues(alpha: 0.07),
                    ),
                  _UpcomingTile(booking: upcoming[i]),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _UpcomingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final time = (booking['time'] ?? '').toString();
    final startTime = time.split(RegExp(r'[-–]')).first.trim();
    final name = (booking['name'] ?? '').toString();
    final terrain = (booking['terrain'] ?? '').toString();
    final status = (booking['status'] ?? '').toString();
    final badge = _badgeFor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(
                  startTime,
                  style: kArchivo(size: 17, weight: FontWeight.w700, color: kTextPrim),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: kTextPrim.withValues(alpha: 0.08)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: kManrope(size: 14.5, weight: FontWeight.w600, color: kTextPrim, height: 1.3),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  terrain,
                  style: kManrope(size: 12.5, weight: FontWeight.w400, color: kTextSub, height: 1.35),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: badge.$2, borderRadius: BorderRadius.circular(8)),
              child: Text(
                badge.$1,
                style: kManrope(size: 11, weight: FontWeight.w700, color: badge.$3),
              ),
            ),
        ],
      ),
    );
  }

  static (String, Color, Color)? _badgeFor(String status) {
    switch (status) {
      case 'confirmed':
        return ('PAYÉ', kGreenLight, kGreenInk);
      case 'pending':
        return ('ACOMPTE', kBlueLight, kBlueInk);
      default:
        return null;
    }
  }
}

class _UpcomingLoading extends StatelessWidget {
  const _UpcomingLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(20)),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: kGreen, strokeWidth: 2),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }
}

class _NoUpcoming extends StatelessWidget {
  const _NoUpcoming();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(12)),
            child: const PhosphorIcon(PhosphorIconsBold.check, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rien en attente',
                  style: kArchivo(size: 14.5, weight: FontWeight.w700, color: kGreenInk),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toutes les demandes sont traitées.',
                  style: kManrope(size: 12.5, weight: FontWeight.w400, color: kGreenMutedText, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
