import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/owner_ui.dart';
import '../controllers/payments_controller.dart';

class PaymentsScreen extends GetView<PaymentsController> {
  const PaymentsScreen({super.key});

  String _fmt(int amount) {
    final str = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: RefreshIndicator(
          onRefresh: controller.refreshPayments,
          color: kGreen,
          backgroundColor: kBgCard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildPayoutDestination()),
              SliverToBoxAdapter(child: _buildNotice()),
              SliverToBoxAdapter(child: _buildMethodBreakdown()),
              SliverToBoxAdapter(child: _buildFilterChips()),
              SliverToBoxAdapter(child: _buildTransactionsHeader()),
              SliverToBoxAdapter(child: _buildGroupedTransactions(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayoutDestination() {
    return Obx(() {
      final configured =
          controller.payoutPhone.value != null &&
          controller.payoutPhone.value!.isNotEmpty;
      final method = controller.payoutMethodLabel;
      final phone = controller.payoutPhone.value ?? 'Aucun numéro défini';

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: InkWell(
          onTap: controller.goToPayoutSettings,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(18),
              boxShadow: kCardShadow,
              border: Border.all(
                color: configured
                    ? kGreen.withValues(alpha: 0.22)
                    : kGold.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: configured
                      ? PaymentBrandBadge(
                          method: controller.payoutMethod.value ?? method,
                          size: 48,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: kGoldLight,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              PhosphorIcons.creditCard(
                                PhosphorIconsStyle.duotone,
                              ),
                              color: kGold,
                              size: 23,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        configured
                            ? 'Destination des reversements'
                            : 'Coordonnées de reversement',
                        style: const TextStyle(
                          color: kTextPrim,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        configured ? '$method · $phone' : phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kTextSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: kBgSurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Text(
                        configured ? 'Modifier' : 'Configurer',
                        style: const TextStyle(
                          color: kGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        PhosphorIcons.caretRight(PhosphorIconsStyle.duotone),
                        color: kGreen,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
    });
  }

  Widget _buildNotice() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              minHeight: 3,
              color: kGreen,
              backgroundColor: kGreenLight,
            ),
          ),
        );
      }

      if (controller.errorMessage.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kRedLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
              color: kRed,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.errorMessage.value,
                style: const TextStyle(
                  color: kRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Header vert avec revenus + sélecteur de période ───────────────────────
  Widget _buildHeader(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 24),
      decoration: const BoxDecoration(
        gradient: kGreenGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Barre du haut
          Row(
            children: [
              GestureDetector(
                onTap: Get.back,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIcons.caretLeft(PhosphorIconsStyle.duotone),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Paiements',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 20),

          // Sélecteur de période
          Obx(
            () => Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _PeriodTab(
                    label: 'Jour',
                    key_: 'day',
                    active: controller.selectedPeriod.value == 'day',
                    onTap: () => controller.setPeriod('day'),
                  ),
                  _PeriodTab(
                    label: 'Semaine',
                    key_: 'week',
                    active: controller.selectedPeriod.value == 'week',
                    onTap: () => controller.setPeriod('week'),
                  ),
                  _PeriodTab(
                    label: 'Mois',
                    key_: 'month',
                    active: controller.selectedPeriod.value == 'month',
                    onTap: () => controller.setPeriod('month'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Montant total
          Obx(
            () => Column(
              children: [
                Text(
                  'Revenus totaux',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(controller.totalRevenue.value)} F CFA',
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Stats compactes
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HeaderStat(
                  icon: PhosphorIcons.calendarBlank(PhosphorIconsStyle.duotone),
                  label: 'Ce mois',
                  value: '${_fmt(controller.monthlyRevenue.value)} F',
                ),
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                _HeaderStat(
                  icon: PhosphorIcons.hourglass(PhosphorIconsStyle.duotone),
                  label: 'En attente',
                  value: '${_fmt(controller.pendingAmount.value)} F',
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05, duration: 350.ms);
  }

  // ── Barre de répartition par méthode de paiement ──────────────────────────
  Widget _buildMethodBreakdown() {
    return Obx(() {
      final breakdown = controller.methodBreakdown;
      final total = controller.totalPaidAmount;
      if (total == 0) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: kCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OwnerSectionHeader(
                title: 'Répartition des paiements',
                subtitle: 'Part de chaque moyen de paiement encaissé',
              ),
              const SizedBox(height: 12),

              // Barre de répartition
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: breakdown.entries.map((entry) {
                      final ratio = entry.value / total;
                      return Expanded(
                        flex: (ratio * 100).round().clamp(1, 100),
                        child: Container(
                          color: _methodColor(entry.key),
                          margin: const EdgeInsets.only(right: 2),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Légende
              Row(
                children: breakdown.entries.map((entry) {
                  final percent = ((entry.value / total) * 100).round();
                  return Expanded(
                    child: Row(
                      children: [
                        PaymentBrandBadge(
                          method: _methodToBrandKey(entry.key),
                          size: 28,
                          compact: true,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${entry.key} $percent%',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kTextSub,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 150.ms, duration: 300.ms);
    });
  }

  Color _methodColor(String method) {
    switch (method) {
      case 'Wave':
        return const Color(0xFF00B0F0);
      case 'Orange Money':
        return const Color(0xFFFF6D00);
      case 'Yas Money':
        return const Color(0xFFFFD100);
      default:
        return kTextSub;
    }
  }

  String _methodToBrandKey(String method) {
    switch (method) {
      case 'Wave':
        return 'WAVE';
      case 'Orange Money':
        return 'ORANGE_MONEY';
      case 'Yas Money':
        return 'FREE_MONEY';
      default:
        return method;
    }
  }

  // ── Filtres (Tout / Payé / En attente / Échoué) ───────────────────────────
  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Tout'},
      {'key': 'paid', 'label': 'Payé'},
      {'key': 'pending', 'label': 'En attente'},
      {'key': 'failed', 'label': 'Échoué'},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 40,
        child: Obx(() {
          final active = controller.selectedFilter.value;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemCount: filters.length,
            itemBuilder: (_, i) {
              final f = filters[i];
              final isActive = active == f['key'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.setFilter(f['key']!);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? kGreen : kBgCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isActive ? [] : kCardShadow,
                    border: isActive
                        ? null
                        : Border.all(color: kBorder, width: 0.5),
                  ),
                  child: Text(
                    f['label']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : kTextSub,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  // ── En-tête "Transactions" + compteur ─────────────────────────────────────
  Widget _buildTransactionsHeader() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.listDashes(PhosphorIconsStyle.duotone),
              size: 20,
              color: kTextPrim,
            ),
            const SizedBox(width: 8),
            const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: kTextPrim,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kGreenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${controller.filteredTransactions.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kGreen,
                ),
              ),
            ),
            const Spacer(),
            // Compteurs rapides
            Row(
              children: [
                _MiniCount(count: controller.paidCount, color: kGreen),
                const SizedBox(width: 6),
                _MiniCount(count: controller.pendingCount, color: kGold),
                if (controller.failedCount > 0) ...[
                  const SizedBox(width: 6),
                  _MiniCount(count: controller.failedCount, color: kRed),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Liste groupée par date ────────────────────────────────────────────────
  Widget _buildGroupedTransactions(BuildContext context) {
    return Obx(() {
      final grouped = controller.groupedTransactions;
      if (grouped.isEmpty) {
        return _buildEmptyState();
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Column(
            key: ValueKey(controller.selectedFilter.value),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in grouped.entries) ...[
                // Date header
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: kGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key == _todayLabel() ? "Aujourd'hui" : entry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kTextSub,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_fmt(_dayTotal(entry.value))} F',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kTextLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // Transactions du jour
                ...entry.value.asMap().entries.map((txEntry) {
                  return _TransactionCard(
                        transaction: txEntry.value,
                        formatAmount: _fmt,
                        onTap: () =>
                            _showTransactionDetail(context, txEntry.value),
                      )
                      .animate()
                      .fadeIn(delay: (txEntry.key * 60).ms, duration: 250.ms)
                      .slideX(begin: 0.03, duration: 250.ms);
                }),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kBgSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.duotone),
                size: 32,
                color: kTextLight,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune transaction',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextPrim,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aucune transaction ne correspond\nau filtre sélectionné.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kTextSub, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _todayLabel() =>
      DateFormat('d MMM yyyy', 'fr_FR').format(DateTime.now());
  int _dayTotal(List<TransactionModel> txns) =>
      txns.fold(0, (s, t) => s + t.amount);

  // ── Bottom sheet détail transaction ────────────────────────────────────────
  void _showTransactionDetail(BuildContext context, TransactionModel tx) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _TransactionDetailSheet(transaction: tx, formatAmount: _fmt),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodTab extends StatelessWidget {
  final String label;
  final String key_;
  final bool active;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.label,
    required this.key_,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? kGreen : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniCount extends StatelessWidget {
  final int count;
  final Color color;
  const _MiniCount({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final String Function(int) formatAmount;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.transaction,
    required this.formatAmount,
    required this.onTap,
  });

  Color get _methodBg {
    switch (transaction.method) {
      case 'Wave':
        return const Color(0xFFE0F4FD);
      case 'Orange Money':
        return const Color(0xFF1A1A1A);
      case 'Yas Money':
        return const Color(0xFFFFF8E0);
      default:
        return kBgSurface;
    }
  }

  Widget _buildMethodLogo() {
    switch (transaction.method) {
      case 'Wave':
        return const PaymentBrandBadge(method: 'WAVE', size: 44);
      case 'Orange Money':
        return const PaymentBrandBadge(method: 'ORANGE_MONEY', size: 44);
      case 'Yas Money':
        return const PaymentBrandBadge(method: 'FREE_MONEY', size: 44);
      default:
        return Icon(
          PhosphorIcons.creditCard(PhosphorIconsStyle.duotone),
          color: kTextSub,
          size: 22,
        );
    }
  }

  Color get _statusColor {
    switch (transaction.status) {
      case 'paid':
        return kGreen;
      case 'pending':
        return kGold;
      case 'failed':
        return kRed;
      default:
        return kTextSub;
    }
  }

  Color get _statusBg {
    switch (transaction.status) {
      case 'paid':
        return kGreenLight;
      case 'pending':
        return kGoldLight;
      case 'failed':
        return kRedLight;
      default:
        return kBgSurface;
    }
  }

  IconData get _statusIcon {
    switch (transaction.status) {
      case 'paid':
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone);
      case 'pending':
        return PhosphorIcons.clock(PhosphorIconsStyle.duotone);
      case 'failed':
        return PhosphorIcons.xCircle(PhosphorIconsStyle.duotone);
      default:
        return PhosphorIcons.question(PhosphorIconsStyle.duotone);
    }
  }

  String get _statusLabel {
    switch (transaction.status) {
      case 'paid':
        return 'Payé';
      case 'pending':
        return 'En attente';
      case 'failed':
        return 'Échoué';
      default:
        return transaction.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kCardShadow,
        ),
        child: Row(
          children: [
            // Logo méthode de paiement
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _methodBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: _buildMethodLogo(),
              ),
            ),
            const SizedBox(width: 12),

            // Infos client
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.client,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kTextPrim,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.mapPin(PhosphorIconsStyle.duotone),
                        size: 12,
                        color: kTextLight,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          transaction.terrain,
                          style: const TextStyle(
                            fontSize: 11,
                            color: kTextLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (transaction.timeSlot.isNotEmpty) ...[
                        Container(
                          width: 3,
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: const BoxDecoration(
                            color: kTextLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          transaction.timeSlot,
                          style: const TextStyle(
                            fontSize: 11,
                            color: kTextLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Montant + statut
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatAmount(transaction.amount)} F',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: kTextPrim,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, size: 11, color: _statusColor),
                      const SizedBox(width: 3),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet détail d'une transaction ────────────────────────────────────

class _TransactionDetailSheet extends StatelessWidget {
  final TransactionModel transaction;
  final String Function(int) formatAmount;

  const _TransactionDetailSheet({
    required this.transaction,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = transaction.status == 'paid';
    final isPending = transaction.status == 'pending';

    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    String statusLabel;
    if (isPaid) {
      statusColor = kGreen;
      statusBg = kGreenLight;
      statusIcon = PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone);
      statusLabel = 'Payé';
    } else if (isPending) {
      statusColor = kGold;
      statusBg = kGoldLight;
      statusIcon = PhosphorIcons.clock(PhosphorIconsStyle.duotone);
      statusLabel = 'En attente';
    } else {
      statusColor = kRed;
      statusBg = kRedLight;
      statusIcon = PhosphorIcons.xCircle(PhosphorIconsStyle.duotone);
      statusLabel = 'Échoué';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: kElevatedShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Icône statut
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: statusBg, shape: BoxShape.circle),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(height: 14),

          // Montant
          Text(
            '${formatAmount(transaction.amount)} F CFA',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kTextPrim,
            ),
          ),
          const SizedBox(height: 6),

          // Badge statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Détails
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kBgSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Client',
                    value: transaction.client,
                    icon: PhosphorIcons.user(PhosphorIconsStyle.duotone),
                  ),
                  const _DetailDivider(),
                  _DetailRow(
                    label: 'Terrain',
                    value: transaction.terrain,
                    icon: PhosphorIcons.mapPin(PhosphorIconsStyle.duotone),
                  ),
                  const _DetailDivider(),
                  _DetailRow(
                    label: 'Créneau',
                    value: transaction.timeSlot.isNotEmpty
                        ? transaction.timeSlot
                        : '-',
                    icon: PhosphorIcons.clock(PhosphorIconsStyle.duotone),
                  ),
                  const _DetailDivider(),
                  _DetailRow(
                    label: 'Méthode',
                    value: transaction.method,
                    icon: PhosphorIcons.creditCard(PhosphorIconsStyle.duotone),
                  ),
                  const _DetailDivider(),
                  _DetailRow(
                    label: 'Date',
                    value: transaction.date,
                    icon: PhosphorIcons.calendar(PhosphorIconsStyle.duotone),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: Navigator.of(context).pop,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Fermer',
                          style: TextStyle(
                            color: kTextSub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isPending) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).pop();
                            Get.snackbar(
                              'Relance envoyée',
                              'Un rappel a été envoyé à ${transaction.client}',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: kBgCard,
                              colorText: kTextPrim,
                              margin: const EdgeInsets.all(16),
                              borderRadius: 16,
                              icon: Icon(
                                PhosphorIcons.bellRinging(
                                  PhosphorIconsStyle.duotone,
                                ),
                                color: kGold,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGold,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: Icon(
                            PhosphorIcons.bellRinging(
                              PhosphorIconsStyle.duotone,
                            ),
                            size: 18,
                          ),
                          label: const Text(
                            'Relancer',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kTextLight),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 12, color: kTextLight)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kTextPrim,
          ),
        ),
      ],
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Container(height: 1, color: kDivider),
  );
}
