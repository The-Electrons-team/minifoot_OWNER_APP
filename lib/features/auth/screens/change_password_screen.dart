import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/auth_controller.dart';

class ForceChangePasswordScreen extends StatefulWidget {
  const ForceChangePasswordScreen({super.key});

  @override
  State<ForceChangePasswordScreen> createState() =>
      _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState extends State<ForceChangePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authController = Get.find<AuthController>();
  final _obscurePassword = true.obs;
  final _obscureConfirm = true.obs;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final pass = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pass.isEmpty) {
      AppSnackbar.warning('Veuillez saisir un mot de passe.');
      return;
    }
    final passwordError = AppValidators.password(pass);
    if (passwordError != null) {
      AppSnackbar.warning('$passwordError.');
      return;
    }
    if (pass != confirm) {
      AppSnackbar.warning('Les mots de passe ne correspondent pas.');
      return;
    }

    _authController.changePassword(pass);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  PhosphorIconsRegular.lockKeyOpen,
                  color: kGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nouveau mot de passe',
                style: TextStyle(
                  color: kTextPrim,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Par sécurité, vous devez changer votre mot de passe lors de votre première connexion.',
                style: TextStyle(color: kTextSub, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 40),

              // Password field
              const Text(
                'Nouveau mot de passe',
                style: TextStyle(
                  color: kTextSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                () => TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword.value,
                  autofillHints: const [AutofillHints.newPassword],
                  style: const TextStyle(color: kTextPrim, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Entrez votre nouveau mot de passe',
                    prefixIcon: const Icon(
                      PhosphorIconsRegular.lock,
                      color: kTextLight,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () => _obscurePassword.toggle(),
                      icon: Icon(
                        _obscurePassword.value
                            ? PhosphorIconsRegular.eyeSlash
                            : PhosphorIconsRegular.eye,
                        color: kTextLight,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Confirm password field
              const Text(
                'Confirmer le mot de passe',
                style: TextStyle(
                  color: kTextSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                () => TextField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm.value,
                  autofillHints: const [AutofillHints.newPassword],
                  style: const TextStyle(color: kTextPrim, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Confirmez votre nouveau mot de passe',
                    prefixIcon: const Icon(
                      PhosphorIconsRegular.lock,
                      color: kTextLight,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () => _obscureConfirm.toggle(),
                      icon: Icon(
                        _obscureConfirm.value
                            ? PhosphorIconsRegular.eyeSlash
                            : PhosphorIconsRegular.eye,
                        color: kTextLight,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _authController.isLoading.value
                        ? null
                        : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: _authController.isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Enregistrer et continuer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () => _authController.logout(),
                  child: const Text(
                    'Se déconnecter',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
