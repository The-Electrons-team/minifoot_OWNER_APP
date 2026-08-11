import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/owner_zone_options.dart';
import '../controllers/terrain_controller.dart';
import 'sub_terrain_sheet.dart';

/// Quartiers proposés en premier — ils couvrent la majorité des complexes de
/// Dakar. « Autre… » ouvre la saisie libre pour tout le reste du pays.
const _quartiers = ['Ouakam', 'Yoff', 'Ngor', 'Almadies', 'Mermoz', 'Sacré-Cœur'];

// Écrans 36 à 38 du design (assistant « Nouveau complexe ») et édition d'un
// complexe existant. L'étape 3 n'existe pas dans le fichier de design : elle
// est reconstituée à partir du récapitulatif (adresse, position, tarif de
// base — la position est obligatoire côté API).
class TerrainFormScreen extends StatefulWidget {
  const TerrainFormScreen({super.key});

  @override
  State<TerrainFormScreen> createState() => _TerrainFormScreenState();
}

class _TerrainFormScreenState extends State<TerrainFormScreen> {
  final TerrainController controller = Get.find<TerrainController>();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _customQuartierCtrl = TextEditingController();

  final _step = 0.obs;
  final _quartier = ''.obs;
  final _zone = 'DAKAR'.obs;
  final _lat = Rxn<double>();
  final _lng = Rxn<double>();
  final _isLocating = false.obs;
  final _isSaving = false.obs;
  final _subTerrains = <SubTerrainModel>[].obs;
  final _images = <XFile>[].obs;

  TerrainModel? _editing;

  bool get _isEdit => _editing != null;
  int get _lastStep => _isEdit ? 3 : 3;

  @override
  void initState() {
    super.initState();
    final argument = Get.arguments;
    if (argument is TerrainModel) {
      _editing = argument;
      _nameCtrl.text = argument.name;
      _addressCtrl.text = argument.address;
      _priceCtrl.text = argument.pricePerHour.toString();
      _zone.value = argument.zone.isEmpty ? 'DAKAR' : argument.zone;
      _lat.value = argument.lat;
      _lng.value = argument.lng;
      _subTerrains.value = List.of(argument.subTerrains);
      final match = _quartiers.firstWhereOrNull(
        (q) => argument.address.toLowerCase().contains(q.toLowerCase()),
      );
      if (match != null) _quartier.value = match;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _customQuartierCtrl.dispose();
    super.dispose();
  }

  // ── Navigation entre étapes ───────────────────────────────────────────────
  String? _blockingReason(int step) {
    switch (step) {
      case 0:
        if (_nameCtrl.text.trim().length < 3) return 'Donnez un nom à votre complexe.';
        if (_effectiveQuartier.isEmpty) return 'Choisissez un quartier.';
        return null;
      case 1:
        if (_subTerrains.isEmpty) return 'Indiquez combien de terrains vous avez.';
        return null;
      case 2:
        if (_addressCtrl.text.trim().length < 5) return 'Précisez l\'adresse.';
        if (_lat.value == null || _lng.value == null) {
          return 'Ajoutez la position du complexe.';
        }
        if ((int.tryParse(_priceCtrl.text.trim()) ?? 0) <= 0) {
          return 'Indiquez le tarif horaire de base.';
        }
        return null;
      default:
        return null;
    }
  }

  String get _effectiveQuartier => _quartier.value == 'Autre'
      ? _customQuartierCtrl.text.trim()
      : _quartier.value;

  void _next() {
    final reason = _blockingReason(_step.value);
    if (reason != null) {
      AppSnackbar.warning(reason);
      return;
    }
    if (_step.value < _lastStep) {
      _step.value += 1;
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _close() async {
    if (_step.value == 0 && !_isEdit && _nameCtrl.text.trim().isEmpty) {
      Get.back();
      return;
    }
    final leave = await AppDialog.confirm(
      title: 'Quitter l\'assistant ?',
      message: _isEdit
          ? 'Les modifications non enregistrées seront perdues.'
          : 'Ce que vous avez saisi sera perdu.',
      confirmLabel: 'Quitter',
      cancelLabel: 'Continuer',
      destructive: true,
    );
    if (leave) Get.back();
  }

  // ── Sous-terrains ─────────────────────────────────────────────────────────
  void _setCount(int count) {
    final basePrice = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    final existing = List.of(_subTerrains);
    final next = <SubTerrainModel>[];
    for (var i = 0; i < count; i++) {
      if (i < existing.length) {
        next.add(existing[i]);
      } else {
        next.add(
          SubTerrainModel(
            name: 'Terrain ${String.fromCharCode(65 + i)}',
            divisionType: 'FULL',
            divisionIndex: i,
            capacity: 10,
            type: '5v5',
            pricePerHour: basePrice > 0 ? basePrice : null,
          ),
        );
      }
    }
    _subTerrains.value = next;
  }

  Future<void> _editSubTerrain(int index) async {
    final updated = await showModalBottomSheet<SubTerrainModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SubTerrainSheet(
        subTerrain: _subTerrains[index],
        complexName: _nameCtrl.text.trim(),
        basePrice: int.tryParse(_priceCtrl.text.trim()),
      ),
    );
    if (updated != null) _subTerrains[index] = updated;
  }

  Future<void> _addSubTerrain() async {
    final created = await showModalBottomSheet<SubTerrainModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SubTerrainSheet(
        complexName: _nameCtrl.text.trim(),
        basePrice: int.tryParse(_priceCtrl.text.trim()),
        defaultName: 'Terrain ${String.fromCharCode(65 + _subTerrains.length)}',
      ),
    );
    if (created != null) _subTerrains.add(created);
  }

  // ── Position ──────────────────────────────────────────────────────────────
  Future<void> _useCurrentLocation() async {
    _isLocating.value = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        AppSnackbar.warning('GPS désactivé. Activez la localisation.');
        await Geolocator.openLocationSettings();
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        AppSnackbar.warning('Autorisation de localisation requise.');
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        AppSnackbar.warning('Localisation bloquée dans les réglages.');
        await Geolocator.openAppSettings();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _lat.value = pos.latitude;
      _lng.value = pos.longitude;
      await _reverseGeocode(pos.latitude, pos.longitude);
      HapticFeedback.selectionClick();
    } catch (_) {
      AppSnackbar.error('Impossible d\'obtenir votre position. Réessayez.');
    } finally {
      _isLocating.value = false;
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final res = await http
          .get(AppConfig.reverseGeocode(lat, lng), headers: {'Accept-Language': 'fr'})
          .timeout(AppConfig.geocodingTimeout);
      if (res.statusCode != 200) return;
      final address = jsonDecode(res.body)['display_name']?.toString() ?? '';
      if (address.isEmpty) return;
      if (_addressCtrl.text.trim().isEmpty) _addressCtrl.text = address;
      _zone.value = _zoneFromAddress(address);
    } catch (_) {
      // Le géocodage est un confort : son échec ne bloque pas la saisie.
    }
  }

  static String _zoneFromAddress(String address) {
    final normalized = address.toUpperCase().replaceAll('-', '_');
    for (final entry in ownerZoneLabels.entries) {
      if (normalized.contains(entry.key) ||
          normalized.contains(entry.value.toUpperCase().replaceAll('-', '_'))) {
        return entry.key;
      }
    }
    return 'DAKAR';
  }

  // ── Photos ────────────────────────────────────────────────────────────────
  Future<void> _pickImages() async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty) _images.addAll(picked);
    } catch (_) {
      AppSnackbar.error('Impossible d\'ouvrir la galerie.');
    }
  }

  // ── Enregistrement ────────────────────────────────────────────────────────
  Future<void> _submit() async {
    for (var step = 0; step <= 2; step++) {
      final reason = _blockingReason(step);
      if (reason != null) {
        _step.value = step;
        AppSnackbar.warning(reason);
        return;
      }
    }

    _isSaving.value = true;
    try {
      // Reprise après un échec d'envoi des photos : le complexe existe déjà,
      // on le met à jour au lieu d'en créer un second.
      if (!_isEdit && controller.createdTerrainId.value.isNotEmpty) {
        _editing = controller.allTerrains.firstWhereOrNull(
          (t) => t.id == controller.createdTerrainId.value,
        );
        controller.selectedTerrain.value = _editing;
      }

      final address = _addressCtrl.text.trim();
      await controller.saveTerrain(
        name: _nameCtrl.text.trim(),
        address: address.contains(_effectiveQuartier)
            ? address
            : '$address, $_effectiveQuartier',
        zone: _zone.value,
        pricePerHour: int.parse(_priceCtrl.text.trim()),
        lat: _lat.value!,
        lng: _lng.value!,
        subTerrains: _subTerrains,
        images: _images,
      );
      controller.createdTerrainId.value = '';
      if (!mounted) return;
      Get.back();
      await Future<void>.delayed(const Duration(milliseconds: 220));
      // Écran 41 du design : confirmation brève, pas de page dédiée.
      AppSnackbar.success(
        _isEdit ? 'Modifications enregistrées.' : 'Complexe envoyé pour validation.',
      );
    } on TerrainImagesUploadException {
      if (!mounted) return;
      AppSnackbar.warning(
        'Complexe enregistré. Les photos n\'ont pas pu être envoyées — réessayez depuis le complexe.',
      );
      Get.back();
    } catch (_) {
      AppSnackbar.error('Enregistrement impossible. Vérifiez votre connexion.');
    } finally {
      _isSaving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Obx(
            () => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_step.value == 0) {
                            _close();
                          } else {
                            _step.value -= 1;
                          }
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: kBgCard,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: kTextPrim.withValues(alpha: 0.08),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: PhosphorIcon(
                            _step.value == 0
                                ? PhosphorIconsBold.x
                                : PhosphorIconsRegular.caretLeft,
                            color: kTextPrim,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: List.generate(
                            4,
                            (i) => Expanded(
                              child: Container(
                                height: 5,
                                margin: EdgeInsets.only(right: i == 3 ? 0 : 5),
                                decoration: BoxDecoration(
                                  color: i <= _step.value
                                      ? kGreen
                                      : kTextPrim.withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
                    child: switch (_step.value) {
                      0 => _stepIdentity(),
                      1 => _stepCount(),
                      2 => _stepLocation(),
                      _ => _stepRecap(),
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                  child: Column(
                    children: [
                      _PrimaryButton(
                        label: _step.value < _lastStep
                            ? 'Continuer'
                            : _isEdit
                                ? 'Enregistrer'
                                : 'Envoyer pour validation',
                        busy: _isSaving.value,
                        onTap: _step.value < _lastStep ? _next : _submit,
                      ),
                      if (!_isEdit) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Vous pouvez quitter à tout moment, rien n\'est publié avant votre validation.',
                          textAlign: TextAlign.center,
                          style: kManrope(
                            size: 12,
                            weight: FontWeight.w400,
                            color: kTextSub,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Étape 1 : identité (écran 36) ─────────────────────────────────────────
  Widget _stepIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepLabel(step: 1),
        _StepTitle(
          _isEdit ? 'Modifier votre complexe' : 'Comment s\'appelle\nvotre complexe ?',
        ),
        _StepHint(
          'C\'est le nom que les joueurs verront en cherchant un terrain près d\'eux.',
        ),
        const _FieldLabel('NOM DU COMPLEXE'),
        _TextField(
          controller: _nameCtrl,
          hint: 'Complexe Ouakam',
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 22),
        const _FieldLabel('QUARTIER'),
        const SizedBox(height: 11),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final quartier in _quartiers)
                _ChoiceChip(
                  label: quartier,
                  selected: _quartier.value == quartier,
                  onTap: () => _quartier.value = quartier,
                ),
              _ChoiceChip(
                label: 'Autre…',
                selected: _quartier.value == 'Autre',
                muted: true,
                onTap: () => _quartier.value = 'Autre',
              ),
            ],
          ),
        ),
        Obx(
          () => _quartier.value != 'Autre'
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _TextField(
                    controller: _customQuartierCtrl,
                    hint: 'Nom du quartier',
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
        ),
      ],
    );
  }

  // ── Étape 2 : nombre de terrains (écran 37) ───────────────────────────────
  Widget _stepCount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepLabel(step: 2),
        _StepTitle('Combien de terrains\ndans ce complexe ?'),
        _StepHint(
          'Vous réglerez les prix et les formats ensuite. Rien n\'est publié avant votre validation.',
        ),
        Obx(
          () => Column(
            children: [
              for (final option in const [
                (1, 'Un seul terrain'),
                (2, 'Deux terrains'),
                (3, 'Trois terrains ou plus'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CountOption(
                    count: option.$1,
                    label: option.$2,
                    selected: option.$1 == 3
                        ? _subTerrains.length >= 3
                        : _subTerrains.length == option.$1,
                    onTap: () => _setCount(option.$1),
                  ),
                ),
            ],
          ),
        ),
        Obx(
          () => _subTerrains.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FieldLabel('VOS TERRAINS'),
                      const SizedBox(height: 10),
                      for (var i = 0; i < _subTerrains.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SubTerrainRow(
                            subTerrain: _subTerrains[i],
                            onTap: () => _editSubTerrain(i),
                            onRemove: _subTerrains.length > 1
                                ? () => _subTerrains.removeAt(i)
                                : null,
                          ),
                        ),
                      _DashedButton(
                        label: '+ Ajouter un terrain',
                        onTap: _addSubTerrain,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // ── Étape 3 : adresse, position, tarif ───────────────────────────────────
  Widget _stepLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepLabel(step: 3),
        _StepTitle('Où se trouve\nvotre complexe ?'),
        _StepHint(
          'La position permet aux joueurs de vous trouver et de calculer leur trajet.',
        ),
        const _FieldLabel('ADRESSE'),
        _TextField(
          controller: _addressCtrl,
          hint: 'Cité Aliou Sow, en face de la mosquée',
          maxLines: 2,
        ),
        const SizedBox(height: 14),
        Obx(
          () => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isLocating.value ? null : _useCurrentLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: _lat.value == null ? kBgCard : kGreenLight,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: _lat.value == null ? kBorder : kGreen,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  if (_isLocating.value)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: kGreen, strokeWidth: 2),
                    )
                  else
                    PhosphorIcon(
                      _lat.value == null
                          ? PhosphorIconsRegular.crosshair
                          : PhosphorIconsBold.check,
                      color: kGreen,
                      size: 20,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _lat.value == null
                          ? 'Utiliser ma position actuelle'
                          : 'Position enregistrée',
                      style: kManrope(
                        size: 14,
                        weight: FontWeight.w700,
                        color: _lat.value == null ? kTextPrim : const Color(0xFF00552C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const _FieldLabel('TARIF HORAIRE DE BASE'),
        _TextField(
          controller: _priceCtrl,
          hint: '15000',
          keyboardType: TextInputType.number,
          suffix: 'F / heure',
        ),
        const SizedBox(height: 22),
        const _FieldLabel('PHOTOS (FACULTATIF)'),
        const SizedBox(height: 10),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _images.length; i++)
                _ImageThumb(
                  file: _images[i],
                  onRemove: () => _images.removeAt(i),
                ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _pickImages,
                child: Container(
                  width: 82,
                  height: 82,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kTextPrim.withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                  ),
                  child: const PhosphorIcon(
                    PhosphorIconsRegular.plus,
                    color: kGreen,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Étape 4 : récapitulatif (écran 38) ───────────────────────────────────
  Widget _stepRecap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepLabel(step: 4),
        _StepTitle('Tout est correct ?'),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RecapRow(
                label: 'COMPLEXE',
                value:
                    '${_nameCtrl.text.trim()}${_effectiveQuartier.isEmpty ? '' : ' · $_effectiveQuartier'}',
                onEdit: () => _step.value = 0,
              ),
              _RecapRow(
                label: 'TERRAINS',
                value: _subTerrainsSummary,
                onEdit: () => _step.value = 1,
              ),
              _RecapRow(
                label: 'ADRESSE',
                value: _addressCtrl.text.trim().isEmpty
                    ? '—'
                    : _addressCtrl.text.trim(),
                onEdit: () => _step.value = 2,
              ),
              _RecapRow(
                label: 'TARIF DE BASE',
                value: '${_priceCtrl.text.trim()} FCFA / heure',
                onEdit: () => _step.value = 2,
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: kGoldLight, borderRadius: BorderRadius.circular(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PhosphorIcon(
                PhosphorIconsRegular.info,
                color: Color(0xFF92400E),
                size: 18,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  _isEdit
                      ? 'Les modifications sont visibles par les joueurs immédiatement.'
                      : 'Le complexe sera visible par les joueurs après validation de l\'équipe MiniFoot.',
                  style: kManrope(
                    size: 13,
                    weight: FontWeight.w500,
                    color: const Color(0xFF92400E),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _subTerrainsSummary {
    if (_subTerrains.isEmpty) return '—';
    final formats = _subTerrains.map((s) => s.type).toSet().toList()..sort();
    final count = '${_subTerrains.length} terrain${_subTerrains.length > 1 ? 's' : ''}';
    return formats.isEmpty ? count : '$count · ${formats.join(' et ')}';
  }
}

// ─── Pièces d'interface ─────────────────────────────────────────────────────
class _StepLabel extends StatelessWidget {
  final int step;

  const _StepLabel({required this.step});

  @override
  Widget build(BuildContext context) {
    return Text(
      'ÉTAPE $step SUR 4',
      style: kManrope(
        size: 11.5,
        weight: FontWeight.w700,
        color: kGreen,
        letterSpacing: 0.1 * 11.5,
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String title;

  const _StepTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        title,
        style: kArchivo(
          size: 27,
          weight: FontWeight.w800,
          color: kTextPrim,
          height: 1.18,
          letterSpacing: -0.02 * 27,
        ),
      ),
    );
  }
}

class _StepHint extends StatelessWidget {
  final String hint;

  const _StepHint(this.hint);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Text(
        hint,
        style: kManrope(size: 13.5, weight: FontWeight.w400, color: kTextSub, height: 1.6),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: kManrope(
        size: 11.5,
        weight: FontWeight.w700,
        color: kTextSub,
        letterSpacing: 0.08 * 11.5,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final String? suffix;

  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      constraints: const BoxConstraints(minHeight: 62),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: kBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              maxLines: maxLines,
              style: kArchivo(size: 17, weight: FontWeight.w700, color: kTextPrim),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: kArchivo(size: 17, weight: FontWeight.w700, color: kTextLight),
              ),
            ),
          ),
          if (suffix != null)
            Text(
              suffix!,
              style: kManrope(size: 13, weight: FontWeight.w600, color: kTextSub),
            ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool muted;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? kGreen : kBgCard,
          borderRadius: BorderRadius.circular(13),
          boxShadow: selected
              ? null
              : [
                  BoxShadow(
                    color: kTextPrim.withValues(alpha: 0.07),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: kManrope(
            size: 13.5,
            weight: FontWeight.w600,
            color: selected
                ? Colors.white
                : muted
                    ? kTextSub
                    : kTextPrim,
          ),
        ),
      ),
    );
  }
}

class _CountOption extends StatelessWidget {
  final int count;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CountOption({
    required this.count,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? kGreen : Colors.transparent, width: 2),
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
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? kGreen : kBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                count == 3 ? '3+' : '$count',
                style: kArchivo(
                  size: 18,
                  weight: FontWeight.w800,
                  color: selected ? Colors.white : kTextPrim,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: kManrope(size: 14.5, weight: FontWeight.w600, color: kTextPrim),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubTerrainRow extends StatelessWidget {
  final SubTerrainModel subTerrain;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _SubTerrainRow({
    required this.subTerrain,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subTerrain.name,
                    style: kArchivo(size: 15, weight: FontWeight.w700, color: kTextPrim),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      subTerrain.type,
                      if (subTerrain.pricePerHour != null)
                        '${subTerrain.pricePerHour} F/h',
                    ].join(' · '),
                    style: kManrope(size: 12.5, weight: FontWeight.w400, color: kTextSub),
                  ),
                ],
              ),
            ),
            if (onRemove != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: PhosphorIcon(PhosphorIconsRegular.trash, color: kRed, size: 18),
                ),
              ),
            const SizedBox(width: 4),
            const PhosphorIcon(PhosphorIconsRegular.caretRight, color: kTextLight, size: 16),
          ],
        ),
      ),
    );
  }
}

class _DashedButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DashedButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kTextPrim.withValues(alpha: 0.18), width: 1.5),
        ),
        child: Text(
          label,
          style: kManrope(size: 13.5, weight: FontWeight.w700, color: kGreen),
        ),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;

  const _ImageThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              // `XFile.path` est un chemin local, pas une URL : Image.file,
              // sinon la vignette reste vide sur l'appareil.
              child: Image.file(
                File(file.path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: kBgSurface,
                  child: Center(
                    child: PhosphorIcon(
                      PhosphorIconsRegular.image,
                      color: kTextSub,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kTextPrim.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const PhosphorIcon(PhosphorIconsBold.x, color: Colors.white, size: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;
  final bool last;

  const _RecapRow({
    required this.label,
    required this.value,
    required this.onEdit,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: last ? 0 : 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: kManrope(
                    size: 11,
                    weight: FontWeight.w600,
                    color: kTextSub,
                    letterSpacing: 0.06 * 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: kArchivo(size: 15, weight: FontWeight.w700, color: kTextPrim, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                'Modifier',
                style: kManrope(size: 13, weight: FontWeight.w700, color: kGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: busy ? kGreen.withValues(alpha: 0.6) : kGreen,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: kGreen.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                label,
                style: kManrope(size: 15.5, weight: FontWeight.w700, color: Colors.white),
              ),
      ),
    );
  }
}
