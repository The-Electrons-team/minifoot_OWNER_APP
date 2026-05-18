import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/auth_controller.dart';

class OwnerPendingScreen extends StatefulWidget {
  const OwnerPendingScreen({super.key});

  @override
  State<OwnerPendingScreen> createState() => _OwnerPendingScreenState();
}

class _OwnerPendingScreenState extends State<OwnerPendingScreen> {
  final AuthController controller = Get.find<AuthController>();
  final ImagePicker _picker = ImagePicker();

  File? _profile;
  File? _cniFront;
  File? _cniBack;
  final TextEditingController _cniCtrl = TextEditingController();

  @override
  void dispose() {
    _cniCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ValueChanged<File> onPicked) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: kBgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),
              _SourceTile(
                icon: PhosphorIcons.camera(PhosphorIconsStyle.duotone),
                label: 'Prendre une photo',
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              _SourceTile(
                icon: PhosphorIcons.image(PhosphorIconsStyle.duotone),
                label: 'Choisir depuis la galerie',
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() => onPicked(File(picked.path)));
      }
    } catch (e) {
      AppSnackbar.error('Impossible d\'accéder à la caméra ou la galerie. Vérifiez les permissions.');
    }
  }

  Future<void> _submitDocuments() async {
    final cni = _cniCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (cni.length != 13) {
      AppSnackbar.warning('La CNI doit faire exactement 13 chiffres.');
      return;
    }
    if (_profile == null || _cniFront == null || _cniBack == null) {
      AppSnackbar.warning('Veuillez fournir les 3 photos requises (profil, recto CNI, verso CNI).');
      return;
    }

    try {
      await controller.uploadOwnerDocuments(
        cniNumber: cni,
        profilePhoto: _profile!,
        cniFront: _cniFront!,
        cniBack: _cniBack!,
      );
      AppSnackbar.success('Vos documents de vérification ont été envoyés avec succès.');
    } catch (_) {
      // error already reported by Controller Snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentUser = controller.user.value;
      final isRejected = currentUser?.isOwnerRejected == true;
      final isDossierIncomplete =
          currentUser?.cniNumber == null || currentUser?.cniNumber?.isEmpty == true;

      return Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: isDossierIncomplete && !isRejected
                        ? _buildIncompleteDossierFlow()
                        : _buildStandardStatusView(currentUser, isRejected),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildIncompleteDossierFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.identificationCard(PhosphorIconsStyle.duotone),
              color: kOrange,
              size: 48,
            ),
          ),
        ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        const Text(
          'Dossier incomplet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: kTextPrim,
          ),
        ),
        IconButton(
          onPressed: controller.checkAuthStatus,
          icon: const Icon(Icons.refresh_rounded, color: kGreen),
          tooltip: 'Actualiser mon statut',
        ),
        const SizedBox(height: 10),
        const Text(
          'Vos pièces justificatives sont manquantes ou ont échoué à l’envoi. Complétez-les pour activer la vérification de votre compte.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kTextSub, fontSize: 13, height: 1.5),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),

        // CNI FIELD
        const Text(
          'Numéro CNI (13 chiffres)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kTextPrim),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cniCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(13),
          ],
          decoration: InputDecoration(
            hintText: 'Ex: 1773199901827',
            prefixIcon: Icon(PhosphorIcons.creditCard(), size: 20, color: kTextLight),
          ),
        ),
        const SizedBox(height: 24),

        // DOCUMENTS ROW
        const Text(
          'Documents originaux requis',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kTextPrim),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _UploadBox(
                label: 'Profil',
                file: _profile,
                icon: PhosphorIcons.user(PhosphorIconsStyle.duotone),
                onTap: () => _pickImage((f) => _profile = f),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UploadBox(
                label: 'CNI Recto',
                file: _cniFront,
                icon: PhosphorIcons.identificationCard(PhosphorIconsStyle.duotone),
                onTap: () => _pickImage((f) => _cniFront = f),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UploadBox(
                label: 'CNI Verso',
                file: _cniBack,
                icon: PhosphorIcons.identificationCard(PhosphorIconsStyle.duotone),
                onTap: () => _pickImage((f) => _cniBack = f),
              ),
            ),
          ],
        ),

        const Spacer(),
        const SizedBox(height: 32),

        // ACTION BUTTON
        Obx(() => SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: controller.isLoading.value ? null : _submitDocuments,
                icon: controller.isLoading.value
                    ? const SizedBox.shrink()
                    : Icon(
                        PhosphorIcons.cloudArrowUp(PhosphorIconsStyle.duotone),
                        color: Colors.white,
                        size: 22,
                      ),
                label: controller.isLoading.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Envoyer mon dossier',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            )),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: controller.logout,
          icon: Icon(PhosphorIcons.signOut(), size: 18),
          label: const Text(
            'Se déconnecter',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: TextButton.styleFrom(
            foregroundColor: kTextSub,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStandardStatusView(dynamic currentUser, bool isRejected) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: (isRejected ? kRed : kGreen).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isRejected
                ? PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone)
                : PhosphorIcons.hourglassMedium(PhosphorIconsStyle.duotone),
            color: isRejected ? kRed : kGreen,
            size: 44,
          ),
        ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 28),
        Text(
          isRejected ? 'Validation refusée' : 'Compte en attente de validation',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: kTextPrim,
            height: 1.25,
          ),
        ),
        IconButton(
          onPressed: controller.checkAuthStatus,
          icon: const Icon(Icons.refresh_rounded, color: kGreen),
          tooltip: 'Actualiser mon statut',
        ),
        const SizedBox(height: 12),
        Text(
          isRejected
              ? (currentUser?.ownerRejectionReason ??
                  'Vos documents n’ont pas été validés. Contactez MiniFoot pour corriger votre dossier.')
              : 'Votre compte gérant a bien été créé. Un administrateur MiniFoot doit valider vos documents avant l’ajout de complexes, terrains, réservations et paiements.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kTextSub,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kBgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            children: [
              _InfoRow(
                label: 'Téléphone',
                value: currentUser?.phone ?? '-',
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Statut',
                value: isRejected ? 'Refusé' : 'En attente',
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'CNI',
                value: currentUser?.cniNumber ?? '-',
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: controller.logout,
            icon: Icon(
              PhosphorIcons.signOut(PhosphorIconsStyle.duotone),
              color: Colors.white,
              size: 20,
            ),
            label: const Text(
              'Se déconnecter',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kTextPrim,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  final String label;
  final File? file;
  final IconData icon;
  final VoidCallback onTap;

  const _UploadBox({
    required this.label,
    required this.file,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile ? kGreen : kBorder,
            width: hasFile ? 1.5 : 1,
          ),
          image: hasFile
              ? DecorationImage(
                  image: FileImage(file!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.2),
                    BlendMode.darken,
                  ),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (hasFile ? kGreen : kBgSurface).withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasFile ? PhosphorIcons.check() : icon,
                      color: hasFile ? Colors.white : kTextSub,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: hasFile ? Colors.white : kTextSub,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            if (hasFile)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: kBorder),
                  ),
                  child: Icon(PhosphorIcons.pencilSimple(), size: 10, color: kTextPrim),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: kGreen),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: kTextPrim,
          fontSize: 14,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kTextSub, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: kTextPrim,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
