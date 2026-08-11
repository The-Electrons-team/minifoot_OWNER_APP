import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/terrain_controller.dart';

// Écran 35 (Photos du complexe) : glisser pour réordonner, la première est la
// photo principale.
class TerrainPhotosScreen extends StatefulWidget {
  const TerrainPhotosScreen({super.key});

  @override
  State<TerrainPhotosScreen> createState() => _TerrainPhotosScreenState();
}

class _TerrainPhotosScreenState extends State<TerrainPhotosScreen> {
  final TerrainController controller = Get.find<TerrainController>();

  late TerrainModel _terrain;
  late List<String> _urls;
  bool _busy = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _terrain = Get.arguments as TerrainModel;
    _urls = [
      ..._terrain.imageUrls,
      if (_terrain.imageUrls.isEmpty && (_terrain.imageUrl ?? '').isNotEmpty)
        _terrain.imageUrl!,
    ];
  }

  Future<void> _addPhotos() async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;
      setState(() => _busy = true);
      await controller.addImages(_terrain.id, picked);
      final refreshed = controller.allTerrains.firstWhereOrNull(
        (t) => t.id == _terrain.id,
      );
      if (refreshed != null && mounted) {
        setState(() {
          _terrain = refreshed;
          _urls = List.of(refreshed.imageUrls);
        });
      }
      AppSnackbar.success('Photos ajoutées.');
    } catch (_) {
      AppSnackbar.error('Impossible d\'ajouter ces photos.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(int index) async {
    final confirmed = await AppDialog.confirm(
      title: 'Retirer cette photo ?',
      message: 'Elle ne sera plus visible par les joueurs.',
      confirmLabel: 'Retirer',
      cancelLabel: 'Garder',
      destructive: true,
    );
    if (!confirmed) return;
    setState(() {
      _urls.removeAt(index);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await controller.reorderImages(_terrain.id, _urls);
      if (!mounted) return;
      Get.back();
      await Future<void>.delayed(const Duration(milliseconds: 220));
      AppSnackbar.success('Modifications enregistrées.');
    } catch (_) {
      AppSnackbar.error('Enregistrement impossible. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Get.back(),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10, top: 4, bottom: 4),
                      child: PhosphorIcon(
                        PhosphorIconsRegular.caretLeft,
                        size: 24,
                        color: kTextPrim,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Photos du complexe',
                          style: kArchivo(
                            size: 21,
                            weight: FontWeight.w800,
                            color: kTextPrim,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Glissez pour réordonner — la première est la principale.',
                          style: kManrope(
                            size: 12.5,
                            weight: FontWeight.w400,
                            color: kTextSub,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _urls.isEmpty
                  ? const _EmptyState()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                      itemCount: _urls.length,
                      onReorder: (from, to) {
                        setState(() {
                          final target = to > from ? to - 1 : to;
                          final url = _urls.removeAt(from);
                          _urls.insert(target, url);
                          _dirty = true;
                        });
                      },
                      itemBuilder: (_, i) => Padding(
                        key: ValueKey(_urls[i]),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PhotoRow(
                          url: _urls[i],
                          isMain: i == 0,
                          index: i,
                          onRemove: () => _remove(i),
                        ),
                      ),
                    ),
            ),
            Padding
              (
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _busy ? null : _addPhotos,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: kTextPrim.withValues(alpha: 0.18),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '+ Ajouter des photos',
                        style: kManrope(size: 14, weight: FontWeight.w700, color: kGreen),
                      ),
                    ),
                  ),
                  if (_dirty) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _busy ? null : _save,
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _busy ? kGreen.withValues(alpha: 0.6) : kGreen,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Enregistrer l\'ordre',
                                style: kManrope(
                                  size: 15.5,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  final String url;
  final bool isMain;
  final int index;
  final VoidCallback onRemove;

  const _PhotoRow({
    required this.url,
    required this.isMain,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kTextPrim.withValues(alpha: 0.07),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 74,
              height: 60,
              child: AppNetworkImage(url: url, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMain ? 'Photo principale' : 'Photo ${index + 1}',
                  style: kArchivo(
                    size: 15,
                    weight: FontWeight.w700,
                    color: isMain ? kGreen : kTextPrim,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isMain ? 'Affichée dans la liste et la recherche' : 'Vue dans la galerie',
                  style: kManrope(size: 12, weight: FontWeight.w400, color: kTextSub),
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: PhosphorIcon(PhosphorIconsRegular.trash, color: kRed, size: 18),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(left: 4, right: 4),
              child: PhosphorIcon(PhosphorIconsRegular.dotsSixVertical, color: kTextLight, size: 20),
            ),
          ),
        ],
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
                color: const Color(0xFFEFEAE0),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const PhosphorIcon(PhosphorIconsRegular.image, color: kTextSub, size: 40),
            ),
            const SizedBox(height: 22),
            Text(
              'Aucune photo',
              textAlign: TextAlign.center,
              style: kArchivo(size: 21, weight: FontWeight.w800, color: kTextPrim, height: 1.25),
            ),
            const SizedBox(height: 10),
            Text(
              'Les complexes avec photos reçoivent nettement plus de réservations.',
              textAlign: TextAlign.center,
              style: kManrope(size: 14, weight: FontWeight.w400, color: kTextSub, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
