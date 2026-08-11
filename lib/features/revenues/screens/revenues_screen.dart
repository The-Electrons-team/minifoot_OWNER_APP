import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/services/revenue_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_loading.dart' show ShimmerBox;
import '../../reports/screens/report_screen.dart';
import '../controllers/revenues_controller.dart';

// Écrans 42 (Revenus & historique) et 43 (Détail d'un versement) du design.
class RevenuesScreen extends GetView<RevenuesController> {
  const RevenuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        color: kGreen,
        onRefresh: controller.refreshRevenues,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            const SliverToBoxAdapter(child: _MonthHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _PeriodSwitch(),
                    const SizedBox(height: 18),
                    const _PeriodTotal(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Obx(() {
              if (controller.isLoading.value && controller.transactions.isEmpty) {
                return const SliverPadding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 24),
                  sliver: SliverToBoxAdapter(child: _ListLoading()),
                );
              }
              final transactions = controller.transactions.take(12).toList();
              if (transactions.isEmpty) {
                return const SliverToBoxAdapter(child: _EmptyState());
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                sliver: SliverList.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _TransactionRow(transaction: transactions[i]),
                ),
              );
            }),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    Obx(
                      () => controller.payouts.isEmpty
                          ? const SizedBox.shrink()
                          : _PayoutsSection(payouts: controller.payouts),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Get.to(
                        () => const ReportScreen(),
                        arguments: {'reportType': 'revenues'},
                      ),
                      child: SizedBox(
                        height: 48,
                        child: Center(
                          child: Text(
                            'Voir tout l\'historique',
                            style: kManrope(size: 14, weight: FontWeight.w700, color: kGreen),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── En-tête vert : encaissé du mois ────────────────────────────────────────
class _MonthHeader extends GetView<RevenuesController> {
  const _MonthHeader();

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMMM', 'fr_FR').format(DateTime.now()).toUpperCase();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + 18, 22, 26),
      decoration: const BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REVENUS ENCAISSÉS · $month',
            style: kManrope(
              size: 11.5,
              weight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.75),
              letterSpacing: 0.08 * 11.5,
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _thousands(controller.monthPaid.value),
                  style: kArchivo(
                    size: 40,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.02 * 40,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'FCFA',
                    style: kManrope(
                      size: 14,
                      weight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            if (controller.pendingAmount.value == 0) return const SizedBox.shrink();
            final count = controller.pendingCount.value;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_thousands(controller.pendingAmount.value)} F encore en attente de validation'
                '${count > 0 ? ' ($count résa${count > 1 ? 's' : ''})' : ''}',
                style: kManrope(
                  size: 13,
                  weight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            );
          }),
          Obx(() {
            final last = controller.payouts.isEmpty ? null : controller.payouts.first;
            if (last == null || (last.phone ?? '').isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const PhosphorIcon(PhosphorIconsRegular.arrowsClockwise, color: Colors.white, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dernier versement reçu sur ${_maskPhone(last.phone!)}',
                      style: kManrope(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return phone;
    return '•• ${digits.substring(digits.length - 4, digits.length - 2)} ${digits.substring(digits.length - 2)}';
  }
}

// ─── Filtre Jour / Semaine / Mois ───────────────────────────────────────────
class _PeriodSwitch extends GetView<RevenuesController> {
  const _PeriodSwitch();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7DB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Obx(
        () => Row(
          children: [
            _tab('Jour', RevenuePeriod.daily),
            _tab('Semaine', RevenuePeriod.weekly),
            _tab('Mois', RevenuePeriod.monthly),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, RevenuePeriod value) {
    final selected = controller.period.value == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          controller.period.value = value;
          controller.selectedBar.value = -1;
        },
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? kBgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [BoxShadow(color: kTextPrim.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            style: kManrope(
              size: 13,
              weight: FontWeight.w700,
              color: selected ? kTextPrim : kTextSub,
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodTotal extends GetView<RevenuesController> {
  const _PeriodTotal();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final entries = controller.entries;
      final total = controller.totalRevenue;
      // Variation vs la période précédente, uniquement quand les deux
      // existent : un « +100 % » sorti d'une seule valeur n'informe personne.
      int? delta;
      if (entries.length >= 2) {
        final previous = entries[entries.length - 2].amount;
        final current = entries.last.amount;
        if (previous > 0) {
          delta = (((current - previous) / previous) * 100).round();
        }
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENCAISSÉ · ${controller.periodLabel.toUpperCase()}',
                  style: kManrope(
                    size: 11,
                    weight: FontWeight.w600,
                    color: kTextSub,
                    letterSpacing: 0.06 * 11,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${_thousands(total)} F',
                  style: kArchivo(size: 26, weight: FontWeight.w800, color: kTextPrim),
                ),
              ],
            ),
          ),
          if (delta != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: delta >= 0 ? kGreenLight : kRedLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${delta >= 0 ? '+' : ''}$delta %',
                style: kManrope(
                  size: 12,
                  weight: FontWeight.w700,
                  color: delta >= 0 ? const Color(0xFF00552C) : kRed,
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ─── Ligne de transaction ───────────────────────────────────────────────────
class _TransactionRow extends StatelessWidget {
  final OwnerTransaction transaction;

  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final credited = transaction.status == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: kTextPrim.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: credited ? kGreenLight : kGoldLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: PhosphorIcon(
              PhosphorIconsBold.plus,
              color: credited ? kGreen : const Color(0xFF92400E),
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [transaction.client, transaction.terrain]
                      .where((e) => e.isNotEmpty)
                      .join(' · '),
                  style: kManrope(size: 13.5, weight: FontWeight.w600, color: kTextPrim, height: 1.3),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.dateLabel,
                  style: kManrope(size: 12, weight: FontWeight.w400, color: kTextSub, height: 1.3),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${_thousands(transaction.amount)}',
                style: kArchivo(
                  size: 14,
                  weight: FontWeight.w700,
                  color: credited ? kGreen : kTextPrim,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                credited ? 'CRÉDITÉ' : 'EN ATTENTE',
                style: kManrope(
                  size: 10,
                  weight: FontWeight.w700,
                  color: credited ? const Color(0xFF00552C) : const Color(0xFF92400E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Versements reçus (écran 43 en feuille) ─────────────────────────────────
class _PayoutsSection extends StatelessWidget {
  final List<OwnerPayout> payouts;

  const _PayoutsSection({required this.payouts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10, top: 8),
          child: Text(
            'VERSEMENTS REÇUS',
            style: kManrope(
              size: 13,
              weight: FontWeight.w700,
              color: kTextPrim,
              letterSpacing: 0.09 * 13,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: kTextPrim.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < payouts.length; i++) ...[
                if (i > 0)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(left: 16),
                    color: kTextPrim.withValues(alpha: 0.07),
                  ),
                _PayoutRow(payout: payouts[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PayoutRow extends StatelessWidget {
  final OwnerPayout payout;

  const _PayoutRow({required this.payout});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _PayoutSheet(payout: payout),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payout.paidAt == null
                        ? 'Versement'
                        : 'Versement du ${DateFormat('d MMMM', 'fr_FR').format(payout.paidAt!)}',
                    style: kManrope(size: 13.5, weight: FontWeight.w600, color: kTextPrim, height: 1.3),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${payout.reservationCount} réservation${payout.reservationCount > 1 ? 's' : ''}',
                    style: kManrope(size: 12, weight: FontWeight.w400, color: kTextSub, height: 1.3),
                  ),
                ],
              ),
            ),
            Text(
              '${_thousands(payout.netAmount)} F',
              style: kArchivo(size: 14, weight: FontWeight.w700, color: kTextPrim),
            ),
            const SizedBox(width: 8),
            const PhosphorIcon(PhosphorIconsRegular.caretRight, color: kTextLight, size: 16),
          ],
        ),
      ),
    );
  }
}

class _PayoutSheet extends StatelessWidget {
  final OwnerPayout payout;

  const _PayoutSheet({required this.payout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(22, 24, 22, 28 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            payout.paidAt == null
                ? 'VERSEMENT'
                : 'VERSEMENT DU ${DateFormat('d MMMM', 'fr_FR').format(payout.paidAt!).toUpperCase()}',
            style: kManrope(
              size: 11.5,
              weight: FontWeight.w700,
              color: kTextSub,
              letterSpacing: 0.08 * 11.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _thousands(payout.netAmount),
                style: kArchivo(size: 34, weight: FontWeight.w800, color: kTextPrim),
              ),
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'FCFA',
                  style: kManrope(size: 13, weight: FontWeight.w600, color: kTextSub),
                ),
              ),
            ],
          ),
          if ((payout.phone ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reçu sur ${payout.phone}',
              style: kManrope(size: 13, weight: FontWeight.w500, color: kTextSub),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _Line(
                  label: '${payout.reservationCount} réservation${payout.reservationCount > 1 ? 's' : ''} encaissée${payout.reservationCount > 1 ? 's' : ''}',
                  value: _thousands(payout.grossAmount),
                ),
                _Line(label: 'Commission MiniFoot', value: '− ${_thousands(payout.platformFee)}'),
                _Line(label: 'Frais de transfert', value: '− ${_thousands(payout.transferFee)}'),
                _Line(label: 'Net versé', value: _thousands(payout.netAmount), strong: true, last: true),
              ],
            ),
          ),
          if (payout.periodStart != null && payout.periodEnd != null) ...[
            const SizedBox(height: 18),
            Text(
              'PÉRIODE COUVERTE',
              style: kManrope(
                size: 11,
                weight: FontWeight.w600,
                color: kTextSub,
                letterSpacing: 0.06 * 11,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${DateFormat('d', 'fr_FR').format(payout.periodStart!)} → ${DateFormat('d MMMM yyyy', 'fr_FR').format(payout.periodEnd!)}',
              style: kArchivo(size: 15, weight: FontWeight.w700, color: kTextPrim),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Référence ${payout.reference}',
            style: kManrope(size: 12.5, weight: FontWeight.w400, color: kTextSub),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final bool last;

  const _Line({
    required this.label,
    required this.value,
    this.strong = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: kTextPrim.withValues(alpha: 0.07))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: kManrope(
                size: 13.5,
                weight: strong ? FontWeight.w700 : FontWeight.w500,
                color: strong ? kTextPrim : kTextSub,
              ),
            ),
          ),
          Text(
            value,
            style: kArchivo(size: strong ? 17 : 14, weight: FontWeight.w700, color: kTextPrim),
          ),
        ],
      ),
    );
  }
}

class _ListLoading extends StatelessWidget {
  const _ListLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: ShimmerBox(width: double.infinity, height: 66, borderRadius: 18),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 40, 34, 20),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFEAE0),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const PhosphorIcon(PhosphorIconsRegular.wallet, color: kTextSub, size: 40),
          ),
          const SizedBox(height: 22),
          Text(
            'Aucun encaissement',
            textAlign: TextAlign.center,
            style: kArchivo(size: 21, weight: FontWeight.w800, color: kTextPrim, height: 1.25),
          ),
          const SizedBox(height: 10),
          Text(
            'Les paiements de vos joueurs apparaîtront ici après le check-in.',
            textAlign: TextAlign.center,
            style: kManrope(size: 14, weight: FontWeight.w400, color: kTextSub, height: 1.6),
          ),
        ],
      ),
    );
  }
}

String _thousands(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(s[i]);
  }
  return buffer.toString();
}
