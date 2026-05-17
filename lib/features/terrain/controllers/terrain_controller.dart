import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/terrain_service.dart';
import '../../../routes/app_routes.dart';

class SubTerrainModel {
  final String? id;
  final String name;
  final String? physicalName;
  final String? divisionGroup;
  final String divisionType;
  final int divisionIndex;
  final int capacity;
  final String type;
  final String? surface;
  final int? pricePerHour;
  final List<PricingPeriodModel> pricingPeriods;
  final bool isActive;

  const SubTerrainModel({
    this.id,
    required this.name,
    this.physicalName,
    this.divisionGroup,
    this.divisionType = 'FULL',
    this.divisionIndex = 0,
    required this.capacity,
    required this.type,
    this.surface,
    this.pricePerHour,
    this.pricingPeriods = const [],
    this.isActive = true,
  });

  factory SubTerrainModel.fromJson(Map<String, dynamic> json) {
    return SubTerrainModel(
      id: json['id'],
      name: json['name'] ?? '',
      physicalName: json['physicalName'],
      divisionGroup: json['divisionGroup'],
      divisionType: json['divisionType'] ?? 'FULL',
      divisionIndex: (json['divisionIndex'] ?? 0) as int,
      capacity: (json['capacity'] ?? 10) as int,
      type: json['type'] ?? '5v5',
      surface: json['surface'],
      pricePerHour: json['pricePerHour'] as int?,
      pricingPeriods: (json['pricingPeriods'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PricingPeriodModel.fromJson)
          .toList(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null && id!.isNotEmpty) 'id': id,
    'name': name,
    if (physicalName != null && physicalName!.isNotEmpty)
      'physicalName': physicalName,
    if (divisionGroup != null && divisionGroup!.isNotEmpty)
      'divisionGroup': divisionGroup,
    'divisionType': divisionType,
    'divisionIndex': divisionIndex,
    'capacity': capacity,
    'type': type,
    if (surface != null && surface!.isNotEmpty) 'surface': surface,
    if (pricePerHour != null && pricePerHour! > 0) 'pricePerHour': pricePerHour,
    'pricingPeriods': pricingPeriods.map((period) => period.toJson()).toList(),
    'isActive': isActive,
  };
}

class PricingPeriodModel {
  final String label;
  final String startTime;
  final String endTime;
  final int pricePerHour;
  final List<int> days;

  const PricingPeriodModel({
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.pricePerHour,
    this.days = const [],
  });

  factory PricingPeriodModel.fromJson(Map<String, dynamic> json) {
    return PricingPeriodModel(
      label: json['label']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '08:00',
      endTime: json['endTime']?.toString() ?? '18:00',
      pricePerHour: (json['pricePerHour'] as num?)?.toInt() ?? 0,
      days: (json['days'] as List<dynamic>? ?? [])
          .whereType<num>()
          .map((day) => day.toInt())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'startTime': startTime,
    'endTime': endTime,
    'pricePerHour': pricePerHour,
    if (days.isNotEmpty) 'days': days,
  };
}

class TerrainModel {
  final String id;
  final String name;
  final String address;
  final String? description;
  final int pricePerHour;
  final String zone;
  final List<String> features;
  final List<String> contactPhones;
  final String? imageUrl;
  final List<String> imageUrls;
  final double rating;
  bool isActive;
  final double? lat;
  final double? lng;
  final String? managerId;
  final List<SubTerrainModel> subTerrains;

  TerrainModel({
    required this.id,
    required this.name,
    required this.address,
    this.description,
    required this.pricePerHour,
    required this.zone,
    this.features = const [],
    this.contactPhones = const [],
    this.imageUrl,
    this.imageUrls = const [],
    this.rating = 0,
    required this.isActive,
    this.lat,
    this.lng,
    this.managerId,
    this.subTerrains = const [],
  });

  factory TerrainModel.fromJson(Map<String, dynamic> json) {
    return TerrainModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      description: json['description'],
      pricePerHour: (json['pricePerHour'] ?? 0) as int,
      zone: json['zone'] ?? 'DAKAR',
      features: (json['features'] as List<dynamic>? ?? []).cast<String>(),
      contactPhones: (json['contactPhones'] as List<dynamic>? ?? [])
          .cast<String>(),
      imageUrl: json['imageUrl'],
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? []).cast<String>(),
      rating: (json['rating'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? true,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      managerId: json['managerId'],
      subTerrains: (json['subTerrains'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SubTerrainModel.fromJson)
          .toList(),
    );
  }

  String get displayCapacity {
    const caps = ['5v5', '7v7', '11v11'];
    final found = features.where((f) => caps.contains(f)).toList();
    return found.isNotEmpty ? found.join(', ') : '—';
  }

  String get displaySurface {
    const surfaces = ['Gazon synthétique', 'Gazon naturel', 'Terre battue'];
    return features.firstWhere((f) => surfaces.contains(f), orElse: () => '—');
  }

  String get displayImage =>
      imageUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');

  int get miniTerrainCount => subTerrains.length;

  int get physicalTerrainCount {
    if (subTerrains.isEmpty) return 1;
    return subTerrains
        .map(
          (subTerrain) =>
              subTerrain.divisionGroup ??
              subTerrain.physicalName ??
              subTerrain.name,
        )
        .toSet()
        .length;
  }

  int get activeMiniTerrainCount =>
      subTerrains.where((subTerrain) => subTerrain.isActive).length;

  String get complexeStatusLabel {
    if (!isActive) return 'En pause';
    if (subTerrains.isEmpty) return 'Complexe simple';
    if (activeMiniTerrainCount == subTerrains.length) return 'Complexe actif';
    if (activeMiniTerrainCount == 0) return 'Découpes en pause';
    return 'Partiellement active';
  }

  String get physicalTerrainLabel {
    final count = physicalTerrainCount;
    return '$count terrain${count > 1 ? 's' : ''}';
  }

  String get reservableUnitLabel {
    if (subTerrains.isEmpty) return '1 terrain';
    return '$miniTerrainCount option${miniTerrainCount > 1 ? 's' : ''}';
  }

  String get displayPriceRange {
    final allPrices = <int>{pricePerHour};
    for (final sub in subTerrains) {
      if (sub.pricePerHour != null) allPrices.add(sub.pricePerHour!);
      for (final period in sub.pricingPeriods) {
        allPrices.add(period.pricePerHour);
      }
    }

    final prices = allPrices.toList()..sort();
    if (prices.isEmpty) return '$pricePerHour F/h';
    if (prices.length == 1) return '${prices.first} F/h';
    return '${prices.first} - ${prices.last} F/h';
  }
}

class TerrainReviewModel {
  final String id;
  final String terrainId;
  final String userId;
  final double rating;
  final String? comment;
  final String userName;
  final String? userAvatar;
  final DateTime createdAt;

  TerrainReviewModel({
    required this.id,
    required this.terrainId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
  });

  factory TerrainReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return TerrainReviewModel(
      id: json['id']?.toString() ?? '',
      terrainId: json['terrainId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'],
      userName: user != null
          ? '${user['firstName'] ?? user['first_name']} ${user['lastName'] ?? user['last_name']}'
          : 'Anonyme',
      userAvatar: user?['avatarUrl'] ?? user?['avatar_url'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class TerrainController extends GetxController {
  final _service = TerrainService();

  final terrains = <TerrainModel>[].obs;
  final allTerrains = <TerrainModel>[].obs;
  final isLoading = false.obs;
  final selectedTerrain = Rxn<TerrainModel>();
  final reviews = <TerrainReviewModel>[].obs;
  final isLoadingReviews = false.obs;
  final currentPhotoIndex = 0.obs;
  final selectedTabIndex = 0.obs;
  final searchQuery = ''.obs;
  final statusFilter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    loadTerrains();
  }

  Future<void> loadTerrains() async {
    isLoading.value = true;
    try {
      final data = await _service.getMesTerrains();
      final list = data
          .map((e) => TerrainModel.fromJson(e as Map<String, dynamic>))
          .toList();
      allTerrains.value = list;
      _applyFilters();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les terrains',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshTerrains() => loadTerrains();

  void onSearch(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void selectStatusFilter(String filter) {
    statusFilter.value = filter;
    _applyFilters();
  }

  void _applyFilters() {
    final query = searchQuery.value.trim().toLowerCase();
    Iterable<TerrainModel> filtered = allTerrains;

    if (statusFilter.value == 'active') {
      filtered = filtered.where((t) => t.isActive);
    } else if (statusFilter.value == 'inactive') {
      filtered = filtered.where((t) => !t.isActive);
    }

    if (query.isNotEmpty) {
      filtered = filtered.where(
        (t) =>
            t.name.toLowerCase().contains(query) ||
            t.address.toLowerCase().contains(query) ||
            t.zone.toLowerCase().contains(query) ||
            t.subTerrains.any(
              (subTerrain) => subTerrain.name.toLowerCase().contains(query),
            ),
      );
    }

    terrains.value = filtered.toList();
  }

  int get totalTerrains => allTerrains.length;
  int get activeTerrains => allTerrains.where((t) => t.isActive).length;
  int get inactiveTerrains => allTerrains.where((t) => !t.isActive).length;
  int get totalPhysicalTerrains => allTerrains.fold<int>(
    0,
    (sum, terrain) => sum + terrain.physicalTerrainCount,
  );

  Future<void> toggleStatus(String id) async {
    final idx = terrains.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final terrain = terrains[idx];
    final newStatus = !terrain.isActive;
    try {
      await _service.modifierTerrain(id, {'isActive': newStatus});
      terrain.isActive = newStatus;
      terrains.refresh();
      final allIdx = allTerrains.indexWhere((t) => t.id == id);
      if (allIdx != -1) allTerrains[allIdx].isActive = newStatus;
      _applyFilters();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de modifier le statut',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void deleteConfirm(String id) {
    Get.defaultDialog(
      title: 'Supprimer le terrain',
      middleText: 'Cette action est irréversible. Confirmer ?',
      textConfirm: 'Supprimer',
      textCancel: 'Annuler',
      onConfirm: () async {
        Get.back();
        try {
          await _service.supprimerTerrain(id);
          terrains.removeWhere((t) => t.id == id);
          allTerrains.removeWhere((t) => t.id == id);
          Get.snackbar(
            'Succès',
            'Terrain supprimé',
            snackPosition: SnackPosition.TOP,
          );
        } catch (e) {
          Get.snackbar(
            'Erreur',
            'Impossible de supprimer le terrain',
            snackPosition: SnackPosition.TOP,
          );
        }
      },
    );
  }

  void goToDetail(TerrainModel terrain) {
    selectedTerrain.value = terrain;
    reviews.clear();
    currentPhotoIndex.value = 0;
    loadReviews(terrain.id);
    Get.toNamed(Routes.terrainDetail, arguments: terrain);
  }

  Future<void> loadReviews(String terrainId) async {
    isLoadingReviews.value = true;
    try {
      final data = await _service.getReviews(terrainId);
      reviews.value = data
          .map((e) => TerrainReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur chargement avis: $e');
    } finally {
      isLoadingReviews.value = false;
    }
  }

  void goToForm(TerrainModel? terrain) {
    selectedTerrain.value = terrain;
    Get.toNamed(Routes.terrainForm, arguments: terrain);
  }

  Future<void> saveTerrain({
    required String name,
    required String address,
    required String zone,
    required int pricePerHour,
    required double lat,
    required double lng,
    String? description,
    List<String> features = const [],
    List<String> contactPhones = const [],
    required List<SubTerrainModel> subTerrains,
    List<XFile> images = const [],
    String? managerId,
  }) async {
    final data = {
      'name': name,
      'address': address,
      'zone': zone,
      'pricePerHour': pricePerHour,
      'lat': lat,
      'lng': lng,
      if (description != null) 'description': description,
      'features': features,
      'contactPhones': contactPhones,
      'subTerrains': subTerrains.map((s) => s.toJson()).toList(),
    };

    final terrain = selectedTerrain.value;
    final String terrainId;

    if (terrain == null) {
      final createData = <String, dynamic>{...data};
      if (managerId != null) createData['managerId'] = managerId;
      final result = await _service.creerTerrain(createData);
      terrainId = result['id'] as String;
    } else {
      await _service.modifierTerrain(terrain.id, data);
      terrainId = terrain.id;
    }

    if (images.isNotEmpty) {
      await _service.uploadImages(terrainId, images);
    }

    await loadTerrains();
  }

  void goBack() => Get.back();
}
