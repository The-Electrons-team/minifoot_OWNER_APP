import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../core/services/reservation_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../routes/app_routes.dart';
import '../../shell/controllers/shell_controller.dart';

class DashboardController extends GetxController {
  final _service = DashboardService();
  final _reservationService = ReservationService();
  final _auth = Get.find<AuthController>();

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
  String? get avatarUrl => _auth.user.value?.avatarUrl;

  /// Réservation en acompte dont le solde reste à encaisser en espèces sur
  /// place (design "Détail d'une réservation", écran 27) : le propriétaire
  /// doit confirmer manuellement une fois l'argent reçu.
  Map<String, dynamic>? get urgentBooking {
    for (final booking in recentBookings) {
      if (booking['status'] == 'awaiting_owner_confirmation') return booking;
    }
    return null;
  }

  /// Les 3 prochaines réservations du jour, dans l'ordre du planning.
  List<Map<String, dynamic>> get upcomingBookings => recentBookings
      .where((b) => b['status'] != 'cancelled' && b != urgentBooking)
      .take(3)
      .toList();

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
      errorMessage.value =
          'Impossible de charger le tableau de bord. Vérifiez votre connexion.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboard();
  }

  Future<void> refuseUrgentBooking(String id) async {
    try {
      await _reservationService.cancelOwnerReservation(id);
      AppSnackbar.success('Réservation refusée.');
      await loadDashboard();
    } catch (_) {
      AppSnackbar.error('Impossible de refuser cette réservation. Réessayez.');
    }
  }

  Future<void> confirmUrgentBooking(String id) async {
    try {
      await _reservationService.confirmOwnerDeposit(id);
      AppSnackbar.success('Réservation confirmée.');
      await loadDashboard();
    } catch (_) {
      AppSnackbar.error('Impossible de confirmer cette réservation. Réessayez.');
    }
  }

  /// Coquille de navigation, si le tableau de bord y est hébergé.
  ///
  /// `Get.find` lève quand la dépendance manque : le tableau de bord serait
  /// alors inutilisable hors de la coquille, alors qu'il sait très bien
  /// naviguer par routes. On dégrade au lieu de planter.
  ShellController? get _shell =>
      Get.isRegistered<ShellController>() ? Get.find<ShellController>() : null;

  /// Bascule sur un onglet quand la destination en est un pour ce rôle,
  /// sinon empile la route.
  ///
  /// Les onglets 1 et 3 changent de contenu selon le rôle : pour un
  /// propriétaire ce sont Terrains et Paiements, pour un contrôleur
  /// Réservations et Créneaux. Basculer aveuglément sur l'onglet 1 enverrait
  /// un propriétaire sur ses terrains alors qu'il a demandé ses réservations.
  void _goToTabOrRoute({
    required bool isTab,
    required int tab,
    required String route,
  }) {
    final shell = _shell;
    if (isTab && shell != null) {
      shell.select(tab);
    } else {
      Get.toNamed(route);
    }
  }

  void goToTerrains() =>
      _goToTabOrRoute(isTab: !isController, tab: 1, route: Routes.terrainList);
  void goToReservations() =>
      _goToTabOrRoute(isTab: isController, tab: 1, route: Routes.reservations);
  void goToAvailability() =>
      _goToTabOrRoute(isTab: isController, tab: 3, route: Routes.availability);
  void goToPayments() =>
      _goToTabOrRoute(isTab: !isController, tab: 3, route: Routes.payments);
  void goToProfile() =>
      _goToTabOrRoute(isTab: true, tab: 4, route: Routes.profile);
  void goToNotifications() => Get.toNamed(Routes.notifications);
  void goToQrCheckIn() =>
      _goToTabOrRoute(isTab: true, tab: 2, route: Routes.qrCheckIn);
  void goToControllers() => Get.toNamed(Routes.controllers);
}
