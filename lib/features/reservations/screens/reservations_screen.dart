import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/utils/app_format.dart';
import '../../../core/utils/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_states.dart';
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
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Get.back(),
          behavior: HitTestBehavior.opaque,
          child: const Center(
            child: PhosphorIcon(
              PhosphorIconsRegular.caretLeft,
              color: kTextPrim,
              size: 24,
            ),
          ),
        ),
        title: const Text(
          'Réservations',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kTextPrim,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => Get.to(
              () => const ReportScreen(),
              arguments: {'reportType': 'reservations'},
            ),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PhosphorIcon(PhosphorIconsDuotone.filePdf,
                color: kGreen,
                size: 22,
              ),
            ),
          ),
        ],
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
    const filters = [
      ('all', 'Toutes'),
      ('confirmed', 'Confirmées'),
      ('pending', 'En attente'),
      ('cancelled', 'Annulées'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Obx(() {
        final active = controller.selectedFilter.value;
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: kBgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: filters.map((f) {
              final isActive = active == f.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.setFilter(f.$1),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? kGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : kTextSub,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  Widget _buildSummaryStrip() {
    return Obx(() {
      final list = controller.filteredReservations;
      final totalAmount = list.fold<int>(0, (sum, item) => sum + item.amount);
      final checkedInCount = list.where((item) => item.isCheckedIn).length;
      final pendingActionCount =
          list.where((item) => item.status == 'pending').length;

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        child: Container(
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
                  child: _ResStatCell(
                    icon: PhosphorIconsDuotone.wallet,
                    iconColor: kGreen,
                    value: _formatAmount(totalAmount),
                    label: 'Montant',
                  ),
                ),
                const VerticalDivider(color: kDivider, width: 1, thickness: 1),
                Expanded(
                  child: _ResStatCell(
                    icon: PhosphorIconsDuotone.sealCheck,
                    iconColor: kBlue,
                    value: '$checkedInCount',
                    label: 'Présences',
                  ),
                ),
                const VerticalDivider(color: kDivider, width: 1, thickness: 1),
                Expanded(
                  child: _ResStatCell(
                    icon: PhosphorIconsDuotone.hourglassMedium,
                    iconColor: kGold,
                    value: '$pendingActionCount',
                    label: 'À traiter',
                  ),
                ),
              ],
            ),
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

      // L'erreur passe avant le vide : un échec de chargement ne doit pas
      // s'afficher comme « Aucune réservation ».
      if (controller.errorMessage.value.isNotEmpty) {
        return AppErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.refreshReservations,
        );
      }

      final list = controller.filteredReservations;

      if (list.isEmpty) {
        return const Center(
          child: Text(
            'Aucune réservation',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kTextSub,
            ),
          ),
        );
      }

      return NotificationListener<ScrollNotification>(
        // Charge la page suivante avant d'atteindre le bas, pour que le
        // défilement ne marque pas d'arrêt.
        onNotification: (scroll) {
          if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 400) {
            controller.loadMore();
          }
          return false;
        },
        child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: list.length + (controller.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= list.length) return const _LoadMoreIndicator();
          final reservation = list[i];
          final card = _ReservationCard(
            reservation: reservation,
            onTap: () => _openReservationDetails(reservation),
          );

          // Refuser une réservation demandait d'ouvrir le détail : c'est
          // l'action la plus fréquente sur cet écran, elle mérite d'être
          // accessible d'un glissement. Seules les réservations encore
          // annulables l'exposent.
          final canRefuse =
              reservation.status == 'pending' ||
              reservation.status == 'confirmed';

          return Slidable(
            key: ValueKey(reservation.id),
            enabled: canRefuse,
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.28,
              children: [
                SlidableAction(
                  onPressed: (_) => controller.cancelReservation(reservation.id),
                  backgroundColor: kRed,
                  foregroundColor: Colors.white,
                  icon: PhosphorIconsRegular.x,
                  label: 'Refuser',
                  borderRadius: AppRadius.mdAll,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            child: card,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: AppMotion.stagger(i))
              .slideY(begin: 0.1, end: 0);
        },
        ),
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

String _formatAmount(int amount) => AppFormat.amount(amount);

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
                              PhosphorIcon(PhosphorIconsDuotone.phone,
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
                            PhosphorIconsBold.caretRight,
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
                      child: PhosphorIcon(PhosphorIconsDuotone.courtBasketball,
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
                            icon: PhosphorIconsDuotone.calendarBlank,
                            label: reservation.date,
                          ),
                          _MetaText(
                            icon: PhosphorIconsDuotone.clock,
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
                          icon: PhosphorIconsDuotone.creditCard,
                          label: reservation.paymentStatus,
                          value: reservation.paymentMethod,
                        ),
                      ),
                      Container(width: 1, height: 24, color: kBorder),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InlineState(
                          icon: reservation.isCheckedIn
                              ? PhosphorIconsDuotone.sealCheck
                              : PhosphorIconsDuotone.mapPinLine,
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

class _ResStatCell extends StatelessWidget {
  final dynamic icon;
  final Color iconColor;
  final String value;
  final String label;

  const _ResStatCell({
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
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: PhosphorIcon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: kTextPrim,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: kTextSub,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _InlineState extends StatelessWidget {
  final dynamic icon;
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
          child: PhosphorIcon(icon, size: 15, color: kTextSub),
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
  final dynamic icon;
  final String label;

  const _MetaText({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(icon, color: kTextLight, size: 14),
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

/// Pied de liste affiché pendant le chargement de la page suivante.
class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: kGreen),
      ),
    ),
  );
}
