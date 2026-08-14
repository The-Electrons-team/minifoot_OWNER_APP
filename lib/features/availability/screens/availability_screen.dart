import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../routes/app_routes.dart';
import '../controllers/availability_controller.dart';
import '../controllers/availability_range_helper.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Screen principal
// ══════════════════════════════════════════════════════════════════════════════

class AvailabilityScreen extends GetView<AvailabilityController> {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // AppBar + Calendrier dans un bloc scrollable fixe en haut
          _buildStickyHeader(context),
          // Contenu scrollable en bas (créneaux) — swipe gauche/droite pour changer de jour
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -200) {
                  // Swipe gauche → jour suivant
                  HapticFeedback.selectionClick();
                  controller.goToAdjacentDay(1);
                } else if (details.primaryVelocity! > 200) {
                  // Swipe droite → jour précédent
                  HapticFeedback.selectionClick();
                  controller.goToAdjacentDay(-1);
                }
              },
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const _SlotsShimmer();
                }
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: RefreshIndicator(
                    key: ValueKey(controller.selectedDate.value),
                    color: kGreen,
                    onRefresh: controller.refreshAvailability,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(child: _buildSlotsSection(context)),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      // FAB pour bloquer/débloquer en lot (bonne pratique : action principale accessible)
      floatingActionButton: _buildFab(),
    );
  }

  // ── AppBar + Terrain selector + Stats + Calendrier ───────────────────────────
  Widget _buildStickyHeader(BuildContext context) {
    return Container(
      color: kBgCard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAppBar(context),
          _buildTerrainSelector(),
          _buildCalendar(),
          Container(height: 1, color: kDivider),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 8),
      child: Row(
        children: [
          // Bouton retour
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: kBgSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsRegular.caretLeft,
                  color: kTextPrim,
                  size: 16,
                ),
              ),
            ),
          ),
          // Titre centré sur 2 lignes
          const Expanded(
            child: Text(
              'Créneaux',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kGreen,
              ),
            ),
          ),
          // Toggle mois / semaine
          Obx(
            () => GestureDetector(
              onTap: controller.isController ? null : controller.toggleFormat,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kGreenLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.isController ||
                              controller.calendarFormat.value == 'month'
                          ? PhosphorIconsRegular.calendar
                          : PhosphorIconsRegular.calendarBlank,
                      size: 16,
                      color: kGreen,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      controller.isController ||
                              controller.calendarFormat.value == 'month'
                          ? 'Semaine'
                          : 'Mois',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sélecteur de terrain ─────────────────────────────────────────────────────
  Widget _buildTerrainSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Obx(() {
        if (controller.isLoadingTerrains.value) {
          return Container(
                height: 42,
                decoration: BoxDecoration(
                  color: kBgSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: kBgCard);
        }

        if (controller.terrains.isEmpty) {
          return const _NoTerrainChip();
        }

        final terrains = controller.terrains;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              color: kBgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(3),
            child: IntrinsicHeight(
              child: Row(
                children: List.generate(terrains.length, (i) {
                  final terrain = terrains[i];
                  final selected = controller.isTerrainSelected(terrain);
                  final label = terrain.isComplexView
                      ? terrain.complexName
                      : terrain.isMiniTerrain
                      ? terrain.name
                      : terrain.complexName;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.selectTerrain(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      constraints: const BoxConstraints(maxWidth: 140),
                      margin: EdgeInsets.only(
                        right: i < terrains.length - 1 ? 3 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? kGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : kTextSub,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Calendrier table_calendar ────────────────────────────────────────────────
  Widget _buildCalendar() {
    return Obx(() {
      final isMonth = controller.calendarFormat.value == 'month';
      return TableCalendar(
        firstDay: controller.firstSelectableDay,
        lastDay: controller.lastSelectableDay,
        focusedDay: controller.focusedDay.value,
        selectedDayPredicate: (day) =>
            controller.isSameDay(day, controller.selectedDate.value),
        calendarFormat: controller.isController || !isMonth
            ? CalendarFormat.week
            : CalendarFormat.month,
        onDaySelected: controller.onDaySelected,
        onPageChanged: controller.onPageChanged,
        eventLoader: controller.getEventsForDay,
        enabledDayPredicate: controller.canAccessDate,

        // ── Marqueurs personnalisés ───────────────────────────────────────────
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            final count = events.length;
            // Plus il y a de réservations, plus la barre est pleine et foncée
            final intensity = (count / 3).clamp(0.0, 1.0);
            final barColor = Color.lerp(
              const Color(0xFFFCD34D), // or clair
              const Color(0xFFD97706), // or foncé
              intensity,
            )!;
            return Positioned(
              bottom: 4,
              left: 6,
              right: 6,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          },
        ),

        // ── Style ─────────────────────────────────────────────────────────────
        calendarStyle: CalendarStyle(
          // Jours normaux
          defaultTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: kTextPrim,
          ),
          weekendTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kGold,
          ),
          // Jour sélectionné
          selectedDecoration: const BoxDecoration(
            color: kGreen,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          // Aujourd'hui
          todayDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: kGreen, width: 2),
          ),
          todayTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kGreen,
          ),
          // Jours hors du mois courant
          outsideDaysVisible: false,
          // Marqueurs d'événements
          markerDecoration: const BoxDecoration(
            color: kGold,
            shape: BoxShape.circle,
          ),
          markerSize: 5,
          markersMaxCount: 3,
          markerMargin: const EdgeInsets.only(top: 2),
          cellMargin: const EdgeInsets.all(4),
        ),

        // ── Header du calendrier ──────────────────────────────────────────────
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kTextPrim,
          ),
          leftChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kBgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              PhosphorIconsRegular.caretLeft,
              color: kTextSub,
              size: 20,
            ),
          ),
          rightChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kBgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              PhosphorIconsRegular.caretRight,
              color: kTextSub,
              size: 20,
            ),
          ),
          headerPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        ),

        // ── Noms des jours de la semaine ──────────────────────────────────────
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: kTextSub,
          ),
          weekendStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: kGold,
          ),
        ),

        locale: 'fr_FR',
      );
    });
  }

  // ── Section créneaux organisée par période ──────────────────────────────────
  Widget _buildSlotsSection(BuildContext context) {
    return Obx(() {
      final slots = controller.slots;
      if (controller.isLoadingTerrains.value) {
        return const SizedBox.shrink();
      }
      if (controller.terrains.isEmpty) {
        return const _AvailabilityEmptyState(showCreateButton: true);
      }
      if (slots.isEmpty) {
        return const _AvailabilityEmptyState();
      }

      // Séparer par périodes
      final morning = slots.where((s) => _hourOf(s.time) < 12).toList();
      final afternoon = slots
          .where((s) => _hourOf(s.time) >= 12 && _hourOf(s.time) < 17)
          .toList();
      final evening = slots.where((s) => _hourOf(s.time) >= 17).toList();

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDayOverview(),
            const SizedBox(height: 18),

            // ── Matin ────────────────────────────────────────────────────
            if (morning.isNotEmpty) ...[
              _PeriodHeader(
                label: 'Matin',
                icon: PhosphorIconsRegular.sun,
                color: kGold,
                count: morning.where((s) => s.isBooked).length,
                total: morning.length,
              ),
              const SizedBox(height: 8),
              _buildSlotGrid(morning, context, 0),
              const SizedBox(height: 18),
            ],

            // ── Après-midi ───────────────────────────────────────────────
            if (afternoon.isNotEmpty) ...[
              _PeriodHeader(
                label: 'Après-midi',
                icon: PhosphorIconsRegular.cloud,
                color: kBlue,
                count: afternoon.where((s) => s.isBooked).length,
                total: afternoon.length,
              ),
              const SizedBox(height: 8),
              _buildSlotGrid(afternoon, context, morning.length),
              const SizedBox(height: 18),
            ],

            // ── Soirée ───────────────────────────────────────────────────
            if (evening.isNotEmpty) ...[
              _PeriodHeader(
                label: 'Soirée',
                icon: PhosphorIconsRegular.moon,
                color: const Color(0xFF7C3AED),
                count: evening.where((s) => s.isBooked).length,
                total: evening.length,
              ),
              const SizedBox(height: 8),
              _buildSlotGrid(
                evening,
                context,
                morning.length + afternoon.length,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildSlotGrid(
    List<TimeSlot> slots,
    BuildContext context,
    int animOffset,
  ) {
    return Column(
      children: List.generate(slots.length, (i) {
        final slot = slots[i];
        final isNow = _isCurrentHourSlot(slot.time);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child:
              _SlotCard(
                    slot: slot,
                    isNow: isNow,
                    onTap: () => _onSlotTap(context, slot),
                    onLongPress: () async {
                      if (slot.isBooked) return;
                      if (!controller.canToggleRange(slot.time, 2)) {
                        AppSnackbar.warning(
                          'Le blocage rapide nécessite au moins 1h de créneaux continus libres.',
                        );
                        return;
                      }
                      HapticFeedback.heavyImpact();
                      final wasBlocked = slot.isBlocked;
                      final ok = await controller.toggleBlockRange(
                        slot.time,
                        2,
                      );
                      if (!ok) return;
                      AppSnackbar.success(
                        wasBlocked
                            ? 'Créneau débloqué : ${slot.time} → ${rangeEndTime(slot.time, 2)}'
                            : 'Créneau bloqué : ${slot.time} → ${rangeEndTime(slot.time, 2)}',
                      );
                    },
                  )
                  .animate()
                  .fadeIn(duration: 180.ms, delay: ((animOffset + i) * 18).ms)
                  .slideY(begin: 0.06, end: 0),
        );
      }),
    );
  }

  Widget _buildDayOverview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  PhosphorIconsFill.soccerBall,
                  color: kGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.selectedComplexLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextPrim,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.selectedUnitLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OverviewPill(
                  label: 'Libres',
                  value: controller.availableCount,
                  color: kGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewPill(
                  label: 'Réservés',
                  value: controller.bookedCount,
                  color: kGold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewPill(
                  label: 'Bloqués',
                  value: controller.blockedCount,
                  color: kTextSub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Occupation',
                style: TextStyle(
                  color: kTextSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                controller.occupancyLabel,
                style: const TextStyle(
                  color: kTextPrim,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: controller.occupancyRate,
                    minHeight: 6,
                    color: kGreen,
                    backgroundColor: kBgSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Vérifie si un créneau correspond à l'heure actuelle
  bool _isCurrentHourSlot(String time) {
    final now = DateTime.now();
    final hour = _hourOf(time);
    final selectedDay = controller.selectedDate.value;
    return controller.isSameDay(selectedDay, now) && hour == now.hour;
  }

  /// Extrait l'heure depuis "08h00"
  int _hourOf(String time) => int.tryParse(time.substring(0, 2)) ?? 0;

  // ── FAB ─────────────────────────────────────────────────────────────────────
  Widget _buildFab() {
    return Obx(() {
      if (controller.terrains.isEmpty ||
          controller.slots.isEmpty ||
          controller.isLoading.value ||
          controller.isLoadingTerrains.value) {
        return const SizedBox.shrink();
      }

      final isBusy = controller.isBulkUpdating.value;
      return FloatingActionButton.extended(
        onPressed: isBusy ? null : () => _showBulkActionSheet(),
        backgroundColor: isBusy ? kTextLight : kGreen,
        elevation: 3,
        icon: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : PhosphorIcon(
                PhosphorIconsDuotone.slidersHorizontal,
                color: Colors.white,
                size: 20,
              ),
        label: Text(
          isBusy ? 'Mise à jour' : 'Gérer',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      );
    });
  }

  // ── Tap sur un créneau → bottom sheet de détail ─────────────────────────────
  void _onSlotTap(BuildContext context, TimeSlot slot) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SlotDetailSheet(slot: slot, controller: controller),
    );
  }

  // ── Bottom sheet d'actions en lot ──────────────────────────────────────────
  void _showBulkActionSheet() {
    HapticFeedback.lightImpact();
    Get.bottomSheet(
      _BulkActionSheet(controller: controller),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Widget : Carte créneau
// ══════════════════════════════════════════════════════════════════════════════

class _SlotCard extends StatelessWidget {
  final TimeSlot slot;
  final bool isNow;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SlotCard({
    required this.slot,
    this.isNow = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AvailabilityController>();
    final accentColor = ctrl.slotColor(slot.status);
    final softColor = ctrl.slotBgColor(slot.status);
    final icon = ctrl.slotIcon(slot.status);
    final title = slot.isBooked && slot.bookedBy.isNotEmpty
        ? _truncate(slot.bookedBy, 28)
        : ctrl.slotLabel(slot.status);
    final subtitle = slot.isBooked
        ? 'Réservation confirmée'
        : slot.isBlocked
        ? 'Indisponible à la réservation'
        : 'Disponible à la réservation';

    return Material(
      color: kBgCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        splashColor: accentColor.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isNow ? kGreen : kBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 54,
                decoration: BoxDecoration(
                  color: isNow ? kGreen : accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 56,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      slot.time,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isNow ? kGreen : kTextPrim,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      slot.endTime,
                      style: const TextStyle(
                        fontSize: 11,
                        color: kTextSub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PhosphorIcon(icon, size: 19, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: kTextPrim,
                            ),
                          ),
                        ),
                        if (isNow) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kGreenLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Maintenant',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: kGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextSub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  ctrl.slotLabel(slot.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                PhosphorIconsRegular.caretRight,
                size: 20,
                color: kTextLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max - 1)}…' : s;
}

class _OverviewPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _OverviewPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: kTextSub,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Widget : En-tête de période (Matin / Après-midi / Soirée)
// ══════════════════════════════════════════════════════════════════════════════

class _PeriodHeader extends StatelessWidget {
  final String label;
  final dynamic icon;
  final Color color;
  final int count;
  final int total;

  const _PeriodHeader({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: kGoldLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count réservé${count > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: kGold,
              ),
            ),
          ),
        const Spacer(),
        Text(
          '$total créneaux',
          style: const TextStyle(fontSize: 10, color: kTextLight),
        ),
      ],
    );
  }
}

class _NoTerrainChip extends StatelessWidget {
  const _NoTerrainChip();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Aucun complexe',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: kTextSub,
        ),
      ),
    );
  }
}

class _AvailabilityEmptyState extends StatelessWidget {
  final bool showCreateButton;

  const _AvailabilityEmptyState({this.showCreateButton = false});

  @override
  Widget build(BuildContext context) {
    if (showCreateButton) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 44, 24, 0),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => Get.toNamed(Routes.terrainForm),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            icon: const PhosphorIcon(
              PhosphorIconsRegular.plus,
              size: 20,
              color: Colors.white,
            ),
            label: const Text(
              'Créer un complexe',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 44, 24, 0),
      child: Center(
        child: Text(
          'Aucun créneau',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: kTextSub,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Widget : Bottom sheet détail créneau
// ══════════════════════════════════════════════════════════════════════════════

class _SlotDetailSheet extends StatefulWidget {
  final TimeSlot slot;
  final AvailabilityController controller;

  const _SlotDetailSheet({required this.slot, required this.controller});

  @override
  State<_SlotDetailSheet> createState() => _SlotDetailSheetState();
}

class _SlotDetailSheetState extends State<_SlotDetailSheet> {
  late DateTime endDate;
  late String endTime;

  @override
  void initState() {
    super.initState();
    endDate = widget.controller.selectedDate.value;
    endTime = widget.slot.endTime;
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final controller = widget.controller;
    final accentColor = controller.slotColor(slot.status);
    final bgColor = controller.slotBgColor(slot.status);
    final actionEnabled = !slot.isBooked && _isPeriodValid(controller, slot);
    final endLabel = _formatDateLabel(endDate);

    return Container(
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: kElevatedShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Icône du statut
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(
              controller.slotIcon(slot.status),
              color: accentColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),

          // Heure
          Text(
            '${slot.time} → $endTime',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kTextPrim,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),

          // Statut badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              controller.slotLabel(slot.status),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (!slot.isBooked) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fin du blocage',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kTextSub,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      _PeriodFieldButton(
                        label: 'Date',
                        value: endLabel,
                        icon: PhosphorIconsRegular.calendarBlank,
                        onTap: () => _pickEndDate(context, controller),
                      ),
                      const SizedBox(height: 12),
                      _PeriodFieldButton(
                        label: 'Heure',
                        value: endTime,
                        icon: PhosphorIconsRegular.clock,
                        onTap: () => _pickEndTime(context, controller),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    actionEnabled
                        ? 'La plage sera appliquée du ${controller.selectedDateLabel} à ${slot.time} jusqu’au $endLabel à $endTime.'
                        : 'Choisis une date et une heure de fin après ${slot.time}.',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: kTextSub,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Info équipe si réservé
          if (slot.isBooked) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBgSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: kGoldLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.users,
                        color: kGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Équipe réservante',
                            style: TextStyle(fontSize: 11, color: kTextSub),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            slot.bookedBy,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kTextPrim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 8),
          ],

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SafeArea(
              top: false,
              child: slot.isBooked
                  // Réservé → juste fermer
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: Navigator.of(context).pop,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kBorder),
                        ),
                        child: const Text(
                          'Fermer',
                          style: TextStyle(
                            color: kTextSub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  // Libre ou Bloqué → action de toggle
                  : Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: Navigator.of(context).pop,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: kBorder),
                              ),
                              child: const Text(
                                'Annuler',
                                style: TextStyle(
                                  color: kTextSub,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: !actionEnabled
                                  ? null
                                  : () async {
                                      HapticFeedback.mediumImpact();
                                      final count = await controller
                                          .toggleBlockPeriod(
                                            startDate:
                                                controller.selectedDate.value,
                                            startTime: slot.time,
                                            endDate: endDate,
                                            endTime: endTime,
                                            unblock: slot.isBlocked,
                                          );
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop();
                                      AppSnackbar.success(
                                        count == 0
                                            ? 'Aucun créneau modifié.'
                                            : '$count créneau${count > 1 ? 'x' : ''} ${slot.isBlocked ? 'débloqué' : 'bloqué'}${count > 1 ? 's' : ''}.',
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                disabledBackgroundColor: kDivider,
                                backgroundColor: slot.isBlocked ? kGreen : kRed,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              icon: Icon(
                                slot.isBlocked
                                    ? PhosphorIconsRegular.lockOpen
                                    : PhosphorIconsFill.lock,
                                size: 18,
                              ),
                              label: Text(
                                slot.isBlocked
                                    ? 'Débloquer la plage'
                                    : 'Bloquer la plage',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPeriodValid(AvailabilityController controller, TimeSlot slot) {
    final startDate = DateTime(
      controller.selectedDate.value.year,
      controller.selectedDate.value.month,
      controller.selectedDate.value.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    if (normalizedEnd.isBefore(startDate)) return false;
    if (!controller.canAccessDate(normalizedEnd)) return false;
    if (normalizedEnd.isAtSameMomentAs(startDate)) {
      return _minutes(endTime) > _minutes(slot.time);
    }
    return true;
  }

  int _minutes(String time) {
    final parts = time.split('h');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatDateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _pickEndDate(
    BuildContext context,
    AvailabilityController controller,
  ) async {
    final firstDate = DateTime(
      controller.selectedDate.value.year,
      controller.selectedDate.value.month,
      controller.selectedDate.value.day,
    );
    final lastDate = DateTime(
      controller.lastSelectableDay.year,
      controller.lastSelectableDay.month,
      controller.lastSelectableDay.day,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate.isBefore(firstDate) ? firstDate : endDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kGreen,
              onPrimary: Colors.white,
              onSurface: kTextPrim,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: kGreen),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => endDate = picked);
  }

  Future<void> _pickEndTime(
    BuildContext context,
    AvailabilityController controller,
  ) async {
    final parts = endTime.split('h');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kGreen,
              onPrimary: Colors.white,
              onSurface: kTextPrim,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: kGreen),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );
    if (picked == null) return;
    final hour = picked.hour.toString().padLeft(2, '0');
    final minute = picked.minute.toString().padLeft(2, '0');
    setState(() => endTime = '${hour}h$minute');
  }
}

class _PeriodFieldButton extends StatelessWidget {
  final String label;
  final String value;
  final dynamic icon;
  final VoidCallback onTap;

  const _PeriodFieldButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBgSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              PhosphorIcon(icon, size: 16, color: kTextSub),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11, color: kTextSub),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kTextPrim,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Widget : Bottom sheet actions en lot
// ══════════════════════════════════════════════════════════════════════════════

class _BulkActionSheet extends StatelessWidget {
  final AvailabilityController controller;

  const _BulkActionSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Text(
              'Gérer les créneaux',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kTextPrim,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Appliquer une action sur tous les créneaux libres du jour',
              style: TextStyle(fontSize: 13, color: kTextSub, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // Action : Bloquer tous les créneaux libres
          _BulkActionTile(
            icon: PhosphorIconsFill.lock,
            iconColor: kRed,
            iconBg: kRedLight,
            title: 'Bloquer tous les créneaux libres',
            subtitle: 'Personne ne pourra réserver aujourd\'hui',
            onTap: () async {
              HapticFeedback.mediumImpact();
              final count = await controller.blockAllAvailable();
              Get.back();
              AppSnackbar.success(
                count == 0
                    ? 'Aucun créneau libre à bloquer.'
                    : '$count créneau${count > 1 ? 'x' : ''} bloqué${count > 1 ? 's' : ''}.',
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: kDivider, height: 1),
          ),

          // Action : Débloquer tous les créneaux bloqués
          _BulkActionTile(
            icon: PhosphorIconsRegular.lockOpen,
            iconColor: kGreen,
            iconBg: kGreenLight,
            title: 'Débloquer tous les créneaux',
            subtitle: 'Rendre disponibles les créneaux bloqués',
            onTap: () async {
              HapticFeedback.mediumImpact();
              final count = await controller.unblockAllBlocked();
              Get.back();
              AppSnackbar.success(
                count == 0
                    ? 'Aucun créneau bloqué à débloquer.'
                    : '$count créneau${count > 1 ? 'x' : ''} débloqué${count > 1 ? 's' : ''}.',
              );
            },
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kBorder),
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(
                      color: kTextSub,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkActionTile extends StatelessWidget {
  final dynamic icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BulkActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: PhosphorIcon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kTextPrim,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: kTextSub),
                  ),
                ],
              ),
            ),
            const Icon(
              PhosphorIconsRegular.caretRight,
              color: kTextLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Widget : Shimmer de chargement
// ══════════════════════════════════════════════════════════════════════════════

class _SlotsShimmer extends StatelessWidget {
  const _SlotsShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      itemCount: 8,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (_, i) =>
          Container(
                height: 78,
                decoration: BoxDecoration(
                  color: kBgSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: kBgCard),
    );
  }
}
