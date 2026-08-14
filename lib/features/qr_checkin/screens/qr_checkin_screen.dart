import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/qr_checkin_controller.dart';
import 'attendance_screen.dart';

// Écrans 16 à 24 du design : scan, vérification, billet valide, présence
// confirmée, billet déjà utilisé, créneau pas commencé, caméra refusée.
class QrCheckInScreen extends StatefulWidget {
  const QrCheckInScreen({super.key});

  @override
  State<QrCheckInScreen> createState() => _QrCheckInScreenState();
}

class _QrCheckInScreenState extends State<QrCheckInScreen> {
  final QrCheckInController controller = Get.find<QrCheckInController>();
  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _scannerStarted = true;
  bool _torchEnabled = false;

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  Future<void> _pauseScanner() async {
    if (!_scannerStarted) return;
    await scannerController.stop();
    if (mounted) setState(() => _scannerStarted = false);
  }

  Future<void> _resumeScanner() async {
    controller.resetScan();
    await scannerController.start();
    if (mounted) setState(() => _scannerStarted = true);
  }

  Future<void> _toggleTorch() async {
    await scannerController.toggleTorch();
    if (mounted) setState(() => _torchEnabled = !_torchEnabled);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    await _pauseScanner();
    await controller.scanCode(raw);
    if (controller.status.value.isNotEmpty) HapticFeedback.selectionClick();
  }

  Future<void> _confirmCheckIn() async {
    final confirmed = await controller.confirmCheckIn();
    if (confirmed) HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.cameraDenied.value) {
        return _CameraDeniedView(onRetry: () => controller.cameraDenied.value = false);
      }

      final status = controller.status.value;
      if (controller.isProcessing.value) return const _VerifyingView();

      switch (status) {
        case 'ready':
          return controller.isTooEarly
              ? _TooEarlyView(
                  controller: controller,
                  onConfirm: _confirmCheckIn,
                  onBack: _resumeScanner,
                )
              : _ValidTicketView(
                  controller: controller,
                  onConfirm: _confirmCheckIn,
                  onWrongTicket: _resumeScanner,
                );
        case 'checked_in':
          return _CheckedInView(
            controller: controller,
            onScanNext: _resumeScanner,
            onHome: () => Get.back(),
          );
        case 'already_checked_in':
          return _AlreadyUsedView(
            controller: controller,
            onScanNext: _resumeScanner,
          );
        case '':
          return _ScannerView(
            scannerController: scannerController,
            torchEnabled: _torchEnabled,
            onToggleTorch: _toggleTorch,
            onDetect: _onDetect,
            onClose: () => Get.back(),
            onCameraDenied: () => controller.cameraDenied.value = true,
          );
        default:
          return _RejectedView(
            controller: controller,
            onScanNext: _resumeScanner,
          );
      }
    });
  }
}

// ─── Écran 16 : scan ────────────────────────────────────────────────────────
class _ScannerView extends StatelessWidget {
  final MobileScannerController scannerController;
  final bool torchEnabled;
  final VoidCallback onToggleTorch;
  final void Function(BarcodeCapture) onDetect;
  final VoidCallback onClose;
  final VoidCallback onCameraDenied;

  const _ScannerView({
    required this.scannerController,
    required this.torchEnabled,
    required this.onToggleTorch,
    required this.onDetect,
    required this.onClose,
    required this.onCameraDenied,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScannerBg,
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: onDetect,
            errorBuilder: (context, error) {
              if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
                WidgetsBinding.instance.addPostFrameCallback((_) => onCameraDenied());
              }
              return const ColoredBox(color: kScannerBg);
            },
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.16),
                radius: 0.62,
                colors: [kGreenOverlay35, Colors.transparent],
              ),
            ),
            child: SizedBox.expand(),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundButton(icon: PhosphorIconsBold.x, onTap: onClose),
                      Text(
                        'CHECK-IN',
                        style: kManrope(
                          size: 14,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.06 * 14,
                        ),
                      ),
                      _RoundButton(
                        icon: torchEnabled
                            ? PhosphorIconsFill.lightbulb
                            : PhosphorIconsRegular.lightbulb,
                        onTap: onToggleTorch,
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                const _ScanFrame(),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: Column(
                    children: [
                      Text(
                        'Placez le QR du joueur dans le cadre',
                        textAlign: TextAlign.center,
                        style: kArchivo(size: 19, weight: FontWeight.w700, color: Colors.white, height: 1.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La lecture est automatique.',
                        textAlign: TextAlign.center,
                        style: kManrope(
                          size: 13.5,
                          weight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 38),
                  child: Column(
                    children: [
                      _DarkButton(
                        label: 'Saisir le code à 6 chiffres',
                        onTap: () => AppSnackbar.info('Bientôt disponible.'),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Get.to(() => const AttendanceScreen()),
                        child: SizedBox(
                          height: 46,
                          child: Center(
                            child: Text(
                              'Chercher dans les réservations du jour',
                              style: kManrope(
                                size: 13.5,
                                weight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
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
    );
  }
}

class _ScanFrame extends StatefulWidget {
  const _ScanFrame();

  @override
  State<_ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<_ScanFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        children: [
          const _Corner(alignment: Alignment.topLeft),
          const _Corner(alignment: Alignment.topRight),
          const _Corner(alignment: Alignment.bottomLeft),
          const _Corner(alignment: Alignment.bottomRight),
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => Positioned(
              left: 14,
              right: 14,
              top: 120 + (_anim.value * 184 - 92),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: kGreenLight,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: kGreenLight.withValues(alpha: 0.55),
                      blurRadius: 18,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final Alignment alignment;

  const _Corner({required this.alignment});

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Colors.white, width: 4);
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    return Align(
      alignment: alignment,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? side : BorderSide.none,
            bottom: isTop ? BorderSide.none : side,
            left: isLeft ? side : BorderSide.none,
            right: isLeft ? BorderSide.none : side,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(16) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(16) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(16) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(16) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

// ─── Écran 17 : vérification ────────────────────────────────────────────────
class _VerifyingView extends StatelessWidget {
  const _VerifyingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScannerBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(color: kGreenLight, strokeWidth: 3),
            ),
            const SizedBox(height: 22),
            Text(
              'Vérification…',
              style: kArchivo(size: 19, weight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Écran 18 : billet valide ───────────────────────────────────────────────
class _ValidTicketView extends StatelessWidget {
  final QrCheckInController controller;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onWrongTicket;

  const _ValidTicketView({
    required this.controller,
    required this.onConfirm,
    required this.onWrongTicket,
  });

  @override
  Widget build(BuildContext context) {
    final r = controller.reservation.value ?? const {};
    return _ResultScaffold(
      headerColor: kGreenLight,
      iconBg: kGreen,
      icon: PhosphorIconsBold.check,
      iconColor: Colors.white,
      title: 'Billet valide',
      titleColor: kGreenInk,
      subtitle: 'Réservation payée intégralement',
      subtitleColor: kGreenMutedText,
      statusBarDark: true,
      body: Column(
        children: [
          _ClientCard(reservation: r),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            child: Text(
              'Le joueur est attendu à ${r['startSlot'] ?? ''}.\nConfirmez sa présence pour libérer l\'accès au terrain.',
              textAlign: TextAlign.center,
              style: kManrope(size: 13, weight: FontWeight.w400, color: kTextSub, height: 1.55),
            ),
          ),
        ],
      ),
      primaryLabel: 'Confirmer la présence',
      onPrimary: onConfirm,
      secondaryLabel: 'Ce n\'est pas le bon billet',
      onSecondary: onWrongTicket,
      busy: controller.isConfirming.value,
    );
  }
}

// ─── Écran 22 : créneau pas commencé ────────────────────────────────────────
class _TooEarlyView extends StatelessWidget {
  final QrCheckInController controller;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onBack;

  const _TooEarlyView({
    required this.controller,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final r = controller.reservation.value ?? const {};
    final now = DateFormat('HH:mm').format(DateTime.now());
    return _ResultScaffold(
      headerColor: kGold,
      iconBg: Colors.white.withValues(alpha: 0.24),
      icon: PhosphorIconsRegular.clock,
      iconColor: Colors.white,
      title: 'Créneau pas commencé',
      titleColor: Colors.white,
      subtitle: 'Le billet est valide, mais ${controller.timeUntilSlot}',
      subtitleColor: Colors.white.withValues(alpha: 0.9),
      body: Column(
        children: [
          _ClientCard(
            reservation: r,
            slotLabel: 'SON CRÉNEAU',
            slotBg: kGoldLight,
            slotLabelColor: kGoldInk,
            slotValueColor: kGoldDarkInk,
            secondTileLabel: 'IL EST',
            secondTileValue: now,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
            child: Text(
              'Vous pouvez le faire entrer maintenant — la présence sera datée de l\'heure réelle.',
              textAlign: TextAlign.center,
              style: kManrope(size: 13, weight: FontWeight.w400, color: kTextSub, height: 1.55),
            ),
          ),
        ],
      ),
      primaryLabel: 'Confirmer quand même',
      onPrimary: onConfirm,
      secondaryLabel: 'Revenir au scan',
      onSecondary: onBack,
      busy: controller.isConfirming.value,
    );
  }
}

// ─── Écran 21 : billet déjà utilisé ─────────────────────────────────────────
class _AlreadyUsedView extends StatelessWidget {
  final QrCheckInController controller;
  final Future<void> Function() onScanNext;

  const _AlreadyUsedView({required this.controller, required this.onScanNext});

  @override
  Widget build(BuildContext context) {
    final r = controller.reservation.value ?? const {};
    final checkedInAt = DateTime.tryParse(r['checkedInAt']?.toString() ?? '')?.toLocal();
    final since = checkedInAt == null ? null : DateTime.now().difference(checkedInAt);

    return _ResultScaffold(
      headerColor: kRed,
      iconBg: Colors.white.withValues(alpha: 0.2),
      icon: PhosphorIconsBold.x,
      iconColor: Colors.white,
      title: 'Billet déjà utilisé',
      titleColor: Colors.white,
      subtitle: since == null
          ? 'Ce QR a déjà servi'
          : 'Ce QR a servi il y a ${_humanize(since)}',
      subtitleColor: Colors.white.withValues(alpha: 0.85),
      body: Column(
        children: [
          _ClientCard(reservation: r, avatarMuted: true),
          if (checkedInAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                decoration: BoxDecoration(
                  color: kRedSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREMIER SCAN',
                      style: kManrope(
                        size: 11,
                        weight: FontWeight.w500,
                        color: kRedStrong,
                        letterSpacing: 0.04 * 11,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      DateFormat('HH:mm', 'fr_FR').format(checkedInAt),
                      style: kArchivo(size: 15, weight: FontWeight.w700, color: kRedInk, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
            child: Text(
              'Si le joueur affirme ne pas être entré, laissez-le passer : la double entrée est déjà tracée dans l\'historique.',
              textAlign: TextAlign.center,
              style: kManrope(size: 13, weight: FontWeight.w400, color: kTextSub, height: 1.55),
            ),
          ),
        ],
      ),
      primaryLabel: 'Scanner le suivant',
      onPrimary: onScanNext,
      // Le scan refusé est déjà tracé dans l'historique côté backend : on
      // laisse donc le propriétaire arbitrer sur place sans rien réécrire.
      secondaryLabel: 'Laisser entrer quand même',
      onSecondary: () async {
        AppSnackbar.info('Entrée autorisée. Le double scan reste tracé.');
        await onScanNext();
      },
      busy: false,
    );
  }

  static String _humanize(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} minutes';
    if (d.inHours < 24) return '${d.inHours} h';
    return '${d.inDays} j';
  }
}

// ─── Billet refusé (not_confirmed / not_found / erreur) ─────────────────────
class _RejectedView extends StatelessWidget {
  final QrCheckInController controller;
  final Future<void> Function() onScanNext;

  const _RejectedView({required this.controller, required this.onScanNext});

  @override
  Widget build(BuildContext context) {
    final r = controller.reservation.value;
    return _ResultScaffold(
      headerColor: kRed,
      iconBg: Colors.white.withValues(alpha: 0.2),
      icon: PhosphorIconsBold.warning,
      iconColor: Colors.white,
      title: controller.status.value == 'not_confirmed'
          ? 'Billet non payé'
          : 'Billet non reconnu',
      titleColor: Colors.white,
      subtitle: controller.message.value,
      subtitleColor: Colors.white.withValues(alpha: 0.85),
      body: r == null
          ? const SizedBox.shrink()
          : _ClientCard(reservation: r, avatarMuted: true),
      primaryLabel: 'Scanner le suivant',
      onPrimary: onScanNext,
      busy: false,
    );
  }
}

// ─── Écran 19 : présence confirmée ──────────────────────────────────────────
class _CheckedInView extends StatelessWidget {
  final QrCheckInController controller;
  final Future<void> Function() onScanNext;
  final VoidCallback onHome;

  const _CheckedInView({
    required this.controller,
    required this.onScanNext,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final r = controller.reservation.value ?? const {};
    final checkedInAt = DateTime.tryParse(r['checkedInAt']?.toString() ?? '')?.toLocal();
    final terrain = [
      r['terrainName']?.toString() ?? '',
      if ((r['subTerrainName']?.toString() ?? '').isNotEmpty) r['subTerrainName'].toString(),
    ].where((e) => e.isNotEmpty).join(' — ');

    return Scaffold(
      backgroundColor: kGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 98,
                height: 98,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: kGreenLight, shape: BoxShape.circle),
                child: const PhosphorIcon(PhosphorIconsBold.check, color: kGreen, size: 50),
              ),
              const SizedBox(height: 26),
              Text(
                'Présence\nconfirmée',
                textAlign: TextAlign.center,
                style: kArchivo(
                  size: 31,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.02 * 31,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${r['clientName'] ?? ''}${terrain.isEmpty ? '' : ' · $terrain'} · ${r['startSlot'] ?? ''}'
                '${checkedInAt == null ? '' : '\nEnregistré à ${DateFormat('HH:mm').format(checkedInAt)}'}',
                textAlign: TextAlign.center,
                style: kManrope(
                  size: 14.5,
                  weight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.5,
                ),
              ),
              Obx(() {
                final upcoming = controller.upcomingWithinHour.value;
                if (upcoming == 0) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(top: 26),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$upcoming joueur${upcoming > 1 ? 's' : ''} attendu${upcoming > 1 ? 's' : ''} dans l\'heure',
                        style: kManrope(size: 13, weight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                );
              }),
              const Spacer(),
              _WhiteButton(
                label: 'Scanner le suivant',
                icon: PhosphorIconsRegular.scan,
                onTap: onScanNext,
              ),
              const SizedBox(height: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onHome,
                child: SizedBox(
                  height: 48,
                  child: Center(
                    child: Text(
                      'Revenir à l\'accueil',
                      style: kManrope(
                        size: 14.5,
                        weight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Écran 24 : caméra bloquée ──────────────────────────────────────────────
class _CameraDeniedView extends StatelessWidget {
  final VoidCallback onRetry;

  const _CameraDeniedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScannerBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kRed.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const PhosphorIcon(
                  PhosphorIconsRegular.cameraSlash,
                  color: kRedMuted,
                  size: 44,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'L\'appareil photo est bloqué',
                textAlign: TextAlign.center,
                style: kArchivo(size: 26, weight: FontWeight.w800, color: Colors.white, height: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                'MiniFoot n\'utilise la caméra que pour lire les QR des joueurs. Aucune photo n\'est enregistrée.',
                textAlign: TextAlign.center,
                style: kManrope(
                  size: 14,
                  weight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.62),
                  height: 1.6,
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => AppSnackbar.info('Bientôt disponible.'),
                child: Container(
                  height: 58,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(18)),
                  child: Text(
                    'Saisir le code à la main',
                    style: kManrope(size: 16, weight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _DarkButton(
                label: 'Ouvrir les réglages du téléphone',
                height: 52,
                onTap: () async {
                  await openAppSettings();
                  onRetry();
                },
              ),
              const SizedBox(height: 38),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pièces réutilisées ─────────────────────────────────────────────────────
class _ResultScaffold extends StatelessWidget {
  final Color headerColor;
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final String subtitle;
  final Color subtitleColor;
  final Widget body;
  final String primaryLabel;
  final Future<void> Function() onPrimary;
  final String? secondaryLabel;
  final Future<void> Function()? onSecondary;
  final bool busy;
  final bool statusBarDark;

  const _ResultScaffold({
    required this.headerColor,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.subtitle,
    required this.subtitleColor,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    required this.busy,
    this.statusBarDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + 22, 22, 32),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: PhosphorIcon(icon, color: iconColor, size: 38),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: kArchivo(size: 26, weight: FontWeight.w800, color: titleColor, height: 1.2),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: kManrope(size: 13.5, weight: FontWeight.w500, color: subtitleColor, height: 1.45),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 22, bottom: 16),
              child: body,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: busy ? null : () => onPrimary(),
                  child: Container(
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: busy ? kGreen.withValues(alpha: 0.6) : kGreen,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: kGreen.withValues(alpha: 0.4),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            primaryLabel,
                            style: kManrope(size: 16, weight: FontWeight.w700, color: Colors.white),
                          ),
                  ),
                ),
                if (secondaryLabel != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: busy ? null : () => onSecondary?.call(),
                    child: SizedBox(
                      height: 48,
                      child: Center(
                        child: Text(
                          secondaryLabel!,
                          style: kManrope(size: 14, weight: FontWeight.w600, color: kTextSub),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Map<String, dynamic> reservation;
  final bool avatarMuted;
  final String slotLabel;
  final Color slotBg;
  final Color slotLabelColor;
  final Color slotValueColor;
  final String? secondTileLabel;
  final String? secondTileValue;

  const _ClientCard({
    required this.reservation,
    this.avatarMuted = false,
    this.slotLabel = 'CRÉNEAU',
    this.slotBg = kBg,
    this.slotLabelColor = kTextSub,
    this.slotValueColor = kTextPrim,
    this.secondTileLabel,
    this.secondTileValue,
  });

  @override
  Widget build(BuildContext context) {
    final name = reservation['clientName']?.toString() ?? '';
    final phone = reservation['clientPhone']?.toString() ?? '';
    final terrain = [
      reservation['terrainName']?.toString() ?? '',
      if ((reservation['subTerrainName']?.toString() ?? '').isNotEmpty)
        reservation['subTerrainName'].toString(),
    ].where((e) => e.isNotEmpty).join(' — ');
    final slot =
        '${reservation['startSlot'] ?? ''} → ${reservation['endSlot'] ?? ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: kTextPrim.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: avatarMuted ? kSurfaceMuted : kGreen,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Text(
                    _initials(name),
                    style: kArchivo(
                      size: 18,
                      weight: FontWeight.w700,
                      color: avatarMuted ? kTextSub : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: kArchivo(size: 19, weight: FontWeight.w700, color: kTextPrim, height: 1.2),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          phone,
                          style: kManrope(size: 13, weight: FontWeight.w400, color: kTextSub, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    label: slotLabel,
                    value: slot,
                    bg: slotBg,
                    labelColor: slotLabelColor,
                    valueColor: slotValueColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Tile(
                    label: secondTileLabel ?? 'TERRAIN',
                    value: secondTileValue ?? (terrain.isEmpty ? '—' : terrain),
                    bg: kBg,
                    labelColor: kTextSub,
                    valueColor: kTextPrim,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts.last[0] : '';
    return '$first$second'.toUpperCase();
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final Color bg;
  final Color labelColor;
  final Color valueColor;

  const _Tile({
    required this.label,
    required this.value,
    required this.bg,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: kManrope(size: 11, weight: FontWeight.w500, color: labelColor, letterSpacing: 0.04 * 11),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: kArchivo(size: 16, weight: FontWeight.w700, color: valueColor, height: 1.15),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: PhosphorIcon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _DarkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double height;

  const _DarkButton({required this.label, required this.onTap, this.height = 54});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: kManrope(size: 14.5, weight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}

class _WhiteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Future<void> Function() onTap;

  const _WhiteButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(),
      child: Container(
        height: 58,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(icon, color: kGreen, size: 20),
            const SizedBox(width: 10),
            Text(label, style: kManrope(size: 16, weight: FontWeight.w700, color: kGreen)),
          ],
        ),
      ),
    );
  }
}
