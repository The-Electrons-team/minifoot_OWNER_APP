import 'package:get/get.dart';

import '../../../core/services/in_app_notification_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type; // 'booking', 'payment', 'system', 'chat'
  final String time;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.time,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
        DateTime.now();
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['body']?.toString() ?? '',
      type: _mapType(json),
      time: _relativeTime(createdAt),
      isRead: json['read'] == true,
      createdAt: createdAt,
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      time: time,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  static String _mapType(Map<String, dynamic> json) {
    final data = json['data'];
    final kind = data is Map ? data['kind']?.toString() : null;
    if (kind == 'payment') return 'payment';
    if (kind == 'reservation_cancelled') return 'booking';

    return switch (json['type']?.toString()) {
      'RESERVATION' => 'booking',
      'PROMO' => 'system',
      'SYSTEM' => 'system',
      'CHAT' => 'chat',
      'MATCH' => 'system',
      _ => 'system',
    };
  }

  static String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l’instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class NotificationsController extends GetxController {
  final _service = InAppNotificationService();

  final notifications = <NotificationItem>[].obs;
  final selectedFilter = 'all'.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final total = 0.obs;
  final unreadTotal = 0.obs;

  /// Pagination. Le backend renvoie 30 éléments par page et le total : sans
  /// chargement progressif, un propriétaire actif ne voyait jamais au-delà des
  /// 30 dernières notifications.
  final currentPage = 1.obs;
  final isLoadingMore = false.obs;

  bool get hasMore => notifications.length < total.value;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  void setFilter(String filter) => selectedFilter.value = filter;

  List<NotificationItem> get filteredNotifications {
    if (selectedFilter.value == 'all') return notifications;
    return notifications.where((n) => n.type == selectedFilter.value).toList();
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    isLoading.value = true;
    errorMessage.value = '';
    currentPage.value = 1;
    try {
      final body = await _service.getNotifications();
      final data = body['data'];
      notifications.value = data is List
          ? data
                .whereType<Map>()
                .map(
                  (item) => NotificationItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : [];
      total.value = _asInt(body['total']);
      unreadTotal.value = _asInt(body['unreadCount']);
      _syncDashboardBadge();
    } catch (_) {
      errorMessage.value =
          'Impossible de charger les notifications. Vérifiez votre connexion.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshNotifications() async {
    await loadNotifications();
  }

  /// Charge la page suivante et l'ajoute à la liste.
  ///
  /// Silencieux en cas d'échec : on ne remplace pas une liste déjà affichée par
  /// un écran d'erreur — l'utilisateur garde ce qu'il a et peut réessayer en
  /// continuant à faire défiler.
  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value || !hasMore) return;
    isLoadingMore.value = true;
    try {
      final body = await _service.getNotifications(page: currentPage.value + 1);
      final data = body['data'];
      if (data is List) {
        notifications.addAll(
          data.whereType<Map>().map(
            (item) => NotificationItem.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
        currentPage.value += 1;
        total.value = _asInt(body['total']);
      }
    } catch (_) {
      // volontairement silencieux
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> markRead(NotificationItem item) async {
    if (item.isRead || item.id.isEmpty) return;
    final index = notifications.indexWhere((n) => n.id == item.id);
    if (index == -1) return;

    notifications[index] = item.copyWith(isRead: true);
    unreadTotal.value = unreadCount;
    _syncDashboardBadge();
    try {
      await _service.markRead(item.id);
    } catch (_) {
      notifications[index] = item;
      unreadTotal.value = unreadCount;
      _syncDashboardBadge();
      AppSnackbar.error('Impossible de marquer cette notification comme lue.');
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount == 0) return;
    final previous = notifications.toList();
    notifications.value = notifications
        .map((item) => item.copyWith(isRead: true))
        .toList(growable: false);
    unreadTotal.value = 0;
    _syncDashboardBadge();

    try {
      await _service.markAllRead();
    } catch (_) {
      notifications.value = previous;
      unreadTotal.value = unreadCount;
      _syncDashboardBadge();
      AppSnackbar.error('Impossible de marquer toutes les notifications comme lues.');
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _syncDashboardBadge() {
    if (!Get.isRegistered<DashboardController>()) return;
    Get.find<DashboardController>().notificationCount.value = unreadTotal.value;
  }
}
