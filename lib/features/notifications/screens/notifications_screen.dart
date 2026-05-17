import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
        leading: IconButton(
          icon: Icon(
            PhosphorIcons.arrowLeft(PhosphorIconsStyle.duotone),
            color: kTextPrim,
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.markAllRead(),
            child: const Text(
              'Tout lire',
              style: TextStyle(
                color: kGreen,
                fontWeight: FontWeight.w600,
                fontSize: 14,
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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

// ─── Filtres chips ────────────────────────────────────────────────────────────

class _FilterChips extends GetView<NotificationsController> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBgCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          final selected = controller.selectedFilter.value;
          final unread = controller.unreadCount;
          return Row(
            children: [
              _FilterChip(
                label: unread > 0 ? 'Toutes ($unread)' : 'Toutes',
                value: 'all',
                isSelected: selected == 'all',
                onTap: () => controller.setFilter('all'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Réservations',
                value: 'booking',
                isSelected: selected == 'booking',
                onTap: () => controller.setFilter('booking'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Paiements',
                value: 'payment',
                isSelected: selected == 'payment',
                onTap: () => controller.setFilter('payment'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Système',
                value: 'system',
                isSelected: selected == 'system',
                onTap: () => controller.setFilter('system'),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kGreen : kBgSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : kTextSub,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
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
          borderRadius: BorderRadius.circular(16),
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
    final (IconData icon, Color iconColor, Color bgColor) = switch (type) {
      'booking' => (
        PhosphorIcons.calendarBlank(PhosphorIconsStyle.duotone),
        kBlue,
        kBlueLight,
      ),
      'payment' => (
        PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
        kGreen,
        kGreenLight,
      ),
      'chat' => (
        PhosphorIcons.chatCircleText(PhosphorIconsStyle.duotone),
        kGold,
        kGoldLight,
      ),
      'system' => (
        PhosphorIcons.info(PhosphorIconsStyle.duotone),
        kTextSub,
        kBgSurface,
      ),
      _ => (
        PhosphorIcons.bell(PhosphorIconsStyle.duotone),
        kTextSub,
        kBgSurface,
      ),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 22),
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
          Icon(
            PhosphorIcons.bellSlash(PhosphorIconsStyle.duotone),
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
            Icon(
              PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
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
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
