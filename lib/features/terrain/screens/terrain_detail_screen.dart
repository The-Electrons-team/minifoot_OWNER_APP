import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../routes/app_routes.dart';
import '../controllers/terrain_controller.dart';

// Écran 34 (Détail du complexe) du design.
class TerrainDetailScreen extends StatefulWidget {
  const TerrainDetailScreen({super.key});

  @override
  State<TerrainDetailScreen> createState() => _TerrainDetailScreenState();
}

class _TerrainDetailScreenState extends State<TerrainDetailScreen> {
  final TerrainController controller = Get.find<TerrainController>();
  final _pageController = PageController();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final argument = Get.arguments;
    if (argument is TerrainModel) controller.selectedTerrain.value = argument;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final terrain = controller.selectedTerrain.value;
      if (terrain == null) {
        return const Scaffold(
          backgroundColor: kBg,
          body: Center(child: CircularProgressIndicator(color: kGreen)),
        );
      }

      final images = [
        ...terrain.imageUrls,
        if (terrain.imageUrls.isEmpty && (terrain.imageUrl ?? '').isNotEmpty) terrain.imageUrl!,
      ];

      return Scaffold(
        backgroundColor: kBg,
        body: Stack(
          children: [
            RefreshIndicator(
              color: kGreen,
              onRefresh: controller.refreshTerrains,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  children: [
                    _Gallery(
                      images: images,
                      pageController: _pageController,
                      onBack: () => Get.back(),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -26),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        terrain.name,
                                        style: kArchivo(
                                          size: 25,
                                          weight: FontWeight.w800,
                                          color: kTextPrim,
                                          height: 1.15,
                                          letterSpacing: -0.02 * 25,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        [terrain.address, terrain.zone]
                                            .where((e) => e.isNotEmpty)
                                            .join(' · '),
                                        style: kManrope(
                                          size: 13.5,
                                          weight: FontWeight.w400,
                                          color: kTextSub,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _StatusToggle(
                                  active: terrain.isActive,
                                  onTap: () => controller.toggleStatus(terrain.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _Tabs(
                              index: _tab,
                              onChanged: (i) => setState(() => _tab = i),
                            ),
                            const SizedBox(height: 16),
                            if (_tab == 0)
                              _SubTerrainsTab(terrain: terrain)
                            else
                              _FeaturesTab(terrain: terrain),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, kBg],
                    stops: [0, 0.34],
                  ),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.toNamed(Routes.availability, arguments: terrain.id),
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kGreen,
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: [
                        BoxShadow(
                          color: kGreen.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      'Gérer les disponibilités',
                      style: kManrope(size: 15.5, weight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _Gallery extends StatefulWidget {
  final List<String> images;
  final PageController pageController;
  final VoidCallback onBack;

  const _Gallery({
    required this.images,
    required this.pageController,
    required this.onBack,
  });

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.images.isNotEmpty;
    return SizedBox(
      height: 230,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImages)
            PageView.builder(
              controller: widget.pageController,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => AppNetworkImage(url: widget.images[i], fit: BoxFit.cover),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFB9B2A4),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x5C006F39), Color(0x14006F39)],
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onBack,
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const PhosphorIcon(
                      PhosphorIconsRegular.caretLeft,
                      color: kTextPrim,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              left: 16,
              bottom: 16,
              child: Row(
                children: List.generate(
                  widget.images.length,
                  (i) => Container(
                    width: 26,
                    height: 4,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: i == _index ? Colors.white : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          if (!hasImages)
            Positioned(
              right: 16,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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
        ],
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _StatusToggle({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(color: kTextPrim.withValues(alpha: 0.08), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            Text(
              active ? 'Actif' : 'En pause',
              style: kManrope(size: 12, weight: FontWeight.w700, color: kTextPrim),
            ),
            const SizedBox(width: 9),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 22,
              decoration: BoxDecoration(
                color: active ? kGreenLight : kBorder,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: active ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active ? kGreen : kTextLight,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _Tabs({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7DB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tab('Sous-terrains', 0),
          _tab('Équipements', 1),
        ],
      ),
    );
  }

  Widget _tab(String label, int i) {
    final selected = index == i;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(i),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? kBgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [BoxShadow(color: kTextPrim.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            style: kManrope(
              size: 13,
              weight: FontWeight.w700,
              color: selected ? kTextPrim : kTextSub,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubTerrainsTab extends StatelessWidget {
  final TerrainModel terrain;

  const _SubTerrainsTab({required this.terrain});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final sub in terrain.subTerrains) ...[
          _SubTerrainCard(sub: sub),
          const SizedBox(height: 12),
        ],
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Get.toNamed(Routes.terrainForm, arguments: terrain),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kTextPrim.withValues(alpha: 0.18), width: 1.5),
            ),
            child: Text(
              '+ Ajouter un sous-terrain',
              style: kManrope(size: 13.5, weight: FontWeight.w700, color: kGreen),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubTerrainCard extends StatelessWidget {
  final SubTerrainModel sub;

  const _SubTerrainCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final details = [
      sub.type,
      if ((sub.surface ?? '').isNotEmpty) sub.surface!,
    ].where((e) => e.isNotEmpty).join(' · ');

    return Opacity(
      opacity: sub.isActive ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: kTextPrim.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sub.isActive ? kGreenLight : const Color(0xFFEDE7DB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _initial(sub.name),
                style: kArchivo(
                  size: 17,
                  weight: FontWeight.w800,
                  color: sub.isActive ? kGreen : kTextSub,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    style: kArchivo(size: 15.5, weight: FontWeight.w700, color: kTextPrim, height: 1.2),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sub.isActive ? details : 'Indisponible',
                    style: kManrope(size: 12.5, weight: FontWeight.w400, color: kTextSub, height: 1.4),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (sub.isActive && sub.pricePerHour != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_thousands(sub.pricePerHour!)} F',
                    style: kArchivo(size: 15, weight: FontWeight.w700, color: kTextPrim),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '/ heure',
                    style: kManrope(size: 11, weight: FontWeight.w500, color: kTextSub),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    // « Terrain A » → A, sinon la première lettre.
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.last[0].toUpperCase();
  }
}

class _FeaturesTab extends StatelessWidget {
  final TerrainModel terrain;

  const _FeaturesTab({required this.terrain});

  @override
  Widget build(BuildContext context) {
    if (terrain.features.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(20)),
        child: Text(
          'Aucun équipement renseigné.',
          textAlign: TextAlign.center,
          style: kManrope(size: 13.5, weight: FontWeight.w500, color: kTextSub),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: terrain.features
          .map(
            (feature) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PhosphorIcon(PhosphorIconsBold.check, color: kGreen, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    feature,
                    style: kManrope(size: 13, weight: FontWeight.w600, color: kTextPrim),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

String _thousands(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(s[i]);
  }
  return buffer.toString();
}
