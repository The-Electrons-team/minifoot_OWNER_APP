import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_loading.dart' show ShimmerBox;
import '../../reservations/controllers/reservations_controller.dart';
import '../controllers/attendance_controller.dart';

// Écran 20 (Présences du jour) : valider une entrée à la main, sans scanner.
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AttendanceController());
    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        color: kGreen,
        onRefresh: controller.refreshAttendance,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _Header(controller: controller)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              sliver: SliverToBoxAdapter(child: _Filters(controller: controller)),
            ),
            Obx(() {
              if (controller.isLoading.value && controller.reservations.isEmpty) {
                return const SliverPadding(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 24),
                  sliver: SliverToBoxAdapter(
                    child: ShimmerBox(width: double.infinity, height: 260, borderRadius: 22),
                  ),
                );
              }
              if (controller.errorMessage.value.isNotEmpty &&
                  controller.reservations.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    message: controller.errorMessage.value,
                    onRetry: controller.refreshAttendance,
                  ),
                );
              }
              final list = controller.visible;
              if (list.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                );
              }
              return SliverPadding
                (
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: kBgCard,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: kTextPrim.withValues(alpha: 0.07),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < list.length; i++)
                              _AttendanceRow(
                                reservation: list[i],
                                controller: controller,
                                last: i == list.length - 1,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Une présence validée à la main est signalée comme telle dans vos rapports.',
                        textAlign: TextAlign.center,
                        style: kManrope(
                          size: 12.5,
                          weight: FontWeight.w400,
                          color: kTextSub,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AttendanceController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 26),
      decoration: const BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Get.back(),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const PhosphorIcon(
                    PhosphorIconsRegular.caretLeft,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Présences du jour',
                  style: kArchivo(
                    size: 21,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Obx(() {
            final entered = controller.enteredCount;
            final total = controller.reservations.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: '$entered',
                        style: kArchivo(size: 40, weight: FontWeight.w800, color: Colors.white),
                        children: [
                          TextSpan(
                            text: '/$total',
                            style: kArchivo(
                              size: 22,
                              weight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        'joueurs entrés\nsur $total réservation${total > 1 ? 's' : ''}',
                        style: kManrope(
                          size: 13,
                          weight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.78),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      flex: entered == 0 ? 0 : entered,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: kGreenLight,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    if (entered > 0 && entered < total) const SizedBox(width: 4),
                    Expanded(
                      flex: (total - entered) <= 0 ? 0 : total - entered,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final AttendanceController controller;

  const _Filters({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              label: 'Tous',
              selected: controller.filter.value == AttendanceFilter.all &&
                  controller.terrainFilter.value.isEmpty,
              dark: true,
              onTap: () {
                controller.setFilter(AttendanceFilter.all);
                controller.terrainFilter.value = '';
              },
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Attendus · ${controller.expectedCount}',
              selected: controller.filter.value == AttendanceFilter.expected,
              dark: true,
              onTap: () => controller.setFilter(
                controller.filter.value == AttendanceFilter.expected
                    ? AttendanceFilter.all
                    : AttendanceFilter.expected,
              ),
            ),
            for (final terrain in controller.terrains) ...[
              const SizedBox(width: 8),
              _Chip(
                label: terrain,
                selected: controller.terrainFilter.value == terrain,
                dark: true,
                onTap: () => controller.toggleTerrain(terrain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? kTextPrim : kBgCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? null
              : [
                  BoxShadow(
                    color: kTextPrim.withValues(alpha: 0.07),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: kManrope(
            size: 13,
            weight: FontWeight.w600,
            color: selected ? Colors.white : kTextSub,
          ),
        ),
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final ReservationModel reservation;
  final AttendanceController controller;
  final bool last;

  const _AttendanceRow({
    required this.reservation,
    required this.controller,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.stateOf(reservation);
      final entered =
          state == AttendanceState.scanned || state == AttendanceState.manual;
      final busy = controller.actingId.value == reservation.id;
      final terrain = reservation.subTerrainName.isNotEmpty
          ? reservation.subTerrainName
          : reservation.terrain;

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: kTextPrim.withValues(alpha: 0.07))),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: entered ? kGreenLight : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: entered
                    ? null
                    : Border.all(color: kTextPrim.withValues(alpha: 0.18), width: 2),
              ),
              child: entered
                  ? const PhosphorIcon(PhosphorIconsBold.check, color: kGreen, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation.clientName,
                    style: kArchivo(size: 15, weight: FontWeight.w700, color: kTextPrim, height: 1.2),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$terrain · ${reservation.startSlot} · ${_stateLabel(state)}',
                    style: kManrope(size: 12, weight: FontWeight.w400, color: kTextSub, height: 1.35),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!entered) ...[
              const SizedBox(width: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: busy ? null : () => controller.markEntered(reservation),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: busy ? kGreen.withValues(alpha: 0.6) : kGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Entré',
                          style: kManrope(size: 13, weight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  String _stateLabel(AttendanceState state) {
    switch (state) {
      case AttendanceState.scanned:
        final at = reservation.checkedInAt;
        final time = at.contains('•') ? at.split('•').last.trim() : at;
        return time.isEmpty ? 'scanné' : 'scanné $time';
      case AttendanceState.manual:
        return 'validée à la main';
      case AttendanceState.expected:
        return 'attendu';
      case AttendanceState.absent:
        return 'absent';
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEAE0),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const PhosphorIcon(PhosphorIconsRegular.users, color: kTextSub, size: 40),
            ),
            const SizedBox(height: 22),
            Text(
              'Aucune réservation aujourd\'hui',
              textAlign: TextAlign.center,
              style: kArchivo(size: 20, weight: FontWeight.w800, color: kTextPrim, height: 1.25),
            ),
            const SizedBox(height: 10),
            Text(
              'Les joueurs attendus apparaîtront ici dès la première réservation confirmée.',
              textAlign: TextAlign.center,
              style: kManrope(size: 14, weight: FontWeight.w400, color: kTextSub, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: kManrope(size: 14, weight: FontWeight.w600, color: kTextSub, height: 1.5),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onRetry(),
              child: Text(
                'Réessayer',
                style: kManrope(size: 14, weight: FontWeight.w700, color: kGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
