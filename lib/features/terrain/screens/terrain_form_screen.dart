import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/lottie_success_dialog.dart';
import '../controllers/owner_zone_options.dart';
import '../controllers/terrain_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class TerrainFormScreen extends StatefulWidget {
  const TerrainFormScreen({super.key});
  @override
  State<TerrainFormScreen> createState() => _TerrainFormScreenState();
}

class _PricingPeriodDraft {
  final TextEditingController labelCtrl;
  final TextEditingController startCtrl;
  final TextEditingController endCtrl;
  final TextEditingController priceCtrl;
  final RxString target;
  final RxSet<int> days;

  _PricingPeriodDraft({
    required String label,
    required String startTime,
    required String endTime,
    required int pricePerHour,
    String target = 'FULL',
    List<int> days = const [],
  }) : labelCtrl = TextEditingController(text: label),
       startCtrl = TextEditingController(text: startTime),
       endCtrl = TextEditingController(text: endTime),
       priceCtrl = TextEditingController(text: '$pricePerHour'),
       target = target.obs,
       days = days.toSet().obs;

  factory _PricingPeriodDraft.fromModel(
    PricingPeriodModel model, {
    String target = 'FULL',
  }) {
    return _PricingPeriodDraft(
      label: model.label,
      startTime: model.startTime,
      endTime: model.endTime,
      pricePerHour: model.pricePerHour,
      target: target,
      days: model.days,
    );
  }

  PricingPeriodModel? toModel() {
    final start = startCtrl.text.trim();
    final end = endCtrl.text.trim();
    final price = int.tryParse(priceCtrl.text.trim());
    if (price == null || price <= 0) return null;
    if (!_isValidTime(start) || !_isValidTime(end)) return null;
    if (_timeToMinutes(end) <= _timeToMinutes(start)) return null;
    final label = labelCtrl.text.trim().isEmpty
        ? '${target.value == 'HALF' ? 'Demi terrain' : 'Terrain complet'} $start-$end'
        : labelCtrl.text.trim();
    return PricingPeriodModel(
      label: label,
      startTime: start,
      endTime: end,
      pricePerHour: price,
      days: days.toList()..sort(),
    );
  }

  void dispose() {
    labelCtrl.dispose();
    startCtrl.dispose();
    endCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _SubTerrainDraft {
  final String? divisionGroup;
  final Map<String, String> idsByDivision;
  final TextEditingController nameCtrl;
  final TextEditingController capacityCtrl;
  final TextEditingController priceCtrl;
  final RxSet<String> formats;
  final RxString surface;
  final RxBool isActive;
  final RxBool allowFull;
  final RxBool allowHalf;
  final RxBool allowThird;
  final RxList<_PricingPeriodDraft> pricingPeriods;

  _SubTerrainDraft({
    this.divisionGroup,
    Map<String, String>? idsByDivision,
    required String name,
    int capacity = 10,
    String type = '5v5',
    String surface = 'Gazon synthétique',
    int? pricePerHour,
    bool isActive = true,
    bool allowFull = true,
    bool allowHalf = false,
    bool allowThird = false,
    List<PricingPeriodModel> pricingPeriods = const [],
  }) : idsByDivision = idsByDivision ?? const {},
       nameCtrl = TextEditingController(text: name),
       capacityCtrl = TextEditingController(text: '$capacity'),
       priceCtrl = TextEditingController(
         text: pricePerHour == null ? '' : '$pricePerHour',
       ),
       formats = type
           .split(',')
           .map((value) => value.trim())
           .where((value) => value.isNotEmpty)
           .toSet()
           .obs,
       surface = surface.obs,
       isActive = isActive.obs,
       allowFull = allowFull.obs,
       allowHalf = allowHalf.obs,
       allowThird = allowThird.obs,
       pricingPeriods = pricingPeriods.isEmpty
           ? <_PricingPeriodDraft>[].obs
           : pricingPeriods
                 .map((period) => _PricingPeriodDraft.fromModel(period))
                 .toList()
                 .obs;

  factory _SubTerrainDraft.fromModels(List<SubTerrainModel> models) {
    final first = models.first;
    final physicalName = first.physicalName ?? _stripDivisionLabel(first.name);
    SubTerrainModel? full;
    for (final model in models) {
      if (model.divisionType == 'FULL') {
        full = model;
        break;
      }
    }
    SubTerrainModel? halfModel;
    for (final model in models) {
      if (model.divisionType == 'HALF') halfModel ??= model;
    }
    final half = models.any((m) => m.divisionType == 'HALF');
    int? inferredFullPrice = full?.pricePerHour;
    if (inferredFullPrice == null && halfModel?.pricePerHour != null) {
      inferredFullPrice = halfModel!.pricePerHour! * 2;
    }
    inferredFullPrice ??= first.pricePerHour;
    final idsByDivision = <String, String>{};
    for (final model in models) {
      if (model.id == null || model.id!.isEmpty) continue;
      idsByDivision['${model.divisionType}:${model.divisionIndex}'] =
          model.id!;
    }
    final periods = <_PricingPeriodDraft>[
      ...?full?.pricingPeriods.map(
        (period) => _PricingPeriodDraft.fromModel(period, target: 'FULL'),
      ),
      ...?halfModel?.pricingPeriods.map(
        (period) => _PricingPeriodDraft.fromModel(period, target: 'HALF'),
      ),
    ];

    final draft = _SubTerrainDraft(
      divisionGroup: first.divisionGroup ?? first.id,
      idsByDivision: idsByDivision,
      name: physicalName,
      capacity: first.capacity,
      type: first.type,
      surface: first.surface ?? 'Gazon synthétique',
      pricePerHour: inferredFullPrice,
      pricingPeriods: const [],
      isActive: models.any((m) => m.isActive),
      allowFull: full != null || !half,
      allowHalf: half,
      allowThird: false,
    );
    draft.pricingPeriods.assignAll(periods);
    return draft;
  }

  List<SubTerrainModel>? toModels(int index, int defaultPricePerHour) {
    final name = nameCtrl.text.trim();
    const capacity = 10;
    final selectedFormats = _TerrainFormScreenState._miniTerrainTypes
        .where(formats.contains)
        .toList();
    if (name.isEmpty) return null;
    if (selectedFormats.isEmpty) return null;
    if (pricingPeriods.isEmpty) return null;
    if (pricingPeriods.any((period) => period.toModel() == null)) return null;
    final hasFull = pricingPeriods.any((period) => period.target.value == 'FULL');
    final hasHalf = pricingPeriods.any((period) => period.target.value == 'HALF');
    if (!hasFull && !hasHalf) return null;
    final group =
        divisionGroup ??
        'terrain_${index + 1}_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

    List<PricingPeriodModel> pricingPeriodsFor(String target) {
      return pricingPeriods
          .where((period) => period.target.value == target)
          .map((period) => period.toModel())
          .whereType<PricingPeriodModel>()
          .toList();
    }

    SubTerrainModel unit(
      String label,
      String divisionType,
      int divisionIndex,
      int? price,
      List<PricingPeriodModel> periods,
    ) {
      return SubTerrainModel(
        id: idsByDivision['$divisionType:$divisionIndex'],
        name: '$name - $label',
        physicalName: name,
        divisionGroup: group,
        divisionType: divisionType,
        divisionIndex: divisionIndex,
        capacity: capacity,
        type: selectedFormats.join(', '),
        surface: surface.value,
        pricePerHour: price,
        pricingPeriods: periods,
        isActive: isActive.value,
      );
    }

    final units = <SubTerrainModel>[];
    if (hasFull) {
      final periods = pricingPeriodsFor('FULL');
      final price = periods.isEmpty ? defaultPricePerHour : periods.first.pricePerHour;
      units.add(unit('Terrain complet', 'FULL', 0, price, periods));
    }
    if (hasHalf) {
      final periods = pricingPeriodsFor('HALF');
      final price = periods.isEmpty ? (defaultPricePerHour / 2).ceil() : periods.first.pricePerHour;
      units
        ..add(unit('Demi terrain 1', 'HALF', 1, price, periods))
        ..add(unit('Demi terrain 2', 'HALF', 2, price, periods));
    }
    return units;
  }

  void addPricingPeriod(String target) {
    pricingPeriods.add(
      _PricingPeriodDraft(
        label: 'Soirée',
        startTime: '18:00',
        endTime: '23:00',
        pricePerHour: 10000,
        target: target,
      ),
    );
  }

  void removePricingPeriod(_PricingPeriodDraft period) {
    period.dispose();
    pricingPeriods.remove(period);
  }

  void dispose() {
    nameCtrl.dispose();
    capacityCtrl.dispose();
    priceCtrl.dispose();
    for (final period in pricingPeriods) {
      period.dispose();
    }
  }
}

bool _isValidTime(String value) => RegExp(r'^\d{2}:\d{2}$').hasMatch(value);

int _timeToMinutes(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return -1;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

String _stripDivisionLabel(String value) {
  return value
      .replaceAll(
        RegExp(
          r'\s*-\s*(Entier|Terrain complet|Demi( terrain)?\s+\d+|Tiers\s+\d+)$',
        ),
        '',
      )
      .trim();
}

class _TerrainFormScreenState extends State<TerrainFormScreen> {
  late final TerrainController _ctrl;
  late final bool _isEditing;

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '10000');
  final _dimCtrl = TextEditingController(text: '40 x 25 m');
  final _openCtrl = TextEditingController(text: '08:00');
  final _closeCtrl = TextEditingController(text: '23:00');

  final _images = <XFile>[].obs;
  final _surface = 'Gazon synthétique'.obs;
  final _zone = 'DAKAR'.obs;
  final _capacities = <String>{}.obs;
  final _mapCenter = Rx<LatLng>(const LatLng(14.6937, -17.4441));
  final _isLocating = false.obs;
  final _isSaving = false.obs;
  final _step = 0.obs;
  final _pageCtrl = PageController();
  final _editingTerrainIndex = RxnInt();
  final _miniTerrains = <_SubTerrainDraft>[].obs;
  final _contactPhones = <String>[].obs;
  final _phoneCtrl = TextEditingController();

  final _equipments = <String, bool>{
    'Éclairage': true,
    'Vestiaires': true,
    'Parking': false,
    'Tribunes': false,
    'Wi-Fi': false,
    'Buvette': false,
    'Douches': false,
    'Arbitre': false,
    'Ballon': false,
  }.obs;

  static const _surfaces = [
    'Gazon synthétique',
    'Gazon naturel',
    'Terre battue',
  ];
  static const _allCapacities = ['5v5', '7v7', '11v11'];
  static const _miniTerrainTypes = ['5v5', '7v7', '9v9', '11v11'];
  static const _dayLabels = {
    1: 'Lun',
    2: 'Mar',
    3: 'Mer',
    4: 'Jeu',
    5: 'Ven',
    6: 'Sam',
    0: 'Dim',
  };

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<TerrainController>();
    _isEditing = _ctrl.selectedTerrain.value != null;
    final t = _ctrl.selectedTerrain.value;
    if (t != null) {
      _nameCtrl.text = t.name;
      _addressCtrl.text = t.address;
      _descCtrl.text = t.description ?? '';
      _priceCtrl.text = '${t.pricePerHour}';
      _zone.value = t.zone;

      const validSurfaces = [
        'Gazon synthétique',
        'Gazon naturel',
        'Terre battue',
      ];
      final surf = t.features.firstWhere(
        (f) => validSurfaces.contains(f),
        orElse: () => 'Gazon synthétique',
      );
      _surface.value = surf;

      _contactPhones.assignAll(t.contactPhones);

      const caps = {'5v5', '7v7', '11v11'};
      for (final f in t.features) {
        if (caps.contains(f)) _capacities.add(f);
        if (_equipments.containsKey(f)) _equipments[f] = true;
      }

      if (t.lat != null && t.lng != null) {
        _mapCenter.value = LatLng(t.lat!, t.lng!);
      }

      final grouped = <String, List<SubTerrainModel>>{};
      for (final subTerrain in t.subTerrains) {
        final key =
            subTerrain.divisionGroup ??
            subTerrain.physicalName ??
            subTerrain.id ??
            subTerrain.name;
        grouped.putIfAbsent(key, () => []).add(subTerrain);
      }
      _miniTerrains.value = grouped.values
          .where((group) => group.isNotEmpty)
          .map(_SubTerrainDraft.fromModels)
          .toList();
    }

    if (_miniTerrains.isNotEmpty) _editingTerrainIndex.value = 0;
    if (!_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _dimCtrl.dispose();
    _openCtrl.dispose();
    _closeCtrl.dispose();
    _pageCtrl.dispose();
    _phoneCtrl.dispose();
    for (final miniTerrain in _miniTerrains) {
      miniTerrain.dispose();
    }
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final uri = AppConfig.reverseGeocode(point.latitude, point.longitude);
      final res = await http
          .get(uri, headers: {'Accept-Language': 'fr'})
          .timeout(AppConfig.geocodingTimeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final address = data['display_name']?.toString() ?? '';
        _addressCtrl.text = address;
        _zone.value = _zoneFromAddress(address);
      }
    } catch (_) {}
  }

  String _zoneFromAddress(String address) {
    final normalized = address
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Ï', 'I');
    for (final zone in ownerZoneLabels.keys) {
      final label = ownerZoneLabels[zone]!
          .toUpperCase()
          .replaceAll('-', '_')
          .replaceAll('É', 'E')
          .replaceAll('È', 'E')
          .replaceAll('Ê', 'E')
          .replaceAll('Ï', 'I');
      if (normalized.contains(zone) || normalized.contains(label)) {
        return zone;
      }
    }
    return 'DAKAR';
  }

  // ── Géolocalisation ────────────────────────────────────────────────────────
  Future<void> _useCurrentLocation() async {
    _isLocating.value = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppSnackbar.warning('GPS désactivé. Activez la localisation sur votre appareil.');
        await Geolocator.openLocationSettings();
        _isLocating.value = false;
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          AppSnackbar.warning('Autorisation de localisation requise.');
          _isLocating.value = false;
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        AppSnackbar.warning('Localisation bloquée. Activez-la dans les réglages de l\'application.');
        await Geolocator.openAppSettings();
        _isLocating.value = false;
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final pt = LatLng(pos.latitude, pos.longitude);
      _mapCenter.value = pt;
      await _reverseGeocode(pt);
      if (_addressCtrl.text.trim().isEmpty) {
        _addressCtrl.text = 'Position actuelle détectée';
      }
    } catch (e) {
      AppSnackbar.error('Impossible d\'obtenir votre position. Réessayez.');
    }
    _isLocating.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF0EBE3))),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Center(
              child: GestureDetector(
                onTap: () {
                  if (_step.value > 0) {
                    _goPrevious();
                  } else {
                    _ctrl.goBack();
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0EBE3),
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
            centerTitle: true,
            title: Text(
              _isEditing ? 'Modifier complexe' : 'Nouveau complexe',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF006F39),
              ),
            ),
          ),
        ),
      ),
      body: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: _buildStepHeader(),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                physics: const BouncingScrollPhysics(),
                itemCount: 5,
                onPageChanged: (page) {
                  if (page == 3 && _miniTerrains.isEmpty) {
                    _addMiniTerrain(animate: false);
                  }
                  _step.value = page;
                },
                itemBuilder: (context, page) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    physics: const BouncingScrollPhysics(),
                    child: _buildStepContent(page),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFF0EBE3))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: _buildBottomActions(),
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    final current = _step.value + 1;
    final titles = [
      'Infos',
      'Photos',
      'Terrains',
      'Terrain',
      'Résumé',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Étape $current sur 5',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final active = index <= _step.value;
            return Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF006F39)
                      : const Color(0xFFE5E0D8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          titles[_step.value],
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    return _buildStepContent(_step.value);
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return Column(
          children: [
            _buildInfoSection(),
          ],
        );
      case 1:
        return Column(
          children: [
            _buildPhotosSection(),
            const SizedBox(height: 16),
            _buildEquipmentsSection(),
          ],
        );
      case 2:
        return _buildTerrainListStep();
      case 3:
        return _buildTerrainEditorStep();
      default:
        return _buildReviewStep();
    }
  }

  Widget _buildTerrainListStep() {
    return _Card(
      title: 'Terrains du complexe',
      icon: PhosphorIconsLight.soccerBall,
      child: Obx(() {
        if (_miniTerrains.isEmpty) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addMiniTerrain,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006F39),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Ajouter un terrain',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          );
        }

        return Column(
          children: [
            ...List.generate(_miniTerrains.length, (index) {
              final terrain = _miniTerrains[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _miniTerrains.length - 1 ? 0 : 8,
                ),
                child: _TerrainDraftTile(
                  index: index,
                  terrain: terrain,
                  onEdit: () {
                    _editingTerrainIndex.value = index;
                    _setStep(3);
                  },
                  onDelete: _miniTerrains.length <= 1
                      ? null
                      : () => _removeMiniTerrain(terrain),
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _addMiniTerrain,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF006F39),
                  side: const BorderSide(color: Color(0xFFE5E0D8)),
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Ajouter un terrain',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTerrainEditorStep() {
    return Obx(() {
      if (_miniTerrains.isEmpty) {
        return _Card(
          title: 'Terrain',
          icon: PhosphorIconsLight.soccerBall,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addMiniTerrain,
              icon: const Icon(PhosphorIconsLight.plus, size: 18),
              label: const Text('Ajouter un terrain'),
            ),
          ),
        );
      }

      final index = (_editingTerrainIndex.value ?? 0)
          .clamp(
        0,
        _miniTerrains.length - 1,
      )
          .toInt();
      final terrain = _miniTerrains[index];
      return _buildMiniTerrainCard(terrain, index);
    });
  }

  Widget _buildReviewStep() {
    final equipments = _equipments.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    return Column(
      children: [
        _Card(
          title: 'Complexe',
          icon: PhosphorIconsLight.buildings,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewLine(label: 'Nom', value: _nameCtrl.text.trim()),
              _ReviewLine(label: 'Adresse', value: _addressCtrl.text.trim()),
              _ReviewLine(label: 'Photos', value: '${_images.length} ajoutée(s)'),
              _ReviewLine(
                label: 'Équipements',
                value: equipments.isEmpty ? 'Aucun' : equipments.join(', '),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          title: 'Terrains',
          icon: PhosphorIconsLight.soccerBall,
          child: Obx(
            () => Column(
              children: List.generate(_miniTerrains.length, (index) {
                final terrain = _miniTerrains[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _miniTerrains.length - 1 ? 0 : 10,
                  ),
                  child: _TerrainDraftTile(
                    index: index,
                    terrain: terrain,
                    onEdit: () {
                      _editingTerrainIndex.value = index;
                      _setStep(3);
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // ── 1. Photos ──────────────────────────────────────────────────────────────
  Widget _buildPhotosSection() {
    final existingImage = _ctrl.selectedTerrain.value?.displayImage ?? '';

    return Obx(() {
      final hasExistingImage = existingImage.isNotEmpty;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E0D8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    PhosphorIconsLight.imageSquare,
                    color: Color(0xFF006F39),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Photos',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(PhosphorIconsLight.plus, size: 18),
                label: Text(
                  _images.isEmpty && !hasExistingImage
                      ? 'Ajouter des photos'
                      : 'Ajouter encore',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF006F39),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFE5E0D8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (hasExistingImage && _images.isEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  existingImage,
                  height: 92,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_images.length, (index) {
                  return _PhotoThumb(
                    image: _images[index],
                    isPrimary: index == 0,
                    onRemove: () => _images.removeAt(index),
                  );
                }),
              ),
            ],
          ],
        ),
      );
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      _images.addAll(images);
    }
  }

  // ── 2. Informations ──────────────────────────────────────────────────────
  Widget _buildInfoSection() => _Card(
    title: 'Complexe',
    icon: PhosphorIconsLight.fileText,
    child: Column(
      children: [
        _Field(
          label: 'Nom du complexe *',
          ctrl: _nameCtrl,
          hint: 'Ex: Complexe Foot Almadies',
          icon: PhosphorIconsLight.pen,
        ),
        const SizedBox(height: 16),
        // Description
        _MultilineField(
          label: 'Description',
          ctrl: _descCtrl,
          hint: 'Décrivez le complexe et ses terrains...',
        ),
        const SizedBox(height: 16),
        _buildContactPhonesList(),
      ],
    ),
  );

  Widget _buildContactPhonesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéros de contact',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        Obx(() => Column(
              children: [
                ..._contactPhones.map((phone) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAF7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E0D8)),
                        ),
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsLight.phone,
                                color: Color(0xFF006F39), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                phone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _contactPhones.remove(phone),
                              icon: const Icon(PhosphorIconsLight.trash,
                                  color: Color(0xFFEF4444), size: 18),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            )),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E0D8)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(PhosphorIconsLight.phone,
                  color: Color(0xFF006F39), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Ajouter un numéro...',
                    hintStyle: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final phone = _phoneCtrl.text.trim();
                  if (phone.isNotEmpty && !_contactPhones.contains(phone)) {
                    _contactPhones.add(phone);
                    _phoneCtrl.clear();
                  }
                },
                icon: const Icon(PhosphorIconsLight.plusCircle,
                    color: Color(0xFF006F39), size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required RxString obs,
    required List<DropdownMenuItem<String>> items,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
        ),
      ),
      const SizedBox(height: 6),
      Obx(
        () => Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E0D8)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: obs.value,
              isExpanded: true,
              icon: const Icon(
                PhosphorIconsLight.caretDown,
                color: Color(0xFF006F39),
                size: 16,
              ),
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              items: items,
              onChanged: (v) {
                if (v != null) obs.value = v;
              },
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildMiniTerrainsSection() => _Card(
    title: 'Terrains physiques',
    icon: PhosphorIconsLight.soccerBall,
    trailing: _IconPillButton(
      icon: PhosphorIconsLight.plus,
      label: 'Ajouter',
      onTap: _addMiniTerrain,
    ),
    child: Obx(
      () => Column(
        children: [
          ...List.generate(_miniTerrains.length, (index) {
            final miniTerrain = _miniTerrains[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _miniTerrains.length - 1 ? 0 : 12,
              ),
              child: _buildMiniTerrainCard(miniTerrain, index),
            );
          }),
        ],
      ),
    ),
  );

  Widget _buildMiniTerrainCard(_SubTerrainDraft miniTerrain, int index) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E0D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  PhosphorIconsLight.soccerBall,
                  color: Color(0xFF006F39),
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Terrain ${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Obx(
                () => Switch.adaptive(
                  value: miniTerrain.isActive.value,
                  activeThumbColor: const Color(0xFF006F39),
                  onChanged: (value) => miniTerrain.isActive.value = value,
                ),
              ),
              if (_miniTerrains.length > 1)
                IconButton(
                  onPressed: () => _removeMiniTerrain(miniTerrain),
                  icon: const Icon(
                    PhosphorIconsLight.trash,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Nom du terrain physique *',
            ctrl: miniTerrain.nameCtrl,
            hint: 'Ex: Terrain A',
            icon: PhosphorIconsLight.pen,
          ),
          const SizedBox(height: 12),
          _buildFormatsSelector(miniTerrain),
          const SizedBox(height: 12),
          _buildDropdown(
            label: 'Surface',
            obs: miniTerrain.surface,
            items: _surfaces
                .map(
                  (surface) =>
                      DropdownMenuItem(value: surface, child: Text(surface)),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          _buildPricingSection(miniTerrain),
        ],
      ),
    );
  }

  Widget _buildPricingSection(_SubTerrainDraft miniTerrain) {
    return Obx(() {
      final hasFull =
          miniTerrain.pricingPeriods.any((period) => period.target.value == 'FULL');
      final hasHalf =
          miniTerrain.pricingPeriods.any((period) => period.target.value == 'HALF');

      if (!hasFull && !hasHalf) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarifs',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _AddPricingTypeButton(
                    label: 'Terrain complet',
                    onTap: () => miniTerrain.addPricingPeriod('FULL'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AddPricingTypeButton(
                    label: 'Demi terrain',
                    onTap: () => miniTerrain.addPricingPeriod('HALF'),
                  ),
                ),
              ],
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tarifs',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (hasFull) _buildPricingTypeCard(miniTerrain, 'FULL'),
          if (hasFull && hasHalf) const SizedBox(height: 10),
          if (hasHalf) _buildPricingTypeCard(miniTerrain, 'HALF'),
          if (!hasFull || !hasHalf) ...[
            const SizedBox(height: 10),
            _AddPricingTypeButton(
              label: hasFull ? 'Ajouter demi terrain' : 'Ajouter terrain complet',
              onTap: () => miniTerrain.addPricingPeriod(hasFull ? 'HALF' : 'FULL'),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildPricingTypeCard(_SubTerrainDraft miniTerrain, String target) {
    final label = target == 'HALF' ? 'Demi terrain' : 'Terrain complet';

    return Obx(() {
      final periods = miniTerrain.pricingPeriods
          .where((period) => period.target.value == target)
          .toList();

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E0D8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _IconPillButton(
                  label: 'Tarif',
                  icon: PhosphorIconsLight.plus,
                  onTap: () => miniTerrain.addPricingPeriod(target),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...periods.map((period) {
              return Padding(
                padding: EdgeInsets.only(bottom: period == periods.last ? 0 : 10),
                child: _buildPricingPeriodRow(miniTerrain, period),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildPricingPeriodRow(
    _SubTerrainDraft miniTerrain,
    _PricingPeriodDraft period,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E0D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => miniTerrain.removePricingPeriod(period),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 34, height: 28),
              icon: const Icon(
                PhosphorIconsLight.trash,
                color: Color(0xFFEF4444),
                size: 17,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _CompactField(
                  label: 'Début',
                  ctrl: period.startCtrl,
                  hint: '18:00',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactField(
                  label: 'Fin',
                  ctrl: period.endCtrl,
                  hint: '23:00',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactField(
                  label: 'Prix / heure',
                  ctrl: period.priceCtrl,
                  hint: '20000',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Jours',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _dayLabels.entries.map((entry) {
                  final selected = period.days.contains(entry.key);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _DivisionChip(
                      label: entry.value,
                      selected: selected,
                      onTap: () {
                        if (selected) {
                          period.days.remove(entry.key);
                        } else {
                          period.days.add(entry.key);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Aucun jour sélectionné = tous les jours.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _addMiniTerrain({bool animate = true}) {
    final name = String.fromCharCode(65 + _miniTerrains.length);
    _miniTerrains.add(
      _SubTerrainDraft(name: 'Terrain $name', capacity: 10, type: '5v5'),
    );
    _editingTerrainIndex.value = _miniTerrains.length - 1;
    _setStep(3, animate: animate);
  }

  Widget _buildFormatsSelector(_SubTerrainDraft miniTerrain) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Formats disponibles',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        Obx(
          () => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _miniTerrainTypes.map((type) {
                final selected = miniTerrain.formats.contains(type);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _DivisionChip(
                    label: type,
                    selected: selected,
                    onTap: () {
                      if (selected && miniTerrain.formats.length > 1) {
                        miniTerrain.formats.remove(type);
                      } else if (!selected) {
                        miniTerrain.formats.add(type);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _removeMiniTerrain(_SubTerrainDraft miniTerrain) {
    miniTerrain.dispose();
    _miniTerrains.remove(miniTerrain);
  }

  // ── 3. Formats de jeu — Chips ─────────────────────────────────────────────
  Widget _buildCapacitySection() => _Card(
    title: 'Formats disponibles',
    icon: PhosphorIconsLight.users,
    child: Obx(
      () => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _allCapacities.map((c) {
          final sel = _capacities.contains(c);
          return GestureDetector(
            onTap: () {
              if (sel) {
                _capacities.remove(c);
              } else {
                _capacities.add(c);
              }
            },
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF006F39) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel
                      ? const Color(0xFF006F39)
                      : const Color(0xFFE5E0D8),
                ),
              ),
              child: Text(
                c,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );

  // ── 4. Équipements — Grid ────────────────────────────────────────────────
  Widget _buildEquipmentsSection() => _Card(
    title: 'Équipements inclus',
    icon: PhosphorIconsLight.shieldCheck,
    child: Obx(() {
      final icons = {
        'Éclairage': PhosphorIconsLight.lightbulb,
        'Vestiaires': PhosphorIconsLight.shirtFolded,
        'Ballon': PhosphorIconsLight.soccerBall,
        'Caméra': PhosphorIconsLight.videoCamera,
        'Wifi': PhosphorIconsLight.wifiHigh,
        'Parking': PhosphorIconsLight.park,
        'Tribunes': PhosphorIconsLight.chair,
        'Buvette': PhosphorIconsLight.coffee,
        'Douches': PhosphorIconsLight.shower,
        'Arbitre': PhosphorIconsLight.flag,
      };

      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3.5,
        children: _equipments.entries.map((e) {
          final on = e.value;
          final icon = icons[e.key] ?? PhosphorIconsLight.checks;
          return GestureDetector(
            onTap: () => _equipments[e.key] = !on,
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: on ? const Color(0xFFE8F5E9) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: on ? const Color(0xFF006F39) : const Color(0xFFE5E0D8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: on
                        ? const Color(0xFF006F39)
                        : const Color(0xFF9CA3AF),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                        color: on
                            ? const Color(0xFF006F39)
                            : const Color(0xFF6B7280),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }),
  );

  // ── 6. Navigation ────────────────────────────────────────────────────────
  Widget _buildBottomActions() => Obx(() {
    final isLast = _step.value == 4;
    final isTerrainEditor = _step.value == 3;
    final label = isLast
        ? 'Confirmer'
        : isTerrainEditor
            ? 'Valider ce terrain'
            : _step.value == 2 && _miniTerrains.isEmpty
                ? 'Ajouter un terrain'
                : _step.value == 2
                    ? 'Voir le récapitulatif'
                    : 'Continuer';

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving.value ? null : _goNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006F39),
          disabledBackgroundColor: const Color(0xFF006F39).withAlpha(120),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isSaving.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  });

  void _goPrevious() {
    if (_step.value == 3) {
      _setStep(2);
      return;
    }
    if (_step.value == 4) {
      _setStep(2);
      return;
    }
    if (_step.value > 0) _setStep(_step.value - 1);
  }

  Future<void> _goNext() async {
    if (_step.value == 0 && !await _validateComplexInfo()) return;
    if (_step.value == 2 && _miniTerrains.isEmpty) {
      _addMiniTerrain();
      return;
    }
    if (_step.value == 2) {
      _setStep(4);
      return;
    }
    if (_step.value == 3) {
      if (!_validateCurrentTerrain()) return;
      _setStep(2);
      return;
    }
    if (_step.value == 4) {
      await _onSave();
      return;
    }
    _setStep(_step.value + 1);
  }

  void _setStep(int step, {bool animate = true}) {
    final target = step.clamp(0, 4).toInt();
    _step.value = target;
    if (!_pageCtrl.hasClients) return;
    if (animate) {
      _pageCtrl.animateToPage(
        target,
        duration: 220.ms,
        curve: Curves.easeOutCubic,
      );
    } else {
      _pageCtrl.jumpToPage(target);
    }
  }

  Future<bool> _validateComplexInfo() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppSnackbar.warning('Veuillez saisir un nom pour le complexe.');
      return false;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      await _useCurrentLocation();
    }
    if (_addressCtrl.text.trim().isEmpty) {
      AppSnackbar.warning('Autorisez la localisation pour continuer.');
      return false;
    }
    return true;
  }

  bool _validateCurrentTerrain() {
    final index = _editingTerrainIndex.value;
    if (index == null || index < 0 || index >= _miniTerrains.length) {
      return false;
    }
    final valid = _miniTerrains[index].toModels(index, 0);
    if (valid == null) {
      AppSnackbar.warning('Terrain incomplet. Vérifiez le nom, les formats, les découpes et les tarifs.');
      return false;
    }
    return true;
  }

  Future<void> _onSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppSnackbar.warning('Veuillez saisir un nom pour le complexe.');
      return;
    }

    final subTerrainGroups = <List<SubTerrainModel>>[];
    for (var i = 0; i < _miniTerrains.length; i++) {
      final models = _miniTerrains[i].toModels(i, 0);
      if (models == null) {
        subTerrainGroups.clear();
        break;
      }
      subTerrainGroups.add(models);
    }
    final subTerrains = subTerrainGroups.expand((models) => models).toList();
    if (subTerrains.isEmpty ||
        subTerrainGroups.length != _miniTerrains.length) {
      AppSnackbar.warning('Chaque terrain doit avoir un nom, un format, des tarifs valides et au moins une découpe réservable.');
      return;
    }
    final price = _deriveComplexPrice(subTerrains);

    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      AppSnackbar.warning('Autorisez la localisation pour continuer.');
      return;
    }

    _isSaving.value = true;
    try {
      final features = [
        _surface.value,
        ..._capacities,
        ..._equipments.entries.where((e) => e.value).map((e) => e.key),
      ];

      final authCtrl = Get.find<AuthController>();

      await _ctrl.saveTerrain(
        name: name,
        address: address,
        zone: _zone.value,
        pricePerHour: price,
        lat: _mapCenter.value.latitude,
        lng: _mapCenter.value.longitude,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        features: features,
        contactPhones: _contactPhones.toList(),
        subTerrains: subTerrains,
        images: _images.toList(),
        managerId: authCtrl.user.value?.id,
      );

      Get.dialog(
        LottieSuccessDialog(
          message: _isEditing ? 'Complexe modifié !' : 'Terrain créé !',
          subtitle: _isEditing
              ? 'Les modifications ont été enregistrées'
              : 'Votre complexe et ses terrains sont prêts',
        ),
        barrierDismissible: false,
      );
      await Future.delayed(const Duration(seconds: 2));
      if (Get.isDialogOpen ?? false) Get.back();
      await Future.delayed(const Duration(milliseconds: 80));
      _ctrl.goBack();
    } catch (e) {
      AppSnackbar.error('Impossible d\'enregistrer le terrain. Vérifiez les informations et réessayez.');
    } finally {
      _isSaving.value = false;
    }
  }

  int _deriveComplexPrice(List<SubTerrainModel> subTerrains) {
    final prices = subTerrains
        .expand(
          (subTerrain) => [
            subTerrain.pricePerHour,
            ...subTerrain.pricingPeriods.map((period) => period.pricePerHour),
          ],
        )
        .whereType<int>()
        .where((price) => price > 0)
        .toList()
      ..sort();
    return prices.isEmpty ? 10000 : prices.first;
  }
}

// ─── Widgets de structure ──────────────────────────────────────────────────

class _IconPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IconPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF006F39),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final XFile image;
  final bool isPrimary;
  final VoidCallback onRemove;

  const _PhotoThumb({
    required this.image,
    required this.isPrimary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FutureBuilder(
          future: image.readAsBytes(),
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            return Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isPrimary
                      ? const Color(0xFF006F39)
                      : const Color(0xFFE5E0D8),
                  width: isPrimary ? 2 : 1,
                ),
                color: const Color(0xFFF9FAF7),
              ),
              clipBehavior: Clip.antiAlias,
              child: bytes == null
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      width: 70,
                      height: 70,
                      errorBuilder: (_, __, ___) => const Icon(
                        PhosphorIconsLight.imageBroken,
                        color: Color(0xFF9CA3AF),
                        size: 22,
                      ),
                    ),
            );
          },
        ),
        Positioned(
          top: -7,
          right: -7,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
        if (isPrimary)
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF006F39),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ),
      ],
    );
  }
}

class _TerrainDraftTile extends StatelessWidget {
  final int index;
  final _SubTerrainDraft terrain;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _TerrainDraftTile({
    required this.index,
    required this.terrain,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final formats = terrain.formats.isEmpty
          ? 'Aucun format'
          : terrain.formats.join(', ');
      final cuts = [
        if (terrain.pricingPeriods.any((period) => period.target.value == 'FULL'))
          'Complet',
        if (terrain.pricingPeriods.any((period) => period.target.value == 'HALF'))
          'Demi-terrain',
      ].join(', ');

      return Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAF7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E0D8)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF006F39),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    terrain.nameCtrl.text.trim().isEmpty
                        ? 'Terrain ${index + 1}'
                        : terrain.nameCtrl.text.trim(),
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$formats · ${cuts.isEmpty ? 'Aucune découpe' : cuts}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              icon: const Icon(
                PhosphorIconsLight.pencilSimple,
                color: Color(0xFF006F39),
                size: 17,
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints.tightFor(width: 36, height: 36),
                icon: const Icon(
                  PhosphorIconsLight.trash,
                  color: Color(0xFFEF4444),
                  size: 17,
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _ReviewLine extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _Card({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E0D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E0D8)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, color: const Color(0xFF006F39), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final TextInputType? keyboardType;

  const _CompactField({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 42,
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAF7),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E0D8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E0D8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF006F39)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DivisionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DivisionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 180.ms,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF006F39) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF006F39) : const Color(0xFFE5E0D8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AddPricingTypeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddPricingTypeButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF006F39)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PhosphorIconsLight.plus, size: 15, color: Color(0xFF006F39)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF006F39),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultilineField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;

  const _MultilineField({
    required this.label,
    required this.ctrl,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0EBE3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E0D8)),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
