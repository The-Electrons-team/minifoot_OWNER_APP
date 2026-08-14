import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/terrain_controller.dart';

/// Formats proposés, avec la capacité correspondante — le backend attend un
/// `capacity` cohérent avec le `type`, autant le déduire ici.
const _formats = <(String, int, String)>[
  ('5v5', 10, '10 joueurs'),
  ('7v7', 14, '14 joueurs'),
  ('9v9', 18, '18 joueurs'),
  ('11v11', 22, '22 joueurs'),
];

const _surfaces = ['Synthétique', 'Gazon naturel', 'Béton', 'Sable'];

const _caracteristiques = [
  'Éclairé',
  'Couvert',
  'Vestiaires',
  'Douches',
  'Tribunes',
  'Filets neufs',
];

// Écrans 39 (Ajouter un sous-terrain) et 40 (Modifier un sous-terrain).
class SubTerrainSheet extends StatefulWidget {
  final SubTerrainModel? subTerrain;
  final String complexName;
  final int? basePrice;
  final String? defaultName;

  const SubTerrainSheet({
    super.key,
    this.subTerrain,
    required this.complexName,
    this.basePrice,
    this.defaultName,
  });

  @override
  State<SubTerrainSheet> createState() => _SubTerrainSheetState();
}

class _SubTerrainSheetState extends State<SubTerrainSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _peakPriceCtrl;

  late String _type;
  String? _surface;
  final _features = <String>{};
  bool _hasPeakPricing = false;

  bool get _isEdit => widget.subTerrain != null;

  @override
  void initState() {
    super.initState();
    final sub = widget.subTerrain;
    _nameCtrl = TextEditingController(
      text: sub?.name ?? widget.defaultName ?? 'Terrain A',
    );
    _priceCtrl = TextEditingController(
      text: (sub?.pricePerHour ?? widget.basePrice)?.toString() ?? '',
    );
    _type = sub?.type ?? '5v5';
    _surface = sub?.surface;

    // Une période tarifaire déjà enregistrée = tarif heures pleines actif.
    final peak = sub?.pricingPeriods.firstWhereOrNull(
      (period) => period.pricePerHour > (sub.pricePerHour ?? 0),
    );
    _hasPeakPricing = peak != null;
    _peakPriceCtrl = TextEditingController(
      text: peak?.pricePerHour.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _peakPriceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppSnackbar.warning('Donnez un nom court à ce terrain.');
      return;
    }
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (price <= 0) {
      AppSnackbar.warning('Indiquez le tarif horaire.');
      return;
    }
    final peakPrice = int.tryParse(_peakPriceCtrl.text.trim()) ?? 0;
    if (_hasPeakPricing && peakPrice <= 0) {
      AppSnackbar.warning('Indiquez le tarif des heures pleines.');
      return;
    }

    final capacity = _formats.firstWhere((f) => f.$1 == _type).$2;
    final existing = widget.subTerrain;

    Get.back(
      result: SubTerrainModel(
        id: existing?.id,
        name: name,
        physicalName: existing?.physicalName ?? name,
        divisionGroup: existing?.divisionGroup,
        divisionType: existing?.divisionType ?? 'FULL',
        divisionIndex: existing?.divisionIndex ?? 0,
        capacity: capacity,
        type: _type,
        surface: _surface,
        pricePerHour: price,
        pricingPeriods: _hasPeakPricing
            ? [
                // 18h–22h en semaine : le créneau le plus demandé, comme
                // proposé par le design (écran 40).
                PricingPeriodModel(
                  label: 'Heures pleines',
                  startTime: '18:00',
                  endTime: '22:00',
                  pricePerHour: peakPrice,
                  days: const [1, 2, 3, 4, 5],
                ),
              ]
            : const [],
        isActive: existing?.isActive ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEdit ? _nameCtrl.text : 'Nouveau terrain',
                        style: kArchivo(
                          size: 22,
                          weight: FontWeight.w800,
                          color: kTextPrim,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.complexName.isEmpty
                            ? 'Il rejoindra le planning dès l\'enregistrement.'
                            : 'Dans ${widget.complexName} — il rejoindra le planning dès l\'enregistrement.',
                        style: kManrope(
                          size: 12.5,
                          weight: FontWeight.w400,
                          color: kTextSub,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.back(),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kBgCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const PhosphorIcon(
                      PhosphorIconsBold.x,
                      color: kTextPrim,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Label('NOM COURT'),
                  _Input(controller: _nameCtrl, hint: 'Terrain C'),
                  const SizedBox(height: 22),
                  const _Label('FORMAT'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final format in _formats)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: format == _formats.last ? 0 : 8,
                            ),
                            child: _FormatButton(
                              format: format.$1,
                              players: format.$3,
                              selected: _type == format.$1,
                              onTap: () => setState(() => _type = format.$1),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _Label('TARIF HORAIRE'),
                  _PriceRow(
                    title: 'Tarif normal',
                    subtitle: 'Appliqué par défaut',
                    controller: _priceCtrl,
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _hasPeakPricing = !_hasPeakPricing),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tarif heures pleines',
                                  style: kManrope(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: kTextPrim,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '18h – 22h en semaine',
                                  style: kManrope(
                                    size: 12.5,
                                    weight: FontWeight.w400,
                                    color: kTextSub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _Switch(value: _hasPeakPricing),
                        ],
                      ),
                    ),
                  ),
                  if (_hasPeakPricing)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _PriceRow(
                        title: 'Heures pleines',
                        subtitle: '18h – 22h, lundi au vendredi',
                        controller: _peakPriceCtrl,
                      ),
                    ),
                  const SizedBox(height: 22),
                  const _Label('SURFACE'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final surface in _surfaces)
                        _Chip(
                          label: surface,
                          selected: _surface == surface,
                          onTap: () => setState(
                            () => _surface = _surface == surface ? null : surface,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _Label('CARACTÉRISTIQUES'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final feature in _caracteristiques)
                        _Chip(
                          label: feature,
                          selected: _features.contains(feature),
                          onTap: () => setState(() {
                            if (!_features.remove(feature)) _features.add(feature);
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              12,
              22,
              20 + MediaQuery.of(context).padding.bottom,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _save,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kGreen,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Text(
                  _isEdit ? 'Enregistrer' : 'Ajouter ce terrain',
                  style: kManrope(size: 15.5, weight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String label;

  const _Label(this.label);

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

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _Input({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 58,
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          style: kArchivo(size: 16, weight: FontWeight.w700, color: kTextPrim),
          decoration: InputDecoration(
            border: InputBorder.none,
            isCollapsed: true,
            hintText: hint,
            hintStyle: kArchivo(size: 16, weight: FontWeight.w700, color: kTextLight),
          ),
        ),
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final String format;
  final String players;
  final bool selected;
  final VoidCallback onTap;

  const _FormatButton({
    required this.format,
    required this.players,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? kGreen : kBgCard,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              format,
              style: kArchivo(
                size: 16,
                weight: FontWeight.w800,
                color: selected ? Colors.white : kTextPrim,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              players,
              style: kManrope(
                size: 10.5,
                weight: FontWeight.w500,
                color: selected ? Colors.white.withValues(alpha: 0.8) : kTextSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController controller;

  const _PriceRow({
    required this.title,
    required this.subtitle,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: kManrope(size: 14, weight: FontWeight.w700, color: kTextPrim),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: kManrope(size: 12.5, weight: FontWeight.w400, color: kTextSub),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: kArchivo(size: 17, weight: FontWeight.w800, color: kTextPrim),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: '0',
                hintStyle: kArchivo(size: 17, weight: FontWeight.w800, color: kTextLight),
                suffixText: ' F',
                suffixStyle: kManrope(size: 13, weight: FontWeight.w600, color: kTextSub),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? kGreenLight : kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? kGreen : Colors.transparent, width: 1.5),
        ),
        child: Text(
          label,
          style: kManrope(
            size: 13,
            weight: FontWeight.w600,
            color: selected ? kGreenInk : kTextPrim,
          ),
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  final bool value;

  const _Switch({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 44,
      height: 26,
      decoration: BoxDecoration(
        color: value ? kGreen : kBorder,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 180),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
