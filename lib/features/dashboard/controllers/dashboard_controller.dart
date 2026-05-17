import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../routes/app_routes.dart';

class DashboardController extends GetxController {
  final _service = DashboardService();
  final _auth = Get.find<AuthController>();

  final selectedTab = 0.obs;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final ownerName = 'Propriétaire'.obs;
  final totalRevenue = 0.obs;
  final todayRevenue = 0.obs;
  final totalBookings = 0.obs;
  final todayBookings = 0.obs;
  final confirmedBookings = 0.obs;
  final pendingPayments = 0.obs;
  final terrainCount = 0.obs;
  final activeTerrainCount = 0.obs;
  final rating = 0.0.obs;
  final occupancyRate = 0.0.obs;
  final notificationCount = 0.obs;
  final chartPeriod = 'week'.obs; // 'week' ou 'month'

  final monthlyData = List<double>.filled(12, 0).obs;
  final weeklyData = List<double>.filled(7, 0).obs;
  final recentBookings = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  void toggleChartPeriod(String period) => chartPeriod.value = period;

  List<double> get activeChartData =>
      chartPeriod.value == 'week' ? weeklyData : monthlyData;

  List<String> get activeChartLabels => chartPeriod.value == 'week'
      ? ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
      : [
          'Jan',
          'Fév',
          'Mar',
          'Avr',
          'Mai',
          'Jun',
          'Jul',
          'Aoû',
          'Sep',
          'Oct',
          'Nov',
          'Déc',
        ];

  String get ownerInitials {
    final parts = ownerName.value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'MF';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts.last[0] : '';
    return '$first$second'.toUpperCase();
  }

  bool get isController => _auth.user.value?.isController == true;

  Future<void> loadDashboard() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final data = await _service.getOwnerDashboard();
      ownerName.value = data.ownerName;
      totalRevenue.value = data.totalRevenue;
      todayRevenue.value = data.todayRevenue;
      totalBookings.value = data.totalBookings;
      todayBookings.value = data.todayBookings;
      confirmedBookings.value = data.confirmedBookings;
      pendingPayments.value = data.pendingPayments;
      terrainCount.value = data.terrainCount;
      activeTerrainCount.value = data.activeTerrainCount;
      rating.value = data.rating;
      occupancyRate.value = data.occupancyRate;
      weeklyData.value = data.weeklyData;
      monthlyData.value = data.monthlyData;
      recentBookings.value = data.recentBookings;
      notificationCount.value = data.unreadNotifications;
    } catch (_) {
      errorMessage.value = 'Impossible de charger le tableau de bord';
      Get.snackbar(
        'Erreur',
        'Impossible de charger le tableau de bord',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboard();
  }

  void changeTab(int i) => selectedTab.value = i;

  Future<void> openBottomTab(int tabIndex, String route) async {
    selectedTab.value = tabIndex;
    try {
      await Get.toNamed(route);
    } finally {
      Future.microtask(() => selectedTab.value = 0);
    }
  }

  void goToTerrains() => Get.toNamed(Routes.terrainList);
  void goToReservations() => Get.toNamed(Routes.reservations);
  void goToAvailability() => Get.toNamed(Routes.availability);
  void goToPayments() => Get.toNamed(Routes.payments);
  void goToProfile() => Get.toNamed(Routes.profile);
  void goToNotifications() => Get.toNamed(Routes.notifications);
  void goToQrCheckIn() => Get.toNamed(Routes.qrCheckIn);
  void goToControllers() => Get.toNamed(Routes.controllers);
}
