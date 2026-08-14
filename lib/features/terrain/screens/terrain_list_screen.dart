import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/shimmer_loading.dart' show ShimmerBox;
import '../../../routes/app_routes.dart';
import '../controllers/terrain_controller.dart';

// Écran 33 (Mes complexes) du design.
class TerrainListScreen extends GetView<TerrainController> {
  const TerrainListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: kGreen,
          onRefresh: controller.refreshTerrains,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Mes complexes',
                              style: kArchivo(
                                size: 28,
                                weight: FontWeight.w800,
                                letterSpacing: -0.02 * 28,
                              ),
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Get.toNamed(Routes.terrainForm),
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: kGreen,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const PhosphorIcon(
                                PhosphorIconsBold.plus,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Obx(
                        () => Text(
                          _subtitle(controller),
                          style: kManrope(size: 13.5, weight: FontWeight.w400, color: kTextSub, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              Obx(() {
                if (controller.isLoading.value && controller.terrains.isEmpty) {
                  return const SliverPadding(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 24),
                    sliver: SliverToBoxAdapter(child: _ListLoading()),
                  );
                }
                if (controller.errorMessage.value.isNotEmpty && controller.terrains.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      message: controller.errorMessage.value,
                      onRetry: controller.refreshTerrains,
                    ),
                  );
                }
                if (controller.terrains.isEmpty) {
                  return const SliverFillRemaining(hasScrollBody: false, child: _EmptyState());
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                  sliver: SliverList.separated(
                    itemCount: controller.terrains.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => _ComplexCard(terrain: controller.terrains[i]),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  static String _subtitle(TerrainController controller) {
    final complexes = controller.terrains.length;
    final units = controller.terrains.fold<int>(0, (sum, t) => sum + t.miniTerrainCount);
    final complexLabel = '$complexes complexe${complexes > 1 ? 's' : ''}';
    if (units == 0) return complexLabel;
    return '$complexLabel · $units sous-terrain${units > 1 ? 's' : ''}';
  }
}

class _ComplexCard extends GetView<TerrainController> {
  final TerrainModel terrain;

  const _ComplexCard({required this.terrain});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: kTextPrim.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _CardHeader(terrain: terrain),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (terrain.miniTerrainCount > 0)
                            _Chip('${terrain.miniTerrainCount} sous-terrain${terrain.miniTerrainCount > 1 ? 's' : ''}'),
                          if (_formats(terrain).isNotEmpty) _Chip(_formats(terrain)),
                          _Chip(terrain.displayPriceRange),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (terrain.isActive)
                  Row(
                    children: [
                      Expanded(
                        child: _CardButton(
                          label: 'Gérer',
                          bg: kBg,
                          fg: kTextPrim,
                          onTap: () => Get.toNamed(Routes.terrainDetail, arguments: terrain),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CardButton(
                          label: 'Disponibilités',
                          bg: kGreenLight,
                          fg: kGreenInk,
                          onTap: () => Get.toNamed(Routes.availability, arguments: terrain.id),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.only(top: 14),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: kTextPrim.withValues(alpha: 0.07))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Invisible pour les joueurs',
                            style: kManrope(size: 12.5, weight: FontWeight.w400, color: kTextSub, height: 1.4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => controller.toggleStatus(terrain.id),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: kGreen,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Text(
                              'Réactiver',
                              style: kManrope(size: 13.5, weight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formats(TerrainModel terrain) {
    final formats = terrain.subTerrains
        .map((sub) => sub.type)
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return formats.join(' · ');
  }
}

class _CardHeader extends StatelessWidget {
  final TerrainModel terrain;

  const _CardHeader({required this.terrain});

  @override
  Widget build(BuildContext context) {
    final image = terrain.displayImage;
    final hasImage = image.isNotEmpty;

    return SizedBox(
      height: 132,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            AppNetworkImage(url: image, fit: BoxFit.cover)
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kGreenOverlay22, kGreenOverlay05],
                ),
                color: kSurfacePlaceholder,
              ),
            ),
          if (hasImage)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, kOverlayBlack40],
                ),
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: terrain.isActive ? kGreen : kGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    terrain.isActive ? 'ACTIF' : 'EN PAUSE',
                    style: kManrope(
                      size: 11,
                      weight: FontWeight.w700,
                      color: terrain.isActive ? kGreenInk : kGoldInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!hasImage)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kTextPrim.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PHOTO À AJOUTER',
                  style: kManrope(
                    size: 10.5,
                    weight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Text(
              terrain.name,
              style: kArchivo(
                size: 20,
                weight: FontWeight.w700,
                color: hasImage ? Colors.white : kTextPrim,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        label,
        style: kManrope(size: 12, weight: FontWeight.w600, color: kTextPrim),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _CardButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
        child: Text(
          label,
          style: kManrope(size: 13.5, weight: FontWeight.w700, color: fg),
        ),
      ),
    );
  }
}

class _ListLoading extends StatelessWidget {
  const _ListLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: ShimmerBox(width: double.infinity, height: 250, borderRadius: 22),
        ),
      ),
    );
  }
}

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
                color: kSurfaceMuted,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const PhosphorIcon(PhosphorIconsRegular.soccerBall, color: kTextSub, size: 40),
            ),
            const SizedBox(height: 22),
            Text(
              'Aucun complexe',
              textAlign: TextAlign.center,
              style: kArchivo(size: 21, weight: FontWeight.w800, color: kTextPrim, height: 1.25),
            ),
            const SizedBox(height: 10),
            Text(
              'Ajoutez votre premier complexe pour commencer à recevoir des réservations.',
              textAlign: TextAlign.center,
              style: kManrope(size: 14, weight: FontWeight.w400, color: kTextSub, height: 1.6),
            ),
            const SizedBox(height: 26),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Get.toNamed(Routes.terrainForm),
              child: Container(
                width: double.infinity,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(17)),
                child: Text(
                  'Ajouter un complexe',
                  style: kManrope(size: 15.5, weight: FontWeight.w700, color: Colors.white),
                ),
              ),
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
