import 'package:get/get.dart';
import '../../../core/services/controller_service.dart';
import '../../../core/services/terrain_service.dart';

class OwnerControllerModel {
  final String id;
  final String fullName;
  final String phone;
  final bool isActive;
  final int commissionPerCheckIn;
  final List<String> complexes;
  final List<String> complexIds;
  final int scans;
  final int confirmed;
  final int blockedSlots;
  final int amountEarned;

  OwnerControllerModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.isActive,
    required this.commissionPerCheckIn,
    required this.complexes,
    required this.complexIds,
    required this.scans,
    required this.confirmed,
    required this.blockedSlots,
    required this.amountEarned,
  });

  factory OwnerControllerModel.fromJson(Map<String, dynamic> json) {
    final firstName = (json['firstName'] ?? '').toString();
    final lastName = (json['lastName'] ?? '').toString();
    final stats = json['todayStats'] as Map<String, dynamic>? ?? {};
    final links = ((json['complexes'] ?? json['terrains']) as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return OwnerControllerModel(
      id: (json['id'] ?? '').toString(),
      fullName: '$firstName $lastName'.trim(),
      phone: (json['phone'] ?? '').toString(),
      isActive: json['isActive'] == true,
      commissionPerCheckIn: _asInt(json['commissionPerCheckIn']),
      complexes: links
          .map((item) => (item['name'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList(),
      complexIds: links
          .map((item) => (item['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(),
      scans: _asInt(stats['scans']),
      confirmed: _asInt(stats['confirmed']),
      blockedSlots: _asInt(stats['blockedSlots']),
      amountEarned: _asInt(stats['amountEarned']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ControllerActivityModel {
  final String id;
  final String action;
  final String result;
  final String terrainName;
  final String reservationReference;
  final String slot;
  final int amountEarned;
  final DateTime? createdAt;

  ControllerActivityModel({
    required this.id,
    required this.action,
    required this.result,
    required this.terrainName,
    required this.reservationReference,
    required this.slot,
    required this.amountEarned,
    required this.createdAt,
  });

  factory ControllerActivityModel.fromJson(Map<String, dynamic> json) {
    final terrain = json['terrain'] as Map<String, dynamic>?;
    final reservation = json['reservation'] as Map<String, dynamic>?;
    return ControllerActivityModel(
      id: (json['id'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      result: (json['result'] ?? '').toString(),
      terrainName: (terrain?['name'] ?? '').toString(),
      reservationReference: (reservation?['reference'] ?? '').toString(),
      slot: (json['slot'] ?? '').toString(),
      amountEarned: OwnerControllerModel._asInt(json['amountEarned']),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }

  String get actionLabel {
    switch (action) {
      case 'CHECK_IN_SCAN':
        return 'Scan QR';
      case 'CHECK_IN_CONFIRM':
        return 'Présence confirmée';
      case 'SLOT_BLOCK':
        return 'Créneau bloqué';
      case 'SLOT_UNBLOCK':
        return 'Créneau débloqué';
      default:
        return 'Action';
    }
  }

  String get resultLabel {
    switch (result) {
      case 'SUCCESS':
        return 'Réussi';
      case 'DENIED':
        return 'Refusé';
      case 'NOT_FOUND':
        return 'Introuvable';
      case 'ALREADY_DONE':
        return 'Déjà fait';
      case 'FAILED':
      default:
        return 'Échec';
    }
  }
}

class ControllerTerrainOption {
  final String id;
  final String name;

  ControllerTerrainOption({required this.id, required this.name});
}

class ControllersController extends GetxController {
  final _service = ControllerService();
  final _terrainService = TerrainService();

  final isLoading = false.obs;
  final isLoadingActivity = false.obs;
  final controllers = <OwnerControllerModel>[].obs;
  final terrains = <ControllerTerrainOption>[].obs;
  final activities = <ControllerActivityModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    try {
      final data = await _service.getControllers();
      controllers.value = data
          .map(
            (item) =>
                OwnerControllerModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      final terrainData = await _terrainService.getMesTerrains();
      terrains.value = terrainData
          .map(
            (item) => ControllerTerrainOption(
              id: (item['id'] ?? '').toString(),
              name: (item['name'] ?? '').toString(),
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList();
    } catch (_) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les controllers',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> createController({
    required String firstName,
    required String lastName,
    required String phone,
    required List<String> complexIds,
  }) async {
    try {
      final result = await _service.createController(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        complexIds: complexIds,
      );
      await refreshAll();
      return result['credentials'] as Map<String, dynamic>?;
    } catch (_) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le controller',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    }
  }

  Future<void> toggleActive(OwnerControllerModel controller) async {
    try {
      await _service.updateController(controller.id, {
        'isActive': !controller.isActive,
      });
      await refreshAll();
    } catch (_) {
      Get.snackbar(
        'Erreur',
        'Impossible de modifier ce controller',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<OwnerControllerModel?> updateControllerComplexes(
    OwnerControllerModel controller,
    List<String> complexIds,
  ) async {
    try {
      final data = await _service.updateController(controller.id, {
        'complexIds': complexIds,
      });
      final updated = OwnerControllerModel.fromJson(data);
      final index = controllers.indexWhere((item) => item.id == updated.id);
      if (index != -1) {
        controllers[index] = updated;
        controllers.refresh();
      }
      return updated;
    } catch (_) {
      Get.snackbar(
        'Erreur',
        'Impossible de modifier les complexes du controller',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    }
  }

  Future<void> loadActivity(String controllerId) async {
    isLoadingActivity.value = true;
    try {
      final data = await _service.getActivity(controllerId);
      activities.value = data
          .map(
            (item) =>
                ControllerActivityModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger l’activité',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoadingActivity.value = false;
    }
  }
}
