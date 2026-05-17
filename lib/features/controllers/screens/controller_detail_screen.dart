import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/controllers_controller.dart';

class ControllerDetailScreen extends StatefulWidget {
  const ControllerDetailScreen({super.key});

  @override
  State<ControllerDetailScreen> createState() => _ControllerDetailScreenState();
}

class _ControllerDetailScreenState extends State<ControllerDetailScreen> {
  late final ControllersController controller;
  late final OwnerControllerModel item;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ControllersController>();
    item = Get.arguments as OwnerControllerModel;
    controller.loadActivity(item.id);
  }

  String _formatAmount(int amount) {
    final text = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return '${buffer.toString()} F CFA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: Icon(
            PhosphorIcons.arrowLeft(PhosphorIconsStyle.duotone),
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
                    icon: PhosphorIcons.qrCode(PhosphorIconsStyle.duotone),
                    color: kBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'Présences',
                    value: '${item.confirmed}',
                    icon: PhosphorIcons.sealCheck(PhosphorIconsStyle.duotone),
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
                    icon: PhosphorIcons.lock(PhosphorIconsStyle.duotone),
                    color: kGold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'Gain aujourd’hui',
                    value: _formatAmount(item.amountEarned),
                    icon: PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
                    color: kOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Terrains autorisés',
              child: item.terrains.isEmpty
                  ? const Text(
                      'Aucun terrain assigné',
                      style: TextStyle(color: kTextSub, fontSize: 13),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.terrains
                          .map(
                            (terrain) => Chip(
                              label: Text(terrain),
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
            child: Icon(
              PhosphorIcons.identificationBadge(PhosphorIconsStyle.duotone),
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
  final IconData icon;
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
          Icon(icon, color: color, size: 20),
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

  const _SectionCard({required this.title, required this.child});

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
          Text(
            title,
            style: const TextStyle(
              color: kTextPrim,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
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
        : DateFormat('dd/MM HH:mm').format(activity.createdAt!.toLocal());

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
            child: Icon(
              PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.duotone),
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
