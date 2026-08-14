import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/reservations_controller.dart';

// Écrans 27 (Détail d'une réservation) et 28 (Refuser — confirmation).
class ReservationDetailScreen extends StatefulWidget {
  const ReservationDetailScreen({super.key});

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  late final ReservationsController controller;
  late final String reservationId;
  late Future<ReservationModel> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ReservationsController>();
    reservationId = (Get.arguments ?? '').toString();
    _future = controller.getReservationDetail(reservationId);
  }

  Future<void> _reload() async {
    setState(() => _future = controller.getReservationDetail(reservationId));
  }

  Future<void> _confirm(ReservationModel r) async {
    setState(() => _busy = true);
    try {
      await controller.confirmDeposit(r.id);
      if (!mounted) return;
      Get.back(result: true);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRefuseSheet(ReservationModel r) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RefuseSheet(reservation: r),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await controller.cancelReservationDirect(r.id, notify: false);
      if (!mounted) return;
      Get.back(result: true);
      await Future<void>.delayed(const Duration(milliseconds: 220));
      AppSnackbar.success(
        r.isDeposit
            ? 'Réservation refusée. Le joueur est remboursé.'
            : 'Réservation refusée. Le créneau est à nouveau disponible.',
      );
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: FutureBuilder<ReservationModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: kGreen));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _ErrorState(onRetry: _reload);
            }
            final r = snapshot.data!;
            return RefreshIndicator(
              color: kGreen,
              onRefresh: _reload,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Get.back(),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: PhosphorIcon(PhosphorIconsRegular.caretLeft, size: 24, color: kTextPrim),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(16)),
                          child: Text(
                            _initialsOf(r.clientName),
                            style: kArchivo(size: 17, weight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.clientName,
                                style: kArchivo(size: 19, weight: FontWeight.w700, color: kTextPrim),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                r.phone.isNotEmpty ? r.phone : 'Numéro non renseigné',
                                style: kManrope(size: 13, weight: FontWeight.w400, color: kTextSub, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        if (r.phone.isNotEmpty)
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: kBgCard,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(color: kTextPrim.withValues(alpha: 0.08), blurRadius: 2, offset: const Offset(0, 1)),
                              ],
                            ),
                            child: const PhosphorIcon(PhosphorIconsRegular.phone, color: kGreen, size: 20),
                          ),
                      ],
                    ),
                    if (r.status == 'awaiting_owner_confirmation') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: kGoldLight, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                'Acompte versé — encaissez le solde sur place puis confirmez.',
                                style: kManrope(size: 13.5, weight: FontWeight.w600, color: kGoldInk, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: kTextPrim.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _InfoRow(label: 'Créneau', value: '${r.date} · ${r.timeSlot}'),
                          _InfoRow(
                            label: 'Terrain',
                            value: r.subTerrainName.isNotEmpty ? '${r.terrain} · ${r.subTerrainName}' : r.terrain,
                          ),
                          if (r.isDeposit) ...[
                            _InfoRow(
                              label: 'Acompte versé',
                              value: '${_thousands(r.depositAmount ?? 0)} F',
                              valueColor: kBlue,
                            ),
                            _InfoRow(
                              label: 'Reste à payer sur place',
                              value: '${_thousands(r.balanceDue)} F',
                              big: true,
                              last: true,
                            ),
                          ] else
                            _InfoRow(label: 'Montant', value: '${_thousands(r.amount)} F', big: true, last: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (r.status == 'awaiting_owner_confirmation')
                      _PrimaryButton(
                        label: 'Confirmer la réservation',
                        busy: _busy,
                        onTap: () => _confirm(r),
                      ),
                    if (r.canCancel) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _busy
                                  ? null
                                  : () => AppSnackbar.info('Bientôt disponible.'),
                              child: Container(
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: kBgCard,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(color: kTextPrim.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
                                  ],
                                ),
                                child: Text(
                                  'Proposer un autre créneau',
                                  style: kManrope(size: 14, weight: FontWeight.w700, color: kTextPrim),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _busy ? null : () => _openRefuseSheet(r),
                            child: Container(
                              width: 96,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: kRed.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                'Refuser',
                                style: kManrope(size: 14, weight: FontWeight.w700, color: kRed),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts.last[0] : '';
    return '$first$second'.toUpperCase();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool big;
  final bool last;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.big = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: kTextPrim.withValues(alpha: 0.07))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: kManrope(size: 13.5, weight: FontWeight.w500, color: kTextSub)),
          Text(
            value,
            style: kArchivo(size: big ? 17 : 14, weight: FontWeight.w700, color: valueColor ?? kTextPrim),
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

  const _PrimaryButton({required this.label, required this.busy, required this.onTap});

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
            BoxShadow(color: kGreen.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(label, style: kManrope(size: 15.5, weight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}

// ─── Écran 28 : feuille de confirmation du refus ────────────────────────────
class _RefuseSheet extends StatefulWidget {
  final ReservationModel reservation;

  const _RefuseSheet({required this.reservation});

  @override
  State<_RefuseSheet> createState() => _RefuseSheetState();
}

class _RefuseSheetState extends State<_RefuseSheet> {
  int _reasonIndex = 0;
  static const _reasons = ['Terrain indisponible', 'Déjà réservé', 'Autre'];

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    return Container(
      padding: EdgeInsets.fromLTRB(22, 26, 22, 30 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(bottom: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: kRedLight, borderRadius: BorderRadius.circular(20)),
            child: const PhosphorIcon(PhosphorIconsRegular.warningCircle, color: kRed, size: 30),
          ),
          Text(
            'Refuser la demande de ${r.clientName} ?',
            textAlign: TextAlign.center,
            style: kArchivo(size: 22, weight: FontWeight.w800, color: kTextPrim, height: 1.25),
          ),
          const SizedBox(height: 10),
          Text(
            r.isDeposit
                ? "Son acompte de ${_thousands(r.depositAmount ?? 0)} F lui est remboursé automatiquement et le créneau de ${r.startSlot} redevient disponible."
                : "Le créneau de ${r.startSlot} redevient disponible.",
            textAlign: TextAlign.center,
            style: kManrope(size: 14, weight: FontWeight.w400, color: kTextSub, height: 1.55),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MOTIF ENVOYÉ AU JOUEUR',
                  style: kManrope(size: 12.5, weight: FontWeight.w600, color: kTextSub, letterSpacing: 0.06 * 12.5),
                ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_reasons.length, (i) {
                    final selected = i == _reasonIndex;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _reasonIndex = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: kBgCard,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: selected ? kGreen : Colors.transparent, width: 2),
                        ),
                        child: Text(
                          _reasons[i],
                          style: kManrope(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: selected ? kTextPrim : kTextSub,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.back(result: true),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(17)),
              child: Text(
                r.isDeposit ? 'Refuser et rembourser' : 'Refuser',
                style: kManrope(size: 15.5, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.back(result: false),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              child: Text(
                'Garder la demande',
                style: kManrope(size: 14.5, weight: FontWeight.w700, color: kTextPrim),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Impossible de charger la réservation.', style: kManrope(size: 14, weight: FontWeight.w600, color: kTextSub)),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRetry,
            child: Text('Réessayer', style: kManrope(size: 14, weight: FontWeight.w700, color: kGreen)),
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
