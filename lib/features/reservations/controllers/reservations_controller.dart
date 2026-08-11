import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../../core/services/reservation_service.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';

class ReservationModel {
  final String id;
  final String clientName;
  final String teamName;
  final String terrain;
  final String subTerrainName;
  final String date;
  final DateTime? rawDate;
  final String timeSlot;
  final String startSlot;
  final int amount;
  // confirmed / pending / awaiting_owner_confirmation / cancelled
  final String status;
  final String phone;
  final String reference;
  final String paymentMethod;
  final String paymentStatus;
  final String checkedInAt;
  /// QR_OWNER (scanné) ou MANUAL_OWNER (validé à la main) — écran 20.
  final String checkInMethod;
  final bool isDeposit;
  final int? depositAmount;

  ReservationModel({
    required this.id,
    required this.clientName,
    required this.teamName,
    required this.terrain,
    required this.subTerrainName,
    required this.date,
    this.rawDate,
    required this.timeSlot,
    required this.startSlot,
    required this.amount,
    required this.status,
    required this.phone,
    required this.reference,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.checkedInAt,
    this.checkInMethod = '',
    this.isDeposit = false,
    this.depositAmount,
  });

  /// Solde restant à encaisser en espèces sur place (design écran 27).
  int get balanceDue =>
      isDeposit && depositAmount != null ? amount - depositAmount! : 0;

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final terrain = json['terrain'] as Map<String, dynamic>?;
    final subTerrain = json['subTerrain'] as Map<String, dynamic>?;
    final firstName = (user?['firstName'] ?? '').toString().trim();
    final lastName = (user?['lastName'] ?? '').toString().trim();
    final clientName = '$firstName $lastName'.trim();
    final isDeposit =
        json['paymentType']?.toString() == 'DEPOSIT' &&
        json['depositAmount'] != null;
    final depositPaidAt = json['depositPaidAt'];

    return ReservationModel(
      id: (json['id'] ?? '').toString(),
      clientName: clientName.isNotEmpty ? clientName : 'Client MiniFoot',
      teamName: (user?['phone'] ?? json['reference'] ?? 'Client').toString(),
      terrain: (terrain?['name'] ?? 'Terrain').toString(),
      subTerrainName: (subTerrain?['name'] ?? '').toString(),
      date: _formatDate(json['date']),
      rawDate: DateTime.tryParse(json['date']?.toString() ?? '')?.toLocal(),
      timeSlot: _formatSlot(json['startSlot'], json['endSlot']),
      startSlot: (json['startSlot'] ?? '').toString(),
      amount: _asInt(json['finalPrice'] ?? json['totalPrice']),
      status: _mapStatus(json['status'], isDeposit, depositPaidAt),
      phone: (user?['phone'] ?? '').toString(),
      reference: (json['reference'] ?? '').toString(),
      paymentMethod: _formatPaymentMethod(json['paymentMethod']),
      paymentStatus: _formatPaymentStatus(json['payments']),
      checkedInAt: _formatDateTime(json['checkedInAt']),
      checkInMethod: (json['checkInMethod'] ?? '').toString(),
      isDeposit: isDeposit,
      depositAmount: isDeposit ? _asInt(json['depositAmount']) : null,
    );
  }

  bool get canCancel =>
      status == 'pending' || status == 'awaiting_owner_confirmation';
  bool get isCheckedIn => checkedInAt.isNotEmpty;

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return value?.toString() ?? '';
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  static String _formatDateTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    return DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(date);
  }

  static String _formatSlot(dynamic start, dynamic end) {
    final startText = start?.toString() ?? '';
    final endText = end?.toString() ?? '';
    if (startText.isEmpty && endText.isEmpty) return '';
    return '$startText – $endText';
  }

  static String _mapStatus(dynamic value, bool isDeposit, dynamic depositPaidAt) {
    switch (value?.toString()) {
      case 'CONFIRMED':
      case 'COMPLETED':
        return 'confirmed';
      case 'CANCELLED':
        return 'cancelled';
      case 'PENDING_PAYMENT':
      default:
        if (isDeposit && depositPaidAt != null) {
          return 'awaiting_owner_confirmation';
        }
        return 'pending';
    }
  }

  static String _formatPaymentMethod(dynamic value) {
    switch (value?.toString()) {
      case 'WAVE':
        return 'Wave';
      case 'ORANGE_MONEY':
        return 'Orange Money';
      case 'FREE_MONEY':
        return 'Free Money';
      default:
        return value?.toString() ?? 'Non défini';
    }
  }

  static String _formatPaymentStatus(dynamic value) {
    if (value is! List || value.isEmpty) return 'Aucun paiement';
    final lastPayment = value.last;
    final status = lastPayment is Map<String, dynamic>
        ? lastPayment['status']?.toString()
        : null;
    switch (status) {
      case 'COMPLETED':
        return 'Payé';
      case 'FAILED':
        return 'Échoué';
      case 'REFUNDED':
        return 'Remboursé';
      case 'PENDING':
      default:
        return 'En attente';
    }
  }
}

/// Onglets de l'écran Réservations (design "Liste & filtres", écran 25).
enum ReservationTab { today, upcoming, past }

class ReservationsController extends GetxController {
  final _service = ReservationService();
  final _allReservations = <ReservationModel>[].obs;
  final selectedTab = ReservationTab.today.obs;
  final isLoading = false.obs;

  /// Message d'erreur du dernier chargement. Vide = pas d'erreur.
  ///
  /// Sans lui, un échec réseau se présentait comme une liste vide, message
  /// d'accueil compris — trompeur et sans moyen de réessayer.
  final errorMessage = ''.obs;

  /// Pagination. Le backend renvoie 50 éléments par page et le total.
  final currentPage = 1.obs;
  final isLoadingMore = false.obs;
  final total = 0.obs;

  bool get hasMore => _allReservations.length < total.value;

  @override
  void onInit() {
    super.onInit();
    loadReservations();
  }

  Future<void> loadReservations() async {
    isLoading.value = true;
    errorMessage.value = '';
    currentPage.value = 1;
    try {
      final result = await _service.getOwnerReservations();
      total.value = result.total;
      _allReservations.value = result.items
          .map(
            (item) => ReservationModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      errorMessage.value =
          'Impossible de charger les réservations. Vérifiez votre connexion.';
    } finally {
      isLoading.value = false;
    }
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<ReservationModel> get _sortedByDateThenSlot {
    final list = List<ReservationModel>.of(_allReservations);
    list.sort((a, b) {
      final dateCompare = (a.rawDate ?? DateTime(0)).compareTo(
        b.rawDate ?? DateTime(0),
      );
      if (dateCompare != 0) return dateCompare;
      return a.startSlot.compareTo(b.startSlot);
    });
    return list;
  }

  /// Réservations du jour, cancelled comprises (le design les affiche
  /// grisées et barrées plutôt que de les cacher).
  List<ReservationModel> get todayReservations {
    final now = DateTime.now();
    return _sortedByDateThenSlot
        .where((r) => r.rawDate != null && _isSameDay(r.rawDate!, now))
        .toList();
  }

  List<ReservationModel> get upcomingReservations {
    final now = DateTime.now();
    return _sortedByDateThenSlot
        .where(
          (r) =>
              r.rawDate != null &&
              r.rawDate!.isAfter(now) &&
              !_isSameDay(r.rawDate!, now) &&
              r.status != 'cancelled',
        )
        .toList();
  }

  List<ReservationModel> get pastReservations {
    final now = DateTime.now();
    return _sortedByDateThenSlot.reversed
        .where(
          (r) =>
              r.rawDate == null ||
              (r.rawDate!.isBefore(now) && !_isSameDay(r.rawDate!, now)),
        )
        .toList();
  }

  List<ReservationModel> get tabReservations {
    switch (selectedTab.value) {
      case ReservationTab.today:
        return todayReservations;
      case ReservationTab.upcoming:
        return upcomingReservations;
      case ReservationTab.past:
        return pastReservations;
    }
  }

  void setTab(ReservationTab tab) => selectedTab.value = tab;

  /// Charge la page suivante et l'ajoute à la liste.
  ///
  /// Échec silencieux : on ne remplace pas une liste déjà affichée par un
  /// écran d'erreur, l'utilisateur garde ce qu'il a.
  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value || !hasMore) return;
    isLoadingMore.value = true;
    try {
      final result = await _service.getOwnerReservations(
        page: currentPage.value + 1,
      );
      _allReservations.addAll(
        result.items.map(
          (item) => ReservationModel.fromJson(item as Map<String, dynamic>),
        ),
      );
      currentPage.value += 1;
      total.value = result.total;
    } catch (_) {
      // volontairement silencieux
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshReservations() async {
    await loadReservations();
  }

  Future<void> cancelReservation(String id) async {
    final confirmed = await AppDialog.confirm(
      title: 'Refuser la réservation',
      message: 'Cette réservation passera en statut annulé.',
      confirmLabel: 'Refuser',
      cancelLabel: 'Garder',
      destructive: true,
    );
    if (confirmed) await cancelReservationDirect(id);
  }

  Future<void> cancelReservationDirect(String id, {bool notify = true}) async {
    try {
      await _service.cancelOwnerReservation(id);
      await loadReservations();
      if (notify) {
        AppSnackbar.success(
          'Réservation refusée. Le créneau est à nouveau disponible.',
        );
      }
    } catch (e) {
      AppSnackbar.error('Impossible de refuser cette réservation. Réessayez.');
      rethrow;
    }
  }

  /// Confirmation manuelle après encaissement du solde en espèces sur place
  /// (design "Détail d'une réservation", écran 27).
  Future<void> confirmDeposit(String id) async {
    try {
      await _service.confirmOwnerDeposit(id);
      await loadReservations();
      AppSnackbar.success('Réservation confirmée.');
    } catch (e) {
      AppSnackbar.error('Impossible de confirmer cette réservation. Réessayez.');
      rethrow;
    }
  }

  /// Résumé de l'onglet actif : "12 réservations · 1 en attente" + le total
  /// encaissé (paiements complétés uniquement, hors annulées).
  int get tabPendingCount =>
      tabReservations.where((r) => r.status == 'pending').length;

  int get tabTotalAmount => tabReservations
      .where((r) => r.status != 'cancelled')
      .fold(0, (sum, r) => sum + r.amount);

  Future<ReservationModel> getReservationDetail(String id) async {
    final data = await _service.getOwnerReservationDetail(id);
    return ReservationModel.fromJson(data);
  }
}
