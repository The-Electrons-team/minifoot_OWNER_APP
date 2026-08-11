import 'package:get/get.dart';

import '../../../core/services/reservation_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../reservations/controllers/reservations_controller.dart';

/// Filtres de l'écran « Présences du jour » (écran 20 du design).
enum AttendanceFilter { all, expected }

/// Ce que devient une réservation confirmée du jour, vue depuis l'entrée du
/// terrain : déjà entrée (scannée ou pointée à la main), encore attendue, ou
/// absente parce que son créneau est passé.
enum AttendanceState { scanned, manual, expected, absent }

class AttendanceController extends GetxController {
  final _service = ReservationService();

  final reservations = <ReservationModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final filter = AttendanceFilter.all.obs;
  final terrainFilter = ''.obs;

  /// Réservation en cours de pointage — évite le double-tap sur « Entré ».
  final actingId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _service.getOwnerReservations(status: 'CONFIRMED');
      final now = DateTime.now();
      reservations.value =
          result.items
              .map((item) => ReservationModel.fromJson(item as Map<String, dynamic>))
              .where(
                (r) =>
                    r.rawDate != null &&
                    r.rawDate!.year == now.year &&
                    r.rawDate!.month == now.month &&
                    r.rawDate!.day == now.day,
              )
              .toList()
            ..sort((a, b) => a.startSlot.compareTo(b.startSlot));
    } catch (_) {
      errorMessage.value =
          'Impossible de charger les présences. Vérifiez votre connexion.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAttendance() => load();

  AttendanceState stateOf(ReservationModel r) {
    if (r.isCheckedIn) {
      return r.checkInMethod == 'MANUAL_OWNER'
          ? AttendanceState.manual
          : AttendanceState.scanned;
    }
    final start = _slotStart(r);
    if (start != null && DateTime.now().isAfter(start.add(const Duration(hours: 1)))) {
      return AttendanceState.absent;
    }
    return AttendanceState.expected;
  }

  static DateTime? _slotStart(ReservationModel r) {
    if (r.rawDate == null || r.startSlot.isEmpty) return null;
    final parts = r.startSlot.split(RegExp(r'[hH:]'));
    if (parts.isEmpty) return null;
    return DateTime(
      r.rawDate!.year,
      r.rawDate!.month,
      r.rawDate!.day,
      int.tryParse(parts[0]) ?? 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  int get enteredCount =>
      reservations.where((r) => r.isCheckedIn).length;

  int get expectedCount => reservations
      .where((r) => stateOf(r) == AttendanceState.expected)
      .length;

  /// Terrains présents dans la journée, pour le filtre par terrain.
  List<String> get terrains => reservations
      .map((r) => r.subTerrainName.isNotEmpty ? r.subTerrainName : r.terrain)
      .toSet()
      .toList()
    ..sort();

  List<ReservationModel> get visible {
    var list = reservations.toList();
    if (filter.value == AttendanceFilter.expected) {
      list = list.where((r) => stateOf(r) == AttendanceState.expected).toList();
    }
    if (terrainFilter.value.isNotEmpty) {
      list = list
          .where(
            (r) =>
                (r.subTerrainName.isNotEmpty ? r.subTerrainName : r.terrain) ==
                terrainFilter.value,
          )
          .toList();
    }
    return list;
  }

  void setFilter(AttendanceFilter value) => filter.value = value;

  void toggleTerrain(String terrain) =>
      terrainFilter.value = terrainFilter.value == terrain ? '' : terrain;

  /// Pointe une présence sans scanner : tracé comme validation manuelle côté
  /// backend, donc distinguable dans les rapports.
  Future<void> markEntered(ReservationModel r) async {
    if (actingId.value.isNotEmpty) return;
    actingId.value = r.id;
    try {
      await _service.confirmOwnerCheckIn(r.id, manual: true);
      AppSnackbar.success('${r.clientName} est entré.');
      await load();
    } catch (_) {
      AppSnackbar.error('Impossible de valider cette présence. Réessayez.');
    } finally {
      actingId.value = '';
    }
  }
}
