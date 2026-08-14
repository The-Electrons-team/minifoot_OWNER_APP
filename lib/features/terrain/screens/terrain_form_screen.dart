import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/app_async.dart';
import '../../../core/utils/app_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/app_dialog.dart';
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

  /// Décrit *pourquoi* la plage est invalide, ou `null` si elle est correcte.
  ///
  /// `toModel()` renvoyait `null` pour quatre causes différentes, toutes
  /// remontées par le même message : « Terrain incomplet. Vérifiez le nom, les
  /// formats, les découpes et les tarifs. » Sur un écran comptant N terrains ×
  /// M plages, l'utilisateur ne pouvait pas savoir quoi corriger.
  String? get validationError {
    final start = startCtrl.text.trim();
    final end = endCtrl.text.trim();
    final label = labelCtrl.text.trim().isEmpty
        ? 'une plage tarifaire'
        : '« ${labelCtrl.text.trim()} »';

    final price = int.tryParse(priceCtrl.text.trim());
    if (price == null || price <= 0) {
      return 'Renseignez un prix supérieur à 0 pour $label.';
    }
    if (!_isValidTime(start) || !_isValidTime(end)) {
      return 'Les heures de $label sont incomplètes.';
    }
    if (_timeToMinutes(end) <= _timeToMinutes(start)) {
      return 'Pour $label, l\'heure de fin doit suivre l\'heure de début.';
    }
    return null;
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
  final RxnString expandedTarget = RxnString();
  final Rxn<_PricingPeriodDraft> expandedPeriod = Rxn<_PricingPeriodDraft>();

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
      idsByDivision['${model.divisionType}:${model.divisionIndex}'] = model.id!;
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

  /// Décrit ce qui manque à ce terrain, ou `null` s'il est complet.
  String? get validationError {
    final name = nameCtrl.text.trim();
    final label = name.isEmpty ? 'ce terrain' : '« $name »';

    if (name.isEmpty) return 'Donnez un nom à ce terrain.';
    final selectedFormats = _TerrainFormScreenState._miniTerrainTypes
        .where(formats.contains)
        .toList();
    if (selectedFormats.isEmpty) {
      return 'Choisissez au moins un format pour $label.';
    }
    if (pricingPeriods.isEmpty) {
      return 'Ajoutez au moins une plage tarifaire à $label.';
    }
    for (final period in pricingPeriods) {
      final error = period.validationError;
      if (error != null) return error;
    }
    final hasFull = pricingPeriods.any((p) => p.target.value == 'FULL');
    final hasHalf = pricingPeriods.any((p) => p.target.value == 'HALF');
    if (!hasFull && !hasHalf) {
      return 'Indiquez si les tarifs de $label visent le terrain complet ou la demi-surface.';
    }
    return null;
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
    final hasFull = pricingPeriods.any(
      (period) => period.target.value == 'FULL',
    );
    final hasHalf = pricingPeriods.any(
      (period) => period.target.value == 'HALF',
    );
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
      final price = periods.isEmpty
          ? defaultPricePerHour
          : periods.first.pricePerHour;
      units.add(unit('Terrain complet', 'FULL', 0, price, periods));
    }
    if (hasHalf) {
      final periods = pricingPeriodsFor('HALF');
      final price = periods.isEmpty
          ? (defaultPricePerHour / 2).ceil()
          : periods.first.pricePerHour;
      units
        ..add(unit('Demi terrain 1', 'HALF', 1, price, periods))
        ..add(unit('Demi terrain 2', 'HALF', 2, price, periods));
    }
    return units;
  }

  void addPricingPeriod(String target) {
    final period = _PricingPeriodDraft(
      label: '',
      startTime: '08:00',
      endTime: '23:00',
      pricePerHour: 10000,
      target: target,
    );
    pricingPeriods.add(period);
    expandedPeriod.value = period;
    expandedTarget.value = target;
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

/// Déduit un label depuis la plage horaire : Journée ou Soirée.
String _periodLabel(String start, String end) {
  final startMin = _timeToMinutes(start);
  if (startMin < 0) return 'Tarif';
  // Soirée si le créneau commence à partir de 18h
  return startMin >= 17 * 60 ? 'Soirée' : 'Journée';
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
  final _reviewPricingExpanded = <int, RxBool>{};
  final _commune = ''.obs;

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
      _commune.value = t.address;
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

    // Référence pour détecter une modification réelle : à figer après le
    // préremplissage, sinon l'édition serait considérée comme modifiée d'emblée.
    _initialSignature = _inputSignature;

    // Pour un nouveau complexe, on géolocalise d'emblée.
    // Pour un existant, on re-géolocalise si l'adresse stockée ressemble
    // à l'ancienne valeur de fallback ou contient des coordonnées.
    final storedAddress = _addressCtrl.text.trim();
    final needsGeocode =
        !_isEditing ||
        storedAddress.isEmpty ||
        storedAddress.toLowerCase().contains('actuelle') ||
        storedAddress.toLowerCase().contains('détectée') ||
        RegExp(r'^\d+\.\d+').hasMatch(storedAddress);
    if (needsGeocode) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _useCurrentLocation(),
      );
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
      final base = AppConfig.reverseGeocode(point.latitude, point.longitude);
      // addressdetails=1 décompose l'adresse en champs (suburb, city, etc.)
      final uri = base.replace(
        queryParameters: {...base.queryParameters, 'addressdetails': '1'},
      );
      final res = await http
          .get(uri, headers: {'Accept-Language': 'fr'})
          .timeout(AppConfig.geocodingTimeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        // Priorité : sous-quartier → quartier → arrondissement → ville
        final commune =
            addr['suburb']?.toString() ??
            addr['neighbourhood']?.toString() ??
            addr['quarter']?.toString() ??
            addr['city_district']?.toString() ??
            addr['city']?.toString() ??
            addr['town']?.toString() ??
            addr['village']?.toString() ??
            addr['county']?.toString() ??
            '';
        if (commune.isNotEmpty) {
          _addressCtrl.text = commune;
          _commune.value = commune;
          _zone.value = _zoneFromAddress(commune);
        }
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
        AppSnackbar.warning(
          'GPS désactivé. Activez la localisation sur votre appareil.',
        );
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
        AppSnackbar.warning(
          'Localisation bloquée. Activez-la dans les réglages de l\'application.',
        );
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
    } catch (e) {
      AppSnackbar.error('Impossible d\'obtenir votre position. Réessayez.');
    }
    _isLocating.value = false;
  }

  Future<void> _showAddressPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressPickerSheet(
        onUseGps: () async {
          Navigator.of(ctx).pop();
          await _useCurrentLocation();
        },
        onSelect: (commune, lat, lng) {
          _addressCtrl.text = commune;
          _commune.value = commune;
          _mapCenter.value = LatLng(lat, lng);
          _zone.value = _zoneFromAddress(commune);
        },
        searchFn: _searchNominatim,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _searchNominatim(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final base = AppConfig.reverseGeocode(0, 0);
      final searchUri = Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: '/search',
        queryParameters: {
          'q': query.trim(),
          'format': 'json',
          'addressdetails': '1',
          'limit': '8',
          'accept-language': 'fr',
        },
      );
      final res = await http
          .get(searchUri, headers: {'User-Agent': 'MiniFoot-Owner-App/1.0'})
          .timeout(AppConfig.geocodingTimeout);
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // `canPop: false` intercepte le bouton retour matériel et le geste de
    // retour iOS, qui court-circuitaient l'assistant et détruisaient la saisie.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
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
                onTap: _handleBack,
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
            centerTitle: true,
            title: Text(
              _isEditing ? 'Modifier complexe' : 'Nouveau complexe',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: kGreen,
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
          decoration: appSurfaceDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: kBgSurface)),
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
    // L'éditeur de terrain (index 3) est une sous-étape de Terrains (index 2),
    // pas une étape principale — on l'affiche comme étape 3 sur 4.
    final displayIndex = _step.value == 3
        ? 2
        : _step.value > 3
        ? _step.value - 1
        : _step.value;
    final current = displayIndex + 1;
    final titles = ['Infos', 'Photos', 'Terrains', 'Terrain', 'Résumé'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Étape $current sur 4',
          style: const TextStyle(
            color: kTextSub,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            final active = index <= displayIndex;
            // Bar 0→step 0, 1→step 1, 2→step 2, 3→step 4 (skip sub-étape terrain)
            final targetStep = index == 3 ? 4 : index;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _setStep(targetStep),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    height: 5,
                    margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                    decoration: appSurfaceDecoration(
                      color: active ? kGreen : kBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          titles[_step.value],
          style: const TextStyle(
            color: kTextPrim,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return Column(children: [_buildInfoSection()]);
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
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
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
                  foregroundColor: kGreen,
                  side: const BorderSide(color: kBorder),
                  minimumSize: const Size(double.infinity, 46),
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
          .clamp(0, _miniTerrains.length - 1)
          .toInt();
      final terrain = _miniTerrains[index];
      return _buildMiniTerrainCard(terrain, index);
    });
  }

  Widget _buildReviewStep() {
    final equipments = _equipments.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReviewComplexeCard(equipments),
        const SizedBox(height: 16),
        ...List.generate(
          _miniTerrains.length,
          (i) => Padding(
            padding: EdgeInsets.only(
              bottom: i == _miniTerrains.length - 1 ? 0 : 14,
            ),
            child: _buildReviewTerrainCard(_miniTerrains[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewComplexeCard(List<String> equipments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo
        Obx(() {
          if (_images.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_images.first.path),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          );
        }),
        // Nom + badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                _nameCtrl.text.trim().isEmpty
                    ? 'Sans nom'
                    : _nameCtrl.text.trim(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: kTextPrim,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: appSurfaceDecoration(
                color: kGreenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Actif',
                style: TextStyle(
                  color: kGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        // Adresse (commune)
        if (_commune.value.trim().isNotEmpty) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(PhosphorIconsLight.mapPin, size: 13, color: kTextSub),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _commune.value.trim(),
                  style: const TextStyle(
                    color: kTextSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        // Stats card — style dashboard
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: appSurfaceDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(18),
              boxShadow: kCardShadow,
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _ReviewStat(
                    icon: PhosphorIconsDuotone.soccerBall,
                    color: kGreen,
                    value: '${_miniTerrains.length}',
                    label: 'terrain${_miniTerrains.length > 1 ? 's' : ''}',
                  ),
                  const VerticalDivider(
                    color: kDivider,
                    width: 1,
                    thickness: 1,
                  ),
                  _ReviewStat(
                    icon: PhosphorIconsDuotone.image,
                    color: kBlue,
                    value: '${_images.length}',
                    label: 'photo${_images.length > 1 ? 's' : ''}',
                  ),
                  const VerticalDivider(
                    color: kDivider,
                    width: 1,
                    thickness: 1,
                  ),
                  _ReviewStat(
                    icon: PhosphorIconsDuotone.shieldCheck,
                    color: kGold,
                    value: '${equipments.length}',
                    label: 'équip.',
                  ),
                ],
              ),
            ),
          ),
        ),
        // Équipements — grille 2 colonnes sur card
        if (equipments.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: appSurfaceDecoration(
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
              children: equipments.map((e) {
                const icons = {
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
                final icon = icons[e] ?? PhosphorIconsLight.checks;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: appSurfaceDecoration(
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
          ),
        ],
      ],
    );
  }

  Widget _buildReviewTerrainCard(_SubTerrainDraft terrain, int index) {
    final expanded = _reviewPricingExpanded.putIfAbsent(index, () => false.obs);

    return Obx(() {
      final formats = terrain.formats.isEmpty
          ? 'Aucun format'
          : terrain.formats.join(', ');
      final fullPeriods = terrain.pricingPeriods
          .where((p) => p.target.value == 'FULL')
          .toList();
      final halfPeriods = terrain.pricingPeriods
          .where((p) => p.target.value == 'HALF')
          .toList();
      final isExpanded = expanded.value;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: appSurfaceDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom + modifier
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    terrain.nameCtrl.text.trim().isEmpty
                        ? 'Terrain ${index + 1}'
                        : terrain.nameCtrl.text.trim(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: kTextPrim,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _editingTerrainIndex.value = index;
                    _setStep(3);
                  },
                  tooltip: 'Modifier',
                  constraints: const BoxConstraints.tightFor(
                    width: AppTouch.minTarget,
                    height: AppTouch.minTarget,
                  ),
                  icon: const Icon(
                    PhosphorIconsLight.pencilSimple,
                    color: kGreen,
                    size: 18,
                  ),
                ),
              ],
            ),
            // Formats + surface
            Text(
              '$formats • ${terrain.surface.value}',
              style: const TextStyle(
                fontSize: 12,
                color: kTextSub,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 7),
            // Badges
            Row(
              children: [
                if (fullPeriods.isNotEmpty)
                  _ReviewBadge(
                    label: 'Terrain complet',
                    color: kGreen,
                    bg: kGreenLight,
                  ),
                if (fullPeriods.isNotEmpty && halfPeriods.isNotEmpty)
                  const SizedBox(width: 6),
                if (halfPeriods.isNotEmpty)
                  _ReviewBadge(
                    label: 'Demi terrain',
                    color: kBlue,
                    bg: kBlueLight,
                  ),
              ],
            ),
            // Grille tarifaire collapsible
            if (terrain.pricingPeriods.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => expanded.value = !expanded.value,
                child: Row(
                  children: [
                    const Icon(PhosphorIconsLight.tag, size: 13, color: kGreen),
                    const SizedBox(width: 6),
                    const Text(
                      'GRILLE TARIFAIRE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: kGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${terrain.pricingPeriods.length})',
                      style: const TextStyle(
                        fontSize: 10,
                        color: kTextSub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isExpanded
                          ? PhosphorIconsLight.caretUp
                          : PhosphorIconsLight.caretDown,
                      size: 14,
                      color: kTextSub,
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 10),
                ...terrain.pricingPeriods.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final lbl = p.labelCtrl.text.trim().isNotEmpty
                      ? p.labelCtrl.text.trim()
                      : _periodLabel(p.startCtrl.text, p.endCtrl.text);
                  final price = p.priceCtrl.text.trim();
                  final isHalf = p.target.value == 'HALF';
                  final isLast = i == terrain.pricingPeriods.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        lbl,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: kTextPrim,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _ReviewBadge(
                                        label: isHalf ? 'Demi' : 'Complet',
                                        color: isHalf ? kBlue : kGreen,
                                        bg: isHalf ? kBlueLight : kGreenLight,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        PhosphorIconsLight.clock,
                                        size: 11,
                                        color: kTextSub,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${p.startCtrl.text} – ${p.endCtrl.text}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: kTextSub,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (price.isNotEmpty)
                              Text(
                                '$price F',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: kTextPrim,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!isLast) const Divider(color: kDivider, height: 1),
                    ],
                  );
                }),
              ],
            ],
          ],
        ),
      );
    });
  }

  // ── 1. Photos ──────────────────────────────────────────────────────────────
  Widget _buildPhotosSection() {
    final existingImage = _ctrl.selectedTerrain.value?.displayImage ?? '';

    return Obx(() {
      final hasExistingImage = existingImage.isNotEmpty;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: appSurfaceDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
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
                  decoration: appSurfaceDecoration(
                    color: kGreenLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    PhosphorIconsLight.imageSquare,
                    color: kGreen,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Photos',
                    style: TextStyle(
                      color: kTextPrim,
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
                  foregroundColor: kGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: kBorder),
                ),
              ),
            ),
            if (hasExistingImage && _images.isEmpty) ...[
              const SizedBox(height: 12),
              // L'ancien errorBuilder renvoyait un SizedBox.shrink() : l'image
              // disparaissait sans laisser de trace, ce qui ressemblait à un bug.
              AppNetworkImage(
                url: existingImage,
                height: 92,
                width: double.infinity,
                borderRadius: BorderRadius.circular(12),
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
    if (images.isEmpty) return;

    // Compression avant envoi : un propriétaire ajoute souvent 4 ou 5 photos
    // de terrain d'un coup, soit plusieurs dizaines de mégaoctets bruts sur
    // une connexion mobile.
    final compressed = await AppAsync.mapBounded(
      images,
      (image) async => XFile((await AppImage.compress(File(image.path))).path),
      concurrency: 3,
    );
    _images.addAll(compressed);
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
        // Localisation — saisie libre ou GPS
        const Text(
          'Localisation *',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: kTextSub,
          ),
        ),
        const SizedBox(height: 6),
        Obx(() {
          final commune = _commune.value.trim();
          final loading = _isLocating.value;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: loading ? null : _showAddressPicker,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAF7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsLight.mapPin,
                    size: 18,
                    color: commune.isNotEmpty ? kGreen : kTextLight,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: loading
                        ? const Text(
                            'Détection en cours…',
                            style: TextStyle(
                              color: kTextLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : Text(
                            commune.isNotEmpty
                                ? commune
                                : 'Choisir l\'adresse…',
                            style: TextStyle(
                              color: commune.isNotEmpty
                                  ? kTextPrim
                                  : kTextLight,
                              fontSize: 13,
                              fontWeight: commune.isNotEmpty
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kGreen,
                      ),
                    )
                  else
                    const Icon(
                      PhosphorIconsLight.magnifyingGlass,
                      size: 16,
                      color: kTextSub,
                    ),
                ],
              ),
            ),
          );
        }),
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
            color: kTextSub,
          ),
        ),
        const SizedBox(height: 6),
        Obx(
          () => Column(
            children: [
              ..._contactPhones.map(
                (phone) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAF7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          PhosphorIconsLight.phone,
                          color: kGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 14,
                              color: kTextPrim,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _contactPhones.remove(phone),
                          icon: const Icon(
                            PhosphorIconsLight.trash,
                            color: kRed,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(PhosphorIconsLight.phone, color: kGreen, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: kTextPrim,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Ajouter un numéro...',
                    hintStyle: TextStyle(
                      color: kTextLight,
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
                icon: const Icon(
                  PhosphorIconsLight.plusCircle,
                  color: kGreen,
                  size: 20,
                ),
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
          color: kTextSub,
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
            border: Border.all(color: kBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: obs.value,
              isExpanded: true,
              icon: const Icon(
                PhosphorIconsLight.caretDown,
                color: kGreen,
                size: 16,
              ),
              style: const TextStyle(
                color: kTextPrim,
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

  Widget _buildMiniTerrainCard(_SubTerrainDraft miniTerrain, int index) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
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
                  color: kGreenLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  PhosphorIconsLight.soccerBall,
                  color: kGreen,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Terrain ${index + 1}',
                  style: const TextStyle(
                    color: kTextPrim,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Obx(
                () => Switch.adaptive(
                  value: miniTerrain.isActive.value,
                  activeTrackColor: kGreen,
                  onChanged: (value) => miniTerrain.isActive.value = value,
                ),
              ),
              if (_miniTerrains.length > 1)
                IconButton(
                  onPressed: () => _removeMiniTerrain(miniTerrain),
                  icon: const Icon(
                    PhosphorIconsLight.trash,
                    color: kRed,
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
      final hasFull = miniTerrain.pricingPeriods.any(
        (period) => period.target.value == 'FULL',
      );
      final hasHalf = miniTerrain.pricingPeriods.any(
        (period) => period.target.value == 'HALF',
      );

      if (!hasFull && !hasHalf) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarifs',
              style: TextStyle(
                color: kTextSub,
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
              color: kTextSub,
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
              label: hasFull
                  ? 'Ajouter demi terrain'
                  : 'Ajouter terrain complet',
              onTap: () =>
                  miniTerrain.addPricingPeriod(hasFull ? 'HALF' : 'FULL'),
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

      // Collapsed when both types exist and this is not the active one.
      final hasBoth =
          miniTerrain.pricingPeriods.any((p) => p.target.value == 'FULL') &&
          miniTerrain.pricingPeriods.any((p) => p.target.value == 'HALF');
      final isCollapsed =
          hasBoth &&
          miniTerrain.expandedTarget.value != null &&
          miniTerrain.expandedTarget.value != target;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isCollapsed
            ? () => miniTerrain.expandedTarget.value = target
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: isCollapsed
              ? Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: kTextPrim,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${periods.length} tarif${periods.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: kTextSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      PhosphorIconsLight.caretDown,
                      size: 16,
                      color: kTextSub,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: kTextPrim,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...periods.map((period) {
                      // Show expanded period if it's the selected one,
                      // or if it's the only period of its type.
                      final isExpanded =
                          miniTerrain.expandedPeriod.value == period ||
                          (miniTerrain.expandedPeriod.value == null &&
                              periods.length == 1);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: isExpanded
                            ? _buildPricingPeriodRow(miniTerrain, period)
                            : _buildPricingPeriodSummary(miniTerrain, period),
                      );
                    }),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => miniTerrain.addPricingPeriod(target),
                        icon: const Icon(PhosphorIconsLight.plus, size: 16),
                        label: const Text('Ajouter un tarif'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: kGreen,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => miniTerrain.removePricingPeriod(period),
              tooltip: 'Supprimer cette plage tarifaire',
              // 34×28 auparavant : sous le minimum de 48 dp, pour une action
              // destructive — on rate la cible et on supprime par erreur.
              constraints: const BoxConstraints.tightFor(
                width: AppTouch.minTarget,
                height: AppTouch.minTarget,
              ),
              icon: const Icon(PhosphorIconsLight.trash, color: kRed, size: 18),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _CompactField(
                  label: 'Début',
                  ctrl: period.startCtrl,
                  hint: '18:00',
                  isTime: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactField(
                  label: 'Fin',
                  ctrl: period.endCtrl,
                  hint: '23:00',
                  isTime: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactField(
                  label: 'Prix / heure',
                  ctrl: period.priceCtrl,
                  hint: '20000',
                  keyboardType: TextInputType.number,
                  digitsOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Jours',
            style: TextStyle(
              color: kTextSub,
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
              style: TextStyle(color: kTextLight, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingPeriodSummary(
    _SubTerrainDraft miniTerrain,
    _PricingPeriodDraft period,
  ) {
    final start = period.startCtrl.text;
    final end = period.endCtrl.text;
    final label = period.labelCtrl.text.trim().isNotEmpty
        ? period.labelCtrl.text.trim()
        : _periodLabel(start, end);
    final price = period.priceCtrl.text.trim();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => miniTerrain.expandedPeriod.value = period,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAF7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: kTextPrim,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$start – $end',
                    style: const TextStyle(
                      color: kTextSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (price.isNotEmpty) ...[
              Text(
                '$price F/h',
                style: const TextStyle(
                  color: kGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
            ],
            IconButton(
              onPressed: () => miniTerrain.removePricingPeriod(period),
              tooltip: 'Supprimer cette plage tarifaire',
              constraints: const BoxConstraints.tightFor(
                width: AppTouch.minTarget,
                height: AppTouch.minTarget,
              ),
              icon: const Icon(PhosphorIconsLight.trash, color: kRed, size: 18),
            ),
            const Icon(PhosphorIconsLight.caretDown, size: 16, color: kTextSub),
          ],
        ),
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
            color: kTextSub,
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
                color: on ? kGreenLight : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: on ? kGreen : kBorder),
              ),
              child: Row(
                children: [
                  Icon(icon, color: on ? kGreen : kTextLight, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                        color: on ? kGreen : kTextSub,
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
          backgroundColor: kGreen,
          disabledBackgroundColor: kGreen.withAlpha(120),
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

  /// `true` si l'utilisateur a saisi quelque chose qui serait perdu.
  ///
  /// On ne demande confirmation que dans ce cas : un assistant vide qu'on
  /// referme aussitôt ne doit pas poser de question.
  ///
  /// En édition les champs sont préremplis : on compare à un instantané pris à
  /// l'ouverture plutôt qu'au vide, pour ne pas interroger quelqu'un qui n'a
  /// rien touché.
  String get _inputSignature => [
    _nameCtrl.text.trim(),
    _addressCtrl.text.trim(),
    _descCtrl.text.trim(),
    _priceCtrl.text.trim(),
    _images.length,
    _miniTerrains.length,
    _contactPhones.length,
  ].join('|');

  late final String _initialSignature;

  bool get _hasUnsavedInput =>
      _inputSignature != _initialSignature || _step.value > 0;

  /// Gère le retour, matériel comme applicatif : on recule d'une étape tant
  /// qu'il en reste, et on ne quitte qu'après confirmation si de la saisie
  /// serait perdue.
  Future<void> _handleBack() async {
    if (_step.value > 0) {
      _goPrevious();
      return;
    }
    if (_hasUnsavedInput && !await AppDialog.confirmDiscard()) return;
    _ctrl.goBack();
  }

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
    final error = _miniTerrains[index].validationError;
    if (error != null) {
      AppSnackbar.warning(error);
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
      // On nomme le premier terrain fautif et la raison exacte, au lieu de
      // réciter toutes les règles possibles.
      final firstError = _miniTerrains
          .map((terrain) => terrain.validationError)
          .firstWhere((error) => error != null, orElse: () => null);
      AppSnackbar.warning(
        firstError ?? 'Ajoutez au moins un terrain réservable au complexe.',
      );
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
      AppSnackbar.error(
        'Impossible d\'enregistrer le terrain. Vérifiez les informations et réessayez.',
      );
    } finally {
      _isSaving.value = false;
    }
  }

  int _deriveComplexPrice(List<SubTerrainModel> subTerrains) {
    final prices =
        subTerrains
            .expand(
              (subTerrain) => [
                subTerrain.pricePerHour,
                ...subTerrain.pricingPeriods.map(
                  (period) => period.pricePerHour,
                ),
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
                  color: isPrimary ? kGreen : kBorder,
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
                      errorBuilder: (_, _, _) => const Icon(
                        PhosphorIconsLight.imageBroken,
                        color: kTextLight,
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
                color: kRed,
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
              child: const Icon(
                PhosphorIconsRegular.x,
                color: Colors.white,
                size: 12,
              ),
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
                color: kGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsRegular.check,
                color: Colors.white,
                size: 12,
              ),
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
        if (terrain.pricingPeriods.any(
          (period) => period.target.value == 'FULL',
        ))
          'Complet',
        if (terrain.pricingPeriods.any(
          (period) => period.target.value == 'HALF',
        ))
          'Demi-terrain',
      ].join(', ');

      return Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAF7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: kGreenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: kGreen,
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
                      color: kTextPrim,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$formats · ${cuts.isEmpty ? 'Aucune découpe' : cuts}',
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
            IconButton(
              onPressed: onEdit,
              tooltip: 'Modifier ce terrain',
              constraints: const BoxConstraints.tightFor(
                width: AppTouch.minTarget,
                height: AppTouch.minTarget,
              ),
              icon: const Icon(
                PhosphorIconsLight.pencilSimple,
                color: kGreen,
                size: 18,
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                tooltip: 'Supprimer ce terrain',
                constraints: const BoxConstraints.tightFor(
                  width: AppTouch.minTarget,
                  height: AppTouch.minTarget,
                ),
                icon: const Icon(
                  PhosphorIconsLight.trash,
                  color: kRed,
                  size: 18,
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _ReviewStat extends StatelessWidget {
  final dynamic icon;
  final Color color;
  final String value;
  final String label;

  const _ReviewStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: kTextPrim,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: kTextSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _ReviewBadge({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Card({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
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
              Icon(icon, size: 20, color: kTextLight),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextPrim,
                ),
              ),
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

  const _Field({
    required this.label,
    required this.ctrl,
    required this.hint,
    required this.icon,
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
            color: kTextSub,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, color: kGreen, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: const TextStyle(
                    fontSize: 14,
                    color: kTextPrim,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: kTextLight,
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

  /// Ouvre un sélecteur d'heure au lieu du clavier.
  ///
  /// Ces champs attendent `18:00` et ouvraient un clavier **alphabétique**,
  /// sans masque ni contrôle. L'écran Disponibilités utilise déjà
  /// `showTimePicker` correctement — on s'aligne dessus.
  final bool isTime;

  /// Restreint la saisie aux chiffres — un montant n'a pas de lettres.
  final bool digitsOnly;

  const _CompactField({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.keyboardType,
    this.isTime = false,
    this.digitsOnly = false,
  });

  Future<void> _pickTime(BuildContext context) async {
    final parts = ctrl.text.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first)?.clamp(0, 23) ?? 18,
      minute: parts.length > 1
          ? (int.tryParse(parts[1])?.clamp(0, 59) ?? 0)
          : 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        // Format 24 h : « 6:00 PM » n'a pas de sens pour un tarif de terrain.
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;

    ctrl.text =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
  }

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
            color: kTextSub,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 42,
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            readOnly: isTime,
            onTap: isTime ? () => _pickTime(context) : null,
            inputFormatters: digitsOnly
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            style: const TextStyle(
              color: kTextPrim,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: kTextLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAF7),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kGreen),
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
          color: selected ? kGreen : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? kGreen : kBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : kTextSub,
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

  const _AddPricingTypeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kGreenLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kGreen),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PhosphorIconsLight.plus, size: 15, color: kGreen),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kGreen,
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

class _AddressPickerSheet extends StatefulWidget {
  final Future<void> Function() onUseGps;
  final void Function(String commune, double lat, double lng) onSelect;
  final Future<List<Map<String, dynamic>>> Function(String query) searchFn;

  const _AddressPickerSheet({
    required this.onUseGps,
    required this.onSelect,
    required this.searchFn,
  });

  @override
  State<_AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends State<_AddressPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() {
      _searching = true;
    });
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await widget.searchFn(value);
      if (mounted) {
        setState(() {
          _results = results;
          _searching = false;
        });
      }
    });
  }

  String _extractCommune(Map<String, dynamic> result) {
    final addr = result['address'] as Map<String, dynamic>? ?? {};
    return addr['suburb']?.toString() ??
        addr['neighbourhood']?.toString() ??
        addr['quarter']?.toString() ??
        addr['city_district']?.toString() ??
        addr['city']?.toString() ??
        addr['town']?.toString() ??
        addr['village']?.toString() ??
        addr['county']?.toString() ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Text(
                      'Adresse du complexe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kTextPrim,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: kBgSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.x,
                          size: 14,
                          color: kTextSub,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: kBgSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(
                        PhosphorIconsLight.magnifyingGlass,
                        size: 18,
                        color: kTextSub,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kTextPrim,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Rechercher un quartier, commune…',
                            hintStyle: TextStyle(
                              color: kTextLight,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      if (_searching)
                        const Padding(
                          padding: EdgeInsets.only(right: 14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onUseGps,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: kGreenLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kGreen.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          PhosphorIconsLight.mapPin,
                          size: 18,
                          color: kGreen,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Utiliser ma position GPS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kGreen,
                            ),
                          ),
                        ),
                        Icon(
                          PhosphorIconsLight.caretRight,
                          size: 16,
                          color: kGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_results.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Résultats',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kTextSub,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    final commune = _extractCommune(result);
                    final displayName =
                        result['display_name']?.toString() ?? '';
                    final title = commune.isNotEmpty ? commune : displayName;
                    final lat =
                        double.tryParse(result['lat']?.toString() ?? '') ?? 0;
                    final lng =
                        double.tryParse(result['lon']?.toString() ?? '') ?? 0;
                    final isLast = index == _results.length - 1;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelect(title, lat, lng);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : const Border(
                                  bottom: BorderSide(color: kDivider),
                                ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: kBgSurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                PhosphorIconsLight.mapPin,
                                size: 16,
                                color: kTextSub,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: kTextPrim,
                                    ),
                                  ),
                                  if (displayName.isNotEmpty &&
                                      displayName != title)
                                    Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: kTextSub,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              PhosphorIconsLight.caretRight,
                              size: 14,
                              color: kTextLight,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
            color: kTextSub,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: kBgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: kTextPrim),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: kTextLight, fontSize: 13),
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
