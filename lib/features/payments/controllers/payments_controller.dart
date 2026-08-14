import 'package:get/get.dart';
import '../../../core/utils/app_format.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/revenue_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../routes/app_routes.dart';

class TransactionModel {
  final String id;
  final DateTime rawDate;
  final String date;
  final String client;
  final String terrain;
  final int amount;
  final String method; // Wave / Orange Money / Yas Money
  final String status; // paid / pending / failed
  final String timeSlot; // ex: "16h00 - 17h00"
  final String reference;

  TransactionModel({
    required this.id,
    required this.rawDate,
    required this.date,
    required this.client,
    required this.terrain,
    required this.amount,
    required this.method,
    required this.status,
    this.timeSlot = '',
    this.reference = '',
  });

  factory TransactionModel.fromOwnerTransaction(OwnerTransaction tx) {
    return TransactionModel(
      id: tx.id,
      rawDate: tx.date,
      date: tx.dateLabel,
      client: tx.client,
      terrain: tx.terrain,
      amount: tx.amount,
      method: tx.method,
      status: tx.status,
      timeSlot: tx.timeSlot,
      reference: tx.reference,
    );
  }
}

class PaymentsController extends GetxController {
  final _service = RevenueService();
  final _authService = AuthService();

  final totalRevenue = 0.obs;
  final monthlyRevenue = 0.obs;
  final pendingAmount = 0.obs;
  final payoutMethod = RxnString();
  final payoutPhone = RxnString();

  // Solde disponible pour retrait (débloqué après scan QR, pas encore viré)
  final availableBalance = 0.obs;

  /// `true` quand le solde n'a pas pu être récupéré : l'écran doit le dire
  /// plutôt que d'afficher un zéro qui ressemble à un solde réel.
  final balanceUnavailable = false.obs;
  final pendingPaymentsCount = 0.obs;
  final isWithdrawing = false.obs;

  final transactions = <TransactionModel>[].obs;
  final selectedFilter = 'all'.obs;
  final selectedPeriod = 'month'.obs; // day / week / month
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPayments();
  }

  Future<void> loadPayments() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final data = await _service.getOwnerRevenueData();
      totalRevenue.value = data.totalPaid;
      monthlyRevenue.value = data.monthPaid;
      pendingAmount.value = data.pendingAmount;
      transactions.value = data.transactions
          .map(TransactionModel.fromOwnerTransaction)
          .toList();
      await Future.wait([_loadPayoutInfo(), _loadPayoutBalance()]);
    } catch (_) {
      errorMessage.value =
          'Impossible de charger les paiements. Vérifiez votre connexion.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPayoutBalance() async {
    try {
      final token = await _authService.savedToken();
      if (token == null || token.isEmpty) return;
      final data = await _authService.getPayoutBalance(token);
      availableBalance.value = data['availableAmount'] as int? ?? 0;
      pendingPaymentsCount.value = data['pendingPaymentsCount'] as int? ?? 0;
      balanceUnavailable.value = false;
    } catch (_) {
      // Ne pas afficher 0 : sur un écran d'argent, un faux zéro fait croire au
      // propriétaire qu'il n'a rien à retirer. On signale que la valeur est
      // indisponible et on conserve la dernière connue.
      balanceUnavailable.value = true;
    }
  }

  /// Lance un retrait DexPay. [phone] : numéro du compte à créditer.
  /// DexPay détecte l'opérateur automatiquement (Wave, Orange, WhatsApp...).
  Future<void> withdraw(String phone, {int? amount}) async {
    isWithdrawing.value = true;
    try {
      final token = await _authService.savedToken();
      if (token == null || token.isEmpty) throw Exception('Non connecté');
      await _authService.requestPayout(token, phone: phone, amount: amount);
      await Future.wait([_loadPayoutBalance(), loadPayments()]);
      AppSnackbar.success('Votre retrait a été soumis avec succès.');
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      final msg = raw.contains('Non connecté')
          ? 'Session expirée. Reconnectez-vous.'
          : 'Impossible d\'effectuer le retrait. Réessayez.';
      AppSnackbar.error(msg);
    } finally {
      isWithdrawing.value = false;
    }
  }

  /// Transactions filtrées par statut
  List<TransactionModel> get filteredTransactions {
    final periodItems = periodTransactions;
    if (selectedFilter.value == 'all') return periodItems;
    return periodItems.where((t) => t.status == selectedFilter.value).toList();
  }

  List<TransactionModel> get periodTransactions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = switch (selectedPeriod.value) {
      'day' => today,
      'week' => today.subtract(Duration(days: today.weekday - 1)),
      _ => DateTime(now.year, now.month),
    };
    final end = switch (selectedPeriod.value) {
      'day' => start.add(const Duration(days: 1)),
      'week' => start.add(const Duration(days: 7)),
      _ => DateTime(now.year, now.month + 1),
    };

    return transactions.where((t) {
      return !t.rawDate.isBefore(start) && t.rawDate.isBefore(end);
    }).toList();
  }

  /// Transactions groupées par date
  Map<String, List<TransactionModel>> get groupedTransactions {
    final filtered = filteredTransactions;
    final map = <String, List<TransactionModel>>{};
    for (final t in filtered) {
      map.putIfAbsent(t.date, () => []).add(t);
    }
    return map;
  }

  /// Répartition par méthode de paiement (uniquement les payés)
  Map<String, int> get methodBreakdown {
    final paid = periodTransactions.where((t) => t.status == 'paid');
    final map = <String, int>{};
    for (final t in paid) {
      map[t.method] = (map[t.method] ?? 0) + t.amount;
    }
    return map;
  }

  int get totalPaidAmount => periodTransactions
      .where((t) => t.status == 'paid')
      .fold(0, (s, t) => s + t.amount);

  void setFilter(String f) => selectedFilter.value = f;
  void setPeriod(String p) {
    selectedPeriod.value = p;
    selectedFilter.value = 'all';
  }

  Future<void> refreshPayments() async {
    await loadPayments();
  }

  Future<void> goToPayoutSettings() async {
    await Get.toNamed(Routes.paymentMethods);
    await _loadPayoutInfo();
  }

  int get paidCount =>
      periodTransactions.where((t) => t.status == 'paid').length;
  int get pendingCount =>
      periodTransactions.where((t) => t.status == 'pending').length;
  int get failedCount =>
      periodTransactions.where((t) => t.status == 'failed').length;

  String formatAmount(int v) => AppFormat.amountCompact(v);

  Future<void> _loadPayoutInfo() async {
    try {
      final token = await _authService.savedToken();
      if (token == null || token.isEmpty) return;
      final info = await _authService.getPayoutInfo(token);
      final preferred =
          info['preferredPayoutMethod']?.toString() ??
          (info['payoutWavePhone'] != null
              ? 'WAVE'
              : info['payoutOrangePhone'] != null
              ? 'ORANGE_MONEY'
              : info['payoutFreePhone'] != null
              ? 'FREE_MONEY'
              : null);
      payoutMethod.value = preferred;
      payoutPhone.value = switch (preferred) {
        'WAVE' => info['payoutWavePhone']?.toString(),
        'ORANGE_MONEY' => info['payoutOrangePhone']?.toString(),
        'FREE_MONEY' => info['payoutFreePhone']?.toString(),
        _ => null,
      };
    } catch (_) {
      payoutMethod.value = null;
      payoutPhone.value = null;
    }
  }

  String get payoutMethodLabel {
    switch (payoutMethod.value) {
      case 'WAVE':
        return 'Wave';
      case 'ORANGE_MONEY':
        return 'Orange Money';
      case 'FREE_MONEY':
        return 'Yas Money';
      default:
        return 'Non configuré';
    }
  }
}
