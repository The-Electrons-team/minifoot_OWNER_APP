import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  static const double _headerHeight = 360;
  static const double _overlapAmount = 60.0;

  @override
  Widget build(BuildContext context) {
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header image
            _buildHeader(),

            // Card remontee de _overlapAmount dans l image
            Transform.translate(
              offset: const Offset(0, -_overlapAmount),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildFormCard(phoneCtrl, passCtrl),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      child: SizedBox(
        width: double.infinity,
        height: _headerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/terrain.jpeg',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                        'MINIFOOT',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                              color: Color(0x70000000),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                    ),
                    child: const Text(
                      'ESPACE PROPRIETAIRE',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(
    TextEditingController phoneCtrl,
    TextEditingController passCtrl,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: kElevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
                'Connectez-vous pour gerer vos terrains',
                style: TextStyle(fontSize: 14, color: kTextSub, height: 1.5),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 24),

          const _Label('Numero de telephone'),
          const SizedBox(height: 8),
          TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                style: const TextStyle(color: kTextPrim, fontSize: 16),
                decoration: InputDecoration(
                  hintText: '77 000 00 00',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          '\u{1F1F8}\u{1F1F3}',
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '+221',
                          style: TextStyle(
                            color: kTextPrim,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '|',
                          style: TextStyle(color: kBorder, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.15, end: 0),

          const SizedBox(height: 18),

          const _Label('Mot de passe'),
          const SizedBox(height: 8),
          Obx(
                () => TextField(
                  controller: passCtrl,
                  obscureText: controller.obscurePass.value,
                  style: const TextStyle(color: kTextPrim, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        PhosphorIcons.lock(PhosphorIconsStyle.duotone),
                        color: kGreen,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscurePass.value
                            ? PhosphorIcons.eyeClosed()
                            : PhosphorIcons.eye(),
                        color: kTextSub,
                      ),
                      onPressed: controller.toggleObscure,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 250.ms)
              .slideY(begin: 0.15, end: 0),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Get.bottomSheet(
                const _ForgotPasswordSheet(),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              ),
              style: TextButton.styleFrom(
                foregroundColor: kGreen,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: const Text('Mot de passe oublié ?'),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

          const SizedBox(height: 20),

          Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.startLogin(
                            '+221${phoneCtrl.text.trim()}',
                            passCtrl.text.trim(),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: kGreen.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                PhosphorIcons.signIn(
                                  PhosphorIconsStyle.duotone,
                                ),
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 360.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 28),
          const Divider(color: kBorder, thickness: 1),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Pas encore de compte ? ",
                style: TextStyle(color: kTextSub, fontSize: 14),
              ),
              GestureDetector(
                onTap: controller.goToRegister,
                child: const Text(
                  "S'inscrire",
                  style: TextStyle(
                    color: kGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 450.ms),
        ],
      ),
    );
  }
}

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet();

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final AuthController auth = Get.find<AuthController>();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController newPasswordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();

  bool codeSent = false;
  bool obscureNew = true;
  bool obscureConfirm = true;

  String get normalizedPhone => '+221${phoneCtrl.text.trim()}';

  @override
  void dispose() {
    phoneCtrl.dispose();
    codeCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (phoneCtrl.text.trim().length != 9) {
      AppSnackbar.warning('Entrez un numéro sénégalais valide (9 chiffres).');
      return;
    }

    try {
      await auth.requestPasswordReset(normalizedPhone);
      if (mounted) setState(() => codeSent = true);
    } catch (_) {}
  }

  Future<void> _resetPassword() async {
    final code = codeCtrl.text.trim();
    final password = newPasswordCtrl.text.trim();
    final confirm = confirmPasswordCtrl.text.trim();

    if (code.length != 6) {
      AppSnackbar.warning('Le code doit contenir 6 chiffres.');
      return;
    }

    if (password.length < 6) {
      AppSnackbar.warning('Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    if (password != confirm) {
      AppSnackbar.warning('Les mots de passe ne correspondent pas.');
      return;
    }

    try {
      await auth.resetForgottenPassword(
        phone: normalizedPhone,
        code: code,
        password: password,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
        decoration: const BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
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
                Text(
                  codeSent ? 'Nouveau mot de passe' : 'Mot de passe oublié',
                  style: const TextStyle(
                    color: kTextPrim,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  codeSent
                      ? 'Entrez le code reçu puis choisissez un nouveau mot de passe.'
                      : 'Entrez votre numéro pour recevoir un code de réinitialisation.',
                  style: const TextStyle(
                    color: kTextSub,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                if (!codeSent) ...[
                  const _Label('Numéro de téléphone'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: const InputDecoration(
                      hintText: '77 000 00 00',
                      prefixText: '+221 ',
                    ),
                  ),
                  const SizedBox(height: 22),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: auth.isLoading.value ? null : _sendCode,
                        child: auth.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Envoyer le code'),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    normalizedPhone,
                    style: const TextStyle(
                      color: kGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _Label('Code OTP'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: codeCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(hintText: '123456'),
                  ),
                  const SizedBox(height: 14),
                  const _Label('Nouveau mot de passe'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: newPasswordCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      hintText: 'Minimum 6 caractères',
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => obscureNew = !obscureNew),
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: kTextLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _Label('Confirmer'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmPasswordCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      hintText: 'Retapez le mot de passe',
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => obscureConfirm = !obscureConfirm),
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: kTextLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: auth.isLoading.value ? null : _resetPassword,
                        child: auth.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Réinitialiser'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => codeSent = false),
                      child: const Text('Changer de numéro'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: kTextSub,
    ),
  );
}
