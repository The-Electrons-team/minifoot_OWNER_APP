import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_loading.dart' show ShimmerBox;
import '../../reservations/screens/reservation_detail_screen.dart';
import '../controllers/notifications_controller.dart';

// Écran 14 (Notifications) du design : groupées par jour, décision possible
// directement depuis la liste pour les demandes en attente.
class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: kGreen,
          onRefresh: controller.refreshNotifications,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Get.back(),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8, top: 4, bottom: 4),
                          child: PhosphorIcon(
                            PhosphorIconsRegular.caretLeft,
                            size: 24,
                            color: kTextPrim,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Notifications',
                          style: kArchivo(size: 21, weight: FontWeight.w800, color: kTextPrim, height: 1.15),
                        ),
                      ),
                      Obx(
                        () => controller.unreadCount == 0
                            ? const SizedBox.shrink()
                            : GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: controller.markAllRead,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    'Tout lire',
                                    style: kManrope(size: 13, weight: FontWeight.w700, color: kGreen),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              Obx(() {
                if (controller.isLoading.value && controller.notifications.isEmpty) {
                  return const SliverPadding(
                    padding: EdgeInsets.fromLTRB(18, 22, 18, 24),
                    sliver: SliverToBoxAdapter(child: _ListLoading()),
                  );
                }
                if (controller.errorMessage.value.isNotEmpty && controller.notifications.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      message: controller.errorMessage.value,
                      onRetry: controller.refreshNotifications,
                    ),
                  );
                }
                final groups = controller.groupedByDay;
                if (groups.isEmpty) {
                  return const SliverFillRemaining(hasScrollBody: false, child: _EmptyState());
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
                  sliver: SliverList.builder(
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                      final (label, items) = groups[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 2, top: i == 0 ? 14 : 24, bottom: 10),
                            child: Text(
                              label,
                              style: kManrope(
                                size: 12,
                                weight: FontWeight.w700,
                                color: kTextSub,
                                letterSpacing: 0.1 * 12,
                              ),
                            ),
                          ),
                          for (final item in items) ...[
                            _NotificationTile(item: item),
                            const SizedBox(height: 10),
                          ],
                        ],
                      );
                    },
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

class _NotificationTile extends GetView<NotificationsController> {
  final NotificationItem item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final (icon, iconBg, iconFg) = _visualFor(item.type);
    final canAct = item.needsOwnerDecision && (item.reservationId ?? '').isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!item.isRead) controller.markRead(item);
        final id = item.reservationId;
        if (id != null && id.isNotEmpty) {
          Get.to(() => const ReservationDetailScreen(), arguments: id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: kTextPrim.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(13)),
                  child: PhosphorIcon(icon, color: iconFg, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: kManrope(
                          size: 14,
                          weight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                          color: kTextPrim,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [item.time, if (item.message.isNotEmpty) item.message].join(' · '),
                        style: kManrope(size: 12.5, weight: FontWeight.w400, color: kTextSub, height: 1.4),
                      ),
                    ],
                  ),
                ),
                if (!item.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8, top: 6),
                    decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                  ),
              ],
            ),
            if (canAct) ...[
              const SizedBox(height: 14),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: controller.isActing.value
                            ? null
                            : () => controller.confirmReservation(item),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: controller.isActing.value ? kGreen.withValues(alpha: 0.6) : kGreen,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Text(
                            'Confirmer',
                            style: kManrope(size: 13.5, weight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: controller.isActing.value
                          ? null
                          : () => controller.refuseReservation(item),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: kRed.withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: Text(
                          'Refuser',
                          style: kManrope(size: 13.5, weight: FontWeight.w700, color: kRed),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static (IconData, Color, Color) _visualFor(String type) {
    return switch (type) {
      'booking' => (PhosphorIconsRegular.calendarCheck, kBlueLight, kBlue),
      'payment' => (PhosphorIconsRegular.wallet, kGreenLight, kGreen),
      'chat' => (PhosphorIconsRegular.chatCircle, kGoldLight, const Color(0xFF92400E)),
      _ => (PhosphorIconsRegular.bell, kBg, kTextSub),
    };
  }
}

class _ListLoading extends StatelessWidget {
  const _ListLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: ShimmerBox(width: double.infinity, height: 82, borderRadius: 20),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
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
              child: const PhosphorIcon(PhosphorIconsRegular.bell, color: kTextSub, size: 40),
            ),
            const SizedBox(height: 22),
            Text(
              'Rien de neuf',
              textAlign: TextAlign.center,
              style: kArchivo(size: 21, weight: FontWeight.w800, color: kTextPrim, height: 1.25),
            ),
            const SizedBox(height: 10),
            Text(
              'Les demandes, paiements et alertes de vos terrains arriveront ici.',
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
        padding: const EdgeInsets.symmetric(horizontal: 34),
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
