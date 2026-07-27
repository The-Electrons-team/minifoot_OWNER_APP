import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/profile_controller.dart';

class SecurityScreen extends GetView<ProfileController> {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          behavior: HitTestBehavior.opaque,
          child: const Center(
            child: PhosphorIcon(PhosphorIcons.caretLeft,
              color: kTextPrim,
              size: 24,
            ),
          ),
        ),
        title: const Text(
          'Sécurité',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: kTextPrim,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        children: [
          _buildPasswordCard(),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
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
          const Text(
            'Changer le mot de passe',
            style: TextStyle(
              color: kTextPrim,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => _PasswordField(
              controller: controller.currentPasswordCtrl,
              label: 'Mot de passe actuel',
              obscure: controller.obscureCurrentPassword.value,
              onToggle: () => controller.obscureCurrentPassword.toggle(),
            ),
          ),
          const SizedBox(height: 14),
          Obx(
            () => _PasswordField(
              controller: controller.newPasswordCtrl,
              label: 'Nouveau mot de passe',
              hint: 'Min. 6 caractères',
              obscure: controller.obscureNewPassword.value,
              onToggle: () => controller.obscureNewPassword.toggle(),
            ),
          ),
          const SizedBox(height: 14),
          Obx(
            () => _PasswordField(
              controller: controller.confirmPasswordCtrl,
              label: 'Confirmation',
              obscure: controller.obscureConfirmPassword.value,
              onToggle: () => controller.obscureConfirmPassword.toggle(),
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: controller.isChangingPassword.value
                    ? null
                    : controller.changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: kGreen.withValues(alpha: 0.5),
                  elevation: 0,
                ),
                child: controller.isChangingPassword.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Mettre à jour',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    this.hint,
    required this.obscure,
    required this.onToggle,
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
          obscureText: obscure,
          autofillHints: const [AutofillHints.newPassword],
          style: const TextStyle(color: kTextPrim, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 10),
              child: PhosphorIcon(PhosphorIcons.lock,
                color: kTextLight,
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: PhosphorIcon(
                  obscure ? PhosphorIcons.eyeSlash : PhosphorIcons.eye,
                  color: kTextLight,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
