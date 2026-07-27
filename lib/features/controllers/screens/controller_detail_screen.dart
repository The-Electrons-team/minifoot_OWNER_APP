import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/utils/app_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/controllers_controller.dart';

class ControllerDetailScreen extends StatefulWidget {
  const ControllerDetailScreen({super.key});

  @override
  State<ControllerDetailScreen> createState() => _ControllerDetailScreenState();
}

class _ControllerDetailScreenState extends State<ControllerDetailScreen> {
  late final ControllersController controller;
  late OwnerControllerModel item;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ControllersController>();
    item = Get.arguments as OwnerControllerModel;
    controller.loadActivity(item.id);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            PhosphorIconsRegular.caretLeft,
            size: 18,
          ),
        ),
        title: const Text(
          'Détail controller',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: kGreen,
        onRefresh: () => controller.loadActivity(item.id),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _IdentityCard(item: item),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Scans',
                    value: '${item.scans}',
                    icon: PhosphorIconsDuotone.qrCode,
                    color: kBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'Présences',
                    value: '${item.confirmed}',
                    icon: PhosphorIconsDuotone.sealCheck,
                    color: kGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Créneaux bloqués',
                    value: '${item.blockedSlots}',
                    icon: PhosphorIconsDuotone.lock,
                    color: kGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Complexes autorisés',
              action: TextButton.icon(
                onPressed: _showComplexAssignmentSheet,
                icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 16),
                label: const Text('Modifier'),
                style: TextButton.styleFrom(
                  foregroundColor: kGreen,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              child: item.complexes.isEmpty
                  ? const Text(
                      'Aucun complexe assigné',
                      style: TextStyle(color: kTextSub, fontSize: 13),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.complexes
                          .map(
                            (complex) => Chip(
                              label: Text(complex),
                              backgroundColor: kGreenLight,
                              labelStyle: const TextStyle(
                                color: kGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Activité récente',
              child: Obx(() {
                if (controller.isLoadingActivity.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(color: kGreen),
                    ),
                  );
                }
                if (controller.activities.isEmpty) {
                  return const Text(
                    'Aucune activité récente',
                    style: TextStyle(color: kTextSub, fontSize: 13),
                  );
                }
                return Column(
                  children: controller.activities
                      .map((activity) => _ActivityTile(activity: activity))
                      .toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showComplexAssignmentSheet() {
    final selected = item.complexIds.toSet().obs;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Changer l’affectation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: kTextPrim,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.fullName.isEmpty ? item.phone : item.fullName,
                  style: const TextStyle(color: kTextSub, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (controller.terrains.isEmpty)
                  const Text(
                    'Aucun complexe disponible',
                    style: TextStyle(color: kTextSub, fontSize: 13),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.terrains.map((complex) {
                          final isSelected = selected.contains(complex.id);
                          return FilterChip(
                            selected: isSelected,
                            label: Text(complex.name),
                            selectedColor: kGreenLight,
                            checkmarkColor: kGreen,
                            onSelected: (_) {
                              isSelected
                                  ? selected.remove(complex.id)
                                  : selected.add(complex.id);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final updated = await controller.updateControllerComplexes(
                        item,
                        selected.toList(),
                      );
                      if (updated == null) return;
                      setState(() => item = updated);
                      Get.back();
                      AppSnackbar.success('Le contrôleur voit maintenant les créneaux des complexes sélectionnés.');
                    },
                    child: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final OwnerControllerModel item;

  const _IdentityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: item.isActive ? kGreenLight : kBgSurface,
            child: PhosphorIcon(PhosphorIconsDuotone.identificationBadge,
              color: item.isActive ? kGreen : kTextSub,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fullName.isEmpty ? 'Controller' : item.fullName,
                  style: const TextStyle(
                    color: kTextPrim,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.phone,
                  style: const TextStyle(color: kTextSub, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: item.isActive ? kGreenLight : kRedLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.isActive ? 'Actif' : 'Inactif',
              style: TextStyle(
                color: item.isActive ? kGreen : kRed,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final dynamic icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: kTextPrim,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: kTextSub,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _SectionCard({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: kTextPrim,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ControllerActivityModel activity;

  const _ActivityTile({required this.activity});

  Color get _resultColor {
    switch (activity.result) {
      case 'SUCCESS':
        return kGreen;
      case 'DENIED':
      case 'FAILED':
        return kRed;
      case 'NOT_FOUND':
      case 'ALREADY_DONE':
      default:
        return kGold;
    }
  }

  String get _subtitle {
    final parts = [
      if (activity.terrainName.isNotEmpty) activity.terrainName,
      if (activity.slot.isNotEmpty) activity.slot,
      if (activity.reservationReference.isNotEmpty)
        activity.reservationReference,
    ];
    if (parts.isEmpty) return 'Action enregistrée';
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final date = activity.createdAt == null
        ? ''
        : AppFormat.shortDateTime(activity.createdAt!.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _resultColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: PhosphorIcon(PhosphorIconsDuotone.clockCounterClockwise,
              color: _resultColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.actionLabel,
                  style: const TextStyle(
                    color: kTextPrim,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: const TextStyle(color: kTextSub, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity.resultLabel,
                style: TextStyle(
                  color: _resultColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(color: kTextLight, fontSize: 10),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
