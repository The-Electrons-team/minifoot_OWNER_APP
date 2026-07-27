import 'package:get/get.dart';
import '../../../core/services/controller_service.dart';
import '../../../core/services/terrain_service.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';

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
  /// Message d'erreur du dernier chargement. Vide = pas d'erreur.
  ///
  /// Sans lui, un échec réseau se présentait comme une liste vide, message
  /// d'accueil compris — trompeur et sans moyen de réessayer.
  final errorMessage = ''.obs;

  /// Pagination.
  final currentPage = 1.obs;
  final isLoadingMore = false.obs;
  final total = 0.obs;

  bool get hasMore => controllers.length < total.value;
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
    errorMessage.value = '';
    try {
      currentPage.value = 1;
      final result = await _service.getControllers();
      total.value = result.total;
      controllers.value = result.items
          .map(
            (item) =>
                OwnerControllerModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      // Liste complète : elle alimente le sélecteur de complexes autorisés,
      // qui doit tous les proposer.
      final terrainData = await _terrainService.getAllMesTerrains();
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
      errorMessage.value =
          'Impossible de charger les contrôleurs. Vérifiez votre connexion.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Charge la page suivante. Échec silencieux : la liste affichée est conservée.
  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value || !hasMore) return;
    isLoadingMore.value = true;
    try {
      final result = await _service.getControllers(page: currentPage.value + 1);
      controllers.addAll(
        result.items.map(
          (item) => OwnerControllerModel.fromJson(item as Map<String, dynamic>),
        ),
      );
      currentPage.value += 1;
      total.value = result.total;
    } catch (_) {
      // volontairement silencieux
    } finally {
      isLoadingMore.value = false;
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
      AppSnackbar.error('Impossible de créer le contrôleur. Réessayez.');
      return null;
    }
  }

  Future<void> toggleActive(OwnerControllerModel controller) async {
    // La désactivation se faisait instantanément au tap : elle retire à
    // quelqu'un l'accès au scan des QR et à la gestion des créneaux, elle
    // mérite une confirmation.
    if (controller.isActive) {
      final confirmed = await AppDialog.confirm(
        title: 'Désactiver ce contrôleur ?',
        message:
            '${controller.fullName} ne pourra plus scanner les QR codes ni '
            'gérer les créneaux des complexes autorisés.',
        confirmLabel: 'Désactiver',
        destructive: true,
      );
      if (!confirmed) return;
    }

    try {
      await _service.updateController(controller.id, {
        'isActive': !controller.isActive,
      });
      await refreshAll();
    } catch (_) {
      AppSnackbar.error('Impossible de modifier ce contrôleur. Réessayez.');
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
      AppSnackbar.error('Impossible de modifier les complexes du contrôleur. Réessayez.');
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
      AppSnackbar.error('Impossible de charger l\'activité. Réessayez.');
    } finally {
      isLoadingActivity.value = false;
    }
  }
}
