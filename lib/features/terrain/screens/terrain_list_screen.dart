import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
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
                  width: AppTouch.minTarget,
                  height: AppTouch.minTarget,
                  decoration: const BoxDecoration(
                    color: kBgSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    PhosphorIconsLight.arrowLeft,
                    color: kTextPrim,
                    size: 20,
                  ),
                ),
              ),
            ),
            centerTitle: true,
            title: const Text(
              'Mes terrains',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kTextPrim,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms),
      ),
      body: Container(
        color: kBg,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                children: [
                  Obx(
                    () => Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kGreenLight,
                            borderRadius: AppRadius.smAll,
                          ),
                          child: const PhosphorIcon(
                            PhosphorIconsDuotone.soccerBall,
                            color: kGreen,
                            size: 23,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${controller.totalTerrains} complexe${controller.totalTerrains > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: kTextPrim,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${controller.totalPhysicalTerrains} terrain${controller.totalPhysicalTerrains > 1 ? 's' : ''} · ${controller.activeTerrains} actif${controller.activeTerrains > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: kTextSub,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => controller.goToForm(null),
                          icon: const PhosphorIcon(
                            PhosphorIconsRegular.plus,
                            size: 17,
                          ),
                          label: const Text('Ajouter'),
                          style: TextButton.styleFrom(
                            foregroundColor: kGreen,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
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
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
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
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/lottie/football_bounce.json',
                      width: 140,
                      height: 140,
                      repeat: true,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      hasAnyTerrain ? 'Aucun résultat' : 'Aucun terrain',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kTextPrim,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasAnyTerrain
                          ? 'Essayez une autre recherche\nou un autre filtre.'
                          : 'Ajoutez votre premier terrain\npour commencer.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: kTextSub,
                        height: 1.5,
                      ),
                    ),
                    if (!hasAnyTerrain) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => controller.goToForm(null),
                        icon: const Icon(PhosphorIconsLight.plus, size: 18),
                        label: const Text('Ajouter un terrain'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
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
                aspectRatio: 2.7,
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
                      right: 6,
                      top: 4,
                      child: _TerrainMenu(onEdit: onEdit, onDelete: onDelete),
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
                                    fontSize: 17,
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
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${terrain.physicalTerrainLabel} · ${terrain.reservableUnitLabel}',
                            style: const TextStyle(
                              color: kTextSub,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (terrain.rating > 0) ...[
                          const PhosphorIcon(
                            PhosphorIconsFill.star,
                            color: kGold,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            terrain.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: kGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: kDivider),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onToggle,
                          child: _StatusToggle(isActive: terrain.isActive),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: onTap,
                          icon: const PhosphorIcon(
                            PhosphorIconsRegular.arrowRight,
                            size: 16,
                          ),
                          label: const Text('Détail'),
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

enum _TerrainMenuAction { edit, delete }

class _TerrainMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TerrainMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_TerrainMenuAction>(
      tooltip: 'Actions du complexe',
      onSelected: (action) =>
          action == _TerrainMenuAction.edit ? onEdit() : onDelete(),
      icon: const PhosphorIcon(
        PhosphorIconsBold.dotsThreeVertical,
        color: Colors.white,
        size: 20,
      ),
      color: kBgCard,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _TerrainMenuAction.edit,
          child: _TerrainMenuItem(
            icon: PhosphorIconsRegular.pencilSimple,
            label: 'Modifier',
          ),
        ),
        PopupMenuItem(
          value: _TerrainMenuAction.delete,
          child: _TerrainMenuItem(
            icon: PhosphorIconsRegular.trash,
            label: 'Supprimer',
            color: kRed,
          ),
        ),
      ],
    );
  }
}

class _TerrainMenuItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Color color;

  const _TerrainMenuItem({
    required this.icon,
    required this.label,
    this.color = kTextPrim,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
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
