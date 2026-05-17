import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/owner_ui.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../routes/app_routes.dart';
import '../../reports/screens/report_screen.dart';
import '../controllers/reservations_controller.dart';

class ReservationsScreen extends GetView<ReservationsController> {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBgCard,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
          color: kTextPrim,
        ),
        title: const Text(
          'Réservations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kTextPrim,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Get.to(
              () => const ReportScreen(),
              arguments: {'reportType': 'reservations'},
            ),
            icon: Icon(
              PhosphorIcons.filePdf(PhosphorIconsStyle.duotone),
              color: kGreen,
            ),
            tooltip: 'Rapport PDF',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kDivider),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshReservations,
        color: kGreen,
        backgroundColor: kBgCard,
        child: Column(
          children: [
            _buildFilterChips(),
            _buildSummaryStrip(),
            Expanded(child: _buildReservationList()),
          ],
        ),
      ),
    );
  }

  // ── Filter chips row ────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return Obx(() {
      final filters = [
        {'key': 'all', 'label': 'Toutes', 'count': controller.totalCount},
        {
          'key': 'confirmed',
          'label': 'Confirmees',
          'count': controller.confirmedCount,
        },
        {
          'key': 'pending',
          'label': 'En attente',
          'count': controller.pendingCount,
        },
        {
          'key': 'cancelled',
          'label': 'Annulees',
          'count': controller.cancelledCount,
        },
      ];

      return Container(
        color: kBgCard,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((f) {
              final isSelected = controller.selectedFilter.value == f['key'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => controller.setFilter(f['key'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? kGreen : kBgSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isSelected ? kGreen : kBorder),
                    ),
                    child: Row(
                      children: [
                        Text(
                          f['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : kTextSub,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : kBgCard,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${f['count']}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : kTextSub,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildSummaryStrip() {
    return Obx(() {
      final list = controller.filteredReservations;
      final totalAmount = list.fold<int>(0, (sum, item) => sum + item.amount);
      final checkedInCount = list.where((item) => item.isCheckedIn).length;
      final pendingActionCount = list
          .where((item) => item.status == 'pending')
          .length;

      return Container(
        width: double.infinity,
        color: kBgCard,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kGreen.withValues(alpha: 0.08),
                kBlue.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OwnerSectionHeader(
                title: 'Priorités de la vue',
                subtitle:
                    '${list.length} réservation${list.length > 1 ? 's' : ''} à suivre dans ce filtre',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SummaryMetric(
                      icon: PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
                      label: 'Montant',
                      value: _formatAmount(totalAmount),
                      accent: kGreen,
                      background: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryMetric(
                      icon: PhosphorIcons.sealCheck(PhosphorIconsStyle.duotone),
                      label: 'Présences',
                      value: '$checkedInCount',
                      accent: kBlue,
                      background: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryMetric(
                      icon: PhosphorIcons.hourglassMedium(
                        PhosphorIconsStyle.duotone,
                      ),
                      label: 'À traiter',
                      value: '$pendingActionCount',
                      accent: kGold,
                      background: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Reservation list ────────────────────────────────────────────────────────
  Widget _buildReservationList() {
    return Obx(() {
      // Shimmer loading pendant le chargement
      if (controller.isLoading.value) {
        return ShimmerList(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemBuilder: (context, index) => const ReservationCardSkeleton(),
        );
      }

      final list = controller.filteredReservations;

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/football_bounce.json',
                width: 120,
                height: 120,
                repeat: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune reservation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextSub,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.selectedFilter.value == 'all'
                    ? 'Les réservations apparaitront ici'
                    : 'Aucune réservation pour ce filtre',
                style: TextStyle(fontSize: 13, color: kTextLight),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: list.length,
        itemBuilder: (_, i) =>
            _ReservationCard(
                  reservation: list[i],
                  onTap: () => _openReservationDetails(list[i]),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: (i * 80).ms)
                .slideY(begin: 0.1, end: 0),
      );
    });
  }

  Future<void> _openReservationDetails(ReservationModel reservation) async {
    final updated = await Get.toNamed(
      Routes.reservationDetail,
      arguments: reservation.id,
    );
    if (updated == true) {
      await controller.loadReservations();
    }
  }
}

// ── Reservation card ────────────────────────────────────────────────────────

String _formatAmount(int amount) {
  final str = amount.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(str[i]);
  }
  return '${buffer.toString()} F CFA';
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onTap;

  const _ReservationCard({required this.reservation, required this.onTap});

  Color get _statusColor {
    switch (reservation.status) {
      case 'confirmed':
        return kGreen;
      case 'pending':
        return kGold;
      case 'cancelled':
        return kRed;
      default:
        return kTextSub;
    }
  }

  Color get _statusBg {
    switch (reservation.status) {
      case 'confirmed':
        return kGreenLight;
      case 'pending':
        return kGoldLight;
      case 'cancelled':
        return kRedLight;
      default:
        return kBgSurface;
    }
  }

  String get _statusLabel {
    switch (reservation.status) {
      case 'confirmed':
        return 'Confirme';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annule';
      default:
        return reservation.status;
    }
  }

  String get _initials {
    final name = reservation.clientName.trim();
    if (name.isEmpty) return 'MF';
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first.length >= 2
        ? parts.first.substring(0, 2).toUpperCase()
        : parts.first[0].toUpperCase();
  }

  String get _terrainLabel {
    if (reservation.subTerrainName.isEmpty) {
      return reservation.terrain;
    }
    return '${reservation.terrain} • ${reservation.subTerrainName}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: kCardShadow,
              border: Border.all(color: kBorder.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: kGreenLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kGreenDim,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reservation.clientName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kTextPrim,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                PhosphorIcons.phone(PhosphorIconsStyle.duotone),
                                size: 12,
                                color: kTextLight,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  reservation.phone.isEmpty
                                      ? reservation.teamName
                                      : reservation.phone,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: kTextSub,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _statusBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: kBgSurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                            size: 14,
                            color: kTextSub,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: kDivider),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: kBlueLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        PhosphorIcons.courtBasketball(
                          PhosphorIconsStyle.duotone,
                        ),
                        color: kBlue,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _terrainLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: kTextSub,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _MetaText(
                            icon: PhosphorIcons.calendarBlank(
                              PhosphorIconsStyle.duotone,
                            ),
                            label: reservation.date,
                          ),
                          _MetaText(
                            icon: PhosphorIcons.clock(
                              PhosphorIconsStyle.duotone,
                            ),
                            label: reservation.timeSlot,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatAmount(reservation.amount),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kTextPrim,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: kBgSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InlineState(
                          icon: PhosphorIcons.creditCard(
                            PhosphorIconsStyle.duotone,
                          ),
                          label: reservation.paymentStatus,
                          value: reservation.paymentMethod,
                        ),
                      ),
                      Container(width: 1, height: 24, color: kBorder),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InlineState(
                          icon: reservation.isCheckedIn
                              ? PhosphorIcons.sealCheck(
                                  PhosphorIconsStyle.duotone,
                                )
                              : PhosphorIcons.mapPinLine(
                                  PhosphorIconsStyle.duotone,
                                ),
                          label: reservation.isCheckedIn
                              ? 'Présence confirmée'
                              : 'Check-in en attente',
                          value: reservation.isCheckedIn
                              ? 'Joueur arrivé'
                              : 'En attente',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color background;

  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: kTextSub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: kTextPrim,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InlineState extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InlineState({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: kTextSub),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: kTextPrim,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  color: kTextSub,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaText({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: kTextLight, size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: kTextSub,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
