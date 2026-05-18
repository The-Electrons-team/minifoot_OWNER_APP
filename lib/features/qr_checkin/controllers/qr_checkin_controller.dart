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

  Future<void> confirmCheckIn() async {
    final id = reservation.value?['id']?.toString();
    if (id == null || id.isEmpty || isConfirming.value) return;

    isConfirming.value = true;
    try {
      final result = await _service.confirmOwnerCheckIn(id);
      status.value = result['status']?.toString() ?? 'checked_in';
      message.value = result['message']?.toString() ?? 'Présence confirmée';
      reservation.value = result['reservation'] is Map<String, dynamic>
          ? result['reservation'] as Map<String, dynamic>
          : reservation.value;
    } catch (_) {
      AppSnackbar.error('Impossible de confirmer la présence. Réessayez.');
    } finally {
      isConfirming.value = false;
    }
  }

  void resetScan() {
    status.value = '';
    message.value = '';
    reservation.value = null;
    lastScannedCode.value = '';
  }
}
