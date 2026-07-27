import 'package:intl/intl.dart';

import 'reservation_service.dart';

class OwnerTransaction {
  final String id;
  final DateTime date;
  final String dateLabel;
  final String client;
  final String terrain;
  final int amount;
  final String method;
  final String status;
  final String timeSlot;
  final String reference;

  const OwnerTransaction({
    required this.id,
    required this.date,
    required this.dateLabel,
    required this.client,
    required this.terrain,
    required this.amount,
    required this.method,
    required this.status,
    required this.timeSlot,
    required this.reference,
  });
}

class OwnerRevenueEntry {
  final String label;
  final int amount;
  final int bookings;
  final double occupancy;

  const OwnerRevenueEntry({
    required this.label,
    required this.amount,
    required this.bookings,
    required this.occupancy,
  });
}

class TerrainRevenueStat {
  final String name;
  final int amount;
  final double rate;

  const TerrainRevenueStat({
    required this.name,
    required this.amount,
    required this.rate,
  });
}

class OwnerRevenueData {
  final List<OwnerTransaction> transactions;
  final List<OwnerRevenueEntry> dailyEntries;
  final List<OwnerRevenueEntry> weeklyEntries;
  final List<OwnerRevenueEntry> monthlyEntries;
  final List<TerrainRevenueStat> terrainStats;
  final int totalPaid;
  final int monthPaid;
  final int pendingAmount;

  const OwnerRevenueData({
    required this.transactions,
    required this.dailyEntries,
    required this.weeklyEntries,
    required this.monthlyEntries,
    required this.terrainStats,
    required this.totalPaid,
    required this.monthPaid,
    required this.pendingAmount,
  });
}

class RevenueService {
  final _reservationService = ReservationService();

  Future<OwnerRevenueData> getOwnerRevenueData() async {
    final rawReservations = await _reservationService.getAllOwnerReservations();
    final reservations = rawReservations.cast<Map<String, dynamic>>();
    final transactions = <OwnerTransaction>[];

    for (final reservation in reservations) {
      final payments = reservation['payments'];
      if (payments is! List || payments.isEmpty) continue;

      for (final payment in payments) {
        if (payment is! Map<String, dynamic>) continue;
        transactions.add(_transactionFrom(reservation, payment));
      }
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    final totalPaid = transactions
        .where((tx) => tx.status == 'paid')
        .fold<int>(0, (sum, tx) => sum + tx.amount);
    final monthPaid = transactions
        .where(
          (tx) =>
              tx.status == 'paid' &&
              !tx.date.isBefore(monthStart) &&
              tx.date.isBefore(nextMonth),
        )
        .fold<int>(0, (sum, tx) => sum + tx.amount);
    final pendingAmount = transactions
        .where((tx) => tx.status == 'pending')
        .fold<int>(0, (sum, tx) => sum + tx.amount);

    return OwnerRevenueData(
      transactions: transactions,
      dailyEntries: _buildDailyEntries(reservations, now),
      weeklyEntries: _buildWeeklyEntries(reservations, now),
      monthlyEntries: _buildMonthlyEntries(reservations, now),
      terrainStats: _buildTerrainStats(reservations),
      totalPaid: totalPaid,
      monthPaid: monthPaid,
      pendingAmount: pendingAmount,
    );
  }

  static OwnerTransaction _transactionFrom(
    Map<String, dynamic> reservation,
    Map<String, dynamic> payment,
  ) {
    final user = reservation['user'] as Map<String, dynamic>?;
    final terrain = reservation['terrain'] as Map<String, dynamic>?;
    final firstName = (user?['firstName'] ?? '').toString().trim();
    final lastName = (user?['lastName'] ?? '').toString().trim();
    final clientName = '$firstName $lastName'.trim();
    final date =
        _parseDate(payment['ownerReleasedAt']) ??
        _parseDate(payment['paidAt']) ??
        _parseDate(payment['createdAt']) ??
        _parseDate(reservation['date']) ??
        DateTime.now();

    return OwnerTransaction(
      id: (payment['id'] ?? reservation['id'] ?? '').toString(),
      date: date,
      dateLabel: DateFormat('d MMM yyyy', 'fr_FR').format(date),
      client: clientName.isEmpty ? 'Client MiniFoot' : clientName,
      terrain: (terrain?['name'] ?? 'Terrain').toString(),
      amount: _ownerNetPaymentAmount(payment, reservation),
      method: _formatMethod(payment['method'] ?? reservation['paymentMethod']),
      status: _ownerPaymentStatus(payment, reservation),
      timeSlot: _formatSlot(reservation['startSlot'], reservation['endSlot']),
      reference: (reservation['reference'] ?? '').toString(),
    );
  }

  static List<OwnerRevenueEntry> _buildDailyEntries(
    List<Map<String, dynamic>> reservations,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    const labels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      return _entryForRange(
        reservations,
        labels[index],
        day,
        day.add(const Duration(days: 1)),
      );
    });
  }

  static List<OwnerRevenueEntry> _buildWeeklyEntries(
    List<Map<String, dynamic>> reservations,
    DateTime now,
  ) {
    final monthStart = DateTime(now.year, now.month);
    return List.generate(5, (index) {
      final start = monthStart.add(Duration(days: index * 7));
      final end = start.add(const Duration(days: 7));
      return _entryForRange(reservations, 'Sem ${index + 1}', start, end);
    });
  }

  static List<OwnerRevenueEntry> _buildMonthlyEntries(
    List<Map<String, dynamic>> reservations,
    DateTime now,
  ) {
    final start = DateTime(now.year, now.month - 5);
    return List.generate(6, (index) {
      final month = DateTime(start.year, start.month + index);
      final end = DateTime(month.year, month.month + 1);
      final label = DateFormat('MMM', 'fr_FR').format(month);
      return _entryForRange(reservations, label, month, end);
    });
  }

  static OwnerRevenueEntry _entryForRange(
    List<Map<String, dynamic>> reservations,
    String label,
    DateTime start,
    DateTime end,
  ) {
    final inRange = reservations.where((reservation) {
      final date = _parseDate(reservation['date']);
      return date != null && !date.isBefore(start) && date.isBefore(end);
    }).toList();

    final confirmed = inRange.where((reservation) {
      final status = reservation['status']?.toString();
      return status == 'CONFIRMED' || status == 'COMPLETED';
    }).toList();

    final amount = confirmed.fold<int>(
      0,
      (sum, reservation) => sum + _paidAmount(reservation),
    );
    final intervals = confirmed.fold<int>(
      0,
      (sum, reservation) => sum + _asInt(reservation['intervals']),
    );
    final capacity = (inRange.length + confirmed.length).clamp(1, 999) * 4;
    final occupancy = (intervals / capacity).clamp(0.0, 1.0);

    return OwnerRevenueEntry(
      label: label,
      amount: amount,
      bookings: confirmed.length,
      occupancy: occupancy,
    );
  }

  static List<TerrainRevenueStat> _buildTerrainStats(
    List<Map<String, dynamic>> reservations,
  ) {
    final totals = <String, int>{};
    for (final reservation in reservations) {
      final status = reservation['status']?.toString();
      if (status != 'CONFIRMED' && status != 'COMPLETED') continue;

      final terrain = reservation['terrain'] as Map<String, dynamic>?;
      final name = (terrain?['name'] ?? 'Terrain').toString();
      totals[name] = (totals[name] ?? 0) + _paidAmount(reservation);
    }

    final maxAmount = totals.values.fold<int>(0, (max, amount) {
      return amount > max ? amount : max;
    });

    final stats = totals.entries
        .map(
          (entry) => TerrainRevenueStat(
            name: entry.key,
            amount: entry.value,
            rate: maxAmount == 0 ? 0 : entry.value / maxAmount,
          ),
        )
        .toList();
    stats.sort((a, b) => b.amount.compareTo(a.amount));
    return stats.take(5).toList();
  }

  static int _paidAmount(Map<String, dynamic> reservation) {
    final payments = reservation['payments'];
    if (payments is! List) {
      return _asInt(reservation['finalPrice'] ?? reservation['totalPrice']);
    }

    final completed = payments.where((payment) {
      return payment is Map<String, dynamic> &&
          payment['status'] == 'COMPLETED' &&
          payment['ownerReleasedAt'] != null;
    });
    final total = completed.fold<int>(0, (sum, payment) {
      return sum +
          _ownerNetPaymentAmount(
            payment as Map<String, dynamic>,
            reservation,
          );
    });
    return total;
  }

  static DateTime? _parseDate(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '')?.toLocal();

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _ownerNetPaymentAmount(
    Map<String, dynamic> payment,
    Map<String, dynamic> reservation,
  ) {
    final ownerNet = _asInt(payment['ownerNetAmount']);
    if (ownerNet > 0) return ownerNet;
    return _asInt(payment['amount'] ?? reservation['finalPrice']);
  }

  static String _formatSlot(dynamic start, dynamic end) {
    final startText = start?.toString() ?? '';
    final endText = end?.toString() ?? '';
    if (startText.isEmpty && endText.isEmpty) return '';
    return '$startText - $endText';
  }

  static String _formatMethod(dynamic value) {
    switch (value?.toString()) {
      case 'WAVE':
        return 'Wave';
      case 'ORANGE_MONEY':
        return 'Orange Money';
      case 'FREE_MONEY':
        return 'Yas Money';
      default:
        return value?.toString() ?? 'Autre';
    }
  }

  static String _formatStatus(dynamic value) {
    switch (value?.toString()) {
      case 'COMPLETED':
        return 'paid';
      case 'FAILED':
      case 'REFUNDED':
        return 'failed';
      case 'PENDING':
      default:
        return 'pending';
    }
  }

  static String _ownerPaymentStatus(
    Map<String, dynamic> payment,
    Map<String, dynamic> reservation,
  ) {
    // Réservation annulée → le paiement ne compte pas, peu importe son statut
    final reservationStatus = reservation['status']?.toString();
    if (reservationStatus == 'CANCELLED') return 'failed';

    final rawStatus = payment['status']?.toString();
    // Paiement complété mais fonds pas encore débloqués (en attente scan QR)
    if (rawStatus == 'COMPLETED' && payment['ownerReleasedAt'] == null) {
      return 'pending';
    }
    return _formatStatus(rawStatus);
  }
}
