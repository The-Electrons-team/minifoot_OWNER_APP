import 'package:get/get.dart';

import '../../../core/services/reservation_service.dart';
import '../../../core/widgets/app_snackbar.dart';

class QrCheckInController extends GetxController {
  final _service = ReservationService();

  final isProcessing = false.obs;
  final isConfirming = false.obs;
  final status = ''.obs;
  final message = ''.obs;
  final reservation = Rxn<Map<String, dynamic>>();
  final lastScannedCode = ''.obs;

  /// La caméra est refusée par le système (design écran 24).
  final cameraDenied = false.obs;

  /// Joueurs encore attendus dans l'heure qui suit (design écran 19).
  /// Chargé après une présence confirmée, pour enchaîner sans quitter l'écran.
  final upcomingWithinHour = 0.obs;

  Future<void> scanCode(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || isProcessing.value) return;

    isProcessing.value = true;
    lastScannedCode.value = code;

    try {
      final result = await _service.scanOwnerReservation(code);
      status.value = result['status']?.toString() ?? '';
      message.value = result['message']?.toString() ?? '';
      reservation.value = result['reservation'] is Map<String, dynamic>
          ? result['reservation'] as Map<String, dynamic>
          : null;
    } catch (_) {
      status.value = 'error';
      message.value = 'Impossible de lire ce QR code pour le moment';
      reservation.value = null;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> confirmCheckIn() async {
    final id = reservation.value?['id']?.toString();
    if (id == null || id.isEmpty || isConfirming.value) return false;

    isConfirming.value = true;
    try {
      final result = await _service.confirmOwnerCheckIn(id);
      status.value = result['status']?.toString() ?? 'checked_in';
      message.value = result['message']?.toString() ?? 'Présence confirmée';
      reservation.value = result['reservation'] is Map<String, dynamic>
          ? result['reservation'] as Map<String, dynamic>
          : reservation.value;
      _loadUpcomingWithinHour();
      return true;
    } catch (_) {
      AppSnackbar.error('Impossible de confirmer la présence. Réessayez.');
      return false;
    } finally {
      isConfirming.value = false;
    }
  }

  /// Compte les réservations confirmées du jour qui commencent dans l'heure
  /// et dont personne n'est encore entré. Échec silencieux : ce n'est qu'une
  /// indication, elle ne doit pas masquer la présence qui vient d'être prise.
  Future<void> _loadUpcomingWithinHour() async {
    try {
      final result = await _service.getOwnerReservations(status: 'CONFIRMED');
      final now = DateTime.now();
      final limit = now.add(const Duration(hours: 1));
      var count = 0;
      for (final item in result.items) {
        if (item is! Map<String, dynamic>) continue;
        if (item['checkedInAt'] != null) continue;
        final date = DateTime.tryParse(item['date']?.toString() ?? '')?.toLocal();
        final slot = item['startSlot']?.toString() ?? '';
        if (date == null || slot.isEmpty) continue;
        if (date.year != now.year || date.month != now.month || date.day != now.day) {
          continue;
        }
        final parts = slot.split(RegExp(r'[hH:]'));
        final start = DateTime(
          date.year,
          date.month,
          date.day,
          int.tryParse(parts.first) ?? 0,
          parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
        );
        if (start.isAfter(now) && start.isBefore(limit)) count++;
      }
      upcomingWithinHour.value = count;
    } catch (_) {
      upcomingWithinHour.value = 0;
    }
  }

  void resetScan() {
    status.value = '';
    message.value = '';
    reservation.value = null;
    lastScannedCode.value = '';
  }

  // ── Créneau pas encore commencé (design écran 22) ────────────────────────
  // Contrôle purement local : le backend valide le billet, l'app prévient
  // simplement que l'heure n'y est pas encore. Au-delà de 30 min d'avance on
  // affiche l'avertissement ; en deçà c'est une arrivée en avance normale.
  static const _earlyThreshold = Duration(minutes: 30);

  DateTime? get _slotStart {
    final data = reservation.value;
    if (data == null) return null;
    final date = DateTime.tryParse(data['date']?.toString() ?? '')?.toLocal();
    final slot = data['startSlot']?.toString() ?? '';
    if (date == null || slot.isEmpty) return null;
    final parts = slot.split(RegExp(r'[hH:]'));
    if (parts.isEmpty) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.tryParse(parts[0]) ?? 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  bool get isTooEarly {
    if (status.value != 'ready') return false;
    final start = _slotStart;
    if (start == null) return false;
    return start.difference(DateTime.now()) > _earlyThreshold;
  }

  /// « dans 1 h 47 » — délai restant avant le début du créneau.
  String get timeUntilSlot {
    final start = _slotStart;
    if (start == null) return '';
    final diff = start.difference(DateTime.now());
    if (diff.isNegative) return '';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours == 0) return 'dans $minutes min';
    return 'dans $hours h ${minutes.toString().padLeft(2, '0')}';
  }
}
