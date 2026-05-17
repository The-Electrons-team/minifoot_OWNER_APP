import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
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
        backgroundColor: const Color(0xFFF5F0E8),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // AppBar avec Image
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: const Color(0xFF006F39),
              elevation: 0,
              leading: Center(
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF1A1A1A),
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
                      onTap: () => controller.goToForm(terrain),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          PhosphorIconsLight.pencilSimple,
                          color: Color(0xFF006F39),
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
                          return Image.network(
                            images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFEAF5ED),
                              child: const Icon(
                                PhosphorIconsLight.soccerBall,
                                size: 64,
                                color: Color(0xFF006F39),
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: const Color(0xFFEAF5ED),
                        child: const Icon(
                          PhosphorIconsLight.soccerBall,
                          size: 64,
                          color: Color(0xFF006F39),
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
                  color: Color(0xFFF5F0E8),
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
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    PhosphorIconsLight.mapPin,
                                    color: Color(0xFF6B7280),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      terrain.address,
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
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
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            terrain.isActive ? 'Actif' : 'Pause',
                            style: TextStyle(
                              color: terrain.isActive
                                  ? const Color(0xFF006F39)
                                  : const Color(0xFFEF4444),
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
                              bottom: BorderSide(color: Color(0xFFE5E0D8), width: 1),
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
                    backgroundColor: const Color(0xFF006F39),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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

class _SubTerrainTile extends StatelessWidget {
  final SubTerrainModel sub;
  const _SubTerrainTile({required this.sub});

  String _formatDays(List<int> days) {
    if (days.isEmpty) return 'Tous les jours';
    const dayNames = {1: 'Lun', 2: 'Mar', 3: 'Mer', 4: 'Jeu', 5: 'Ven', 6: 'Sam', 0: 'Dim'};
    return days.map((d) => dayNames[d]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E0D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header du Terrain
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    PhosphorIconsLight.soccerBall,
                    color: Color(0xFF006F39),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sub.type} • ${sub.capacity} Joueurs • ${sub.surface ?? 'Synthétique'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (sub.pricePerHour != null && sub.pricingPeriods.isEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${sub.pricePerHour} F',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF006F39),
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'par heure',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          if (sub.pricingPeriods.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(PhosphorIconsLight.tag, size: 14, color: Color(0xFF006F39)),
                      const SizedBox(width: 6),
                      Text(
                        'GRILLE TARIFAIRE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Color(0xFF006F39),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...sub.pricingPeriods.map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
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
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(PhosphorIconsLight.clock,
                                          size: 12, color: Color(0xFF6B7280)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${p.startTime} - ${p.endTime}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(PhosphorIconsLight.calendar,
                                          size: 12, color: Color(0xFF6B7280)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _formatDays(p.days),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${p.pricePerHour} F',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A1A),
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              '/h',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final String label;
  const _FeatureBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    // Liste des capacités et surfaces à exclure pour ne garder que les équipements réels
    const exclusions = ['5v5', '7v7', '11v11', 'Gazon synthétique', 'Gazon naturel', 'Terre battue'];
    if (exclusions.contains(label)) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E0D8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(PhosphorIconsLight.checkCircle, size: 16, color: Color(0xFF006F39)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
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
        border: Border.all(color: const Color(0xFFE5E0D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEAF5ED),
                backgroundImage: review.userAvatar != null
                    ? NetworkImage(review.userAvatar!)
                    : null,
                child: review.userAvatar == null
                    ? const Icon(PhosphorIconsLight.user, size: 16, color: Color(0xFF006F39))
                    : null,
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
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      _timeAgo(review.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
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
                color: Color(0xFF4B5563),
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
              color: selected ? const Color(0xFF006F39) : Colors.transparent,
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
                color: selected ? const Color(0xFF1A1A1A) : const Color(0xFF9CA3AF),
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF006F39) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : const Color(0xFF4B5563),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        const Text(
          'À propos du complexe',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          terrain.description ?? 'Aucune description fournie.',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF4B5563),
            height: 1.6,
          ),
        ),

        const SizedBox(height: 32),

        // Terrains
        if (terrain.subTerrains.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                'Options de réservation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                '${terrain.subTerrains.length} terrains',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF006F39),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...terrain.subTerrains.map((s) => _SubTerrainTile(sub: s)),
        ],

        const SizedBox(height: 32),

        // Équipements
        const Text(
          'Équipements & Services',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: terrain.features.map((f) => _FeatureBadge(label: f)).toList(),
        ),
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
          child: CircularProgressIndicator(color: Color(0xFF006F39)),
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
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucun avis pour le moment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Les retours de vos clients s\'afficheront ici.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
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
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        ...controller.reviews.map((r) => _ReviewCard(review: r)),
        const SizedBox(height: 20),
      ],
    );
  }
}
