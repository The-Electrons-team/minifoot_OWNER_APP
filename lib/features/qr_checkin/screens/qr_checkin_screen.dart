import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../shell/controllers/shell_controller.dart';
import '../controllers/qr_checkin_controller.dart';

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

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'checked_in':
        return kGreen;
      case 'ready':
        return kBlue;
      case 'already_checked_in':
        return kGold;
      case 'not_confirmed':
        return kOrange;
      default:
        return kRed;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'checked_in':
        return PhosphorIconsFill.checkCircle;
      case 'ready':
        return PhosphorIconsFill.qrCode;
      case 'already_checked_in':
        return PhosphorIconsFill.sealCheck;
      case 'not_confirmed':
        return PhosphorIconsFill.clockCountdown;
      default:
        return PhosphorIconsFill.warningCircle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Caméra plein écran ────────────────────────────────────────
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) async {
              // `barcodes` peut être vide : `.first` lèverait alors une
              // StateError en plein scan.
              if (capture.barcodes.isEmpty) return;
              final code = capture.barcodes.first.rawValue;
              if (code == null || code.isEmpty) return;
              await _pauseScanner();
              HapticFeedback.mediumImpact();
              await controller.scanCode(code);
            },
            // Sans ce builder, un refus de la caméra affiche l'erreur brute du
            // plugin et le contrôleur reste bloqué devant un écran noir.
            errorBuilder: (context, error) => _ScannerError(error: error),
          ),

          // ── Overlay sombre autour de la zone de scan ──────────────────
          _ScanOverlay(),

          // ── Barre du haut ─────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Material(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Get.find<ShellController>().select(0),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            PhosphorIconsRegular.caretLeft,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Scanner réservation',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _toggleTorch,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            _torchEnabled
                                ? PhosphorIconsFill.flashlight
                                : PhosphorIconsRegular.flashlight,
                            color: _torchEnabled ? kGold : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Résultat en bas après scan ────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Obx(() {
              final hasResult = controller.status.value.isNotEmpty;
              return AnimatedSlide(
                offset: hasResult ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: hasResult ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: _ResultPanel(
                    controller: controller,
                    onRescan: _resumeScanner,
                    formatDate: _formatDate,
                    statusColor: _statusColor,
                    statusIcon: _statusIcon,
                  ),
                ),
              );
            }),
          ),

          // ── Hint centré en bas de la zone scan (visible avant résultat) ──
          Obx(() {
            if (controller.status.value.isNotEmpty) return const SizedBox();
            return Positioned(
              bottom: 48,
              left: 40,
              right: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Cadrez le QR code dans la zone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
            );
          }),
        ],
      ),
    );
  }
}

// ── Overlay sombre avec découpe centrale ──────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const zoneSize = 240.0;
    const radius = 20.0;
    const borderLen = 36.0;
    const borderW = 4.0;

    return IgnorePointer(
      child: CustomPaint(
        painter: _OverlayPainter(
          zoneSize: zoneSize,
          radius: radius,
        ),
        child: Center(
          child: SizedBox(
            width: zoneSize,
            height: zoneSize,
            child: Stack(
              children: [
                // Coin haut-gauche
                Positioned(
                  top: 0,
                  left: 0,
                  child: _Corner(len: borderLen, w: borderW, r: radius,
                      top: true, left: true),
                ),
                // Coin haut-droit
                Positioned(
                  top: 0,
                  right: 0,
                  child: _Corner(len: borderLen, w: borderW, r: radius,
                      top: true, left: false),
                ),
                // Coin bas-gauche
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _Corner(len: borderLen, w: borderW, r: radius,
                      top: false, left: true),
                ),
                // Coin bas-droit
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _Corner(len: borderLen, w: borderW, r: radius,
                      top: false, left: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double zoneSize;
  final double radius;

  const _OverlayPainter({required this.zoneSize, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.60);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = zoneSize / 2;

    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    final hole = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - half, cy - half, cx + half, cy + half),
      Radius.circular(radius),
    );

    final path = Path()
      ..addRect(full)
      ..addRRect(hole)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => false;
}

class _Corner extends StatelessWidget {
  final double len;
  final double w;
  final double r;
  final bool top;
  final bool left;

  const _Corner({
    required this.len,
    required this.w,
    required this.r,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: len,
      height: len,
      child: CustomPaint(
        painter: _CornerPainter(w: w, r: r, top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double w;
  final double r;
  final bool top;
  final bool left;

  const _CornerPainter({
    required this.w,
    required this.r,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (top && left) {
      path.moveTo(0, s.height);
      path.lineTo(0, r);
      path.arcToPoint(Offset(r, 0),
          radius: Radius.circular(r), clockwise: true);
      path.lineTo(s.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(s.width - r, 0);
      path.arcToPoint(Offset(s.width, r),
          radius: Radius.circular(r), clockwise: true);
      path.lineTo(s.width, s.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, s.height - r);
      path.arcToPoint(Offset(r, s.height),
          radius: Radius.circular(r), clockwise: false);
      path.lineTo(s.width, s.height);
    } else {
      path.moveTo(0, s.height);
      path.lineTo(s.width - r, s.height);
      path.arcToPoint(Offset(s.width, s.height - r),
          radius: Radius.circular(r), clockwise: false);
      path.lineTo(s.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

// ── Panel résultat (slide depuis le bas) ─────────────────────────────────────

class _ResultPanel extends StatelessWidget {
  final QrCheckInController controller;
  final VoidCallback onRescan;
  final String Function(dynamic) formatDate;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;

  const _ResultPanel({
    required this.controller,
    required this.onRescan,
    required this.formatDate,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final status = controller.status.value;
    final reservation = controller.reservation.value;
    final color = statusColor(status);
    final canConfirm = status == 'ready' && reservation != null;

    return Container(
      decoration: const BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: controller.isProcessing.value
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: kGreen),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: kBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status row
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: PhosphorIcon(statusIcon(status),
                              color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            controller.message.value,
                            style: const TextStyle(
                              color: kTextPrim,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (reservation != null) ...[
                      const SizedBox(height: 16),
                      _InfoRow(
                        label: 'Client',
                        value: reservation['clientName']?.toString() ??
                            'Client MiniFoot',
                      ),
                      _InfoRow(
                        label: 'Terrain',
                        value: (reservation['subTerrainName']
                                    ?.toString()
                                    .isNotEmpty ==
                                true)
                            ? '${reservation['terrainName']} · ${reservation['subTerrainName']}'
                            : reservation['terrainName']?.toString() ?? '',
                      ),
                      _InfoRow(
                        label: 'Créneau',
                        value:
                            '${formatDate(reservation['date'])} · ${reservation['startSlot']} → ${reservation['endSlot']}',
                      ),
                      _InfoRow(
                        label: 'Réf.',
                        value: reservation['reference']?.toString() ?? '',
                      ),
                      if (reservation['checkedInAt'] != null)
                        _InfoRow(
                          label: 'Pointé le',
                          value: formatDate(reservation['checkedInAt']),
                        ),
                    ],

                    const SizedBox(height: 20),

                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onRescan,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kBorder),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Rescanner',
                              style: TextStyle(
                                color: kTextSub,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canConfirm
                                ? controller.isConfirming.value
                                    ? null
                                    : controller.confirmCheckIn
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              disabledBackgroundColor: kGreenLight,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: controller.isConfirming.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Confirmer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: kTextLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: kTextPrim,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Écran affiché quand la caméra n'est pas disponible.
///
/// Le cas dominant est un refus de la permission caméra. Sans ce widget, le
/// plugin affiche son message d'erreur brut en anglais sur fond noir et le
/// propriétaire, debout devant son client, n'a aucune idée de quoi faire.
class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  bool get _isPermissionDenied =>
      error.errorCode == MobileScannerErrorCode.permissionDenied;

  @override
  Widget build(BuildContext context) {
    final title = _isPermissionDenied
        ? 'Accès à la caméra refusé'
        : 'Caméra indisponible';
    final message = _isPermissionDenied
        ? 'Autorisez l\'accès à la caméra dans les réglages de votre téléphone '
              'pour scanner les QR codes de réservation.'
        : 'Impossible de démarrer la caméra. Fermez les autres applications '
              'qui l\'utilisent, puis réessayez.';

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIconsDuotone.videoCameraSlash,
                color: Colors.white.withValues(alpha: 0.85),
                size: 56,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                ),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
