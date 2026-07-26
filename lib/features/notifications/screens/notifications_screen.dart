import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/notifications_controller.dart';

class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kTextPrim,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Get.back(),
          behavior: HitTestBehavior.opaque,
          child: const Center(
            child: PhosphorIcon(PhosphorIcons.caretLeft,
              color: kTextPrim,
              size: 24,
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => controller.markAllRead(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: PhosphorIcon(PhosphorIconsDuotone.checkCircle,
                color: kGreen,
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterChips(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.notifications.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: kGreen),
                );
              }
              if (controller.errorMessage.value.isNotEmpty &&
                  controller.notifications.isEmpty) {
                return _ErrorState(
                  message: controller.errorMessage.value,
                  onRetry: controller.loadNotifications,
                );
              }
              final items = controller.filteredNotifications;
              if (items.isEmpty) {
                return _EmptyState();
              }
              return RefreshIndicator(
                color: kGreen,
                onRefresh: controller.refreshNotifications,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  itemCount: items.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationTile(
                      item: items[index],
                      onTap: () => controller.markRead(items[index]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Filtre toggle compact ───────────────────────────────────────────────────

class _FilterChips extends GetView<NotificationsController> {
  static const _filters = [
    ('all', 'Tout'),
    ('booking', 'Réserv.'),
    ('payment', 'Paiem.'),
    ('system', 'Sys.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Obx(() {
        final selected = controller.selectedFilter.value;
        final unread = controller.unreadCount;
        return Container(
          decoration: BoxDecoration(
            color: kBgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            children: _filters.map((f) {
              final isActive = selected == f.$1;
              final label = f.$1 == 'all' && unread > 0
                  ? '${f.$2} ($unread)'
                  : f.$2;
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
                      label,
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
}

// ─── Notification tile ────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isRead ? kBgCard : kGreenLight.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: item.isRead
                ? Colors.transparent
                : kGreen.withValues(alpha: 0.16),
          ),
          boxShadow: kCardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône dans un cercle coloré
            _TypeIcon(type: item.type),
            const SizedBox(width: 12),
            // Contenu texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: kTextPrim,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(
                      color: kTextSub,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Temps + indicateur non lu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.time,
                  style: const TextStyle(color: kTextLight, fontSize: 11),
                ),
                if (!item.isRead) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: kGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Icône selon le type ──────────────────────────────────────────────────────

class _TypeIcon extends StatelessWidget {
  final String type;

  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (dynamic icon, Color iconColor, Color bgColor) = switch (type) {
      'booking' => (
        PhosphorIconsDuotone.calendarBlank,
        kBlue,
        kBlueLight,
      ),
      'payment' => (
        PhosphorIconsDuotone.wallet,
        kGreen,
        kGreenLight,
      ),
      'chat' => (
        PhosphorIconsDuotone.chatCircleText,
        kGold,
        kGoldLight,
      ),
      'system' => (
        PhosphorIconsDuotone.info,
        kTextSub,
        kBgSurface,
      ),
      _ => (
        PhosphorIconsDuotone.bell,
        kTextSub,
        kBgSurface,
      ),
    };

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PhosphorIcon(icon, color: iconColor, size: 22),
    );
  }
}

// ─── État vide ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(PhosphorIconsDuotone.bellSlash,
            size: 64,
            color: kTextLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune notification',
            style: TextStyle(
              color: kTextSub,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(PhosphorIconsDuotone.warningCircle,
              size: 56,
              color: kTextLight,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextSub,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
