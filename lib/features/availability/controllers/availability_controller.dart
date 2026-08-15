import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_async.dart';
import '../../../core/services/terrain_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../auth/controllers/auth_controller.dart';
import 'availability_range_helper.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Modèles
// ══════════════════════════════════════════════════════════════════════════════

enum SlotStatus { available, booked, blocked }

class TimeSlot {
  final String time;
  final String endTime;
  final SlotStatus status;
  final String bookedBy;

  const TimeSlot({
    required this.time,
    required this.endTime,
    required this.status,
    this.bookedBy = '',
  });

  bool get isAvailable => status == SlotStatus.available;
  bool get isBooked => status == SlotStatus.booked;
  bool get isBlocked => status == SlotStatus.blocked;

  TimeSlot copyWith({SlotStatus? status}) => TimeSlot(
    time: time,
    endTime: endTime,
    status: status ?? this.status,
    bookedBy: bookedBy,
  );
}

class TerrainOption {
  final String id;
  final String name;
  final String? subTerrainId;
  final String? parentName;
  final bool isComplexView;

  const TerrainOption({
    required this.id,
    required this.name,
    this.subTerrainId,
    this.parentName,
    this.isComplexView = false,
  });

  bool get isMiniTerrain => subTerrainId != null && subTerrainId!.isNotEmpty;
  String get complexName => parentName ?? name;
}

// ══════════════════════════════════════════════════════════════════════════════
// Controller principal
// ══════════════════════════════════════════════════════════════════════════════

class AvailabilityController extends GetxController {
  final _service = TerrainService();
  final _auth = Get.find<AuthController>();

  final focusedDay = DateTime.now().obs;
  final selectedDate = DateTime.now().obs;
  final selectedTerrain = 0.obs;
  final selectedTerrainKey = ''.obs;
  final slots = <TimeSlot>[].obs;
  final isLoading = false.obs;
  final isLoadingTerrains = false.obs;
  final isBulkUpdating = false.obs;
  final errorMessage = ''.obs;

  final calendarFormat = 'week'.obs;

  final terrains = <TerrainOption>[].obs;
  final complexCount = 0.obs;
  int _slotsRequestId = 0;

  @override
  void onInit() {
    super.onInit();
    _loadTerrains();
  }

  // ── Chargement des terrains ─────────────────────────────────────────────────
  Future<void> _loadTerrains() async {
    isLoadingTerrains.value = true;
    errorMessage.value = '';
    try {
      final data = await _service.getAllMesTerrains();
      final options = <TerrainOption>[];
      var loadedComplexes = 0;
      for (final item in data) {
        final m = item as Map<String, dynamic>;
        final terrainId = m['id'] as String? ?? '';
        final terrainName = m['name'] as String? ?? '';
        if (terrainId.isEmpty) continue;
        loadedComplexes += 1;

        final subTerrains = (m['subTerrains'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .where((subTerrain) => subTerrain['isActive'] != false)
            .toList();

        if (subTerrains.isEmpty) {
          options.add(TerrainOption(id: terrainId, name: terrainName));
        } else {
          options.add(
            TerrainOption(
              id: terrainId,
              name: '$terrainName · Tout le complexe',
              parentName: terrainName,
              isComplexView: true,
            ),
          );
          for (final subTerrain in subTerrains) {
            final subTerrainId = subTerrain['id'] as String? ?? '';
            final subTerrainName = subTerrain['name'] as String? ?? '';
            if (subTerrainId.isEmpty || subTerrainName.isEmpty) continue;
            options.add(
              TerrainOption(
                id: terrainId,
                name: subTerrainName,
                subTerrainId: subTerrainId,
                parentName: terrainName,
              ),
            );
          }
        }
      }
      complexCount.value = loadedComplexes;
      terrains.value = options;
      if (selectedTerrain.value >= terrains.length) {
        selectedTerrain.value = 0;
      }
      if (terrains.isNotEmpty) {
        selectedTerrainKey.value = _optionKey(terrains[selectedTerrain.value]);
      } else {
        selectedTerrainKey.value = '';
      }
      if (terrains.isNotEmpty) {
        await _loadSlots(selectedDate.value);
      } else {
        slots.clear();
      }
    } catch (e) {
      complexCount.value = 0;
      errorMessage.value =
          'Impossible de charger vos terrains. Vérifiez votre connexion.';
    } finally {
      isLoadingTerrains.value = false;
    }
  }

  bool get isController => _auth.user.value?.isController == true;

  DateTime get firstSelectableDay => isController
      ? _today()
      : DateTime.now().subtract(const Duration(days: 365));

  DateTime get lastSelectableDay => isController
      ? _today()
      : DateTime.now().add(const Duration(days: 365));

  String get scopeLabel {
    if (isLoadingTerrains.value) return 'Chargement des complexes';
    if (terrains.isEmpty) return 'Aucun complexe disponible';
    if (isController) {
      return '${complexCount.value} complexe${complexCount.value > 1 ? 's' : ''} assigné${complexCount.value > 1 ? 's' : ''} • aujourd\'hui uniquement';
    }
    return '${complexCount.value} complexe${complexCount.value > 1 ? 's' : ''} • ${terrains.length} option${terrains.length > 1 ? 's' : ''}';
  }

  String get selectedComplexLabel {
    if (terrains.isEmpty) return 'Aucun complexe';
    return terrains[selectedTerrain.value].complexName;
  }

  String get selectedUnitLabel {
    if (terrains.isEmpty) return '';
    final selected = terrains[selectedTerrain.value];
    if (selected.isComplexView) return 'Vue globale du complexe';
    if (selected.isMiniTerrain) return selected.name;
    return 'Terrain principal';
  }

  // ── Sélection de date ───────────────────────────────────────────────────────
  void onDaySelected(DateTime day, DateTime focused) {
    if (!canAccessDate(day)) {
      AppSnackbar.info('Vous pouvez gérer uniquement les créneaux du jour.');
      return;
    }
    final clampedDay = _clampToAllowedRange(day);
    selectedDate.value = clampedDay;
    focusedDay.value = _clampToAllowedRange(focused);
    _loadSlots(clampedDay);
  }

  void onPageChanged(DateTime focused) {
    focusedDay.value = _clampToAllowedRange(focused);
  }

  void goToAdjacentDay(int delta) {
    final target = selectedDate.value.add(Duration(days: delta));
    if (!canAccessDate(target)) {
      AppSnackbar.info('Vous êtes limité aux créneaux du jour.');
      return;
    }
    onDaySelected(target, target);
  }

  // ── Sélection de terrain ────────────────────────────────────────────────────
  void selectTerrain(int index) {
    if (index < 0 || index >= terrains.length) return;
    selectedTerrain.value = index;
    selectedTerrainKey.value = _optionKey(terrains[index]);
    _loadSlots(selectedDate.value);
  }

  bool isTerrainSelected(TerrainOption option) =>
      selectedTerrainKey.value == _optionKey(option);

  String _optionKey(TerrainOption option) =>
      '${option.id}:${option.subTerrainId ?? 'all'}';

  void toggleFormat() {
    if (isController) {
      calendarFormat.value = 'week';
      return;
    }
    calendarFormat.value = calendarFormat.value == 'month' ? 'week' : 'month';
  }

  // ── Chargement des créneaux depuis l'API ─────────────────────────────────────
  Future<void> _loadSlots(DateTime date) async {
    if (terrains.isEmpty) return;
    if (!canAccessDate(date)) {
      slots.clear();
      return;
    }
    final requestId = ++_slotsRequestId;
    final selectedOption = terrains[selectedTerrain.value];
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final terrainId = selectedOption.id;
      final subTerrainId = selectedOption.subTerrainId;
      final dateStr = _formatDate(date);
      final data = await _service.getCreneaux(
        terrainId,
        dateStr,
        subTerrainId: subTerrainId,
      );

      if (requestId != _slotsRequestId ||
          terrains.isEmpty ||
          selectedTerrain.value >= terrains.length) {
        return;
      }
      final currentOption = terrains[selectedTerrain.value];
      if (currentOption.id != selectedOption.id ||
          currentOption.subTerrainId != selectedOption.subTerrainId) {
        return;
      }

      slots.value = data.map((item) {
        final m = item as Map<String, dynamic>;
        final time = m['slot'] as String;
        final rawStatus =
            m['status'] as String? ??
            ((m['available'] == true) ? 'available' : 'blocked');

        final status = switch (rawStatus) {
          'booked' => SlotStatus.booked,
          'blocked' => SlotStatus.blocked,
          _ => SlotStatus.available,
        };

        return TimeSlot(
          time: time,
          endTime: _addThirtyMin(time),
          status: status,
        );
      }).toList();
    } catch (e) {
      if (requestId != _slotsRequestId) return;
      errorMessage.value = 'Impossible de charger les créneaux. Réessayez.';
    } finally {
      if (requestId == _slotsRequestId) {
        isLoading.value = false;
      }
    }
  }

  Future<void> refreshAvailability() async {
    await _loadTerrains();
  }

  // ── Bloquer / Débloquer un créneau ─────────────────────────────────────────
  Future<bool> toggleBlock(String time, {bool silent = false}) async {
    final idx = slots.indexWhere((s) => s.time == time);
    if (idx == -1 || slots[idx].isBooked || terrains.isEmpty) return false;

    final terrainId = terrains[selectedTerrain.value].id;
    final dateStr = _formatDate(selectedDate.value);
    final isCurrentlyBlocked = slots[idx].isBlocked;

    // Mise à jour optimiste
    slots[idx] = slots[idx].copyWith(
      status: isCurrentlyBlocked ? SlotStatus.available : SlotStatus.blocked,
    );
    slots.refresh();

    try {
      if (isCurrentlyBlocked) {
        await _service.debloquerCreneau(
          terrainId,
          dateStr,
          time,
          subTerrainId: terrains[selectedTerrain.value].subTerrainId,
        );
      } else {
        await _service.bloquerCreneau(
          terrainId,
          dateStr,
          time,
          subTerrainId: terrains[selectedTerrain.value].subTerrainId,
        );
      }
      await _loadSlots(selectedDate.value);
      return true;
    } catch (_) {
      // Annulation en cas d'erreur
      slots[idx] = slots[idx].copyWith(
        status: isCurrentlyBlocked ? SlotStatus.blocked : SlotStatus.available,
      );
      slots.refresh();
      if (!silent) {
        AppSnackbar.error('Impossible de modifier ce créneau. Réessayez.');
      }
      return false;
    }
  }

  bool canToggleRange(String time, int slotCount) {
    final idx = slots.indexWhere((slot) => slot.time == time);
    if (idx == -1 || terrains.isEmpty) return false;

    final startSlot = slots[idx];
    if (startSlot.isBooked) return false;

    final expectedTimes = buildTimeRange(time, slotCount);
    final rangeSlots = <TimeSlot>[];

    for (final expectedTime in expectedTimes) {
      final slotIndex = slots.indexWhere((slot) => slot.time == expectedTime);
      if (slotIndex == -1) return false;
      rangeSlots.add(slots[slotIndex]);
    }

    if (startSlot.isBlocked) {
      return rangeSlots.every((slot) => slot.isBlocked);
    }

    return rangeSlots.every((slot) => slot.isAvailable);
  }

  Future<bool> toggleBlockRange(
    String time,
    int slotCount, {
    bool silent = false,
  }) async {
    if (!canToggleRange(time, slotCount)) {
      if (!silent) {
        AppSnackbar.warning('Sélectionnez une plage continue de $slotCount créneau${slotCount > 1 ? 'x' : ''} libre${slotCount > 1 ? 's' : ''}.');
      }
      return false;
    }

    final rangeTimes = buildTimeRange(time, slotCount);
    final startIdx = slots.indexWhere((slot) => slot.time == time);
    if (startIdx == -1) return false;

    final shouldUnblock = slots[startIdx].isBlocked;
    final originalStatuses = <String, SlotStatus>{
      for (final rangeTime in rangeTimes)
        rangeTime: slots.firstWhere((slot) => slot.time == rangeTime).status,
    };

    for (final rangeTime in rangeTimes) {
      final idx = slots.indexWhere((slot) => slot.time == rangeTime);
      slots[idx] = slots[idx].copyWith(
        status: shouldUnblock ? SlotStatus.available : SlotStatus.blocked,
      );
    }
    slots.refresh();

    try {
      for (final rangeTime in rangeTimes) {
        if (shouldUnblock) {
          await _service.debloquerCreneau(
            terrains[selectedTerrain.value].id,
            _formatDate(selectedDate.value),
            rangeTime,
            subTerrainId: terrains[selectedTerrain.value].subTerrainId,
          );
        } else {
          await _service.bloquerCreneau(
            terrains[selectedTerrain.value].id,
            _formatDate(selectedDate.value),
            rangeTime,
            subTerrainId: terrains[selectedTerrain.value].subTerrainId,
          );
        }
      }
      await _loadSlots(selectedDate.value);
      return true;
    } catch (_) {
      for (final rangeTime in rangeTimes) {
        final idx = slots.indexWhere((slot) => slot.time == rangeTime);
        slots[idx] = slots[idx].copyWith(status: originalStatuses[rangeTime]);
      }
      slots.refresh();
      if (!silent) {
        AppSnackbar.error('Impossible de modifier la plage sélectionnée. Réessayez.');
      }
      return false;
    }
  }

  Future<int> toggleBlockPeriod({
    required DateTime startDate,
    required String startTime,
    required DateTime endDate,
    required String endTime,
    required bool unblock,
  }) async {
    if (terrains.isEmpty || isBulkUpdating.value) return 0;

    final start = _startOfDay(startDate);
    final end = _startOfDay(endDate);
    final startMinutes = _parseSlotMinutes(startTime);
    final endMinutes = _parseSlotMinutes(endTime);
    if (start.isAfter(end)) return 0;
    if (isSameDay(start, end) && endMinutes <= startMinutes) return 0;

    // On énumère d'abord toute la plage, puis on l'envoie par lots concurrents :
    // l'API travaille créneau par créneau, et une boucle séquentielle payait la
    // latence réseau des centaines de fois sur une plage de plusieurs jours.
    final targets = <({DateTime day, String slot})>[];
    var day = start;
    while (!day.isAfter(end)) {
      final from = isSameDay(day, start) ? startMinutes : 8 * 60;
      final to = isSameDay(day, end) ? endMinutes : 24 * 60;
      for (var minutes = from; minutes < to; minutes += 30) {
        targets.add((day: day, slot: _formatSlotMinutes(minutes)));
      }
      day = day.add(const Duration(days: 1));
    }

    isBulkUpdating.value = true;
    try {
      final terrain = terrains[selectedTerrain.value];
      final results = await AppAsync.mapBounded(targets, (target) async {
        try {
          if (unblock) {
            await _service.debloquerCreneau(
              terrain.id,
              _formatDate(target.day),
              target.slot,
              subTerrainId: terrain.subTerrainId,
            );
          } else {
            await _service.bloquerCreneau(
              terrain.id,
              _formatDate(target.day),
              target.slot,
              subTerrainId: terrain.subTerrainId,
            );
          }
          return true;
        } catch (_) {
          // Un créneau déjà réservé ou déjà dans l'état demandé ne doit pas
          // empêcher le reste de la plage de se traiter.
          return false;
        }
      });

      await _loadSlots(selectedDate.value);
      return results.where((ok) => ok).length;
    } finally {
      isBulkUpdating.value = false;
    }
  }

  Future<int> blockAllAvailable() async {
    return _bulkToggle(
      slots.where((slot) => slot.isAvailable).map((slot) => slot.time).toList(),
    );
  }

  Future<int> unblockAllBlocked() async {
    return _bulkToggle(
      slots.where((slot) => slot.isBlocked).map((slot) => slot.time).toList(),
    );
  }

  Future<int> _bulkToggle(List<String> times) async {
    if (times.isEmpty || isBulkUpdating.value) return 0;
    isBulkUpdating.value = true;
    var successCount = 0;
    try {
      for (final time in times) {
        final ok = await toggleBlock(time, silent: true);
        if (ok) successCount++;
      }
      return successCount;
    } finally {
      isBulkUpdating.value = false;
    }
  }

  // ── Marqueurs calendrier ────────────────────────────────────────────────────
  List<SlotStatus> getEventsForDay(DateTime day) {
    if (!isSameDay(day, selectedDate.value)) return [];
    return slots
        .where((slot) => slot.isBooked || slot.isBlocked)
        .map((slot) => slot.status)
        .toList();
  }

  bool hasBookingsOnDay(DateTime day) =>
      getEventsForDay(day).any((status) => status == SlotStatus.booked);

  // ── Statistiques ────────────────────────────────────────────────────────────
  int get availableCount => slots.where((s) => s.isAvailable).length;
  int get bookedCount => slots.where((s) => s.isBooked).length;
  int get blockedCount => slots.where((s) => s.isBlocked).length;

  String get occupancyLabel {
    final total = slots.length;
    if (total == 0) return '0%';
    return '${((bookedCount / total) * 100).round()}%';
  }

  double get occupancyRate {
    final total = slots.length;
    if (total == 0) return 0;
    return bookedCount / total;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool canAccessDate(DateTime date) {
    final day = _startOfDay(date);
    return !day.isBefore(_startOfDay(firstSelectableDay)) &&
        !day.isAfter(_startOfDay(lastSelectableDay));
  }

  DateTime _clampToAllowedRange(DateTime date) {
    final day = _startOfDay(date);
    final min = _startOfDay(firstSelectableDay);
    final max = _startOfDay(lastSelectableDay);
    if (day.isBefore(min)) return min;
    if (day.isAfter(max)) return max;
    return day;
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _today() => _startOfDay(DateTime.now());

  String _addThirtyMin(String time) {
    final parts = time.split('h');
    int h = int.parse(parts[0]);
    int m = int.parse(parts[1]);
    m += 30;
    if (m >= 60) {
      m -= 60;
      h += 1;
    }
    return '${h.toString().padLeft(2, '0')}h${m.toString().padLeft(2, '0')}';
  }

  int _parseSlotMinutes(String time) {
    final parts = time.split('h');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatSlotMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}h${m.toString().padLeft(2, '0')}';
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isToday(DateTime day) => isSameDay(day, DateTime.now());
  bool isBeforeToday(DateTime day) => day.isBefore(
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  );

  static const monthNames = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  static const dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  String get selectedMonthYear {
    final d = focusedDay.value;
    return '${monthNames[d.month - 1]} ${d.year}';
  }

  String get selectedDateLabel {
    final d = selectedDate.value;
    final dayName = dayNames[d.weekday - 1];
    return '$dayName ${d.day} ${monthNames[d.month - 1]}';
  }

  Color slotColor(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return kGreen;
      case SlotStatus.booked:
        return kGold;
      case SlotStatus.blocked:
        return kRed;
    }
  }

  Color slotBgColor(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return kGreenLight;
      case SlotStatus.booked:
        return kGoldLight;
      case SlotStatus.blocked:
        return kRedLight;
    }
  }

  String slotLabel(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return 'Libre';
      case SlotStatus.booked:
        return 'Réservé';
      case SlotStatus.blocked:
        return 'Bloqué';
    }
  }

  IconData slotIcon(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return PhosphorIconsRegular.checkCircle;
      case SlotStatus.booked:
        return PhosphorIconsRegular.users;
      case SlotStatus.blocked:
        return PhosphorIconsRegular.lock;
    }
  }
}
