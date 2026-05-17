import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/owner_ui.dart';
import '../controllers/profile_controller.dart';

class EditProfileScreen extends GetView<ProfileController> {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          onPressed: _close,
          icon: Icon(
            PhosphorIcons.arrowLeft(PhosphorIconsStyle.duotone),
            size: 18,
          ),
          color: kTextPrim,
        ),
        title: const Text(
          'Modifier le profil',
          style: TextStyle(
            color: kTextPrim,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(
        () => ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
          children: [
            _buildProfileHero(),
            const SizedBox(height: 16),
            _buildFormCard(),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : controller.saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Enregistrer',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F5EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: kGreenGradient,
                  boxShadow: [
                    BoxShadow(
                      color: kGreen.withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    controller.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.ownerName.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextPrim,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      controller.phone.value,
                      style: const TextStyle(
                        color: kTextSub,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const OwnerSectionHeader(
            title: 'Informations du compte',
            subtitle:
                'Mettez à jour votre identité visible dans l’espace propriétaire.',
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: kCardShadow,
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OwnerSectionHeader(
            title: 'Modifier vos coordonnées',
            subtitle:
                'Gardez un nom professionnel clair pour vos terrains et réservations.',
          ),
          const SizedBox(height: 18),
          _ProfileTextField(
            label: 'Prénom',
            controller: controller.firstNameCtrl,
            icon: PhosphorIcons.user(PhosphorIconsStyle.duotone),
          ),
          const Divider(height: 24, color: kDivider),
          _ProfileTextField(
            label: 'Nom',
            controller: controller.lastNameCtrl,
            icon: PhosphorIcons.identificationBadge(PhosphorIconsStyle.duotone),
          ),
          const Divider(height: 24, color: kDivider),
          _ReadOnlyProfileField(
            label: 'Téléphone',
            value: controller.phone.value,
            icon: PhosphorIcons.phone(PhosphorIconsStyle.duotone),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _showPhoneChangeSheet,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: kBgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: kGreenLight,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone),
                      color: kGreen,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Changer le téléphone',
                          style: TextStyle(
                            color: kTextPrim,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Validation sécurisée par code OTP',
                          style: TextStyle(
                            color: kTextSub,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                    color: kGreen,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _close() {
    controller.resetForm();
    Get.back();
  }

  void _showPhoneChangeSheet() {
    controller.resetPhoneChangeForm();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
        decoration: const BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Changer le téléphone',
                  style: TextStyle(
                    color: kTextPrim,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBlueLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.info(PhosphorIconsStyle.duotone),
                        color: kBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Un code OTP sera envoyé au nouveau numéro pour confirmer le changement.',
                          style: TextStyle(
                            color: kBlue,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller.nextPhoneCtrl,
                  enableInteractiveSelection: false,
                  keyboardType: TextInputType.phone,
                  enabled: !controller.phoneOtpSent.value,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Nouveau numéro',
                    hintText: '77 000 00 00',
                    prefixText: '+221 ',
                  ),
                ),
                if (controller.phoneOtpSent.value) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.phoneOtpCtrl,
                    enableInteractiveSelection: false,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Code OTP',
                      hintText: '123456',
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.isChangingPhone.value
                        ? null
                        : controller.phoneOtpSent.value
                        ? controller.confirmPhoneChange
                        : controller.requestPhoneChange,
                    child: controller.isChangingPhone.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            controller.phoneOtpSent.value
                                ? 'Valider le nouveau numéro'
                                : 'Envoyer le code',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  const _ProfileTextField({
    required this.label,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextSub,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kBgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              _FieldIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  enableInteractiveSelection: false,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    color: kTextPrim,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextSub,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: kBgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              _FieldIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: kTextPrim,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                PhosphorIcons.lockKey(PhosphorIconsStyle.duotone),
                color: kTextLight,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldIcon extends StatelessWidget {
  final IconData icon;

  const _FieldIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: kGreenLight,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: kGreen, size: 17),
    );
  }
}
