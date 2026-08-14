import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/utils/app_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/reservations_controller.dart';

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

  @override
  void initState() {
    super.initState();
    controller = Get.find<ReservationsController>();
    reservationId = (Get.arguments ?? '').toString();
    _future = controller.getReservationDetail(reservationId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = controller.getReservationDetail(reservationId);
    });
  }

  String _formatAmount(int amount) => AppFormat.amount(amount);

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmée';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return kGreen;
      case 'pending':
        return kGold;
      case 'cancelled':
        return kRed;
      default:
        return kTextSub;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'confirmed':
        return kGreenLight;
      case 'pending':
        return kGoldLight;
      case 'cancelled':
        return kRedLight;
      default:
        return kBgSurface;
    }
  }

  Future<void> _confirmCancel(ReservationModel reservation) async {
    // Le même dialogue était recopié à l'identique dans le contrôleur de liste.
    final confirmed = await AppDialog.confirm(
      title: 'Refuser la réservation',
      message: 'Cette réservation passera en statut annulé.',
      confirmLabel: 'Refuser',
      cancelLabel: 'Garder',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await controller.cancelReservationDirect(reservation.id);
      await controller.loadReservations();
      if (!mounted) return;
      Get.back(result: true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.back(),
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
        title: const Text(
          'Détail réservation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: kTextPrim,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        color: kGreen,
        child: FutureBuilder<ReservationModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: kGreen),
              );
            }

            if (!snapshot.hasData) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Text(
                      'Impossible de charger la réservation',
                      style: TextStyle(
                        color: kTextSub,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }

            final reservation = snapshot.data!;
            final terrainLabel = reservation.subTerrainName.isEmpty
                ? reservation.terrain
                : '${reservation.terrain} • ${reservation.subTerrainName}';

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: kElevatedShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reservation.clientName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: kTextPrim,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  reservation.reference.isEmpty
                                      ? reservation.id
                                      : reservation.reference,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: kTextLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _statusBg(reservation.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusLabel(reservation.status),
                              style: TextStyle(
                                color: _statusColor(reservation.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: reservation.isCheckedIn
                              ? kGreenLight
                              : kBgSurface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            PhosphorIcon(
                              reservation.isCheckedIn
                                  ? PhosphorIconsDuotone.sealCheck
                                  : PhosphorIconsDuotone.clockCountdown,
                              color: reservation.isCheckedIn ? kGreen : kGold,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reservation.isCheckedIn
                                        ? 'Présence confirmée'
                                        : 'Check-in non effectué',
                                    style: const TextStyle(
                                      color: kTextPrim,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (reservation.isCheckedIn)
                                    Text(
                                      reservation.checkedInAt,
                                      style: const TextStyle(
                                        color: kTextSub,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Infos client',
                  children: [
                    _DetailRow(
                      icon: PhosphorIconsDuotone.phone,
                      label: 'Téléphone',
                      value: reservation.phone.isEmpty
                          ? 'Non renseigné'
                          : reservation.phone,
                      trailing: reservation.phone.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: reservation.phone),
                                );
                                AppSnackbar.info('Numéro copié dans le presse-papiers.');
                              },
                              icon: PhosphorIcon(PhosphorIconsDuotone.copy,
                                color: kTextSub,
                                size: 16,
                              ),
                            ),
                    ),
                    _DetailRow(
                      icon: PhosphorIconsDuotone.identificationCard,
                      label: 'Alias',
                      value: reservation.teamName,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Infos réservation',
                  children: [
                    _DetailRow(
                      icon: PhosphorIconsDuotone.courtBasketball,
                      label: 'Terrain',
                      value: terrainLabel,
                    ),
                    _DetailRow(
                      icon: PhosphorIconsDuotone.calendarBlank,
                      label: 'Date',
                      value: reservation.date,
                    ),
                    _DetailRow(
                      icon: PhosphorIconsDuotone.clock,
                      label: 'Créneau',
                      value: reservation.timeSlot,
                    ),
                    _DetailRow(
                      icon: PhosphorIconsDuotone.wallet,
                      label: 'Paiement',
                      value:
                          '${reservation.paymentMethod} · ${reservation.paymentStatus}',
                    ),
                    _DetailRow(
                      icon: PhosphorIconsDuotone.money,
                      label: 'Montant',
                      value: _formatAmount(reservation.amount),
                    ),
                  ],
                ),
                if (reservation.canCancel) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmCancel(reservation),
                      icon: PhosphorIcon(PhosphorIconsDuotone.xCircle,
                        size: 18,
                      ),
                      label: const Text('Refuser la réservation'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kRed,
                        side: const BorderSide(color: kRed),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kTextPrim,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kBgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: PhosphorIcon(icon, color: kTextSub, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: kTextLight, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: kTextPrim,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          ...[trailing].whereType<Widget>(),
        ],
      ),
    );
  }
}
