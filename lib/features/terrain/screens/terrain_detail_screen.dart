import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_network_image.dart';
import '../controllers/terrain_controller.dart';

class TerrainDetailScreen extends GetView<TerrainController> {
  const TerrainDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final argument = Get.arguments;
    if (controller.selectedTerrain.value == null && argument is TerrainModel) {
      controller.selectedTerrain.value = argument;
    }

    return Obx(() {
      final terrain = controller.selectedTerrain.value;
      if (terrain == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final images = terrain.imageUrls.isNotEmpty
          ? terrain.imageUrls
          : [if (terrain.imageUrl != null) terrain.imageUrl!];

      return Scaffold(
        backgroundColor: kBg,
        body: RefreshIndicator(
          onRefresh: controller.refreshTerrains,
          color: kGreen,
          backgroundColor: kBgCard,
          child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // AppBar avec Image
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.back(),
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
              actions: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => controller.goToForm(terrain),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: kBgSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          PhosphorIconsLight.pencilSimple,
                          color: kGreen,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (images.isNotEmpty)
                      PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (index) => controller.currentPhotoIndex.value = index,
                        itemBuilder: (context, index) {
                          return AppNetworkImage(
                            url: images[index],
                            fallback: Container(
                              color: kGreenLight,
                              child: const Icon(
                                PhosphorIconsLight.soccerBall,
                                size: 64,
                                color: kGreen,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: kGreenLight,
                        child: const Icon(
                          PhosphorIconsLight.soccerBall,
                          size: 64,
                          color: kGreen,
                        ),
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black54,
                          ],
                        ),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: controller.currentPhotoIndex.value == index ? 20 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: controller.currentPhotoIndex.value == index
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                decoration: const BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                terrain.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: kTextPrim,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    PhosphorIconsLight.mapPin,
                                    color: kTextSub,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      terrain.address,
                                      style: const TextStyle(
                                        color: kTextSub,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: terrain.isActive
                                ? kGreenLight
                                : kRedLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            terrain.isActive ? 'Actif' : 'Pause',
                            style: TextStyle(
                              color: terrain.isActive
                                  ? kGreen
                                  : kRed,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Bar de navigation par onglets
                    Obx(() => Container(
                          height: 45,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: kBorder, width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              _Tab(
                                label: 'À propos',
                                index: 0,
                                selected: controller.selectedTabIndex.value == 0,
                                onTap: () => controller.selectedTabIndex.value = 0,
                              ),
                              _Tab(
                                label: 'Avis des clients',
                                index: 1,
                                selected: controller.selectedTabIndex.value == 1,
                                count: controller.reviews.length,
                                onTap: () => controller.selectedTabIndex.value = 1,
                              ),
                            ],
                          ),
                        )),

                    const SizedBox(height: 24),

                    // Contenu des onglets
                    Obx(() {
                      if (controller.selectedTabIndex.value == 0) {
                        return _AboutTab(terrain: terrain);
                      } else {
                        return _ReviewsTab(controller: controller);
                      }
                    }),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.goToForm(terrain),
                  icon: const Icon(PhosphorIconsLight.pencilSimple, size: 18),
                  label: const Text('Modifier le complexe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Terrain physique regroupé (FULL + HALF) ───────────────────────────────

class _PhysicalTerrainCard extends StatelessWidget {
  final List<SubTerrainModel> group;
  const _PhysicalTerrainCard({required this.group});

  static String _formatDays(List<int> days) {
    if (days.isEmpty) return 'Tous les jours';
    const n = {1: 'Lun', 2: 'Mar', 3: 'Mer', 4: 'Jeu', 5: 'Ven', 6: 'Sam', 0: 'Dim'};
    return days.map((d) => n[d] ?? '').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final first = group.first;
    final physicalName = first.physicalName ?? first.name.split(' - ').first;

    SubTerrainModel? fullSub;
    SubTerrainModel? halfSub;
    for (final s in group) {
      if (s.divisionType == 'FULL') fullSub ??= s;
      if (s.divisionType == 'HALF') halfSub ??= s;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kGreenLight,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    PhosphorIconsLight.soccerBall,
                    color: kGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        physicalName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: kTextPrim,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${first.type} • ${first.surface ?? 'Synthétique'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kTextSub,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: first.isActive ? kGreenLight : kRedLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    first.isActive ? 'Actif' : 'Pause',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: first.isActive ? kGreen : kRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Pricing sections
          if (fullSub != null || halfSub != null)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAF7),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                border: Border(top: BorderSide(color: kBorder)),
              ),
              child: Column(
                children: [
                  if (fullSub != null)
                    _PricingSection(
                      label: 'Terrain complet',
                      color: kGreen,
                      bg: kGreenLight,
                      sub: fullSub,
                      showDivider: halfSub != null,
                    ),
                  if (halfSub != null)
                    _PricingSection(
                      label: 'Demi terrain',
                      color: kBlue,
                      bg: kBlueLight,
                      sub: halfSub,
                      showDivider: false,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final SubTerrainModel sub;
  final bool showDivider;

  const _PricingSection({
    required this.label,
    required this.color,
    required this.bg,
    required this.sub,
    required this.showDivider,
  });

  static String _formatDays(List<int> days) {
    if (days.isEmpty) return '';
    const n = {1: 'Lun', 2: 'Mar', 3: 'Mer', 4: 'Jeu', 5: 'Ven', 6: 'Sam', 0: 'Dim'};
    return days.map((d) => n[d] ?? '').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (sub.pricePerHour != null && sub.pricingPeriods.isEmpty) ...[
                const Spacer(),
                Text(
                  '${sub.pricePerHour} F/h',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (sub.pricingPeriods.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...sub.pricingPeriods.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final days = _formatDays(p.days);
            final isLast = i == sub.pricingPeriods.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kTextPrim,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(PhosphorIconsLight.clock, size: 11, color: kTextSub),
                                const SizedBox(width: 3),
                                Text(
                                  '${p.startTime} – ${p.endTime}',
                                  style: const TextStyle(fontSize: 11, color: kTextSub),
                                ),
                                if (days.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    days,
                                    style: const TextStyle(fontSize: 11, color: kTextLight),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${p.pricePerHour} F/h',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: color,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(color: kDivider, height: 20, indent: 14, endIndent: 14),
              ],
            );
          }),
        ],
        SizedBox(height: showDivider ? 12 : 14),
        if (showDivider) const Divider(color: kBorder, height: 1),
      ],
    );
  }
}

// ── Équipements & services ─────────────────────────────────────────────────

class _EquipmentGrid extends StatelessWidget {
  final List<String> items;
  const _EquipmentGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    const icons = <String, IconData>{
      'Éclairage': PhosphorIconsLight.lightbulb,
      'Vestiaires': PhosphorIconsLight.shirtFolded,
      'Ballon': PhosphorIconsLight.soccerBall,
      'Parking': PhosphorIconsLight.park,
      'Tribunes': PhosphorIconsLight.chair,
      'Wi-Fi': PhosphorIconsLight.wifiHigh,
      'Buvette': PhosphorIconsLight.coffee,
      'Douches': PhosphorIconsLight.shower,
      'Arbitre': PhosphorIconsLight.flag,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3.5,
        children: items.map((e) {
          final icon = icons[e] ?? PhosphorIconsLight.checks;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: kGreenLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: kGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kGreen,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  const _FormatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: kCardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(PhosphorIconsLight.users, size: 15, color: kGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kTextPrim,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: kTextPrim,
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final TerrainReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // `NetworkImage` ne gérait ni le cache ni l'échec : une URL
              // cassée laissait un cercle vide et une exception non traitée.
              AppNetworkImage(
                url: review.userAvatar,
                width: 36,
                height: 36,
                borderRadius: BorderRadius.circular(18),
                fallback: Container(
                  width: 36,
                  height: 36,
                  color: kGreenLight,
                  alignment: Alignment.center,
                  child: const Icon(
                    PhosphorIconsLight.user,
                    size: 16,
                    color: kGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: kTextPrim,
                      ),
                    ),
                    Text(
                      _timeAgo(review.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: kTextLight,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                    size: 16,
                    color: index < review.rating ? const Color(0xFFFBBF24) : const Color(0xFFE5E7EB),
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: const TextStyle(
                fontSize: 13,
                color: kTextSub,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} an(s)';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} mois';
    if (diff.inDays > 0) return '${diff.inDays} j';
    if (diff.inHours > 0) return '${diff.inHours} h';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min';
    return 'À l\'instant';
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int index;
  final bool selected;
  final int? count;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.index,
    required this.selected,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 32),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? kGreen : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: selected ? kTextPrim : kTextLight,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? kGreen : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : kTextSub,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  final TerrainModel terrain;
  const _AboutTab({required this.terrain});

  @override
  Widget build(BuildContext context) {
    // Regroupe les sub-terrains par terrain physique (divisionGroup ou physicalName)
    final grouped = <String, List<SubTerrainModel>>{};
    for (final sub in terrain.subTerrains) {
      final key = sub.divisionGroup ?? sub.physicalName ?? sub.name;
      grouped.putIfAbsent(key, () => []).add(sub);
    }

    // Sépare : formats (capacités), surfaces, équipements
    const knownSurfaces = {'Gazon synthétique', 'Gazon naturel', 'Terre battue'};
    const knownCapacities = {'5v5', '7v7', '9v9', '11v11'};
    final formats = terrain.features.where(knownCapacities.contains).toList();
    final equipment = terrain.features
        .where((f) => !knownCapacities.contains(f) && !knownSurfaces.contains(f))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        if (terrain.description != null && terrain.description!.isNotEmpty) ...[
          const _SectionLabel('À propos'),
          const SizedBox(height: 10),
          Text(
            terrain.description!,
            style: const TextStyle(fontSize: 14, color: kTextSub, height: 1.6),
          ),
          const SizedBox(height: 28),
        ],

        // Terrains physiques regroupés
        if (grouped.isNotEmpty) ...[
          Row(
            children: [
              _SectionLabel('Terrains (${grouped.length})'),
              const Spacer(),
              Text(
                '${terrain.subTerrains.length} surfaces',
                style: const TextStyle(
                  fontSize: 12,
                  color: kGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...grouped.values.map((g) => _PhysicalTerrainCard(group: g)),
          const SizedBox(height: 14),
        ],

        // Formats de jeu
        if (formats.isNotEmpty) ...[
          const _SectionLabel('Formats disponibles'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: formats.map((f) => _FormatChip(label: f)).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Équipements
        if (equipment.isNotEmpty) ...[
          const _SectionLabel('Équipements & services'),
          const SizedBox(height: 12),
          _EquipmentGrid(items: equipment),
        ],
      ],
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final TerrainController controller;
  const _ReviewsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingReviews.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: kGreen),
        ),
      );
    }

    if (controller.reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsLight.chatTeardropDots,
                  size: 40,
                  color: kTextLight,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucun avis pour le moment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextPrim,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Les retours de vos clients s\'afficheront ici.',
                style: TextStyle(
                  fontSize: 13,
                  color: kTextSub,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Derniers avis reçus',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: kTextPrim,
          ),
        ),
        const SizedBox(height: 16),
        ...controller.reviews.map((r) => _ReviewCard(review: r)),
        const SizedBox(height: 20),
      ],
    );
  }
}
