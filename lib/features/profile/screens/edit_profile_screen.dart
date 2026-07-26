import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
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
        leading: GestureDetector(
          onTap: _close,
          behavior: HitTestBehavior.opaque,
          child: const Center(
            child: PhosphorIcon(PhosphorIcons.caretLeft,
              color: kTextPrim,
              size: 24,
            ),
          ),
        ),
        title: const Text(
          'Modifier le profil',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: kTextPrim,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(
        () => ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          children: [
            _buildProfileHero(),
            const SizedBox(height: 18),
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
                    borderRadius: BorderRadius.circular(18),
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
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          // Avatar cliquable
          GestureDetector(
            onTap: _showAvatarPicker,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Obx(() {
                  final hasImage = (controller.avatarUrl.value ?? '').isNotEmpty;
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: hasImage ? null : kGreenGradient,
                      boxShadow: [
                        BoxShadow(
                          color: kGreen.withValues(alpha: 0.20),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? Image.network(
                            controller.avatarUrl.value!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                controller.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              controller.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                  );
                }),
                // Upload indicator
                Obx(() => controller.isUploadingAvatar.value
                    ? Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                ),
                // Camera badge
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: kGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: kBgCard, width: 2.5),
                    ),
                    child: PhosphorIcon(PhosphorIcons.camera,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 4),
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
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileTextField(
            label: 'Prénom',
            controller: controller.firstNameCtrl,
            icon: PhosphorIconsDuotone.user,
          ),
          const Divider(height: 24, color: kDivider),
          _ProfileTextField(
            label: 'Nom',
            controller: controller.lastNameCtrl,
            icon: PhosphorIconsDuotone.identificationBadge,
          ),
          const Divider(height: 24, color: kDivider),
          _ReadOnlyProfileField(
            label: 'Téléphone',
            value: controller.phone.value,
            icon: PhosphorIconsDuotone.phone,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showPhoneChangeSheet,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: kBgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kGreenLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PhosphorIcon(PhosphorIcons.shieldCheck,
                      color: kGreen,
                      size: 18,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PhosphorIcon(PhosphorIcons.caretRight,
                    color: kGreen,
                    size: 18,
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

  void _showAvatarPicker() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 26),
        decoration: const BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
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
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Photo de profil',
                  style: TextStyle(
                    color: kTextPrim,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _AvatarSourceTile(
                icon: PhosphorIconsDuotone.camera,
                title: 'Prendre une photo',
                onTap: () {
                  Get.back();
                  controller.pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              _AvatarSourceTile(
                icon: PhosphorIconsDuotone.images,
                title: 'Choisir depuis la galerie',
                onTap: () {
                  Get.back();
                  controller.pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showPhoneChangeSheet() {
    controller.resetPhoneChangeForm();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
        decoration: const BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(PhosphorIconsDuotone.info,
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
                            height: 1.4,
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

class _AvatarSourceTile extends StatelessWidget {
  final dynamic icon;
  final String title;
  final VoidCallback onTap;

  const _AvatarSourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: PhosphorIcon(icon, color: kGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: kTextPrim,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PhosphorIcon(PhosphorIcons.caretRight,
              color: kTextLight,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final dynamic icon;

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
        TextField(
          controller: controller,
          enableInteractiveSelection: false,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: kTextPrim,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: kBgCard,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: _FieldIcon(icon: icon),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyProfileField extends StatelessWidget {
  final String label;
  final String value;
  final dynamic icon;

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              _FieldIcon(icon: icon),
              const SizedBox(width: 10),
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
              PhosphorIcon(PhosphorIcons.lockKey,
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
  final dynamic icon;

  const _FieldIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: kGreenLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PhosphorIcon(icon, color: kGreen, size: 18),
    );
  }
}
