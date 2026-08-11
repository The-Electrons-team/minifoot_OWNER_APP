import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/shimmer_loading.dart' show ShimmerBox;
import '../controllers/availability_controller.dart';

// Écrans 31 (Planning du jour) et 32 (Sélection multiple) du design.
class AvailabilityScreen extends GetView<AvailabilityController> {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final selecting = controller.isSelecting.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: selecting ? const _SelectionHeader() : const _DayHeader(),
              ),
              if (!selecting) ...[
                const SizedBox(height: 16),
                const _DayStrip(),
                const SizedBox(height: 18),
                const _SummaryLine(),
              ] else
                const SizedBox(height: 22),
              const SizedBox(height: 12),
              Expanded(child: _SlotList(selecting: selecting)),
              if (selecting) const _SelectionActionBar(),
            ],
          );
        }),
      ),
    );
  }
}

// ─── En-têtes ───────────────────────────────────────────────────────────────
class _DayHeader extends GetView<AvailabilityController> {
  const _DayHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareButton(
          icon: PhosphorIconsRegular.caretLeft,
          onTap: () => Get.back(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disponibilités',
                style: kArchivo(size: 21, weight: FontWeight.w800, color: kTextPrim, height: 1.15),
              ),
              const SizedBox(height: 3),
              Obx(
                () => Text(
                  controller.selectedUnitLabel,
                  style: kManrope(size: 12.5, weight: FontWeight.w400, color: kTextSub, height: 1.3),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Obx(
          () => controller.terrains.length > 1
              ? _SquareButton(
                  icon: PhosphorIconsRegular.slidersHorizontal,
                  onTap: () => _openTerrainPicker(context),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _openTerrainPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(18, 20, 18, 24 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choisir un terrain',
              style: kArchivo(size: 18, weight: FontWeight.w800, color: kTextPrim),
            ),
            const SizedBox(height: 14),
            Obx(
              () => Column(
                children: List.generate(controller.terrains.length, (i) {
                  final option = controller.terrains[i];
                  final selected = controller.isTerrainSelected(option);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      controller.selectTerrain(i);
                      Get.back();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? kGreenLight : kBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? kGreen : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.isComplexView
                                  ? option.name
                                  : '${option.complexName} — ${option.name}',
                              style: kManrope(
                                size: 14,
                                weight: FontWeight.w600,
                                color: selected ? const Color(0xFF00552C) : kTextPrim,
                              ),
                            ),
                          ),
                          if (selected)
                            const PhosphorIcon(PhosphorIconsBold.check, color: kGreen, size: 16),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionHeader extends GetView<AvailabilityController> {
  const _SelectionHeader();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.selectedTimes.length;
      return Row(
        children: [
          _SquareButton(icon: PhosphorIconsBold.x, onTap: controller.exitSelection),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0
                      ? 'Choisir des créneaux'
                      : '$count créneau${count > 1 ? 'x' : ''} choisi${count > 1 ? 's' : ''}',
                  style: kArchivo(size: 21, weight: FontWeight.w800, color: kTextPrim, height: 1.15),
                ),
                const SizedBox(height: 3),
                Text(
                  '${controller.selectedDateLabel} · ${controller.selectedUnitLabel}',
                  style: kManrope(size: 12.5, weight: FontWeight.w400, color: kTextSub, height: 1.3),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.selectAllSelectable,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                'Tout',
                style: kManrope(size: 13, weight: FontWeight.w700, color: kGreen),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ─── Bandeau de jours ───────────────────────────────────────────────────────
class _DayStrip extends GetView<AvailabilityController> {
  const _DayStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Obx(() {
        final first = controller.firstSelectableDay;
        final last = controller.lastSelectableDay;
        final days = <DateTime>[];
        var cursor = DateTime(first.year, first.month, first.day);
        while (!cursor.isAfter(last) && days.length < 21) {
          days.add(cursor);
          cursor = cursor.add(const Duration(days: 1));
        }
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: days.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final day = days[i];
            final selected = controller.isSameDay(day, controller.selectedDate.value);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.onDaySelected(day, day),
              child: Container(
                width: 48,
                decoration: BoxDecoration(
                  color: selected ? kGreen : kBgCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E', 'fr_FR').format(day).substring(0, 3).toUpperCase(),
                      style: kManrope(
                        size: 11,
                        weight: FontWeight.w600,
                        color: selected ? Colors.white.withValues(alpha: 0.8) : kTextSub,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('dd').format(day),
                      style: kArchivo(
                        size: 18,
                        weight: FontWeight.w700,
                        color: selected ? Colors.white : kTextPrim,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _SummaryLine extends GetView<AvailabilityController> {
  const _SummaryLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${controller.availableCount} libres · ${controller.bookedCount} réservés · ${controller.blockedCount} bloqués',
                style: kManrope(size: 13, weight: FontWeight.w600, color: kTextSub),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.slots.isEmpty ? null : controller.enterSelection,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                child: Text(
                  'Sélectionner',
                  style: kManrope(size: 13, weight: FontWeight.w700, color: kGreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Liste des créneaux ─────────────────────────────────────────────────────
class _SlotList extends GetView<AvailabilityController> {
  final bool selecting;

  const _SlotList({required this.selecting});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(height: 9),
          itemBuilder: (_, _) =>
              const ShimmerBox(width: double.infinity, height: 66, borderRadius: 18),
        );
      }
      if (controller.errorMessage.value.isNotEmpty) {
        return _ErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.refreshAvailability,
        );
      }
      final slots = controller.slots;
      if (slots.isEmpty) return const _EmptyState();

      return RefreshIndicator(
        color: kGreen,
        onRefresh: controller.refreshAvailability,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.fromLTRB(18, 0, 18, selecting ? 24 : 100),
          itemCount: slots.length,
          separatorBuilder: (_, _) => const SizedBox(height: 9),
          itemBuilder: (_, i) => _SlotRow(slot: slots[i], selecting: selecting),
        ),
      );
    });
  }
}

class _SlotRow extends GetView<AvailabilityController> {
  final TimeSlot slot;
  final bool selecting;

  const _SlotRow({required this.slot, required this.selecting});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectable = controller.isSelectable(slot);
      final selected = controller.selectedTimes.contains(slot.time);
      final busy = controller.isBulkUpdating.value;

      final (bg, timeColor, titleColor, subColor) = switch (slot.status) {
        SlotStatus.blocked => (kGoldLight, const Color(0xFF92400E), const Color(0xFF92400E), const Color(0xFFB45309)),
        _ => (kBgCard, kTextPrim, kTextPrim, kTextSub),
      };

      final title = switch (slot.status) {
        SlotStatus.booked => slot.bookedBy.isEmpty ? 'Réservé' : slot.bookedBy,
        SlotStatus.blocked => 'Bloqué',
        SlotStatus.available => 'Libre',
      };
      final subtitle = switch (slot.status) {
        SlotStatus.booked => selecting ? 'Réservé — non modifiable' : '${slot.time} → ${slot.endTime}',
        SlotStatus.blocked => 'Invisible pour les joueurs',
        SlotStatus.available => 'Visible par les joueurs',
      };

      return Opacity(
        opacity: selecting && !selectable ? 0.45 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: busy
              ? null
              : selecting
                  ? () => controller.toggleSelection(slot)
                  : slot.isBooked
                      ? null
                      : () => controller.toggleBlock(slot.time),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? kGreen : Colors.transparent,
                width: 2,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: kGreen.withValues(alpha: 0.5), blurRadius: 14, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Row(
              children: [
                if (selecting) ...[
                  _Checkbox(checked: selected, enabled: selectable),
                  const SizedBox(width: 12),
                ],
                SizedBox(
                  width: selecting ? 52 : 56,
                  child: Text(
                    slot.time,
                    style: kArchivo(size: 17, weight: FontWeight.w700, color: timeColor),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: kManrope(size: 14, weight: FontWeight.w600, color: titleColor, height: 1.25),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: kManrope(size: 12, weight: FontWeight.w400, color: subColor, height: 1.3),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!selecting) ...[
                  const SizedBox(width: 10),
                  _StatusBadge(status: slot.status),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  final bool enabled;

  const _Checkbox({required this.checked, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? kGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: checked
            ? null
            : Border.all(color: kTextPrim.withValues(alpha: enabled ? 0.2 : 0.12), width: 2),
      ),
      child: checked
          ? const PhosphorIcon(PhosphorIconsBold.check, color: Colors.white, size: 14)
          : null,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SlotStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      SlotStatus.booked => ('RÉSERVÉ', kGreenLight, const Color(0xFF00552C)),
      SlotStatus.blocked => ('LIBÉRER', Colors.white.withValues(alpha: 0.7), const Color(0xFF92400E)),
      SlotStatus.available => ('BLOQUER', kBg, kTextSub),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: kManrope(size: 11, weight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ─── Barre d'action groupée ─────────────────────────────────────────────────
class _SelectionActionBar extends GetView<AvailabilityController> {
  const _SelectionActionBar();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final times = controller.slots
          .where((slot) => controller.selectedTimes.contains(slot.time))
          .map((slot) => slot.time)
          .toList();
      if (times.isEmpty) return const SizedBox.shrink();

      final willBlock = controller.selectionWillBlock;
      final busy = controller.isBulkUpdating.value;

      return Container(
        padding: EdgeInsets.fromLTRB(18, 16, 18, 28 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: kTextPrim,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        times.join(' · '),
                        style: kArchivo(size: 15, weight: FontWeight.w700, color: Colors.white, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        willBlock
                            ? 'Ils deviendront invisibles pour les joueurs'
                            : 'Ils redeviendront réservables par les joueurs',
                        style: kManrope(
                          size: 12.5,
                          weight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.6),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.exitSelection,
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const PhosphorIcon(PhosphorIconsBold.x, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: busy
                  ? null
                  : () async {
                      final changed = await controller.applySelection();
                      if (changed > 0) {
                        AppSnackbar.success(
                          willBlock
                              ? '$changed créneau${changed > 1 ? 'x' : ''} bloqué${changed > 1 ? 's' : ''}.'
                              : '$changed créneau${changed > 1 ? 'x' : ''} libéré${changed > 1 ? 's' : ''}.',
                        );
                      }
                    },
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: busy ? kGold.withValues(alpha: 0.6) : kGold,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: kTextPrim, strokeWidth: 2),
                      )
                    : Text(
                        '${willBlock ? 'Bloquer' : 'Libérer'} ${times.length} créneau${times.length > 1 ? 'x' : ''}',
                        style: kManrope(size: 15, weight: FontWeight.w700, color: kTextPrim),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─── États ──────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEAE0),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const PhosphorIcon(PhosphorIconsRegular.calendarBlank, color: kTextSub, size: 40),
            ),
            const SizedBox(height: 22),
            Text(
              'Aucun créneau ce jour',
              textAlign: TextAlign.center,
              style: kArchivo(size: 21, weight: FontWeight.w800, color: kTextPrim, height: 1.25),
            ),
            const SizedBox(height: 10),
            Text(
              'Vérifiez les horaires d\'ouverture du terrain.',
              textAlign: TextAlign.center,
              style: kManrope(size: 14, weight: FontWeight.w400, color: kTextSub, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: kManrope(size: 14, weight: FontWeight.w600, color: kTextSub, height: 1.5),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onRetry(),
              child: Text(
                'Réessayer',
                style: kManrope(size: 14, weight: FontWeight.w700, color: kGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: kTextPrim.withValues(alpha: 0.08), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: PhosphorIcon(icon, color: kTextPrim, size: 20),
      ),
    );
  }
}
