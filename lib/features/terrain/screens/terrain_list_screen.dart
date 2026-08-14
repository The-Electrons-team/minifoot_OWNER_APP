import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/utils/app_format.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/utils/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../controllers/terrain_controller.dart';

class TerrainListScreen extends GetView<TerrainController> {
  const TerrainListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: kBgSurface)),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Center(
              child: GestureDetector(
                onTap: controller.goBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: kBgSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    PhosphorIconsLight.caretLeft,
                    color: kTextPrim,
                    size: 16,
                  ),
                ),
              ),
            ),
            centerTitle: true,
            title: const Text(
              'Mes complexes',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: kGreen,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms),
      ),
      floatingActionButton: Obx(() {
        if (controller.totalTerrains == 0) return const SizedBox.shrink();
        return FloatingActionButton(
          onPressed: () => controller.goToForm(null),
          backgroundColor: kGreen,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          child: const Icon(
            PhosphorIconsLight.plus,
            color: Colors.white,
            size: 28,
          ),
        );
      }),
      body: Container(
        color: kBg,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                children: [
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: _StatPill(
                            label: 'Complexes',
                            value: '${controller.totalTerrains}',
                            icon: PhosphorIconsLight.buildings,
                            color: kGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatPill(
                            label: 'Terrains',
                            value: '${controller.totalPhysicalTerrains}',
                            icon: PhosphorIconsLight.soccerBall,
                            color: const Color(0xFFB7791F),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatPill(
                            label: 'Actifs',
                            value: '${controller.activeTerrains}',
                            icon: PhosphorIconsLight.checkCircle,
                            color: kBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          PhosphorIconsLight.magnifyingGlass,
                          color: kTextLight,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            onChanged: controller.onSearch,
                            style: const TextStyle(
                              color: kTextPrim,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Rechercher un terrain...',
                              hintStyle: TextStyle(
                                color: kTextLight,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterBar(),
                ],
              ),
            ),

            Expanded(
              // La liste employait une physique « bouncing » : elle *semblait*
              // tirable alors qu'aucun rafraîchissement n'était branché.
              child: RefreshIndicator(
                onRefresh: controller.refreshTerrains,
                color: kGreen,
                backgroundColor: kBgCard,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return ShimmerList(
                      itemBuilder: (context, index) =>
                          const TerrainCardSkeleton(),
                    );
                  }

                  // L'erreur passe avant le vide : sans cela, une coupure
                  // réseau s'affichait comme « Aucun terrain ».
                  if (controller.errorMessage.value.isNotEmpty) {
                    return _scrollableState(
                      context,
                      AppErrorState(
                        message: controller.errorMessage.value,
                        onRetry: controller.refreshTerrains,
                      ),
                    );
                  }

                  if (controller.terrains.isEmpty) {
                    return _buildEmptyState();
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (scroll) {
                      if (scroll.metrics.pixels >=
                          scroll.metrics.maxScrollExtent - 400) {
                        controller.loadMore();
                      }
                      return false;
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children:
                          List.generate(controller.terrains.length, (index) {
                            final terrain = controller.terrains[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child:
                                  _TerrainCard(
                                    onTap: () => controller.goToDetail(terrain),
                                    terrain: terrain,
                                    onToggle: () =>
                                        controller.toggleStatus(terrain.id),
                                    onEdit: () => controller.goToForm(terrain),
                                    onDelete: () =>
                                        controller.deleteConfirm(terrain.id),
                                  ).animate().fadeIn(
                                    duration: 350.ms,
                                    delay: AppMotion.stagger(index, step: 70),
                                  ),
                            );
                          })..addAll(
                            controller.hasMore
                                ? const [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: kGreen,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]
                                : const <Widget>[],
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

  Widget _buildFilterBar() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _FilterChip(
              label: 'Tous',
              count: controller.totalTerrains,
              selected: controller.statusFilter.value == 'all',
              onTap: () => controller.selectStatusFilter('all'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterChip(
              label: 'Actifs',
              count: controller.activeTerrains,
              selected: controller.statusFilter.value == 'active',
              onTap: () => controller.selectStatusFilter('active'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterChip(
              label: 'Inactifs',
              count: controller.inactiveTerrains,
              selected: controller.statusFilter.value == 'inactive',
              onTap: () => controller.selectStatusFilter('inactive'),
            ),
          ),
        ],
      ),
    );
  }

  /// Rend un état plein écran défilable, pour qu'il reste tirable vers le bas
  /// même quand il n'y a rien à faire défiler.
  Widget _scrollableState(BuildContext context, Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: child,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final hasAnyTerrain = controller.totalTerrains > 0;
    if (hasAnyTerrain) {
      return const Center(
        child: Text(
          'Aucun résultat',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: kTextSub,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 0),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () => controller.goToForm(null),
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreen,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          icon: const Icon(
            PhosphorIconsLight.plus,
            size: 20,
            color: Colors.white,
          ),
          label: const Text(
            'Ajouter un complexe',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: kTextPrim,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextSub,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 180.ms,
      height: 38,
      decoration: BoxDecoration(
        color: selected ? kGreen : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? kGreen : kBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : kTextSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.18)
                        : kBgSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? Colors.white : kGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TerrainCard extends StatelessWidget {
  final TerrainModel terrain;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TerrainCard({
    required this.terrain,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: terrain.isActive ? 1.0 : 0.78,
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: kBorder),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.12),
        elevation: 6,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    terrain.displayImage.isNotEmpty
                        ? AppNetworkImage(
                            url: terrain.displayImage,
                            fallback: const _TerrainImageFallback(),
                          )
                        : const _TerrainImageFallback(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.52),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _StatusBadge(isActive: terrain.isActive),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Row(
                        children: [
                          _RoundAction(
                            icon: PhosphorIconsLight.pencilSimple,
                            onTap: onEdit,
                          ),
                          const SizedBox(width: 8),
                          _RoundAction(
                            icon: PhosphorIconsLight.trash,
                            onTap: onDelete,
                            color: kRed,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  terrain.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      PhosphorIconsLight.mapPin,
                                      color: Colors.white70,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        terrain.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatPriceRange(terrain),
                              style: const TextStyle(
                                color: kGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoBadge(
                                label: terrain.physicalTerrainLabel,
                                icon: PhosphorIconsLight.gridFour,
                              ),
                              _InfoBadge(
                                label: terrain.complexeStatusLabel,
                                icon: PhosphorIconsLight.checkCircle,
                              ),
                              _InfoBadge(
                                label: terrain.reservableUnitLabel,
                                icon: PhosphorIconsLight.gridFour,
                              ),
                              _InfoBadge(
                                label: terrain.displaySurface,
                                icon: PhosphorIconsLight.leaf,
                              ),
                              _InfoBadge(
                                label: terrain.rating.toStringAsFixed(1),
                                icon: PhosphorIconsFill.star,
                                iconColor: kGold,
                                backgroundColor: kGoldLight,
                                borderColor: const Color(0xFFFDE68A),
                                textColor: kGold,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (terrain.subTerrains.isNotEmpty) ...[
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: terrain.subTerrains.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final miniTerrain = terrain.subTerrains[index];
                            return _MiniTerrainChip(miniTerrain: miniTerrain);
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onToggle,
                          child: _StatusToggle(isActive: terrain.isActive),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(
                            PhosphorIconsLight.pencilSimple,
                            size: 16,
                          ),
                          label: const Text('Modifier'),
                          style: TextButton.styleFrom(
                            foregroundColor: kGreen,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
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

  static String _formatPriceRange(TerrainModel terrain) {
    final prices = [
      terrain.pricePerHour,
      ...terrain.subTerrains
          .map((subTerrain) => subTerrain.pricePerHour)
          .whereType<int>(),
    ]..sort();
    if (prices.first == prices.last) return _formatHourlyPrice(prices.first);
    return '${_formatAmount(prices.first)} - ${_formatAmount(prices.last)} F/h';
  }

  static String _formatHourlyPrice(int price) => AppFormat.pricePerHour(price);

  static String _formatAmount(int price) =>
      AppFormat.amount(price, withSymbol: false);
}

class _MiniTerrainChip extends StatelessWidget {
  final SubTerrainModel miniTerrain;

  const _MiniTerrainChip({required this.miniTerrain});

  @override
  Widget build(BuildContext context) {
    final color = miniTerrain.isActive ? kGreen : kTextLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: miniTerrain.isActive ? kGreenLight : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsLight.soccerBall, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            '${miniTerrain.name} · ${miniTerrain.type}',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TerrainImageFallback extends StatelessWidget {
  const _TerrainImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kGreenLight,
      child: Center(
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD8E8DD)),
          ),
          child: const Icon(
            PhosphorIconsLight.soccerBall,
            color: kGreen,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? kGreen : kTextSub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Actif' : 'Pause',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _RoundAction({
    required this.icon,
    required this.onTap,
    this.color = kTextPrim,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final bool isActive;

  const _StatusToggle({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? kGreen : kTextLight;
    return Row(
      children: [
        AnimatedContainer(
          duration: 200.ms,
          width: 38,
          height: 22,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? kGreen : kBorder,
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedAlign(
            duration: 200.ms,
            curve: Curves.easeOut,
            alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isActive ? 'Ouvert' : 'En pause',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _InfoBadge({
    required this.label,
    this.icon,
    this.iconColor,
    this.backgroundColor = kBg,
    this.borderColor = kBorder,
    this.textColor = kTextPrim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: iconColor ?? textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
