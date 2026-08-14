import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_loading.dart' show ShimmerBox;
import '../../reports/screens/report_screen.dart';
import '../controllers/reservations_controller.dart';
import 'reservation_detail_screen.dart';

// Écrans 25 (Liste & filtres) et 26 (Recherche — aucun résultat) du design.
class ReservationsScreen extends GetView<ReservationsController> {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: kGreen,
          onRefresh: controller.refreshReservations,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Réservations',
                              style: kArchivo(
                                size: 28,
                                weight: FontWeight.w800,
                                letterSpacing: -0.02 * 28,
                              ),
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Get.to(
                              () => const ReportScreen(),
                              arguments: {'reportType': 'reservations'},
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: PhosphorIcon(
                                PhosphorIconsRegular.filePdf,
                                color: kGreen,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _SearchBar(),
                      const SizedBox(height: 14),
                      const _TabSwitch(),
                      const SizedBox(height: 16),
                      const _SummaryLine(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Obx(() {
                if (controller.isLoading.value) {
                  return const SliverPadding(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 24),
                    sliver: SliverToBoxAdapter(child: _ListLoading()),
                  );
                }
                final query = _searchQuery.value.trim().toLowerCase();
                var list = controller.tabReservations;
                if (query.isNotEmpty) {
                  list = list
                      .where(
                        (r) =>
                            r.clientName.toLowerCase().contains(query) ||
                            r.teamName.toLowerCase().contains(query),
                      )
                      .toList();
                }
                if (list.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(query: query),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ReservationTile(reservation: list[i]),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

final _searchQuery = ''.obs;

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(color: kTextPrim.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass, color: kTextSub, size: 19),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              onChanged: (v) => _searchQuery.value = v,
              style: kManrope(size: 15, weight: FontWeight.w600, color: kTextPrim),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Chercher un client',
                hintStyle: kManrope(size: 15, weight: FontWeight.w600, color: kTextLight),
              ),
            ),
          ),
          Obx(
            () => _searchQuery.value.isEmpty
                ? const SizedBox.shrink()
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _searchQuery.value = '',
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kBgSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const PhosphorIcon(PhosphorIconsBold.x, color: kTextSub, size: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabSwitch extends GetView<ReservationsController> {
  const _TabSwitch();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: kSurfaceStrong, borderRadius: BorderRadius.circular(14)),
      child: Obx(
        () => Row(
          children: [
            _TabButton(
              label: "Aujourd'hui",
              selected: controller.selectedTab.value == ReservationTab.today,
              onTap: () => controller.setTab(ReservationTab.today),
            ),
            _TabButton(
              label: 'À venir',
              selected: controller.selectedTab.value == ReservationTab.upcoming,
              onTap: () => controller.setTab(ReservationTab.upcoming),
            ),
            _TabButton(
              label: 'Passées',
              selected: controller.selectedTab.value == ReservationTab.past,
              onTap: () => controller.setTab(ReservationTab.past),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? kBgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [BoxShadow(color: kTextPrim.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            style: kManrope(
              size: 12.5,
              weight: FontWeight.w700,
              color: selected ? kTextPrim : kTextSub,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryLine extends GetView<ReservationsController> {
  const _SummaryLine();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = controller.tabReservations;
      final pending = controller.tabPendingCount;
      final total = controller.tabTotalAmount;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              pending > 0
                  ? '${list.length} réservation${list.length > 1 ? 's' : ''} · $pending en attente'
                  : '${list.length} réservation${list.length > 1 ? 's' : ''}',
              style: kManrope(size: 13, weight: FontWeight.w600, color: kTextSub),
            ),
            Text(
              '${_thousands(total)} F',
              style: kArchivo(size: 14, weight: FontWeight.w700, color: kTextPrim),
            ),
          ],
        ),
      );
    });
  }
}

class _ReservationTile extends StatelessWidget {
  final ReservationModel reservation;

  const _ReservationTile({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final cancelled = reservation.status == 'cancelled';
    final startTime = reservation.timeSlot.split(RegExp(r'[-–]')).first.trim();
    final badge = _badgeFor(reservation);
    final isNext = _isNextUpcoming(reservation);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.to(
        () => const ReservationDetailScreen(),
        arguments: reservation.id,
      ),
      child: Opacity(
        opacity: cancelled ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(20),
            border: isNext ? Border.all(color: kGreen.withValues(alpha: 0.35), width: 2) : null,
            boxShadow: [
              BoxShadow(color: kTextPrim.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                child: Text(
                  startTime,
                  style: kArchivo(size: 17, weight: FontWeight.w700, color: isNext ? kGreen : kTextPrim),
                ),
              ),
              Container(width: 1, height: 34, color: kTextPrim.withValues(alpha: 0.08)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.clientName,
                      style: kManrope(
                        size: 14.5,
                        weight: FontWeight.w600,
                        color: kTextPrim,
                        height: 1.3,
                      ).copyWith(decoration: cancelled ? TextDecoration.lineThrough : null),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      cancelled
                          ? 'Annulée'
                          : '${reservation.terrain}${reservation.subTerrainName.isNotEmpty ? ' — ${reservation.subTerrainName}' : ''}',
                      style: kManrope(size: 12.5, weight: FontWeight.w400, color: kTextSub, height: 1.35),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!cancelled)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_thousands(reservation.amount)} F',
                      style: kArchivo(size: 13.5, weight: FontWeight.w700, color: kTextPrim),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: badge.$2, borderRadius: BorderRadius.circular(7)),
                        child: Text(
                          badge.$1,
                          style: kManrope(size: 10.5, weight: FontWeight.w700, color: badge.$3),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isNextUpcoming(ReservationModel r) {
    if (r.rawDate == null || r.status == 'cancelled') return false;
    final now = DateTime.now();
    final isToday = r.rawDate!.year == now.year && r.rawDate!.month == now.month && r.rawDate!.day == now.day;
    if (!isToday) return false;
    final parts = r.startSlot.split(RegExp(r'[hH:]'));
    if (parts.length < 2) return false;
    final slotTime = DateTime(now.year, now.month, now.day, int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
    return slotTime.isAfter(now) && slotTime.difference(now).inHours < 3;
  }

  static (String, Color, Color)? _badgeFor(ReservationModel r) {
    if (r.isCheckedIn) return ('PRÉSENT', kGreenLight, kGreenInk);
    if (r.status == 'confirmed') return ('PAYÉ', kGreenLight, kGreenInk);
    if (r.status == 'awaiting_owner_confirmation' || r.paymentStatus == 'Payé') {
      return ('ACOMPTE', kBlueLight, kBlueInk);
    }
    if (r.status == 'pending') return ('EN ATTENTE', kGoldLight, kGoldInk);
    return null;
  }
}

class _EmptyState extends GetView<ReservationsController> {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: kSurfaceMuted, borderRadius: BorderRadius.circular(30)),
              child: PhosphorIcon(
                hasQuery ? PhosphorIconsRegular.magnifyingGlass : PhosphorIconsRegular.calendarBlank,
                color: kTextSub,
                size: 40,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              hasQuery ? 'Aucun « $query » ici' : 'Rien à afficher',
              textAlign: TextAlign.center,
              style: kArchivo(size: 21, weight: FontWeight.w800, color: kTextPrim, height: 1.25),
            ),
            const SizedBox(height: 10),
            Text(
              hasQuery
                  ? 'Essayez un autre nom, ou changez d\'onglet.'
                  : 'Aucune réservation sur cette période.',
              textAlign: TextAlign.center,
              style: kManrope(size: 14, weight: FontWeight.w400, color: kTextSub, height: 1.6),
            ),
            if (hasQuery) ...[
              const SizedBox(height: 26),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _searchQuery.value = '',
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(color: kTextPrim.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
                    ],
                  ),
                  child: Text(
                    'Retirer la recherche',
                    style: kManrope(size: 15, weight: FontWeight.w600, color: kTextPrim),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListLoading extends StatelessWidget {
  const _ListLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: ShimmerBox(width: double.infinity, height: 74, borderRadius: 20),
        ),
      ),
    );
  }
}

String _thousands(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(s[i]);
  }
  return buffer.toString();
}
